(** Central event-routing component for the gateway.

    Owns subscription registries:

    - **Market-data subscribers**, keyed by [Symbol_id.t]. Each subscriber gets
      a pipe of [Best_bid_offer_update] and [Trade_report] events for the
      symbol they asked about. This is the public market-data feed.

    - **Audit subscribers**, an unfiltered firehose of every event the
      matching engine produces. Intended for the exchange operator's monitor;
      not appropriate to expose to ordinary clients.

    [dispatch] is the single place that decides "for each event, who gets
    it". *)

open! Core
open! Async
open Jsip_types
module Metrics = Jsip_gateway_protocol.Metrics

type t

(** Create a dispatcher.

    Events whose audience is a single participant (order-lifecycle responses
    and [Fill] events) are currently handed to a stub [push_to_session] that
    prints them on stdout, prefixed with the target participant. Wiring this
    up to real [Session] outbound pipes is a week-2 exercise. *)
val create : unit -> t

(** Subscribe to public market data for one or more [symbols]. The same pipe
    receives events for every requested symbol; the dispatcher avoids
    duplicates so a subscriber listed against multiple symbols only sees each
    event once. The pipe is removed from the dispatcher when its reader is
    closed. *)
val subscribe_market_data
  :  t
  -> Symbol_id.t list
  -> Exchange_event.t Pipe.Reader.t

(** Subscribe to the full unfiltered event firehose. Intended for the monitor
    / admin tools. [DO NOT EXPOSE] *)
val subscribe_audit : t -> Exchange_event.t Pipe.Reader.t

(** Subscribe to the per-second metrics feed (see {!Metrics.t}). Backs
    {!Rpc_protocol.metrics_feed_rpc}; the pipe is removed when its reader
    closes. *)
val subscribe_metrics : t -> Metrics.t Pipe.Reader.t

(** Push one metrics snapshot to every metrics subscriber. Called once per
    second by the sampler in {!Exchange_server.start}. *)
val push_metrics : t -> Metrics.t -> unit

(** setup / remove a session from the participant table in Dispatcher *)
val clean_up_session : t -> Session.t -> unit Deferred.t

val set_up_session : t -> Participant.t -> unit Deferred.t

(** Route each event to every interested subscriber:

    - Every event is pushed to every audit subscriber.
    - [Best_bid_offer_update] and [Trade_report] are pushed to the
      market-data subscribers that asked for the event's symbol.
    - [Order_accept], [Order_cancel], and [Order_reject] are pushed to the
      session of the order's owning participant (if logged in).
    - [Fill] is pushed to both the aggressor's and the resting party's
      session (if either is logged in).

    Each session lookup is O(1) and independent of subscriber count. *)
val dispatch : t -> Exchange_event.t list -> unit

(** Number of logged-in participants (each has exactly one session). *)
val session_count : t -> int

(** Current buffered length of each audit-subscriber pipe. One entry per
    subscriber, in unspecified order. Feeds {!Metrics.Pipe_occupancy}. *)
val audit_pipe_lengths : t -> int list

(** Current buffered length of each market-data subscriber pipe, grouped by
    the symbol whose bag they are in. A subscriber to several symbols
    contributes to several groups. *)
val market_data_pipe_lengths : t -> (Symbol_id.t * int list) list

(** Current outbound-pipe length of each logged-in session, keyed by
    participant. *)
val session_pipe_lengths : t -> (Participant.t * int) list

module For_testing : sig
  val audit_subscriber_count : t -> int
end

(** helpers for login *)
val valid_participant : t -> Participant.t -> bool

val get_session : t -> Participant.t -> Session.t option
