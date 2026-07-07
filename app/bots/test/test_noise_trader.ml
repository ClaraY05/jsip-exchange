(** Tests for {!Jsip_bots.Noise_trader}.

    Unlike {!Book_filler}, the noise trader's [Config.t] is *abstract*: the
    [.mli] exposes only [Config.create], with no field getters. So these
    tests can never read a value back off a config — they build one with
    [Config.create] and keep the constants they passed as their own [let]s.
    Everything asserted here is therefore about what the bot *submits*, not
    about its internal state.

    The bot fires probabilistically: on each tick it submits a single order
    only with probability [tick_chance]. We pin that probability to the
    extremes ([1.0] to force a submit, [0.0] to force silence) so a
    single-tick run is deterministic and we are testing behavior rather than
    a coin flip. *)

open! Core
open! Async
open Jsip_types
open Jsip_bot_runtime
open! Jsip_bots

let aapl = Symbol.of_string "AAPL"

(* The fundamental the harness pins for [aapl]. With the BBO cache empty
   (nothing has fed a [Best_bid_offer_update]), [choose_price] falls back to
   this value, so every price below is exactly [fair_cents]. *)
let fair_cents = 15000

(* Constants we hand to [Config.create]. They live here, not on the config,
   because the abstract type gives them back no other way. [tick_chance] is a
   parameter so a test can force the bot to always fire (1.0) or never fire
   (0.0). *)
let mean_size = 50

let make_config ~tick_chance : Noise_trader.Config.t =
  Noise_trader.Config.create
    ~symbols:[ aapl ]
    ~mean_size
    ~size_spread_fraction:0.5
    ~tick_chance:(Noise_trader.Percent.of_float tick_chance)
    ~aggressiveness_pct:(Noise_trader.Percent.of_float 0.5)
    ~ioc_pct:(Noise_trader.Percent.of_float 0.2)
;;

(* Drive exactly one [on_tick] and return the orders it submitted, oldest
   first. The harness fixes the participant, the RNG seed (7), and the
   oracle, so this behavior is fully deterministic. *)
let submit_one_tick config =
  let bot, submitted, _cancelled =
    Test_bots.make_recording_bot
      (module Noise_trader)
      config
      ~initial_price_cents:fair_cents
      ()
  in
  let context = Bot_runtime.For_testing.context_of bot in
  let%map () = Noise_trader.on_tick config context in
  List.rev !submitted
;;

let%expect_test "tick_chance = 1.0 submits exactly one well-formed order" =
  let%bind orders = submit_one_tick (make_config ~tick_chance:1.0) in
  (match orders with
   | [ order ] ->
     (* Size is drawn from a band around [mean_size] and clamped to at least
        one share; we can't see the band width (it's internal), so we bound
        it loosely but honestly. *)
     let size = Size.to_int order.size in
     printf "orders submitted: %d\n" (List.length orders);
     printf "size >= 1: %b\n" (size >= 1);
     (* Cache is empty, so pricing falls back to the fundamental. *)
     printf
       "price = fundamental: %b\n"
       (Price.to_int_cents order.price = fair_cents)
   | other ->
     printf "expected exactly one order, got %d\n" (List.length other));
  [%expect
    {|
    orders submitted: 1
    size >= 1: true
    price = fundamental: true
    |}];
  return ()
;;

let%expect_test "tick_chance = 0.0 submits nothing" =
  let%bind orders = submit_one_tick (make_config ~tick_chance:0.0) in
  printf "orders submitted: %d\n" (List.length orders);
  [%expect {| orders submitted: 0 |}];
  return ()
;;

let%expect_test "runs are reproducible: same seed submits identical orders" =
  (* Every stochastic choice flows through [Context.random], which the
     harness seeds identically on each build. Two independent single-tick
     runs must submit byte-for-byte identical requests. *)
  let%bind first = submit_one_tick (make_config ~tick_chance:1.0) in
  let%bind second = submit_one_tick (make_config ~tick_chance:1.0) in
  let identical =
    Sexp.equal
      ([%sexp_of: Order.Request.t list] first)
      ([%sexp_of: Order.Request.t list] second)
  in
  printf "identical across identical seed: %b\n" identical;
  [%expect {| identical across identical seed: true |}];
  return ()
;;
