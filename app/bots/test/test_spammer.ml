(** Tests for the {!Jsip_bots.Spammer} pathological bot.

    The spammer's contract is narrow but easy to get subtly wrong: on every
    tick it must fire a full burst of [orders_per_tick] orders per symbol,
    each with a *fresh* client order ID (resting orders never free their IDs,
    so a reused one would be rejected as a duplicate). These tests pin
    exactly that behavior by recording what a single [on_tick] puts on the
    wire, via the local {!make_recording_bot} harness. *)

open! Core
open! Async
open Jsip_types
open Jsip_fundamental
open Jsip_bot_runtime
open! Jsip_bots
open Jsip_test_harness

(* There is deliberately no reproducibility test here: unlike an RNG-driven
   bot, the spammer makes no [Context.random] calls, so its burst is fixed by
   [Config.t] and the fundamental alone, with nothing stochastic to pin. *)

(* The fundamental the recording harness pins for every configured symbol
   (see {!make_recording_bot}). The spammer reads this each tick and rests
   [passive_offset_cents] off it, so the tests assert emitted prices directly
   against [fair_cents] and the configured offset — both values the bot
   actually consults — rather than a notional reference. *)
let fair_cents = 15_000

let spammer_config ~symbols ~orders_per_tick : Spammer.Config.t =
  { symbols
  ; orders_per_tick
  ; order_size = 10
  ; passive_offset_cents = 14_900
  ; side = Buy
  ; max_concurrent_submits = 4
  ; next_client_order_id = 1
  }
;;

(* Print recorded requests sorted by client order ID, so the output does not
   depend on the completion order of the concurrent submits. Unlike
   [Test_bots.print_submitted], this shows the ID, which is what lets a test
   see that every order in the burst is fresh. *)
let print_requests (submitted : Order.Request.t list ref) =
  !submitted
  |> List.sort ~compare:(fun (a : Order.Request.t) b ->
    Client_order_id.compare a.client_order_id b.client_order_id)
  |> List.iter ~f:(fun (req : Order.Request.t) ->
    printf
      !"id=%{Client_order_id} %{Side} %{Symbol} %d@%{Price#dollar} \
        %{Time_in_force}\n"
      req.client_order_id
      req.side
      req.symbol
      (Size.to_int req.size)
      req.price
      req.time_in_force)
;;

(* A recording [Spammer] bot whose mock oracle knows *every* symbol the bot
   is configured for, reading the set straight off [config.symbols]. The
   shared [Test_bots.make_recording_bot] pins a single-symbol ([aapl]) oracle
   — fine for the single-symbol tests, but the multi-symbol burst test needs
   a fundamental for [tsla] too, and [Fundamental_oracle.price] raises on an
   unknown symbol. Every symbol is pinned to a flat, motionless [fair_cents]
   fundamental (zero volatility, zero mean reversion) so prices are exact.
   Submits and cancels are recorded rather than dispatched. *)
let make_recording_bot (config : Spammer.Config.t) =
  let submitted = ref [] in
  let cancelled = ref [] in
  let submit request =
    submitted := request :: !submitted;
    return (Ok ())
  in
  let cancel order_id =
    cancelled := order_id :: !cancelled;
    return (Ok ())
  in
  let flat_config =
    { Fundamental_oracle.Config.initial_price_cents = fair_cents
    ; volatility_cents_per_sec = 0.0
    ; mean_reversion_strength = 0.0
    ; tick_interval = Time_ns.Span.of_sec 1.0
    }
  in
  let oracle =
    Fundamental_oracle.create
      (Symbol.Map.of_alist_exn
         (List.map config.symbols ~f:(fun symbol -> symbol, flat_config)))
      ~seed:42
  in
  let bot =
    Bot_runtime.create
      (module Spammer)
      config
      ~participant:Harness.alice
      ~oracle
      ~rng:(Splittable_random.of_int 7)
      ~submit
      ~cancel
      ~tick_interval:(Time_ns.Span.of_sec 1.0)
  in
  bot, submitted, cancelled
;;

let%expect_test "one tick fires a full burst of fresh, non-marketable orders"
  =
  let config = spammer_config ~symbols:[ Harness.aapl ] ~orders_per_tick:3 in
  let bot, submitted, _cancelled = make_recording_bot config in
  let ctx = Bot_runtime.For_testing.context_of bot in
  let%bind () = Spammer.on_tick config ctx in
  printf "burst size: %d\n" (List.length !submitted);
  print_requests submitted;
  let orders = List.rev !submitted in
  let all_day =
    List.for_all orders ~f:(fun (r : Order.Request.t) ->
      Time_in_force.equal r.time_in_force Day)
  in
  (* The spammer prices every order a fixed [passive_offset_cents] off the
     fundamental on the passive side, which is exactly what keeps it resting.
     Assert that relationship directly — against [fair_cents] (the
     fundamental the harness pins) and [config.passive_offset_cents], both of
     which the bot consults — rather than eyeballing the printed price. *)
  let priced_on_passive_side =
    List.for_all orders ~f:(fun (r : Order.Request.t) ->
      let expected =
        match r.side with
        | Buy -> fair_cents - config.passive_offset_cents
        | Sell -> fair_cents + config.passive_offset_cents
      in
      Price.to_int_cents r.price = expected)
  in
  printf "all time_in_force = Day: %b\n" all_day;
  printf
    "all priced on the passive side of fair: %b\n"
    priced_on_passive_side;
  [%expect
    {|
    burst size: 3
    id=1 BUY AAPL 10@$1.00 DAY
    id=2 BUY AAPL 10@$1.00 DAY
    id=3 BUY AAPL 10@$1.00 DAY
    all time_in_force = Day: true
    all priced on the passive side of fair: true
    |}];
  return ()
;;

let%expect_test "burst covers every configured symbol" =
  let config =
    spammer_config ~symbols:[ Harness.aapl; Harness.tsla ] ~orders_per_tick:2
  in
  let bot, submitted, _cancelled = make_recording_bot config in
  let ctx = Bot_runtime.For_testing.context_of bot in
  let%bind () = Spammer.on_tick config ctx in
  printf "burst size: %d\n" (List.length !submitted);
  print_requests submitted;
  [%expect
    {|
    burst size: 4
    id=1 BUY AAPL 10@$1.00 DAY
    id=2 BUY AAPL 10@$1.00 DAY
    id=3 BUY TSLA 10@$1.00 DAY
    id=4 BUY TSLA 10@$1.00 DAY
    |}];
  return ()
;;

let%expect_test "client order IDs stay fresh across ticks" =
  let config = spammer_config ~symbols:[ Harness.aapl ] ~orders_per_tick:2 in
  let bot, submitted, _cancelled = make_recording_bot config in
  let ctx = Bot_runtime.For_testing.context_of bot in
  let%bind () = Spammer.on_tick config ctx in
  let%bind () = Spammer.on_tick config ctx in
  print_requests submitted;
  let ids =
    List.map !submitted ~f:(fun (req : Order.Request.t) ->
      req.client_order_id)
  in
  printf
    "all ids distinct: %b\n"
    (not (List.contains_dup ids ~compare:Client_order_id.compare));
  [%expect
    {|
    id=1 BUY AAPL 10@$1.00 DAY
    id=2 BUY AAPL 10@$1.00 DAY
    id=3 BUY AAPL 10@$1.00 DAY
    id=4 BUY AAPL 10@$1.00 DAY
    all ids distinct: true
    |}];
  return ()
;;

let%expect_test "on_event is a no-op: a fill triggers no submit or cancel" =
  let config = spammer_config ~symbols:[ Harness.aapl ] ~orders_per_tick:2 in
  let bot, submitted, cancelled = make_recording_bot config in
  (* A fill in which one of the bot's own resting orders (owned by the
     harness participant, [Harness.alice]) trades against a taker. The
     spammer exists only to flood; it is not reactive, so a fill must move
     neither log. If someone later makes it respond to fills, one of these
     counts leaves zero and this test catches the behavior change. *)
  let fill : Exchange_event.t =
    Fill
      { fill_id = 1
      ; symbol = Harness.aapl
      ; price = Price.of_int_cents 100
      ; size = Size.of_int 10
      ; aggressor_order_id = Order_id.For_testing.of_int 1
      ; aggressor_client_order_id = Client_order_id.of_int 1
      ; aggressor_participant = Harness.bob
      ; aggressor_side = Sell
      ; resting_order_id = Order_id.For_testing.of_int 2
      ; resting_client_order_id = Client_order_id.of_int 1
      ; resting_participant = Harness.alice
      }
  in
  let%bind () = Bot_runtime.feed_event bot fill in
  printf "submitted after fill: %d\n" (List.length !submitted);
  printf "cancelled after fill: %d\n" (List.length !cancelled);
  [%expect {|
    submitted after fill: 0
    cancelled after fill: 0
    |}];
  return ()
;;
