open! Core
open Jsip_types
module Metrics = Jsip_gateway_protocol.Metrics

let default_window_capacity = 60

module Series = struct
  type t = float option array [@@deriving sexp_of, compare, equal]
end

module Display = struct
  module Memory = struct
    type t =
      { live_words : Series.t
      ; live_words_latest : int option
      ; heap_words_latest : int option
      ; top_heap_words_latest : int option
      ; major_collections_latest : int option
      }
    [@@deriving sexp_of, compare, equal]
  end

  module Latency = struct
    type t =
      { p50_ms : Series.t
      ; p90_ms : Series.t
      ; p99_ms : Series.t
      ; count_latest : int option
      }
    [@@deriving sexp_of, compare, equal]
  end

  module Pipe_occupancy = struct
    type t =
      { request_queue : Series.t
      ; request_queue_latest : int option
      ; audit_queues_latest : int list
      ; market_data_queues_latest : (Symbol_id.t * int list) list
      ; session_queues_latest : (Participant.t * int) list
      }
    [@@deriving sexp_of, compare, equal]
  end

  module Engine_busyness = struct
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

(* Newest snapshot at the back, oldest at the front, so [Fdeque.to_list]
   yields the window oldest-first and [peek_back] is the latest reading.
   [window_capacity] is per-instance so different controllers can keep
   different amounts of history. *)
type t =
  { window : Metrics.t Fdeque.t
  ; window_capacity : int
  }

let create ~window_capacity = { window = Fdeque.empty; window_capacity }
let window_capacity t = t.window_capacity

(* Append [metrics] as the newest second (back of the deque). If the window
   is already at capacity, evict the oldest (front) first so the length stays
   bounded. [drop_front_exn] is safe here because a window at capacity is
   non-empty (given [window_capacity >= 1]). [{ t with ... }] carries
   [window_capacity] through unchanged. *)
let feed_metrics t metrics =
  let window =
    if Fdeque.length t.window >= t.window_capacity
    then Fdeque.drop_front_exn t.window
    else t.window
  in
  { t with window = Fdeque.enqueue_back window metrics }
;;

(* --- projection helpers (all pure; used by [display]) --- *)

let span_ms span = Time_ns.Span.to_ms span

(* One slot per snapshot, oldest first. *)
let series snapshots ~f = Array.of_list_map snapshots ~f

(* Project one RPC's per-second latency percentile into a [Series.t]: [None]
   where that second recorded no orders of this kind. *)
let latency_series snapshots ~summary ~percentile =
  series snapshots ~f:(fun (m : Metrics.t) ->
    Option.map (summary m) ~f:(fun (l : Metrics.Latency_summary.t) ->
      span_ms (percentile l)))
;;

(* Build one latency pane from its summary selector. Submit and cancel share
   {!Display.Latency.t}, so this is written once and applied to each. *)
let latency_pane snapshots ~latest ~summary : Display.Latency.t =
  { p50_ms = latency_series snapshots ~summary ~percentile:(fun l -> l.p50)
  ; p90_ms = latency_series snapshots ~summary ~percentile:(fun l -> l.p90)
  ; p99_ms = latency_series snapshots ~summary ~percentile:(fun l -> l.p99)
  ; count_latest =
      Option.bind latest ~f:(fun (m : Metrics.t) ->
        Option.map (summary m) ~f:(fun (l : Metrics.Latency_summary.t) ->
          l.count))
  }
;;

let display t : Display.t =
  let snapshots = Fdeque.to_list t.window in
  let latest = Fdeque.peek_back t.window in
  let latest_map ~f = Option.map latest ~f in
  let memory : Display.Memory.t =
    { live_words =
        series snapshots ~f:(fun (m : Metrics.t) ->
          Some (Int.to_float m.gc.live_words))
    ; live_words_latest =
        latest_map ~f:(fun (m : Metrics.t) -> m.gc.live_words)
    ; heap_words_latest =
        latest_map ~f:(fun (m : Metrics.t) -> m.gc.heap_words)
    ; top_heap_words_latest =
        latest_map ~f:(fun (m : Metrics.t) -> m.gc.top_heap_words)
    ; major_collections_latest =
        latest_map ~f:(fun (m : Metrics.t) -> m.gc.major_collections)
    }
  in
  let pipe_occupancy : Display.Pipe_occupancy.t =
    { request_queue =
        series snapshots ~f:(fun (m : Metrics.t) ->
          Some (Int.to_float m.pipe_occupancy.request_queue))
    ; request_queue_latest =
        latest_map ~f:(fun (m : Metrics.t) -> m.pipe_occupancy.request_queue)
    ; audit_queues_latest =
        Option.value_map latest ~default:[] ~f:(fun (m : Metrics.t) ->
          m.pipe_occupancy.audit)
    ; market_data_queues_latest =
        Option.value_map latest ~default:[] ~f:(fun (m : Metrics.t) ->
          m.pipe_occupancy.market_data)
    ; session_queues_latest =
        Option.value_map latest ~default:[] ~f:(fun (m : Metrics.t) ->
          m.pipe_occupancy.sessions)
    }
  in
  let engine_busyness : Display.Engine_busyness.t =
    { iterations =
        series snapshots ~f:(fun (m : Metrics.t) ->
          Some (Int.to_float m.engine_busyness.iterations))
    ; iterations_latest =
        latest_map ~f:(fun (m : Metrics.t) -> m.engine_busyness.iterations)
    ; max_gap_ms =
        series snapshots ~f:(fun (m : Metrics.t) ->
          Some (span_ms m.engine_busyness.max_inter_iteration_gap))
    ; max_gap_ms_latest =
        latest_map ~f:(fun (m : Metrics.t) ->
          span_ms m.engine_busyness.max_inter_iteration_gap)
    }
  in
  { window_len = Fdeque.length t.window
  ; latest_sampled_at = latest_map ~f:(fun (m : Metrics.t) -> m.sampled_at)
  ; connected_sessions =
      Option.value_map latest ~default:0 ~f:(fun (m : Metrics.t) ->
        m.connected_sessions)
  ; memory
  ; submit_latency =
      latency_pane snapshots ~latest ~summary:(fun (m : Metrics.t) ->
        m.submit_latency)
  ; cancel_latency =
      latency_pane snapshots ~latest ~summary:(fun (m : Metrics.t) ->
        m.cancel_latency)
  ; pipe_occupancy
  ; engine_busyness
  }
;;
