open! Core
open Jsip_types
open Async_log_kernel.Ppx_log_syntax

type t =
  { symbol : Symbol.t
  ; mutable bids : Order.t list
  ; mutable asks : Order.t list
  }
[@@deriving sexp_of]

let create symbol = { symbol; bids = []; asks = [] }
let symbol t = t.symbol

let side_list t side =
  match (side : Side.t) with Buy -> t.bids | Sell -> t.asks
;;

let set_side_list t side orders =
  match (side : Side.t) with
  | Buy -> t.bids <- orders
  | Sell -> t.asks <- orders
;;

let add t order =
  let side = Order.side order in
  set_side_list t side (order :: side_list t side)
;;

let remove' t order_id =
  let remove_from t side order_id =
    let orders = side_list t side in
    match
      List.partition_tf orders ~f:(fun o ->
        Order_id.equal (Order.order_id o) order_id)
    with
    | [], _ -> None
    | [ found ], rest ->
      set_side_list t side rest;
      Some found
    | matches, _ ->
      [%log.info
        "BUG: More than one order matching order_id found when removing"
          (order_id : Order_id.t)
          (matches : Order.t list)
          (t.symbol : Symbol.t)
          (side : Side.t)];
      None
  in
  match remove_from t Buy order_id with
  | Some _ as result -> result
  | None -> remove_from t Sell order_id
;;

let remove t order_id = ignore (remove' t order_id : Order.t option)

let find t order_id =
  let find_in side =
    List.find (side_list t side) ~f:(fun o ->
      Order_id.equal (Order.order_id o) order_id)
  in
  match find_in Buy with Some _ as result -> result | None -> find_in Sell
;;

(* NOTE: This walks the list front-to-back and returns the *first* tradable
   order, not the best-priced one. Orders are in reverse insertion order
   (newest first), so this matches against whatever was most recently added,
   regardless of price. See test_matching_engine.ml for a test that
   demonstrates why this is wrong. *)
let find_match t incoming =
  let incoming_side = Order.side incoming in
  let opposite_side = Side.flip incoming_side in
  let resting_orders = side_list t opposite_side in
  let get_better_order order1 order2 =
    if Price.is_more_aggressive
         opposite_side
         ~price:(Order.price order1)
         ~than:(Order.price order2)
    then order1
    else order2
  in
  let marketable_orders =
    List.filter resting_orders ~f:(fun outgoing_order ->
      Price.is_marketable
        incoming_side
        ~price:(Order.price incoming)
        ~resting_price:(Order.price outgoing_order))
  in
  match marketable_orders with
  | [] -> None
  | first_order :: other_orders ->
    Some (List.fold_left other_orders ~init:first_order ~f:get_better_order)
;;

let orders_on_side t side = side_list t side
let is_empty t = List.is_empty t.bids && List.is_empty t.asks
let count t side = List.length (side_list t side)

let best_price t side =
  let prices =
    List.map (side_list t side) ~f:(fun order -> Order.price order)
  in
  let get_better_price price1 price2 =
    if Price.is_more_aggressive side ~price:price1 ~than:price2
    then price1
    else price2
  in
  List.reduce prices ~f:get_better_price
;;

let best_level t side : Level.t option =
  match best_price t side with
  | None -> None
  | Some price ->
    let total_size =
      List.fold (side_list t side) ~init:Size.zero ~f:(fun acc order ->
        if Price.equal (Order.price order) price
        then Size.( + ) acc (Order.remaining_size order)
        else acc)
    in
    Some { price; size = total_size }
;;

let best_bid_offer t : Bbo.t =
  { bid = best_level t Buy; ask = best_level t Sell }
;;

let snapshot_side t (side : Side.t) =
  let compare (level1 : Level.t) (level2 : Level.t) =
    let price = level1.price in
    let than = level2.price in
    if Price.is_more_aggressive side ~price ~than
    then 1 (* higher precedence *)
    else if Price.( = ) price than
    then 0
    else -1
  in
  orders_on_side t side |> List.map ~f:Level.of_order |> List.sort ~compare
;;

let snapshot t =
  { Book.symbol = symbol t
  ; bids = snapshot_side t Buy
  ; asks = snapshot_side t Sell
  ; bbo = best_bid_offer t
  }
;;

module For_testing = struct
  let remove = remove'
end
