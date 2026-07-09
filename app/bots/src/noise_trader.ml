open! Core
open! Async
open Jsip_types
module Context = Jsip_bot_runtime.Bot_runtime.Context

module Percent = struct
  type t = float [@@deriving sexp_of]

  (* Clamp into the unit interval so a stored [Percent.t] is always a valid
     probability, regardless of what the caller passed. *)
  let of_float value = Float.clamp_exn value ~min:0.0 ~max:1.0
  let to_float t = t
end

module Config = struct
  type t =
    { symbols : Symbol_id.t list
    ; mean_size : int
    ; size_spread_fraction : float
    ; tick_chance : Percent.t
    ; aggressiveness_pct : Percent.t
    ; ioc_pct : Percent.t
    ; bbo_cache : Bbo.t Symbol_id.Table.t
    ; mutable next_client_id : int
    }
  [@@deriving sexp_of]

  let create
    ~symbols
    ~mean_size
    ~size_spread_fraction
    ~tick_chance
    ~aggressiveness_pct
    ~ioc_pct
    =
    { symbols
    ; mean_size
    ; size_spread_fraction
    ; tick_chance
    ; aggressiveness_pct
    ; ioc_pct
    ; bbo_cache = Symbol_id.Table.create ()
    ; next_client_id = 0
    }
  ;;
end

let name = "noise_trader"

(* Cents past the opposite side's best price at which a marketable order is
   quoted, so it crosses the spread and trades immediately. *)
let marketable_cross_cents = 5

(* Cents away from this side's best price at which a resting order is quoted,
   so it joins the book instead of trading. *)
let resting_offset_cents = 5

let on_start (_config : Config.t) (_context : Context.t) : unit Deferred.t =
  (* No ladder or window state to prime; the bot reacts purely on ticks. *)
  Deferred.unit
;;

let on_tick (config : Config.t) (context : Context.t) : unit Deferred.t =
  (* helpers *)
  let random_size ~rng ~mean_size ~size_spread_fraction =
    let jitter =
      Int.max
        1
        (Float.iround_nearest_exn
           (Float.of_int mean_size *. size_spread_fraction))
    in
    let lo = Int.max 1 (mean_size - jitter) in
    let hi = Int.max lo (mean_size + jitter) in
    Size.of_int (Splittable_random.int rng ~lo ~hi)
  in
  (* Pick a price for an order on [side] of [symbol]. *)
  let choose_price
    ~rng
    ~(config : Config.t)
    ~context
    ~symbol
    ~(side : Side.t)
    : Price.t
    =
    let fundamental = Context.fundamental context symbol in
    let best on_side =
      match Hashtbl.find config.bbo_cache symbol with
      | None -> None
      | Some bbo -> Bbo.price bbo on_side
    in
    let is_marketable =
      Float.( < )
        (Splittable_random.float rng ~lo:0.0 ~hi:1.0)
        (Percent.to_float config.aggressiveness_pct)
    in
    match is_marketable with
    | true ->
      (match best (Side.flip side) with
       | None -> fundamental
       | Some opposite_best ->
         let cross = Price.of_int_cents marketable_cross_cents in
         (match side with
          | Buy -> Price.( + ) opposite_best cross
          | Sell -> Price.( - ) opposite_best cross))
    | false ->
      (match best side with
       | None -> fundamental
       | Some own_best ->
         let offset = Price.of_int_cents resting_offset_cents in
         (match side with
          | Buy -> Price.( - ) own_best offset
          | Sell -> Price.( + ) own_best offset))
  in
  (* Most ticks do nothing: only with probability [tick_chance] does the bot
     submit a single order, with a random symbol, side, size, price, and TIF. *)
  let rng = Context.random context in
  let roll = Splittable_random.float rng ~lo:0.0 ~hi:1.0 in
  if Float.( > ) roll (Percent.to_float config.tick_chance)
     || List.is_empty config.symbols
  then Deferred.unit
  else (
    let symbols = config.symbols in
    let symbol =
      List.nth_exn
        symbols
        (Splittable_random.int rng ~lo:0 ~hi:(List.length symbols - 1))
    in
    let side : Side.t =
      if Splittable_random.int rng ~lo:0 ~hi:1 = 0 then Buy else Sell
    in
    let size =
      random_size
        ~rng
        ~mean_size:config.mean_size
        ~size_spread_fraction:config.size_spread_fraction
    in
    let price = choose_price ~rng ~config ~context ~symbol ~side in
    let time_in_force : Time_in_force.t =
      if Float.( < )
           (Splittable_random.float rng ~lo:0.0 ~hi:1.0)
           (Percent.to_float config.ioc_pct)
      then Ioc
      else Day
    in
    let request =
      ({ client_order_id = Client_order_id.of_int config.next_client_id
       ; participant = Context.participant context
       ; symbol_id = symbol
       ; side
       ; price
       ; size
       ; time_in_force
       }
       : Order.Request.t)
    in
    config.next_client_id <- config.next_client_id + 1;
    match%map Context.submit context request with
    | Ok () -> ()
    | Error error ->
      [%log.error "noise_trader: submit failed" (error : Error.t)])
;;

let on_event
  (config : Config.t)
  (_context : Context.t)
  (event : Exchange_event.t)
  : unit Deferred.t
  =
  match event with
  | Best_bid_offer_update { symbol_id; bbo } ->
    Hashtbl.set config.bbo_cache ~key:symbol_id ~data:bbo;
    Deferred.unit
  | Order_accept _ | Fill _ | Order_cancel _ | Order_reject _
  | Trade_report _ | Cancel_reject _ ->
    Deferred.unit
;;
