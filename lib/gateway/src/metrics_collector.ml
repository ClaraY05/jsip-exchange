open! Core
module Metrics = Jsip_gateway_protocol.Metrics

type t =
  { submit_samples : Time_ns.Span.t Queue.t
  ; cancel_samples : Time_ns.Span.t Queue.t
  ; mutable iterations : int
  ; mutable max_inter_iteration_gap : Time_ns.Span.t
  ; mutable last_iteration_at : Time_ns.t option
  }

let create () =
  { submit_samples = Queue.create ()
  ; cancel_samples = Queue.create ()
  ; iterations = 0
  ; max_inter_iteration_gap = Time_ns.Span.zero
  ; last_iteration_at = None
  }
;;

let record_submit_latency t span = Queue.enqueue t.submit_samples span
let record_cancel_latency t span = Queue.enqueue t.cancel_samples span

let record_iteration t ~now =
  t.iterations <- t.iterations + 1;
  (match t.last_iteration_at with
   | None -> ()
   | Some previous ->
     let gap = Time_ns.diff now previous in
     if Time_ns.Span.( > ) gap t.max_inter_iteration_gap
     then t.max_inter_iteration_gap <- gap);
  t.last_iteration_at <- Some now
;;

(* Nearest-rank percentiles over a window's latency samples. Returns [None]
   for an empty window (no percentiles to report — surfaces as
   [submit_latency = None] on the wire); otherwise
   [Some (p50, p90, p99, max)]. *)
let percentiles (samples : Time_ns.Span.t array)
  : (Time_ns.Span.t * Time_ns.Span.t * Time_ns.Span.t * Time_ns.Span.t)
      option
  =
  match Array.is_empty samples with
  | true -> None
  | false ->
    Array.sort samples ~compare:Time_ns.Span.compare;
    let n = Array.length samples in
    let nth_percentile p =
      let rank = Float.iround_up_exn (p /. 100. *. Float.of_int n) - 1 in
      samples.(Int.clamp_exn rank ~min:0 ~max:(n - 1))
    in
    Some
      ( nth_percentile 50.
      , nth_percentile 90.
      , nth_percentile 99.
      , samples.(n - 1) )
;;

let summarize (samples : Time_ns.Span.t Queue.t)
  : Metrics.Latency_summary.t option
  =
  let count = Queue.length samples in
  match percentiles (Queue.to_array samples) with
  | None -> None
  | Some (p50, p90, p99, max) -> Some { count; p50; p90; p99; max }
;;

let snapshot_and_reset t ~dispatcher ~request_queue_depth : Metrics.t =
  let submit_latency = summarize t.submit_samples in
  let cancel_latency = summarize t.cancel_samples in
  let engine_busyness : Metrics.Engine_busyness.t =
    { iterations = t.iterations
    ; max_inter_iteration_gap = t.max_inter_iteration_gap
    }
  in
  let pipe_occupancy : Metrics.Pipe_occupancy.t =
    { request_queue = request_queue_depth
    ; audit = Dispatcher.audit_pipe_lengths dispatcher
    ; market_data = Dispatcher.market_data_pipe_lengths dispatcher
    ; sessions = Dispatcher.session_pipe_lengths dispatcher
    }
  in
  let metrics : Metrics.t =
    { sampled_at = Time_ns.now ()
    ; gc = Metrics.Gc_stats.of_gc_stat (Gc.stat ())
    ; submit_latency
    ; cancel_latency
    ; pipe_occupancy
    ; engine_busyness
    ; connected_sessions = Dispatcher.session_count dispatcher
    }
  in
  (* Reset the per-window accumulators. [last_iteration_at] is intentionally
     kept so the inter-iteration gap stays continuous *)
  Queue.clear t.submit_samples;
  Queue.clear t.cancel_samples;
  t.iterations <- 0;
  t.max_inter_iteration_gap <- Time_ns.Span.zero;
  metrics
;;
