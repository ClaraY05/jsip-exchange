(** Exchange server.

    Runs the matching engine and listens for RPC connections from clients.

    Run with: dune exec app/server/bin/main.exe -- -port 12345

    Market makers and other bots are no longer seeded here: they are deployed
    as {!Jsip_bot_runtime.Bot_runtime.Bot}s through a scenario. See
    [app/scenario_runner/bin] and the scenarios in [app/scenarios/src]. *)

open! Core
open! Async
open Jsip_types
open Jsip_gateway

(* The authoritative symbol names. Serves this list as the [(name, id)]
   directory so clients can recover names. *)
let default_symbol_names =
  List.map [ "AAPL"; "TSLA"; "GOOG"; "MSFT" ] ~f:Symbol.of_string
;;

let start ~port =
  let%bind server =
    Exchange_server.start ~symbol_names:default_symbol_names ~port ()
  in
  print_endline
    [%string
      "JSIP Exchange server listening on port %{Exchange_server.port \
       server#Int}"];
  let symbols =
    List.mapi default_symbol_names ~f:(fun i name ->
      [%string "%{name#Symbol}=%{i#Int}"])
    |> String.concat ~sep:", "
  in
  print_endline [%string "Trading: %{symbols}"];
  Exchange_server.close_finished server
;;

let () =
  Command.async
    ~summary:"JSIP Exchange server"
    (let%map_open.Command port =
       flag "-port" (required int) ~doc:"PORT port to listen on"
     in
     fun () -> start ~port)
  |> Command_unix.run
;;
