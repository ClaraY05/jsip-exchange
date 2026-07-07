(** The streaming RPC that carries {!Metrics.t} snapshots from the exchange
    to the monitoring dashboard, one per second.

    Defined in this js-safe protocol library (depends only on [core],
    [async_rpc_kernel], and [jsip_types]) so both the native exchange server
    and the browser [app/dashboard] client can link the identical wire
    definition. The server side re-exports it as
    [Jsip_gateway.Rpc_protocol.metrics_feed_rpc]. *)

open! Core
open! Async_rpc_kernel

val metrics_feed_rpc : (unit, Metrics.t, Error.t) Rpc.Pipe_rpc.t
