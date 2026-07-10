(** Exchange server for production use and testing.

    Bundles the matching engine, market data bus, and RPC implementations
    into a single server that can be started on any port. Used by the server
    binary, the market maker binary, and integration tests. *)

open! Core
open! Async
open Jsip_types

type t

(** Start a server on the given port trading [symbol_names]. The [i]th name is
    assigned id [i]; the server runs on those ids internally and serves the
    [(name, id)] directory over {!Rpc_protocol.symbol_directory_rpc} so clients
    can recover names. Returns the server handle and the port it is actually
    listening on (useful when you pass port 0 to get an OS-assigned port).

    [metrics_interval] controls how often the [metrics_feed_rpc] snapshot is
    sampled and broadcast; it defaults to one second. Tests pass a small
    value so a snapshot arrives promptly instead of after a real wall-clock
    second. *)
val start
  :  ?metrics_interval:Time_ns.Span.t
  -> symbol_names:Symbol.t list
  -> port:int
  -> unit
  -> t Deferred.t

(** The port the server is listening on. *)
val port : t -> int

(** Stop the server and close all connections. *)
val close : t -> unit Deferred.t

(** Wait until the server's TCP listener is closed. *)
val close_finished : t -> unit Deferred.t
