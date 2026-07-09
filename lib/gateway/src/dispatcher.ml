open! Core
open! Async
open Jsip_types
module Metrics = Jsip_gateway_protocol.Metrics

type t =
  { market_data_subscribers_by_symbol :
      Exchange_event.t Pipe.Writer.t Bag.t Symbol_id.Table.t
  ; audit_subscribers : Exchange_event.t Pipe.Writer.t Bag.t
  ; metrics_subscribers : Metrics.t Pipe.Writer.t Bag.t
  ; mutable participants : Session.t Participant_id.Table.t
  ; registry : Participant_registry.t
  }

let create () =
  { market_data_subscribers_by_symbol = Symbol_id.Table.create ()
  ; audit_subscribers = Bag.create ()
  ; metrics_subscribers = Bag.create ()
  ; participants = Participant_id.Table.create ()
  ; registry = Participant_registry.create ()
  }
;;

let subscribe_market_data t symbols =
  let reader, writer = Pipe.create () in
  (* Register the same writer in every requested symbol's bag. A per-symbol
     publish iterates a single bag, so a subscriber listed in multiple bags
     receives each event exactly once — only via whichever bag matches the
     event's symbol. *)
  let elts =
    List.map symbols ~f:(fun symbol_id ->
      let subscribers =
        Hashtbl.find_or_add
          t.market_data_subscribers_by_symbol
          ~default:Bag.create
          symbol_id
      in
      symbol_id, Bag.add subscribers writer)
  in
  don't_wait_for
    (let%map () = Pipe.closed writer in
     List.iter elts ~f:(fun (symbol_id, elt) ->
       match Hashtbl.find t.market_data_subscribers_by_symbol symbol_id with
       | None -> ()
       | Some subscribers -> Bag.remove subscribers elt));
  reader
;;

let subscribe_audit t =
  let reader, writer = Pipe.create () in
  let elt = Bag.add t.audit_subscribers writer in
  don't_wait_for
    (let%map () = Pipe.closed writer in
     Bag.remove t.audit_subscribers elt);
  reader
;;

let push_market_data t event symbol_id =
  match Hashtbl.find t.market_data_subscribers_by_symbol symbol_id with
  | None -> ()
  | Some subscribers ->
    Bag.iter subscribers ~f:(fun writer ->
      Pipe.write_without_pushback_if_open writer event)
;;

let push_audit t event =
  Bag.iter t.audit_subscribers ~f:(fun writer ->
    Pipe.write_without_pushback_if_open writer event)
;;

(* instrumentation tracking *)
let subscribe_metrics t =
  let reader, writer = Pipe.create () in
  let elt = Bag.add t.metrics_subscribers writer in
  don't_wait_for
    (let%map () = Pipe.closed writer in
     Bag.remove t.metrics_subscribers elt);
  reader
;;

let push_metrics t metrics =
  Bag.iter t.metrics_subscribers ~f:(fun writer ->
    Pipe.write_without_pushback_if_open writer metrics)
;;

let clean_up_session t session =
  let participant = Session.participant session in
  match Participant_registry.id_of_name t.registry participant with
  | None -> Async.return ()
  | Some id ->
    (match Hashtbl.find t.participants id with
     | Some _ ->
       Hashtbl.remove t.participants id;
       Async.return (Session.close session)
     | None -> Async.return ())
;;

let set_up_session t participant =
  let id = Participant_registry.intern t.registry participant in
  let%bind () =
    match Hashtbl.find t.participants id with
    | None -> Async.return ()
    | Some session -> clean_up_session t session
  in
  Async.return
    (Hashtbl.add_exn
       t.participants
       ~key:id
       ~data:(Session.create participant))
;;

let push_to_session t participant event =
  match Participant_registry.id_of_name t.registry participant with
  | None -> ()
  | Some id ->
    (match Hashtbl.find t.participants id with
     | Some session -> Session.push session event
     | None -> ())
;;

let dispatch_event t (event : Exchange_event.t) =
  push_audit t event;
  match event with
  | Best_bid_offer_update { symbol_id; bbo = _ } ->
    push_market_data t event symbol_id
  | Trade_report { symbol_id; price = _; size = _ } ->
    push_market_data t event symbol_id
  | Order_accept { order_id = _; request }
  | Order_reject { request; reason = _ } ->
    push_to_session t request.participant event
  | Cancel_reject { participant; client_order_id = _; reason = _ } ->
    push_to_session t participant event
  | Order_cancel
      { client_order_id = _
      ; order_id = _
      ; participant
      ; symbol_id = _
      ; remaining_size = _
      ; reason = _
      } ->
    push_to_session t participant event
  | Fill
      { fill_id = _
      ; symbol_id = _
      ; price = _
      ; size = _
      ; aggressor_order_id = _
      ; aggressor_client_order_id = _
      ; aggressor_participant
      ; aggressor_side = _
      ; resting_order_id = _
      ; resting_client_order_id = _
      ; resting_participant
      } ->
    push_to_session t aggressor_participant event;
    push_to_session t resting_participant event
;;

let dispatch t events = List.iter events ~f:(dispatch_event t)
let session_count t = Hashtbl.length t.participants

let audit_pipe_lengths t =
  Bag.to_list t.audit_subscribers |> List.map ~f:Pipe.length
;;

let market_data_pipe_lengths t =
  Hashtbl.to_alist t.market_data_subscribers_by_symbol
  |> List.map ~f:(fun (symbol_id, subscribers) ->
    symbol_id, Bag.to_list subscribers |> List.map ~f:Pipe.length)
;;

let session_pipe_lengths t =
  Hashtbl.to_alist t.participants
  |> List.map ~f:(fun (id, session) ->
    (* Display edge: resolve the id back to the participant name. *)
    Participant_registry.name t.registry id, Session.outbound_length session)
;;

module For_testing = struct
  let audit_subscriber_count t = Bag.length t.audit_subscribers
end

let valid_participant t participant =
  match Participant_registry.id_of_name t.registry participant with
  | None -> false
  | Some id -> Hashtbl.mem t.participants id
;;

let get_session t participant =
  match Participant_registry.id_of_name t.registry participant with
  | None -> None
  | Some id -> Hashtbl.find t.participants id
;;
