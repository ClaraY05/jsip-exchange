(** Shared helpers for end-to-end tests that use a real server and RPC
    clients. *)

open! Core
open! Async
open Jsip_types
open Jsip_gateway

(** Start a server on an OS-assigned port, run [f], then shut down.
    [metrics_interval] is forwarded to {!Exchange_server.start}; pass a small
    value when the test needs [metrics_feed_rpc] snapshots to arrive quickly
    rather than once a real second. *)
val with_server
  :  ?metrics_interval:Time_ns.Span.t
  -> symbols:Symbol_id.t list
  -> (server:Exchange_server.t -> port:int -> 'a Deferred.t)
  -> 'a Deferred.t

(** A test client: an open RPC connection to the server. A future revision
    (once the session-feed RPC and login flow exist) will extend this with a
    buffered session feed so [rpc_submit] can return the events produced by
    the just-submitted request. *)
type client

(** Connect a client to [port].

    dispatches a login_rpc with the [participant] and a session_feed_rpc over
    the same connection. Every event received is printed to the feed. *)
val connect_as : port:int -> Participant.t -> client Deferred.t

(** Connect a client to [port].

    dispatches the [participant] and a session_feed_rpc over the same
    connection. No log in is attempted Every event received is printed to the
    feed. *)
val connect_as_no_login : port:int -> Participant.t -> client Deferred.t

(** Open a bare RPC connection to [port] with no login and no session-feed
    subscription. For tests that drive RPCs directly — e.g. exercising the
    "not logged in" / duplicate-login rejection paths — where the fuller
    {!connect_as} flow would get in the way. *)
val connect_raw : port:int -> Rpc.Connection.t Deferred.t

(** The raw RPC connection, useful for tests that exercise unusual RPC paths
    (audit log subscriptions, second clients on the same connection, etc.). *)
val connection : client -> Rpc.Connection.t

(** Subscribe to the exchange's metrics feed ({!Metrics.t} snapshots). Pair
    with a small [metrics_interval] on {!with_server} so snapshots arrive
    promptly. *)
val subscribe_metrics : client -> Metrics.t Pipe.Reader.t Deferred.t

(** Read the next metrics snapshot, raising if the feed closed. *)
val read_metrics : Metrics.t Pipe.Reader.t -> Metrics.t Deferred.t

(** Submit an order via RPC. The RPC is one-way: this returns once the server
    has enqueued the request. Participant-targeted events (acceptance, fills,
    rejection) are currently printed on the server's stdout via the
    dispatcher's session stub. *)
val rpc_submit : client -> Order.Request.t -> unit Deferred.t

(** Cancel an order via RPC. The RPC is one-way: this returns once the server
    has enqueued the request. Participant-targeted events (acceptance, fills,
    rejection, cancel) are currently printed on the server's stdout via the
    dispatcher's session stub. *)
val rpc_cancel : client -> Client_order_id.t -> unit Deferred.t

(** Query the book via RPC. *)
val rpc_book : client -> Symbol_id.t -> Book.t option Deferred.t
