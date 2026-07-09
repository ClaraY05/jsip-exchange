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

let default_symbol_names = [ "AAPL"; "TSLA"; "GOOG"; "MSFT" ]

(* Phase 1 of the symbol-as-int refactor: the wire carries [Symbol_id.t]s, so
   the engine is created with ids [0 .. n-1], one per name in list order. main
   keeps the names (they will seed the Phase 2 symbol directory); for now they
   only feed the startup banner so a human knows which id is which instrument. *)
let default_symbols =
  List.mapi default_symbol_names ~f:(fun i _name -> Symbol_id.of_int i)
;;

let start ~port =
  let%bind server =
    Exchange_server.start ~symbols:default_symbols ~port ()
  in
  print_endline
    [%string
      "JSIP Exchange server listening on port %{Exchange_server.port \
       server#Int}"];
  let symbols =
    List.mapi default_symbol_names ~f:(fun i name ->
      [%string "%{name}=%{i#Int}"])
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
