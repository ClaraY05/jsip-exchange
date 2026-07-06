(** A once-per-second snapshot of exchange health, streamed over
    {!Rpc_protocol.metrics_feed_rpc} to the monitoring dashboard.

    [Metrics.t] records how the {e process} is behaving (memory, latency,
    queue depth).

    Produced by {!Metrics_collector.snapshot_and_reset} and pushed to
    subscribers by {!Dispatcher.push_metrics}. *)

open! Core
open Jsip_types

(** Per-second summary of one RPC's latency distribution. [count] is the
    number of samples in the window, so it doubles as that RPC's throughput
    (requests/second). Percentiles are computed server-side over the window's
    samples; see the rolling-window note on {!Rpc_protocol.metrics_feed_rpc}. *)
module Latency_summary : sig
  type t =
    { count : int
    ; p50 : Time_ns.Span.t
    ; p90 : Time_ns.Span.t
    ; p99 : Time_ns.Span.t
    ; max : Time_ns.Span.t
    }
  [@@deriving sexp, bin_io]
end

(** The subset of {!Core.Gc.Stat.t} the dashboard's memory pane needs.
    [live_words] (words reachable right now) is the headline figure; the
    remaining fields let the dashboard distinguish steady state from a leak *)
module Gc_stats : sig
  type t =
    { live_words : int
    ; heap_words : int
    ; top_heap_words : int
    ; minor_collections : int
    ; major_collections : int
    ; promoted_words : float
    }
  [@@deriving sexp, bin_io]

  (** Project a full [Gc.stat ()] result down to the fields above. *)
  val of_gc_stat : Gc.Stat.t -> t
end

(** Current queue length of every subscriber pipe, so a slow consumer backing
    up is visible immediately. [request_queue] is the inbound matching-engine
    queue (the bounded pipe that feeds
    {!Exchange_server.start_matching_loop}); the others are outbound. Each
    [int] is a [Pipe.length]: one entry per audit subscriber, per market-data
    subscriber (grouped by symbol), and per logged-in session. *)
module Pipe_occupancy : sig
  type t =
    { request_queue : int
    ; audit : int list
    ; market_data : (Symbol.t * int list) list
    ; sessions : (Participant.t * int) list
    }
  [@@deriving sexp, bin_io]
end

(** A proxy for how hard the matching engine is working. [iterations] counts
    how many requests the drain loop handled in the window;
    [max_inter_iteration_gap] is the largest wall-clock gap between
    consecutive iterations. Under backlog the engine iterates back-to-back
    (small gaps); when idle {e or} stalled the gap grows — so read this
    alongside [pipe_occupancy.request_queue], which disambiguates idle from
    stalled. *)
module Engine_busyness : sig
  type t =
    { iterations : int
    ; max_inter_iteration_gap : Time_ns.Span.t
    }
  [@@deriving sexp, bin_io]
end

(** One snapshot of data. [submit_latency]/[cancel_latency] are [None] when
    no orders of that kind arrived during the window (an empty window has no
    percentiles) *)
type t =
  { sampled_at : Time_ns.t
  ; gc : Gc_stats.t
  ; submit_latency : Latency_summary.t option
  ; cancel_latency : Latency_summary.t option
  ; pipe_occupancy : Pipe_occupancy.t
  ; engine_busyness : Engine_busyness.t
  ; connected_sessions : int
  }
[@@deriving sexp, bin_io]
