open! Bonsai_web

(** The bonsai_web application.

    On activation it opens the page's own websocket (same origin), dispatches
    [Jsip_gateway_protocol.Metrics_protocol.metrics_feed_rpc], and drains
    each per-second snapshot into a {!Controller} state machine, rendering
    the result with {!Panes}. Hand it to [Bonsai_web.Start.start]. *)
val app : local_ Bonsai.graph -> Vdom.Node.t Bonsai.t
