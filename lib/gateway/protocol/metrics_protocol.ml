open! Core
open! Async_rpc_kernel

let metrics_feed_rpc =
  Rpc.Pipe_rpc.create
    ~name:"metrics-feed"
    ~version:1
    ~bin_query:Unit.bin_t
    ~bin_response:Metrics.bin_t
    ~bin_error:Error.bin_t
    ()
;;
