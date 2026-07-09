open! Core
open Jsip_types

module Latency_summary = struct
  type t =
    { count : int
    ; p50 : Time_ns.Span.t
    ; p90 : Time_ns.Span.t
    ; p99 : Time_ns.Span.t
    ; max : Time_ns.Span.t
    }
  [@@deriving sexp, bin_io]
end

module Gc_stats = struct
  type t =
    { live_words : int
    ; heap_words : int
    ; top_heap_words : int
    ; minor_collections : int
    ; major_collections : int
    ; promoted_words : float
    }
  [@@deriving sexp, bin_io]

  let of_gc_stat (stat : Gc.Stat.t) =
    { live_words = stat.live_words
    ; heap_words = stat.heap_words
    ; top_heap_words = stat.top_heap_words
    ; minor_collections = stat.minor_collections
    ; major_collections = stat.major_collections
    ; promoted_words = stat.promoted_words
    }
  ;;
end

module Pipe_occupancy = struct
  type t =
    { request_queue : int
    ; audit : int list
    ; market_data : (Symbol_id.t * int list) list
    ; sessions : (Participant.t * int) list
    }
  [@@deriving sexp, bin_io]
end

module Engine_busyness = struct
  type t =
    { iterations : int
    ; max_inter_iteration_gap : Time_ns.Span.t
    }
  [@@deriving sexp, bin_io]
end

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
