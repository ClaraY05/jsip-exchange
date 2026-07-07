(** The dashboard's pure state machine.

    Holds a rolling ~60-second window of {!Jsip_gateway_protocol.Metrics.t}
    snapshots (one per second, oldest first). [feed_metrics] appends a
    snapshot and evicts the oldest once the window is full; [display]
    projects the window into render-ready series the browser layer draws. *)

open! Core
open Jsip_types
module Metrics = Jsip_gateway_protocol.Metrics

(** One value per second across the window, oldest first. [None] marks a
    second with no datum (e.g. [submit_latency = None] when no orders arrived
    that second) so the sparkline can break its line rather than plot a false
    zero. Latencies are stored as milliseconds; counts and word figures as
    floats. *)
module Series : sig
  type t = float option array [@@deriving sexp_of, compare, equal]
end

(** Render-ready projection the browser layer reads. Every field is plain
    data decoupled from Vdom, so the controller stays testable. Series run
    oldest to newest; [_latest] scalars are the most recent snapshot's raw
    values.

    The panes are grouped into one submodule each so a new pane is a localised
    addition (a new submodule + one field on {!t}) rather than a scatter of
    fields across a flat record. *)
module Display : sig
  (** Process-memory pane: the live-words series plus the latest raw GC
      figures shown as stat tiles. *)
  module Memory : sig
    type t =
      { live_words : Series.t
      ; live_words_latest : int option
      ; heap_words_latest : int option
      ; top_heap_words_latest : int option
      ; major_collections_latest : int option
      }
    [@@deriving sexp_of, compare, equal]
  end

  (** One RPC's latency pane (milliseconds). Shared by both the submit and
      cancel panes, which have the same shape; [count_latest] is that RPC's
      most recent per-second throughput. *)
  module Latency : sig
    type t =
      { p50_ms : Series.t
      ; p90_ms : Series.t
      ; p99_ms : Series.t
      ; count_latest : int option
      }
    [@@deriving sexp_of, compare, equal]
  end

  (** Pipe-occupancy pane: the inbound request-queue depth over time plus the
      latest per-subscriber outbound queue lengths. *)
  module Pipe_occupancy : sig
    type t =
      { request_queue : Series.t
      ; request_queue_latest : int option
      ; audit_queues_latest : int list
      ; market_data_queues_latest : (Symbol.t * int list) list
      ; session_queues_latest : (Participant.t * int) list
      }
    [@@deriving sexp_of, compare, equal]
  end

  (** Matching-engine busyness pane: iterations processed per second and the
      largest inter-iteration gap (ms). *)
  module Engine_busyness : sig
    type t =
      { iterations : Series.t
      ; iterations_latest : int option
      ; max_gap_ms : Series.t
      ; max_gap_ms_latest : float option
      }
    [@@deriving sexp_of, compare, equal]
  end

  type t =
    { window_len : int
    ; latest_sampled_at : Time_ns.t option
    ; connected_sessions : int
    ; memory : Memory.t
    ; submit_latency : Latency.t
    ; cancel_latency : Latency.t
    ; pipe_occupancy : Pipe_occupancy.t
    ; engine_busyness : Engine_busyness.t
    }
  [@@deriving sexp_of, compare, equal]
end

type t

(** The default snapshot capacity (~60s of history) the dashboard uses when it
    has no reason to pick another. *)
val default_window_capacity : int

(** [create ~window_capacity] starts an empty window that retains at most
    [window_capacity] snapshots. The capacity is per-instance, so separate
    controllers may keep different amounts of history (e.g. a 60s pane and a
    300s pane). [display] on a fresh [t] reports [window_len = 0] so the
    browser can render a loading state. *)
val create : window_capacity:int -> t

(** The capacity [t] was created with — the maximum snapshots it retains. *)
val window_capacity : t -> int

(** Append [metrics] as the newest second, evicting the oldest once
    [window_capacity t] is exceeded. Pure — returns the updated window. *)
val feed_metrics : t -> Metrics.t -> t

(** Project the current window into render-ready series (oldest first). *)
val display : t -> Display.t
