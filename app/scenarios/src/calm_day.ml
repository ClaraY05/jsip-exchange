open! Core
open Jsip_types
open Jsip_scenario_runner
module Fundamental_oracle = Jsip_fundamental.Fundamental_oracle
module Bot_runtime = Jsip_bot_runtime.Bot_runtime

let name = "calm-day"

let description =
  "Quiet single-symbol market: one market maker, one noise trader, no news."
;;

(* The single symbol this scenario trades. Drives the exchange's known
   symbols, the oracle's price process, and the symbols both bots target. *)
let symbols = [ Symbol.of_string "AAPL" ]

(* Where the fundamental sits and how it moves. "Calm" means modest
   volatility and a gentle pull back toward the mean, per the exercise spec:
   ~3 cents/sec of volatility and a mean-reversion strength of ~0.05. Keeping
   [initial_price_cents] equal to the market maker's [fair_value_cents] below
   makes the two bots quote around the same level so trades actually print. *)
let initial_price_cents = 15000

let oracle_config : Fundamental_oracle.Config.t =
  Symbol.Map.of_alist_exn
    (List.map symbols ~f:(fun symbol ->
       ( symbol
       , ({ initial_price_cents
          ; volatility_cents_per_sec = 3.0
          ; mean_reversion_strength = 0.05
          ; tick_interval = Time_ns.Span.of_sec 1.0
          }
          : Fundamental_oracle.Config.symbol_config) )))
;;

let market_maker_spec () : Bot_spec.t =
  let config : Jsip_market_maker.Market_maker.Config.t =
    { symbol = List.hd_exn symbols
    ; fair_value_cents = initial_price_cents
    ; half_spread_cents = 5
    ; size_per_level = 100
    ; num_levels = 5
    ; client_id_manager = Client_order_id.Generator.create ()
    ; inventory_skew_cents_per_share = 1
    ; inventory_counter = Symbol.Table.create ()
    ; resting_client_order_ids = Client_order_id.Table.create ()
    }
  in
  Bot_spec.T
    { bot =
        (module Jsip_market_maker.Market_maker.Market_maker_bot
        : Bot_runtime.Bot
          with type Config.t = Jsip_market_maker.Market_maker.Config.t)
    ; config
    ; participant = Participant.of_string "MarketMaker"
    ; symbols
    ; rng_seed = 0
    ; tick_interval = Time_ns.Span.of_ms 500.0
    ; is_marketdata_consumer = false
    }
;;

let noise_trader_spec () : Bot_spec.t =
  let config : Jsip_bots.Noise_trader.Config.t =
    Jsip_bots.Noise_trader.Config.create
      ~symbols
      ~mean_size:100
      ~size_spread_fraction:0.2
      ~tick_chance:(Jsip_bots.Noise_trader.Percent.of_float 0.6)
      ~aggressiveness_pct:(Jsip_bots.Noise_trader.Percent.of_float 0.4)
      ~ioc_pct:(Jsip_bots.Noise_trader.Percent.of_float 0.15)
  in
  Bot_spec.T
    { bot =
        (module Jsip_bots.Noise_trader : Bot_runtime.Bot
          with type Config.t = Jsip_bots.Noise_trader.Config.t)
    ; config
    ; participant = Participant.of_string "NoiseTrader"
    ; symbols
    ; rng_seed = 1
    ; tick_interval = Time_ns.Span.of_ms 500.0
    ; is_marketdata_consumer = true
    }
;;

let configure () : Scenario_config.t =
  { name
  ; symbols
  ; oracle_config
  ; news = []
  ; bots = [ market_maker_spec (); noise_trader_spec () ]
  }
;;
