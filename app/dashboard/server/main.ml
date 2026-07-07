(** Dashboard web-server: the bridge that lets a browser watch the exchange.

    - plain HTTP GETs are answered with an embedded [index.html] shell and
      the compiled [main.bc.js] (read from [-js-file], via {!Cohttp_async});
      and
    - a WebSocket upgrade on the same port speaks the RPC protocol, where the
      one implemented RPC — [metrics_feed_rpc] — is {e proxied} to the
      exchange's TCP port. {!Async_rpc_websocket.Rpc.serve} tells the two
      apart by the [Upgrade] header.

    The exchange itself is untouched: it keeps speaking plain TCP, and this
    server is the only thing holding a connection to it. *)

open! Core
open! Async
module Rpc_ws = Rpc_websocket.Rpc
module Metrics_protocol = Jsip_gateway_protocol.Metrics_protocol

(* --- static assets --- *)

(* The page is a fixed shell: a mount point for Bonsai plus the script tag
   that loads the bundle. It never varies, so it lives here rather than as a
   file to serve — the server owns "what page loads the dashboard". The real
   styling is injected by ppx_css from inside [main.bc.js]. *)
let index_html =
  {|<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>JSIP Exchange — Metrics</title>
    <style>
      :root { color-scheme: dark; }
      html, body { margin: 0; min-height: 100%; background: lch(4% 1 265); }
      * { box-sizing: border-box; scrollbar-width: thin; }
    </style>
  </head>
  <body>
    <div id="app"></div>
    <script defer src="./main.bc.js"></script>
  </body>
</html>
|}
;;

let respond_html body =
  Cohttp_async.Server.respond_string
    ~headers:(Cohttp.Header.of_list [ "content-type", "text/html" ])
    body
;;

(* Serve exactly two things: [/] (or [/index.html]) gives the shell and
   [/main.bc.js] the compiled bundle read from [js_file]. Any other path
   returns [Not_found] — a fixed allow-list, so this can't become a
   path-traversal read primitive. *)
let serve_static ~js_file ~body:_ (_ : Socket.Address.Inet.t) request =
  match Uri.path (Cohttp.Request.uri request) with
  | "/" | "/index.html" -> respond_html index_html
  | "/main.bc.js" ->
    Cohttp_async.Server.respond_with_file
      ~headers:(Cohttp.Header.of_list [ "content-type", "text/javascript" ])
      js_file
  | _ -> Cohttp_async.Server.respond_string ~status:`Not_found "Not found"
;;

(* --- metrics proxy --- *)

(* Each browser subscriber opens its own upstream connection to the exchange,
   dispatches the exchange's [metrics_feed_rpc], and we hand that pipe
   straight back — the two RPCs are the same wire definition, so no
   re-encoding. When the browser unsubscribes ([Pipe.closed]) we close the
   upstream connection. *)
let proxy_metrics ~exchange_host ~exchange_port () () =
  let where_to_connect =
    Tcp.Where_to_connect.of_host_and_port
      { host = exchange_host; port = exchange_port }
  in
  match%bind Rpc.Connection.client where_to_connect with
  | Error exn -> return (Error (Error.of_exn exn))
  | Ok connection ->
    (match%bind
       Rpc.Pipe_rpc.dispatch Metrics_protocol.metrics_feed_rpc connection ()
     with
     | Error err | Ok (Error err) ->
       don't_wait_for (Rpc.Connection.close connection);
       return (Error err)
     | Ok (Ok (pipe, _metadata)) ->
       don't_wait_for
         (let%bind () = Pipe.closed pipe in
          Rpc.Connection.close connection);
       return (Ok pipe))
;;

let main ~dashboard_port ~exchange_host ~exchange_port ~js_file () =
  let implementations =
    Rpc.Implementations.create_exn
      ~on_unknown_rpc:`Close_connection
      ~on_exception:Log_on_background_exn
      ~implementations:
        [ Rpc.Pipe_rpc.implement
            Metrics_protocol.metrics_feed_rpc
            (proxy_metrics ~exchange_host ~exchange_port)
        ]
  in
  let%bind _server =
    Rpc_ws.serve
      ~where_to_listen:(Tcp.Where_to_listen.of_port dashboard_port)
      ~implementations
      ~initial_connection_state:(fun () _from _addr _conn -> ())
      ~http_handler:(fun () -> serve_static ~js_file)
      ()
  in
  Core.printf
    "dashboard on http://localhost:%d  (proxying exchange %s:%d)\n%!"
    dashboard_port
    exchange_host
    exchange_port;
  Deferred.never ()
;;

let command =
  Command.async
    ~summary:
      "Serve the JSIP dashboard UI and proxy the exchange's metrics feed \
       over a WebSocket."
    (let%map_open.Command dashboard_port =
       flag
         "-port"
         (optional_with_default 8080 int)
         ~doc:"PORT dashboard HTTP port (default 8080)"
     and exchange_host =
       flag
         "-exchange-host"
         (optional_with_default "localhost" string)
         ~doc:"HOST exchange server host (default localhost)"
     and exchange_port =
       flag
         "-exchange-port"
         (optional_with_default 12345 int)
         ~doc:"PORT exchange server RPC port (default 12345)"
     and js_file =
       flag
         "-js-file"
         (optional_with_default
            "_build/default/app/dashboard/bin/main.bc.js"
            string)
         ~doc:"FILE path to the compiled main.bc.js bundle"
     in
     fun () -> main ~dashboard_port ~exchange_host ~exchange_port ~js_file ())
    ~behave_nicely_in_pipeline:false
;;

let () = Command_unix.run command
