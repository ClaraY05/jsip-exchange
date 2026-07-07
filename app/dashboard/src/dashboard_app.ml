open! Core
open! Async_kernel
open! Bonsai_web
open Jsip_gateway_protocol

(* The only action: a new per-second snapshot arrived on the feed. Injected
   from the drain we start on activation and folded into the controller. *)
module Action = struct
  type t = Feed of Metrics.t [@@deriving sexp_of]
end

(* The dashboard is served from the same host/port it proxies, so the
   websocket lives at the page's own origin: [ws://<host>/] (or [wss://]
   under https). *)
let same_origin_ws_uri () =
  let location = Js_of_ocaml.Dom_html.window##.location in
  let scheme =
    match Js_of_ocaml.Js.to_string location##.protocol with
    | "https:" -> "wss"
    | _ -> "ws"
  in
  let host = Js_of_ocaml.Js.to_string location##.host in
  Uri.of_string [%string "%{scheme}://%{host}/"]
;;

let log_error context error =
  Core.eprint_s [%message context (error : Error.t)]
;;

(* Connect, dispatch the pipe RPC, and drain each snapshot into the state
   machine. This must happen inside an [Effect] (not in [main] like the
   terminal monitor) because the browser cannot block on the connection
   [Deferred] *)
let connect_and_drain inject =
  Effect.of_thunk (fun () ->
    let open Deferred.Let_syntax in
    don't_wait_for
      (match%bind
         Async_js.Rpc.Connection.client ~uri:(same_origin_ws_uri ()) ()
       with
       | Error error ->
         log_error "dashboard: websocket connect failed" error;
         return ()
       | Ok connection ->
         (match%bind
            Async_js.Rpc.Pipe_rpc.dispatch
              Metrics_protocol.metrics_feed_rpc
              connection
              ()
          with
          | Error error | Ok (Error error) ->
            log_error "dashboard: metrics feed failed" error;
            return ()
          | Ok (Ok (pipe, _metadata)) ->
            Pipe.iter_without_pushback pipe ~f:(fun metrics ->
              try
                Effect.Expert.handle_non_dom_event_exn
                  (inject (Action.Feed metrics))
              with
              | exn -> log_error "dashboard: feed raised" (Error.of_exn exn)))))
;;

let app (local_ graph) : Vdom.Node.t Bonsai.t =
  let controller, inject =
    Bonsai.state_machine
      ~default_model:
        (Controller.create
           ~window_capacity:Controller.default_window_capacity)
      ~apply_action:(fun _ctx model (action : Action.t) ->
        match action with
        | Feed metrics -> Controller.feed_metrics model metrics)
      graph
  in
  (* start the drain once, on activation, feeding the same [inject] the state
     machine exposes. *)
  Bonsai.Edge.lifecycle
    ~on_activate:
      (let%map.Bonsai inject in
       connect_and_drain inject)
    graph;
  let display = Bonsai.map controller ~f:Controller.display in
  Bonsai.map display ~f:Panes.dashboard_view
;;
