open! Core
open Jsip_types

module Participant_client_order_ids = struct
  type t =
    { participant : Participant.t
    ; client_order_id : Client_order_id.t
    }
  [@@deriving sexp, compare, sexp_of, hash]

  include functor Comparable.Make_plain
  include functor Hashable.Make_plain
end

module Symbol_registry = struct
  type t = { books : Order_book.t Array.t } [@@deriving sexp_of]

  let create symbols : t =
    { books = Array.of_list (List.map symbols ~f:Order_book.create) }
  ;;

  let book t (symbol_id : Symbol_id.t) : Order_book.t option =
    let symbol_id_int = Symbol_id.to_int symbol_id in
    match symbol_id_int < 0 || symbol_id_int > Array.length t.books with
    | true -> None
    | false -> Some t.books.(symbol_id_int)
  ;;
end

type t =
  { book_registry : Symbol_registry.t
  ; order_id_gen : Order_id.Generator.t
  ; mutable next_fill_id : int
  ; mutable participant_client_order_ids :
      Order.t Participant_client_order_ids.Table.t
  }
[@@deriving sexp_of]

let create symbols =
  { book_registry = Symbol_registry.create symbols
  ; order_id_gen = Order_id.Generator.create ()
  ; next_fill_id = 1
  ; participant_client_order_ids =
      Participant_client_order_ids.Table.create ()
  }
;;

let check_client_order_id t participant client_order_id =
  Hashtbl.find
    t.participant_client_order_ids
    ({ participant; client_order_id } : Participant_client_order_ids.t)
;;

let book t symbol_id = Symbol_registry.book t.book_registry symbol_id

(* remove an order *)
let cancel t participant client_order_id =
  match check_client_order_id t participant client_order_id with
  | None ->
    [ Exchange_event.Cancel_reject
        { participant; client_order_id; reason = "Order does not exist" }
    ]
  | Some order ->
    (match book t (Order.symbol_id order) with
     | None ->
       [ Exchange_event.Cancel_reject
           { participant; client_order_id; reason = "Order does not exist" }
       ]
     | Some book ->
       Hashtbl.remove
         t.participant_client_order_ids
         ({ participant; client_order_id } : Participant_client_order_ids.t);
       let bbo_before = Order_book.best_bid_offer book in
       Order_book.remove book (Order.order_id order);
       let bbo_after = Order_book.best_bid_offer book in
       let order_cancel =
         Exchange_event.Order_cancel
           { client_order_id = Order.client_order_id order
           ; order_id = Order.order_id order
           ; participant = Order.participant order
           ; symbol_id = Order.symbol_id order
           ; remaining_size = Order.size order
           ; reason = Cancel_reason.Participant_requested
           }
       in
       let bbo_events =
         if Bbo.equal bbo_before bbo_after
         then []
         else
           [ Exchange_event.Best_bid_offer_update
               { symbol_id = Order.symbol_id order; bbo = bbo_after }
           ]
       in
       List.concat [ [ order_cancel ]; bbo_events ])
;;

(** Run the matching loop: repeatedly find a compatible resting order and
    fill against it. Returns the list of Fill and Trade_report events
    produced, and the next fill_id to use. *)
let rec match_loop ~book ~order ~fill_id =
  if Size.( <= ) (Order.remaining_size order) Size.zero
  then [], fill_id
  else (
    match Order_book.find_match book order with
    | None -> [], fill_id
    | Some resting ->
      let fill_size =
        Size.min (Order.remaining_size order) (Order.remaining_size resting)
      in
      Order.fill order ~by:fill_size;
      Order.fill resting ~by:fill_size;
      if Order.is_fully_filled resting
      then Order_book.remove book (Order.order_id resting);
      let fill_event =
        Exchange_event.Fill
          { fill_id
          ; symbol_id = Order.symbol_id order
          ; price = Order.price resting
          ; size = fill_size
          ; aggressor_order_id = Order.order_id order
          ; aggressor_participant = Order.participant order
          ; aggressor_client_order_id = Order.client_order_id order
          ; aggressor_side = Order.side order
          ; resting_order_id = Order.order_id resting
          ; resting_client_order_id = Order.client_order_id resting
          ; resting_participant = Order.participant resting
          }
      in
      let trade_event =
        Exchange_event.Trade_report
          { symbol_id = Order.symbol_id order
          ; price = Order.price resting
          ; size = fill_size
          }
      in
      let remaining_events, next_fill_id =
        match_loop ~book ~order ~fill_id:(fill_id + 1)
      in
      fill_event :: trade_event :: remaining_events, next_fill_id)
;;

let submit t (request : Order.Request.t) =
  match Symbol_registry.book t.book_registry request.symbol_id with
  | None ->
    [ Exchange_event.Order_reject { request; reason = "unknown symbol" } ]
  | Some book ->
    let order_id = Order_id.Generator.next t.order_id_gen in
    let order = Order.create request ~order_id in
    let accepted = Exchange_event.Order_accept { order_id; request } in
    (* Snapshot BBO before matching so we can detect changes. *)
    let bbo_before = Order_book.best_bid_offer book in
    (* Match *)
    let fill_events, next_fill_id =
      match_loop ~book ~order ~fill_id:t.next_fill_id
    in
    t.next_fill_id <- next_fill_id;
    (* Post-match: rest on book or cancel unfilled remainder. *)
    let post_events =
      if Size.( > ) (Order.remaining_size order) Size.zero
      then (
        match Order.time_in_force order with
        | Day ->
          Order_book.add book order;
          let key : Participant_client_order_ids.t =
            { participant = Order.participant order
            ; client_order_id = Order.client_order_id order
            }
          in
          Hashtbl.add_exn t.participant_client_order_ids ~key ~data:order;
          []
        | Ioc ->
          [ Exchange_event.Order_cancel
              { client_order_id = request.client_order_id
              ; order_id
              ; participant = Order.participant order
              ; symbol_id = Order.symbol_id order
              ; remaining_size = Order.remaining_size order
              ; reason = Ioc_remainder
              }
          ])
      else []
    in
    (* Emit BBO update if the best bid or ask changed. *)
    let bbo_after = Order_book.best_bid_offer book in
    let bbo_events =
      if Bbo.equal bbo_before bbo_after
      then []
      else
        [ Exchange_event.Best_bid_offer_update
            { symbol_id = Order.symbol_id order; bbo = bbo_after }
        ]
    in
    List.concat [ [ accepted ]; fill_events; post_events; bbo_events ]
;;
