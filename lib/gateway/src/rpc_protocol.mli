(** RPC definitions for client-server communication.

    Defines the RPCs that clients use to interact with the exchange server.
    Each RPC has a query type (what the client sends) and a response type
    (what the server returns).

    We use Async RPCs, but on a production exchange, clients would connect
    over a binary protocol like FIX or a proprietary format. *)

open! Core
open! Async
open Jsip_types
module Metrics = Jsip_gateway_protocol.Metrics

(** participant logs into exchange.

    Validates the inputted name s.t. there are no empty sections. Registers
    the participant and session or returns an error on conflict. Resulting
    connection is a connection state. *)
val login_rpc : (String.t, Participant.t Or_error.t) Rpc.Rpc.t

(** Submit an order to the exchange.

    This is a one-way RPC. The server enqueues the order and returns as soon
    as possible. The matching engine processes the queued request on a
    background worker and hands the resulting [Exchange_event.t]s to the
    [Dispatcher], which routes participant-targeted events (acceptance,
    fills, rejection) to the owning participant's [Session]. The per-session
    RPC that lets a client read its session feed does not exist yet (planned
    for week 2); until it does, those events are printed on the server's
    stdout.

    The error case covers connection-level failures only — connection closed,
    server shutting down, etc. — not domain errors like unknown symbols
    (those arrive as [Order_reject] events on the session feed). *)
val submit_order_rpc : (Order.Request.t, unit Or_error.t) Rpc.Rpc.t

(** Query the order book for a given symbol. Returns a structured snapshot of
    all resting orders on both sides, if a book for that symbol exists. *)
val book_query_rpc : (Symbol_id.t, Book.t option) Rpc.Rpc.t

(** Cancel a given client_order. Returns an error if order does not exist,
    unit if no errors. *)
val cancel_order_rpc : (Client_order_id.t, unit Or_error.t) Rpc.Rpc.t

(** Fetch the symbol directory: the authoritative [(name, id)] pairs the
    server assigned at startup. The wire carries only {!Symbol_id.t} ints; a
    client or monitor calls this once at connect and mirrors it locally
    ({!Symbol_directory}) so it can resolve a human-typed name to an id at
    parse and an id back to a name at render. The server never renders a
    symbol itself — it only serves this directory. *)
val symbol_directory_rpc : (unit, (Symbol.t * Symbol_id.t) list) Rpc.Rpc.t

(** Subscribe to market data for one or more symbols. The server pushes BBO
    updates and trade reports as they happen via a single pipe. The query is
    the list of symbols to subscribe to; using one RPC for the whole list
    avoids the overhead of opening a separate pipe per symbol when a client
    cares about several. *)
val market_data_rpc
  : (Symbol_id.t list, Exchange_event.t, Error.t) Rpc.Pipe_rpc.t

(** Subscribe to the full audit log: every [Exchange_event.t] the matching
    engine produces, across every symbol and participant.

    This RPC is intended for the exchange operator's monitoring and audit
    tools (e.g. the bonsai_term monitor in [app/monitor]) only. Ordinary
    participants — automated bots, human-driven clients — should use
    [market_data_rpc] for public events, and (once it exists, week 2) a
    per-participant session-feed RPC for their own order-lifecycle events. A
    production exchange would gate this RPC behind operator-level
    credentials; this simulator does not, but the same intent applies. *)
val audit_log_rpc : (unit, Exchange_event.t, Error.t) Rpc.Pipe_rpc.t

(** Reads the connection state

    Fails with "not logged in" if there is no existing session, and otherwise
    returns the Pipe.Reader.t. Client subscribes once after login then drains
    the pipe . Delivers the Order calls and Fill events. *)
val session_feed_rpc : (unit, Exchange_event.t, Error.t) Rpc.Pipe_rpc.t

(** Subscribe to the exchange's health telemetry: one {!Metrics.t} snapshot
    per second (memory, submit/cancel latency percentiles, pipe occupancy,
    matching -engine busyness). Backs the monitoring dashboard in
    [app/dashboard].

    Because each window's percentiles cannot be merged across seconds, the
    dashboard treats the stream as a time series — it keeps the ~60 most
    recent snapshots and plots them *)
val metrics_feed_rpc : (unit, Metrics.t, Error.t) Rpc.Pipe_rpc.t
