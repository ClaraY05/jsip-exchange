(** A bot that stands in for non-informed ("noise") trading activity.

    Real markets see huge volumes of buying and selling that has no view on
    where the price is headed — a 401(k) rebalance, an index fund tracking a
    benchmark, a corporation liquidating an acquired block. The noise trader
    is our stand-in for all of it: it isn't trying to make money, so on each
    tick it picks a symbol, side, size, price, and time-in-force more or less
    at random and submits an order. Together with the market maker it keeps
    the matching engine busy — fills happen, the BBO moves, trade prints go
    out — so the informed bots in Part 2 have something to react to.

    To price an order marketable (crossing the spread) versus resting
    (sitting away from the touch), the bot needs the current best bid/offer.
    {!Jsip_bot_runtime.Bot_runtime} deliberately does not track BBOs — every
    strategy uses market data differently — so this bot keeps its own
    per-symbol cache in [Config.bbo_cache], updated from
    [Best_bid_offer_update] events in [on_event]. *)

open! Core
open! Async
open Jsip_types

(** A probability confined to the unit interval [[0.0, 1.0]].

    The type is abstract with a clamping constructor, so a scenario simply
    cannot build a config whose probabilities fall out of range. *)
module Percent : sig
  type t [@@deriving sexp_of]

  (** Clamp a float into [[0.0, 1.0]]: inputs below [0.0] become [0.0] and
      inputs above [1.0] become [1.0] *)
  val of_float : float -> t

  (** The underlying probability as a float in [[0.0, 1.0]] — e.g. to compare
      against a uniform random draw. *)
  val to_float : t -> float
end

module Config : sig
  type t [@@deriving sexp_of]

  (** Build a config from its dials. Because [t] is abstract, these labeled
      arguments are the only place a caller sees the knobs; there are no
      field getters. [next_client_id] starts at [0] and the BBO cache starts
      empty — neither is a caller concern. *)
  val create
    :  symbols:Symbol.t list
         (** Symbols the bot trades. Each tick it picks one uniformly at
             random and submits a single order for it; an empty list makes
             the bot inert. *)
    -> mean_size:int
         (** Center of the order-size band, in whole shares. Each order's
             size is drawn uniformly from a band around this value and
             clamped to at least one share, so quantities vary tick to tick
             without straying far from the mean. *)
    -> size_spread_fraction:float
         (** Half-width of the size band, as a fraction of {!mean_size}. At
             [0.5] each order's size is drawn from roughly [mean_size ± 50%];
             [0.0] pins every order to [mean_size]. Non-negative; larger
             values mean choppier quantities. *)
    -> tick_chance:Percent.t
         (** Probability that a given tick submits an order at all. Most
             ticks do nothing; only with this probability does the bot act *)
    -> aggressiveness_pct:Percent.t
         (** Probability that a submitted order is *marketable* rather
             than *resting* (quoted away from the touch so it joins the
             book). Higher values mean the bot takes liquidity more often
             than it makes it. *)
    -> ioc_pct:Percent.t
         (** Probability that a submitted order is [Ioc]
             (immediate-or-cancel) rather than [Day]. Governs time-in-force
             only *)
    -> t
end

include Jsip_bot_runtime.Bot_runtime.Bot with module Config := Config
