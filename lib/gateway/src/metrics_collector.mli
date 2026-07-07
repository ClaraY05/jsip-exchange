(** Accumulates raw measurements over a one-second window and, once per
    second, turns them into a {!Metrics.t} snapshot.

    Lives on the server. The matching loop
    ({!Exchange_server.start_matching_loop}) records a latency sample per
    order and marks each loop iteration; a {!Async.Clock_ns.every} job calls
    {!snapshot_and_reset} once per second, whose result is handed to
    {!Dispatcher.push_metrics}.

    Only ~1 second of samples is ever held in memory: {!snapshot_and_reset}
    computes the percentiles and then clears the buffers. *)

open! Core
module Metrics = Jsip_gateway_protocol.Metrics

type t

val create : unit -> t

(** Record the end-to-end latency of one processed request [submit/cancel] —
    the time from the RPC handler receiving it to the matching engine
    finishing it. *)
val record_submit_latency : t -> Time_ns.Span.t -> unit

val record_cancel_latency : t -> Time_ns.Span.t -> unit

(** Mark that the matching loop ran one iteration at [now]. The gap since the
    previous iteration feeds
    {!Metrics.Engine_busyness.max_inter_iteration_gap}. Pass the same
    [Time_ns.now ()] the caller already reads for latency, so the loop only
    reads the clock once per request. *)
val record_iteration : t -> now:Time_ns.t -> unit

(** Build a snapshot from the current window and reset the per-window
    accumulators. Reads {!Core.Gc.stat} for the memory pane and the occupancy
    / session figures from [dispatcher]; [request_queue_depth] is the current
    [Pipe.length] of the inbound matching-engine queue (owned by
    {!Exchange_server}, hence passed in). *)
val snapshot_and_reset
  :  t
  -> dispatcher:Dispatcher.t
  -> request_queue_depth:int
  -> Metrics.t

(** [percentiles samples] returns [Some (p50, p90, p99, max)] of [samples],
    or [None] when [samples] is empty. Exposed for unit testing; also used
    internally to summarize each window's latency distribution. *)
val percentiles
  :  Time_ns.Span.t array
  -> (Time_ns.Span.t * Time_ns.Span.t * Time_ns.Span.t * Time_ns.Span.t)
       option
