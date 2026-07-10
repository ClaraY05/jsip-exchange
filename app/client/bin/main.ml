(** Exchange client.

    Connects to a running exchange server and provides an interactive
    command-line interface for submitting orders and querying the book.

    Run with: dune exec app/client/bin/main.exe -- -host localhost -port
    12345 -name Alice *)

open! Core
open! Async
open Jsip_types
open Jsip_gateway

let run_client ~host ~port ~participant_name =
  let where_to_connect =
    Tcp.Where_to_connect.of_host_and_port { host; port }
  in
  let%bind conn = Rpc.Connection.client where_to_connect >>| Result.ok_exn in
  (** login to server and dispatch session feed*)
  let%bind login = Rpc.Rpc.dispatch_exn Rpc_protocol.login_rpc conn participant_name in
  let participant = Or_error.ok_exn login in
  (* Fetch the symbol directory once at connect and mirror it local*)
  let%bind directory_pairs =
    Rpc.Rpc.dispatch_exn Rpc_protocol.symbol_directory_rpc conn ()
  in
  let directory = Symbol_directory.of_pairs_exn directory_pairs in
  let render_symbol id =
    match Symbol_directory.name directory id with
    | Some name -> Symbol.to_string name
    | None -> Symbol_id.to_string id
  in
  print_endline [%string
      {|
  Connected to exchange at %{host}:%{port#Int} as %{participant#Participant}
  Commands: BUY|SELL <symbol> <size> <price> [IOC|DAY]
            BOOK <symbol>
            SUBSCRIBE <symbol>  (stream market data)

  Order acknowledgements, fills, and cancellations are temporarily printed
  by the server process; the SUBSCRIBE command attaches you to a per-symbol
  market-data feed.|}];
  let%bind session_feed, _metadata = (Rpc.Pipe_rpc.dispatch_exn Rpc_protocol.session_feed_rpc conn ()) 
  in
  (** dispatch session feed *)
  don't_wait_for
  (Pipe.iter_without_pushback session_feed ~f:(fun event ->
     match event with 
    | Fill fill ->
      (match
         Event_formatter.format_participant_fill ~render_symbol fill participant
       with
       | Some msg -> print_endline msg
       | None -> ())
    | _ -> print_endline (Event_formatter.format_event ~render_symbol event)));
  let rec loop () = 
    print_string "> ";
    match%bind Reader.read_line (Lazy.force Reader.stdin) with
    | `Eof ->
      print_endline "\nDisconnected.";
      Deferred.Or_error.ok_unit
    | `Ok line ->
      let line = String.strip line in
      if String.is_empty line
      then loop ()
      else (
        match
          Exchange_command.parse line ~default_participant:participant ~directory
        with
        | Error msg ->
          print_endline [%string "ERROR: %{Error.to_string_hum msg}"];
          loop ()
        | Ok (Exchange_command.Submit request) ->
          let%bind.Deferred.Or_error () =
            Rpc.Rpc.dispatch_exn Rpc_protocol.submit_order_rpc conn request
          in
          loop ()
        | Ok (Exchange_command.Cancel client_order_id) ->
            let%bind.Deferred.Or_error () = Rpc.Rpc.dispatch_exn Rpc_protocol.cancel_order_rpc conn client_order_id in
          loop ()
        | Ok (Exchange_command.Book symbol_id) ->
          let%bind result =
            Rpc.Rpc.dispatch_exn Rpc_protocol.book_query_rpc conn symbol_id
          in
          (match result with
           | None ->
             print_endline
               [%string "No book available for %{render_symbol symbol_id}"]
           | Some result ->
             print_endline (Event_formatter.format_book ~render_symbol result));
          loop ()
        | Ok (Exchange_command.Subscribe symbol_id) ->
          let%bind result =
            Rpc.Pipe_rpc.dispatch
              Rpc_protocol.market_data_rpc
              conn
              [ symbol_id ]
          in
          (match result with
           | Error err | Ok (Error err) ->
             print_endline
               [%string "ERROR subscribing: %{Error.to_string_hum err}"];
             loop ()
           | Ok (Ok (reader, _id)) ->
             print_endline
               [%string
                 {|
Subscribed to %{render_symbol symbol_id} market data. Updates will appear below.
Continue entering commands as normal.|}];
             (* Read market data in the background; the command loop
                continues running concurrently. *)
             don't_wait_for
               (Pipe.iter_without_pushback reader ~f:(fun event ->
                  print_endline
                    [%string
                      "[MD] %{Event_formatter.format_event ~render_symbol \
                       event}"]));
             loop ()))
  in
  loop ()
;;

let () =
  Command.async_or_error
    ~summary:"JSIP Exchange client"
    (let%map_open.Command host =
       flag
         "-host"
         (optional_with_default "localhost" string)
         ~doc:"HOST server hostname"
     and port = flag "-port" (required int) ~doc:"PORT server port"
     and participant_name =
       flag
         "-name"
         (optional_with_default (Core_unix.getlogin ()) string)
         ~doc:"NAME participant name"
     in
     fun () -> run_client ~host ~port ~participant_name)
  |> Command_unix.run
;;
