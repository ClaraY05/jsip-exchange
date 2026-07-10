open! Core
open! Async
open Jsip_types
open Jsip_order_book

module Requests = struct
  (* What the client asked for. *)
  module Payload = struct
    type t =
      | Order of Order.Request.t
      | Cancel of
          { participant : Participant.t
          ; client_order_id : Client_order_id.t
          }
    [@@deriving sexp, bin_io]
  end

  (* The payload plus the time the RPC handler received it, used to measure
     end-to-end latency once it finishes processing. *)
  type t =
    { payload : Payload.t
    ; received_at : Time_ns.t
    }
  [@@deriving sexp, bin_io]
end

type t =
  { engine : Matching_engine.t
  ; dispatcher : Dispatcher.t
  ; request_writer : Requests.t Pipe.Writer.t
  ; tcp_server : (Socket.Address.Inet.t, int) Tcp.Server.t
  ; port : int
  }

module Connection_state = struct
  type t = { mutable session : Session.t option }

  let session t = t.session
end

(* Bound how many client requests can sit in the queue waiting for the
   matching engine. Once the queue is full, [Pipe.write] returns a pending
   deferred and the [submit_order_rpc] handler blocks until the engine has
   processed enough requests to free up space — clients get backpressure
   without the server's memory growing unboundedly. *)
let request_queue_size_budget = 1024

(* Take one metrics snapshot (resetting the collector's window) and broadcast
   it to every [metrics_feed_rpc] subscriber. *)
let push_metrics_sample ~dispatcher ~collector ~request_reader =
  Dispatcher.push_metrics
    dispatcher
    (Metrics_collector.snapshot_and_reset
       collector
       ~dispatcher
       ~request_queue_depth:(Pipe.length request_reader))
;;

let handle_write ~request_writer (payload : Requests.Payload.t) =
  let request = { Requests.payload; received_at = Time_ns.now () } in
  let%map () = Pipe.write_if_open request_writer request in
  Ok ()
;;

let start_matching_loop ~engine ~dispatcher ~collector request_reader =
  let filter_bad_client_order_ids engine (request : Order.Request.t) =
    match
      Matching_engine.check_client_order_id
        engine
        request.participant
        request.client_order_id
    with
    | Some _ ->
      [ Exchange_event.Order_reject
          { request; reason = "client order id already exits" }
      ]
    | None -> Matching_engine.submit engine request
  in
  let handle_cancel_requests
    engine
    (participant : Participant.t)
    (client_order_id : Client_order_id.t)
    =
    Matching_engine.cancel engine participant client_order_id
  in
  (* handle submitted requests *)
  don't_wait_for
    (Pipe.iter_without_pushback
       request_reader
       ~f:(fun ({ payload; received_at } : Requests.t) ->
         let started = Time_ns.now () in
         Metrics_collector.record_iteration collector ~now:started;
         let events =
           match payload with
           | Order request ->
             let events = filter_bad_client_order_ids engine request in
             Metrics_collector.record_submit_latency
               collector
               (Time_ns.diff (Time_ns.now ()) received_at);
             events
           | Cancel { participant; client_order_id } ->
             let events =
               handle_cancel_requests engine participant client_order_id
             in
             Metrics_collector.record_cancel_latency
               collector
               (Time_ns.diff (Time_ns.now ()) received_at);
             events
         in
         Dispatcher.dispatch dispatcher events))
;;

let default_metrics_interval = Time_ns.Span.of_sec 1.

let start
  ?(metrics_interval = default_metrics_interval)
  ~symbol_names
  ~port
  ()
  =
  let directory = Symbol_directory.of_names_exn symbol_names in
  let symbols =
    List.mapi symbol_names ~f:(fun i _name -> Symbol_id.of_int i)
  in
  let engine = Matching_engine.create symbols in
  let dispatcher = Dispatcher.create () in
  let collector = Metrics_collector.create () in
  let request_reader, request_writer = Pipe.create () in
  Pipe.set_size_budget request_writer request_queue_size_budget;
  start_matching_loop ~engine ~dispatcher ~collector request_reader;
  let implementations =
    Rpc.Implementations.create_exn
      ~implementations:
        [ Rpc.Rpc.implement
            Rpc_protocol.login_rpc
            (fun (state : Connection_state.t) participant_name ->
               if String.is_empty participant_name
                  || String.for_all participant_name ~f:Char.is_whitespace
               then
                 Async.return
                   (Or_error.error_string
                      "login_rpc: Invalid submitted name, no whitespace / \
                       empty names allowed")
               else (
                 let participant = Participant.of_string participant_name in
                 match state.session with
                 | Some _ ->
                   Async.return
                     (Or_error.error_string
                        "login_rpc: user already logged in")
                 | None ->
                   if Dispatcher.valid_participant dispatcher participant
                   then
                     Async.return
                       (Or_error.error_string
                          "login_rpc: user already exists in dispatch")
                   else (
                     let%bind () =
                       Dispatcher.set_up_session dispatcher participant
                     in
                     state.session
                     <- Dispatcher.get_session dispatcher participant;
                     Async.return (Ok participant))))
        ; Rpc.Rpc.implement
            Rpc_protocol.submit_order_rpc
            (fun state request ->
               match Connection_state.session state with
               | None ->
                 Async.return
                   (Or_error.error_string "submit_order_rpc: not logged in")
               | Some session ->
                 let participant = Session.participant session in
                 handle_write
                   ~request_writer
                   (Order { request with participant }))
        ; Rpc.Rpc.implement'
            Rpc_protocol.symbol_directory_rpc
            (fun state () ->
               ignore state;
               Symbol_directory.to_pairs directory)
        ; Rpc.Rpc.implement' Rpc_protocol.book_query_rpc (fun state symbol ->
            ignore state;
            Matching_engine.book engine symbol
            |> Option.map ~f:Order_book.snapshot)
        ; Rpc.Rpc.implement
            Rpc_protocol.cancel_order_rpc
            (fun state client_order_id ->
               match Connection_state.session state with
               | None ->
                 Async.return
                   (Or_error.error_string "submit_order_rpc: not logged in")
               | Some session ->
                 let participant = Session.participant session in
                 handle_write
                   ~request_writer
                   (Cancel { participant; client_order_id }))
        ; Rpc.Pipe_rpc.implement
            Rpc_protocol.market_data_rpc
            (fun state symbols ->
               ignore state;
               let reader =
                 Dispatcher.subscribe_market_data dispatcher symbols
               in
               return (Ok reader))
        ; Rpc.Pipe_rpc.implement Rpc_protocol.audit_log_rpc (fun state () ->
            ignore state;
            let reader = Dispatcher.subscribe_audit dispatcher in
            return (Ok reader))
        ; Rpc.Pipe_rpc.implement
            Rpc_protocol.metrics_feed_rpc
            (fun state () ->
               ignore state;
               let reader = Dispatcher.subscribe_metrics dispatcher in
               return (Ok reader))
        ; Rpc.Pipe_rpc.implement
            Rpc_protocol.session_feed_rpc
            (fun (state : Connection_state.t) () ->
               match state.session with
               | None -> return (Or_error.error_string "not logged in")
               | Some session ->
                 let reader = Session.reader session in
                 return (Ok reader))
        ]
      ~on_unknown_rpc:`Close_connection
      ~on_exception:Log_on_background_exn
  in
  let initial_connection_state _ conn =
    let state = ({ session = None } : Connection_state.t) in
    let () =
      don't_wait_for
        (let%bind () = Rpc.Connection.close_finished conn in
         match state.session with
         | None -> Async.return ()
         | Some session -> Dispatcher.clean_up_session dispatcher session)
    in
    state
  in
  let%map tcp_server =
    Rpc.Connection.serve
      ~implementations
      ~initial_connection_state
      ~where_to_listen:(Tcp.Where_to_listen.of_port port)
      ()
  in
  let actual_port = Tcp.Server.listening_on tcp_server in
  (* Sample and broadcast health metrics every [metrics_interval], until the
     server shuts down. [~stop] ties the recurring job to the server's
     lifetime so it doesn't outlive it (important in tests, where many
     servers share one scheduler). *)
  Clock_ns.every
    ~stop:(Tcp.Server.close_finished tcp_server)
    metrics_interval
    (fun () -> push_metrics_sample ~dispatcher ~collector ~request_reader);
  { engine; dispatcher; request_writer; tcp_server; port = actual_port }
;;

let port t = t.port

let close t =
  Pipe.close t.request_writer;
  Tcp.Server.close t.tcp_server
;;

let close_finished t = Tcp.Server.close_finished t.tcp_server
