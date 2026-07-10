open! Core
open Jsip_types

(* [render_symbol] turns the wire's [Symbol_id.t] into display text. The
   types in [lib/types] can only print the raw id; name recovery is a
   consumer concern, so the caller supplies the renderer —
   [Symbol_id.to_string] to show ids (server-side logs, tests), or a
   {!Symbol_directory}-backed lookup to show names (client, monitor). That is
   why the fill and book rendering is reproduced here rather than delegated
   to [Fill.to_string]/[Book.to_string]: those stay int-only. *)

type render_symbol = Symbol_id.t -> string

let format_fill
  ~render_symbol
  ({ fill_id
   ; symbol_id
   ; price
   ; size
   ; aggressor_order_id
   ; aggressor_client_order_id
   ; aggressor_participant
   ; aggressor_side
   ; resting_order_id
   ; resting_client_order_id
   ; resting_participant
   } :
    Fill.t)
  =
  sprintf
    "fill_id=%d %s %s x%d aggressor=%s (client-id=%d) (%s) %s resting=%s \
     (client-id=%d) (%s)"
    fill_id
    (render_symbol symbol_id)
    (Price.to_string_dollar price)
    (Size.to_int size)
    (Order_id.to_string aggressor_order_id)
    (Client_order_id.to_int aggressor_client_order_id)
    (Participant.to_string aggressor_participant)
    (Side.to_string aggressor_side)
    (Order_id.to_string resting_order_id)
    (Client_order_id.to_int resting_client_order_id)
    (Participant.to_string resting_participant)
;;

let format_event ~render_symbol = function
  | Exchange_event.Order_accept { order_id; request } ->
    sprintf
      "ACCEPTED client-id=%s id=%s %s %s %d@%s %s"
      (Client_order_id.to_string request.client_order_id)
      (Order_id.to_string order_id)
      (render_symbol request.symbol_id)
      (Side.to_string request.side)
      (Size.to_int request.size)
      (Price.to_string_dollar request.price)
      (Time_in_force.to_string request.time_in_force)
  | Fill fill -> [%string "FILL %{format_fill ~render_symbol fill}"]
  | Order_cancel
      { client_order_id
      ; order_id
      ; participant = _
      ; symbol_id
      ; remaining_size
      ; reason
      } ->
    sprintf
      "CANCELLED client_id=%s id=%s %s remaining=%d reason=%s"
      (Client_order_id.to_string client_order_id)
      (Order_id.to_string order_id)
      (render_symbol symbol_id)
      (Size.to_int remaining_size)
      (Cancel_reason.to_string reason)
  | Order_reject { request; reason } ->
    sprintf
      "REJECTED client-id=%s %s %s %d@%s reason=%s"
      (Client_order_id.to_string request.client_order_id)
      (render_symbol request.symbol_id)
      (Side.to_string request.side)
      (Size.to_int request.size)
      (Price.to_string_dollar request.price)
      reason
  | Best_bid_offer_update { symbol_id; bbo } ->
    let bid = Level.opt_to_string bbo.bid in
    let ask = Level.opt_to_string bbo.ask in
    [%string "BBO %{render_symbol symbol_id} bid=%{bid} ask=%{ask}"]
  | Trade_report { symbol_id; price; size } ->
    let size = Size.to_int size in
    [%string "TRADE %{render_symbol symbol_id} %{price#Price} x%{size#Int}"]
  | Cancel_reject { participant; client_order_id; reason } ->
    sprintf
      "REJECTED Cancel Request client-id:%s (%s) reason=%s"
      (Client_order_id.to_string client_order_id)
      (Participant.to_string participant)
      reason
;;

let format_events ~render_symbol events =
  List.map events ~f:(format_event ~render_symbol) |> String.concat ~sep:"\n"
;;

let format_book ~render_symbol ({ symbol_id; bids; asks; bbo } : Book.t) =
  let format_side label levels =
    match levels with
    | [] -> [%string "  %{label}: (empty)"]
    | _ ->
      let lines =
        List.map levels ~f:(fun level -> [%string "    %{level#Level}"])
        |> String.concat ~sep:"\n"
      in
      [%string "  %{label}:\n%{lines}"]
  in
  String.concat
    ~sep:"\n"
    [ [%string "=== %{render_symbol symbol_id} ==="]
    ; format_side "BIDS" bids
    ; format_side "ASKS" asks
    ; [%string "  BBO: %{bbo#Bbo}"]
    ]
;;

let format_participant_fill ~render_symbol (fill : Fill.t) participant
  : string
  =
  match
    Fill.to_participant_view
      fill
      participant
      (render_symbol fill.symbol_id)
  with
  | None ->
    raise_s
      [%message
        "fill routed to non party"
          (participant : Participant.t)
          (fill : Fill.t)]
  | Some message -> message
;;
