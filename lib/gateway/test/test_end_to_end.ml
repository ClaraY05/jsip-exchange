(** End-to-end tests with a real server and RPC clients.

    These tests spin up an actual exchange server on a local port, connect
    one or more clients via RPC, log them in, and verify the full path:
    client -> network -> server -> matching engine -> dispatcher -> session
    feed -> client. *)

open! Core
open! Async
open Jsip_types
open Jsip_gateway
open Jsip_test_harness
open E2e_helpers

(* ---------------------------------------------------------------- *)
(* Multiple client tests *)
(* ---------------------------------------------------------------- *)

let%expect_test "e2e: two clients trade with each other" =
  with_server ~symbols:[ Harness.aapl ] (fun ~server:_ ~port ->
    let%bind alice = connect_as ~port Harness.alice in
    let%bind bob = connect_as ~port Harness.bob in
    (* Bob places a sell *)
    let%bind () =
      rpc_submit
        bob
        (Harness.sell ~price_cents:15000 ~participant:Harness.bob ())
    in
    [%expect
      {| [for Bob] ACCEPTED client-id=0 id=1 AAPL SELL 100@$150.00 DAY |}];
    (* Alice places a buy — should cross *)
    let%bind () = rpc_submit alice (Harness.buy ~price_cents:15000 ()) in
    [%expect
      {|
      [for Alice] ACCEPTED client-id=0 id=2 AAPL BUY 100@$150.00 DAY
      [for Alice] FILL fill_id=1 AAPL $150.00 x100 aggressor=2 (client-id=0) (Alice) BUY resting=1 (client-id=0) (Bob)
      [for Bob] FILL fill_id=1 AAPL $150.00 x100 aggressor=2 (client-id=0) (Alice) BUY resting=1 (client-id=0) (Bob)
      |}];
    return ())
;;

let%expect_test "e2e: three clients, sequential orders, shared book" =
  with_server ~symbols:[ Harness.aapl ] (fun ~server:_ ~port ->
    let%bind alice = connect_as ~port Harness.alice in
    let%bind bob = connect_as ~port Harness.bob in
    let%bind charlie = connect_as ~port Harness.charlie in
    (* Bob posts a sell *)
    let%bind () =
      rpc_submit
        bob
        (Harness.sell
           ~price_cents:15000
           ~size:50
           ~participant:Harness.bob
           ())
    in
    [%expect
      {| [for Bob] ACCEPTED client-id=0 id=1 AAPL SELL 50@$150.00 DAY |}];
    (* Charlie posts a sell at a higher price *)
    let%bind () =
      rpc_submit
        charlie
        (Harness.sell
           ~price_cents:15010
           ~size:50
           ~participant:Harness.charlie
           ())
    in
    [%expect
      {| [for Charlie] ACCEPTED client-id=0 id=2 AAPL SELL 50@$150.10 DAY |}];
    (* Alice buys 80 — should sweep through both *)
    let%bind () =
      rpc_submit alice (Harness.buy ~price_cents:15010 ~size:80 ())
    in
    [%expect
      {|
      [for Alice] ACCEPTED client-id=0 id=3 AAPL BUY 80@$150.10 DAY
      [for Alice] FILL fill_id=1 AAPL $150.00 x50 aggressor=3 (client-id=0) (Alice) BUY resting=1 (client-id=0) (Bob)
      [for Alice] FILL fill_id=2 AAPL $150.10 x30 aggressor=3 (client-id=0) (Alice) BUY resting=2 (client-id=0) (Charlie)
      [for Bob] FILL fill_id=1 AAPL $150.00 x50 aggressor=3 (client-id=0) (Alice) BUY resting=1 (client-id=0) (Bob)
      [for Charlie] FILL fill_id=2 AAPL $150.10 x30 aggressor=3 (client-id=0) (Alice) BUY resting=2 (client-id=0) (Charlie)
      |}];
    (* Verify book state *)
    let%bind book = rpc_book alice Harness.aapl in
    print_endline (Option.value_exn book |> Book.to_string);
    [%expect
      {|
      === AAPL ===
        BIDS: (empty)
        ASKS:
          $150.10 x20
        BBO: - / $150.10 x20
      |}];
    return ())
;;

(* ---------------------------------------------------------------- *)
(* Market data subscription tests *)
(* ---------------------------------------------------------------- *)

let%expect_test "e2e: market data subscriber receives trade and BBO updates" =
  with_server ~symbols:[ Harness.aapl ] (fun ~server:_ ~port ->
    let%bind sub = connect_as ~port (Participant.of_string "Sub") in
    let%bind alice = connect_as ~port Harness.alice in
    let%bind bob = connect_as ~port Harness.bob in
    let%bind result =
      Rpc.Pipe_rpc.dispatch
        Rpc_protocol.market_data_rpc
        (connection sub)
        [ Harness.aapl ]
    in
    let reader =
      match result with
      | Ok (Ok (reader, _id)) -> reader
      | _ -> failwith "subscribe failed"
    in
    don't_wait_for
      (Pipe.iter_without_pushback reader ~f:(fun event ->
         let e = Event_formatter.format_event event in
         print_endline [%string "[MD Subscriber] %{e}"]));
    (* Post a sell *)
    let%bind () =
      rpc_submit
        bob
        (Harness.sell ~price_cents:15000 ~participant:Harness.bob ())
    in
    [%expect
      {|
      [for Bob] ACCEPTED client-id=0 id=1 AAPL SELL 100@$150.00 DAY
      [MD Subscriber] BBO AAPL bid=- ask=$150.00 x100
      |}];
    (* Cross it with a buy *)
    let%bind () = rpc_submit alice (Harness.buy ~price_cents:15000 ()) in
    [%expect
      {|
      [for Alice] ACCEPTED client-id=0 id=2 AAPL BUY 100@$150.00 DAY
      [for Alice] FILL fill_id=1 AAPL $150.00 x100 aggressor=2 (client-id=0) (Alice) BUY resting=1 (client-id=0) (Bob)
      [for Bob] FILL fill_id=1 AAPL $150.00 x100 aggressor=2 (client-id=0) (Alice) BUY resting=1 (client-id=0) (Bob)
      [MD Subscriber] TRADE AAPL $150.00 x100
      [MD Subscriber] BBO AAPL bid=- ask=-
      |}];
    return ())
;;

let%expect_test "e2e: subscriber only sees events for subscribed symbol" =
  with_server ~symbols:[ Harness.aapl; Harness.tsla ] (fun ~server:_ ~port ->
    let%bind sub = connect_as ~port (Participant.of_string "Sub") in
    let%bind bob = connect_as ~port Harness.bob in
    let%bind result =
      Rpc.Pipe_rpc.dispatch
        Rpc_protocol.market_data_rpc
        (connection sub)
        [ Harness.aapl ]
    in
    let reader =
      match result with
      | Ok (Ok (reader, _id)) -> reader
      | _ -> failwith "subscribe failed"
    in
    don't_wait_for
      (Pipe.iter_without_pushback reader ~f:(fun event ->
         let e = Event_formatter.format_event event in
         print_endline [%string "[MD Subscriber] %{e}"]));
    (* Post on TSLA — subscriber should NOT see this *)
    let%bind () =
      rpc_submit
        bob
        (Harness.sell
           ~price_cents:20000
           ~client_id:(Client_order_id.of_int 0)
           ~symbol:Harness.tsla
           ~participant:Harness.bob
           ())
    in
    [%expect
      {| [for Bob] ACCEPTED client-id=0 id=1 TSLA SELL 100@$200.00 DAY |}];
    (* Post on AAPL — subscriber SHOULD see this *)
    let%bind () =
      rpc_submit
        bob
        (Harness.sell
           ~price_cents:15000
           ~client_id:(Client_order_id.of_int 1)
           ~participant:Harness.bob
           ())
    in
    [%expect
      {|
      [for Bob] ACCEPTED client-id=1 id=2 AAPL SELL 100@$150.00 DAY
      [MD Subscriber] BBO AAPL bid=- ask=$150.00 x100
      |}];
    return ())
;;

(* ---------------------------------------------------------------- *)
(* Concurrent submission test *)
(* ---------------------------------------------------------------- *)

let%expect_test "e2e: many clients submit orders concurrently" =
  with_server ~symbols:[ Harness.aapl ] (fun ~server:_ ~port ->
    let%bind seed = connect_as ~port Harness.bob in
    let%bind () =
      let client_id_manager = Client_order_id.Generator.create () in
      Deferred.List.iter
        (List.init 10 ~f:Fn.id)
        ~how:`Sequential
        ~f:(fun i ->
          rpc_submit
            seed
            (Harness.sell
               ~price_cents:(15000 + i)
               ~client_id:
                 (Client_order_id.of_int
                    (Client_order_id.Generator.next client_id_manager))
               ~participant:Harness.bob
               ())
          |> Deferred.ignore_m)
    in
    let%bind () =
      Deferred.List.iter (List.init 5 ~f:Fn.id) ~how:`Parallel ~f:(fun i ->
        let participant = Participant.of_string [%string "Trader%{i#Int}"] in
        let client_id_manager = Client_order_id.Generator.create () in
        let%bind client = connect_as ~port participant in
        rpc_submit
          client
          (Harness.buy
             ~price_cents:15010
             ~client_id:
               (Client_order_id.of_int
                  (Client_order_id.Generator.next client_id_manager))
             ~participant
             ())
        |> Deferred.ignore_m)
    in
    (* The dispatcher's placeholder [for <Participant>] prints land on stdout
       in an order that depends on which parallel buy was processed first.
       Swallow the trace and assert on the deterministic remaining book state
       instead: 10 sells went in, the 5 buys at $150.10 each hit the
       lowest-priced sell, so 5 sells should remain. *)
    let (_ : string) = [%expect.output] in
    let%bind book = rpc_book seed Harness.aapl in
    let book = Option.value_exn book in
    let remaining_orders = List.length book.bids + List.length book.asks in
    [%test_result: int] remaining_orders ~expect:5;
    return ())
;;

(* ---------------------------------------------------------------- *)
(* Audit log subscription tests *)
(* ---------------------------------------------------------------- *)

let%expect_test "e2e: audit log subscriber sees full unfiltered stream \
                 across symbols"
  =
  with_server ~symbols:[ Harness.aapl; Harness.tsla ] (fun ~server:_ ~port ->
    let%bind sub = connect_as ~port (Participant.of_string "Auditor") in
    let%bind alice = connect_as ~port Harness.alice in
    let%bind bob = connect_as ~port Harness.bob in
    let%bind result =
      Rpc.Pipe_rpc.dispatch Rpc_protocol.audit_log_rpc (connection sub) ()
    in
    let reader =
      match result with
      | Ok (Ok (reader, _id)) -> reader
      | _ -> failwith "subscribe failed"
    in
    don't_wait_for
      (Pipe.iter_without_pushback reader ~f:(fun event ->
         let e = Event_formatter.format_event event in
         print_endline [%string "[AUDIT] %{e}"]));
    (* Post a sell on AAPL — audit subscriber should see ACCEPTED and BBO. *)
    let%bind () =
      rpc_submit
        bob
        (Harness.sell
           ~price_cents:15000
           ~client_id:(Client_order_id.of_int 0)
           ~participant:Harness.bob
           ())
    in
    [%expect
      {|
      [AUDIT] ACCEPTED client-id=0 id=1 AAPL SELL 100@$150.00 DAY
      [AUDIT] BBO AAPL bid=- ask=$150.00 x100
      [for Bob] ACCEPTED client-id=0 id=1 AAPL SELL 100@$150.00 DAY
      |}];
    (* Post a sell on TSLA — audit subscriber should see this too
       (multi-symbol). *)
    let%bind () =
      rpc_submit
        bob
        (Harness.sell
           ~price_cents:20000
           ~symbol:Harness.tsla
           ~client_id:(Client_order_id.of_int 1)
           ~participant:Harness.bob
           ())
    in
    [%expect
      {|
      [AUDIT] ACCEPTED client-id=1 id=2 TSLA SELL 100@$200.00 DAY
      [AUDIT] BBO TSLA bid=- ask=$200.00 x100
      [for Bob] ACCEPTED client-id=1 id=2 TSLA SELL 100@$200.00 DAY
      |}];
    (* Cross the AAPL sell — the audit log should see ACCEPTED + FILL + BBO. *)
    let%bind () = rpc_submit alice (Harness.buy ~price_cents:15000 ()) in
    [%expect
      {|
      [AUDIT] ACCEPTED client-id=0 id=3 AAPL BUY 100@$150.00 DAY
      [AUDIT] FILL fill_id=1 AAPL $150.00 x100 aggressor=3 (client-id=0) (Alice) BUY resting=1 (client-id=0) (Bob)
      [AUDIT] TRADE AAPL $150.00 x100
      [AUDIT] BBO AAPL bid=- ask=-
      [for Alice] ACCEPTED client-id=0 id=3 AAPL BUY 100@$150.00 DAY
      [for Alice] FILL fill_id=1 AAPL $150.00 x100 aggressor=3 (client-id=0) (Alice) BUY resting=1 (client-id=0) (Bob)
      [for Bob] FILL fill_id=1 AAPL $150.00 x100 aggressor=3 (client-id=0) (Alice) BUY resting=1 (client-id=0) (Bob)
      |}];
    return ())
;;

let%expect_test "dispatcher: closing a subscriber's reader removes the \
                 writer"
  =
  let dispatcher = Dispatcher.create () in
  print_s
    [%message
      "initial"
        ~count:
          (Dispatcher.For_testing.audit_subscriber_count dispatcher : int)];
  [%expect {| (initial (count 0)) |}];
  let reader_a = Dispatcher.subscribe_audit dispatcher in
  let reader_b = Dispatcher.subscribe_audit dispatcher in
  print_s
    [%message
      "after subscribe"
        ~count:
          (Dispatcher.For_testing.audit_subscriber_count dispatcher : int)];
  [%expect {| ("after subscribe" (count 2)) |}];
  Pipe.close_read reader_a;
  let%bind () = Async.Scheduler.yield_until_no_jobs_remain () in
  print_s
    [%message
      "after closing reader_a"
        ~count:
          (Dispatcher.For_testing.audit_subscriber_count dispatcher : int)];
  [%expect {| ("after closing reader_a" (count 1)) |}];
  Pipe.close_read reader_b;
  let%bind () = Async.Scheduler.yield_until_no_jobs_remain () in
  print_s
    [%message
      "after closing reader_b"
        ~count:
          (Dispatcher.For_testing.audit_subscriber_count dispatcher : int)];
  [%expect {| ("after closing reader_b" (count 0)) |}];
  return ()
;;

(* ---------------------------------------------------------------- *)
(* Client cancels *)
(* ---------------------------------------------------------------- *)

let%expect_test "e2e: client adds a order, cancels it and gains \
                 order_cancel in feed"
  =
  with_server ~symbols:[ Harness.aapl ] (fun ~server:_ ~port ->
    let%bind alice = connect_as ~port Harness.alice in
    (* Alice places a sell *)
    let%bind () =
      rpc_submit
        alice
        (Harness.sell ~price_cents:15000 ~participant:Harness.alice ())
    in
    [%expect
      {| [for Alice] ACCEPTED client-id=0 id=1 AAPL SELL 100@$150.00 DAY |}];
    (* Alice cancels order *)
    let%bind () = rpc_cancel alice (Client_order_id.of_int 0) in
    [%expect
      {| [for Alice] CANCELLED client_id=0 id=1 AAPL remaining=100 reason=PARTICIPANT_REQUESTED |}];
    return ())
;;

let%expect_test "e2e: duplicate client order IDs are rejected" =
  with_server ~symbols:[ Harness.aapl ] (fun ~server:_ ~port ->
    let%bind alice = connect_as ~port Harness.alice in
    (* Alice places a sell *)
    let%bind () =
      rpc_submit
        alice
        (Harness.sell ~price_cents:15000 ~participant:Harness.alice ())
    in
    [%expect
      {| [for Alice] ACCEPTED client-id=0 id=1 AAPL SELL 100@$150.00 DAY |}];
    let%bind () =
      rpc_submit
        alice
        (Harness.sell ~price_cents:10000 ~participant:Harness.alice ())
    in
    [%expect
      {| [for Alice] REJECTED client-id=0 AAPL SELL 100@$100.00 reason=client order id already exits |}];
    return ())
;;

let%expect_test "e2e: cancel an already filled order" =
  with_server ~symbols:[ Harness.aapl ] (fun ~server:_ ~port ->
    let%bind alice = connect_as ~port Harness.alice in
    let%bind bob = connect_as ~port Harness.bob in
    (* Bob places a sell *)
    let%bind () =
      rpc_submit
        bob
        (Harness.sell ~price_cents:15000 ~participant:Harness.bob ())
    in
    [%expect
      {| [for Bob] ACCEPTED client-id=0 id=1 AAPL SELL 100@$150.00 DAY |}];
    (* Alice places a buy — should cross *)
    let%bind () = rpc_submit alice (Harness.buy ~price_cents:15000 ()) in
    [%expect
      {|
      [for Alice] ACCEPTED client-id=0 id=2 AAPL BUY 100@$150.00 DAY
      [for Alice] FILL fill_id=1 AAPL $150.00 x100 aggressor=2 (client-id=0) (Alice) BUY resting=1 (client-id=0) (Bob)
      [for Bob] FILL fill_id=1 AAPL $150.00 x100 aggressor=2 (client-id=0) (Alice) BUY resting=1 (client-id=0) (Bob)
      |}];
    (* Alice cancels order *)
    let%bind () = rpc_cancel alice (Client_order_id.of_int 0) in
    [%expect
      {| [for Alice] REJECTED Cancel Request client-id:0 (Alice) reason=Order does not exist |}];
    return ())
;;

let%expect_test "e2e: cancel a nonexistent order" =
  with_server ~symbols:[ Harness.aapl ] (fun ~server:_ ~port ->
    let%bind alice = connect_as ~port Harness.alice in
    (* Alice cancels order *)
    let%bind () = rpc_cancel alice (Client_order_id.of_int 0) in
    [%expect
      {| [for Alice] REJECTED Cancel Request client-id:0 (Alice) reason=Order does not exist |}];
    return ())
;;

let%expect_test "e2e: BBO update after cancel" =
  with_server ~symbols:[ Harness.aapl ] (fun ~server:_ ~port ->
    let%bind bob = connect_as ~port Harness.bob in
    let%bind charlie = connect_as ~port Harness.charlie in
    (* Bob posts a sell *)
    let%bind () =
      rpc_submit
        bob
        (Harness.sell
           ~price_cents:15000
           ~size:50
           ~participant:Harness.bob
           ())
    in
    [%expect
      {| [for Bob] ACCEPTED client-id=0 id=1 AAPL SELL 50@$150.00 DAY |}];
    (* Charlie posts a sell at a higher price *)
    let%bind () =
      rpc_submit
        charlie
        (Harness.sell
           ~price_cents:15010
           ~size:50
           ~participant:Harness.charlie
           ())
    in
    [%expect
      {| [for Charlie] ACCEPTED client-id=0 id=2 AAPL SELL 50@$150.10 DAY |}];
    (* Verify book state prior to cancel *)
    let%bind book = rpc_book bob Harness.aapl in
    print_endline (Option.value_exn book |> Book.to_string);
    [%expect
      {|
      === AAPL ===
        BIDS: (empty)
        ASKS:
          $150.00 x50
          $150.10 x50
        BBO: - / $150.00 x50
      |}];
    (* Bob cancels order *)
    let%bind () = rpc_cancel bob (Client_order_id.of_int 0) in
    [%expect
      {| [for Bob] CANCELLED client_id=0 id=1 AAPL remaining=50 reason=PARTICIPANT_REQUESTED |}];
    (* Verify book state after cancel *)
    let%bind book = rpc_book bob Harness.aapl in
    print_endline (Option.value_exn book |> Book.to_string);
    [%expect
      {|
      === AAPL ===
        BIDS: (empty)
        ASKS:
          $150.10 x50
        BBO: - / $150.10 x50
      |}];
    return ())
;;

(* ---------------------------------------------------------------- *)
(* Test login *)
(* ---------------------------------------------------------------- *)

(*=let%expect_test "e2e: no login before submit" =
  with_server ~symbols:[ Harness.aapl ] (fun ~server:_ ~port ->
    let%bind alice = connect_as_no_login ~port Harness.alice in
    require_does_raise_async (fun () ->
      Async.return (rpc_submit alice (Harness.buy ~price_cents:15000 ())));
    [%expect
      {| "Symbol.of_string: symbol must contain only alphanumeric characters" |}];
    [%expect.unreachable];
    return ())
;;

let%expect_test "e2e: no login before cancel" =
  with_server ~symbols:[ Harness.aapl ] (fun ~server:_ ~port ->
    let%bind alice = connect_as_no_login ~port Harness.alice in
    require_does_raise_async (fun () ->
      Async.return (rpc_cancel alice (Client_order_id.of_int 0)));
    [%expect
      {| "Symbol.of_string: symbol must contain only alphanumeric characters" |}];
    [%expect.unreachable];
    return ())
;;

let%expect_test "e2e: two clients attempt to login with the same name" =
  with_server ~symbols:[ Harness.aapl ] (fun ~server:_ ~port ->
    let%bind _ = connect_as ~port Harness.alice in
    let%bind _ = connect_as ~port Harness.alice in
    (* Bob places a sell *)
    [%expect.unreachable];
    return ())
;;*)

(* ---------------------------------------------------------------- *)
(* Metrics feed *)
(* ---------------------------------------------------------------- *)

(* A short metrics interval makes snapshots arrive in milliseconds instead of
   once a real second. *)
let fast_metrics = Time_ns.Span.of_ms 20.

(* The dashboard consumes a whole [Metrics.t] each tick, so this checks the
   snapshot's *content* is coherent, not just a couple of counters. The
   volatile values (latency spans, live-word counts, timestamps) can't be
   pinned, so instead we assert invariants that must hold on every window:

   - latency percentiles are well-formed: [p50 <= p90 <= p99 <= max];
   - memory is actually reported: [live_words > 0];
   - engine busyness agrees with throughput: every processed request is one
     loop iteration and one latency sample, so per window
     [iterations = submits + cancels].

   Those ride alongside the deterministic totals (session count,
   submit/cancel counts, drained request queue). *)
module Metrics_observation = struct
  type t =
    { connected_sessions : int
    ; total_submits : int
    ; total_cancels : int
    ; final_request_queue : int
    ; all_percentiles_ordered : bool
    ; all_live_words_positive : bool
    ; iterations_match_throughput : bool
    }
  [@@deriving sexp_of]
end

let observe_metrics pipe ~expected_submit ~expected_cancel =
  let span_le a b = Time_ns.Span.compare a b <= 0 in
  let percentiles_ordered (s : Metrics.Latency_summary.t) =
    s.count > 0
    && span_le s.p50 s.p90
    && span_le s.p90 s.p99
    && span_le s.p99 s.max
  in
  let total_submits = ref 0
  and total_cancels = ref 0
  and connected_sessions = ref 0
  and final_request_queue = ref 0
  and all_percentiles_ordered = ref true
  and all_live_words_positive = ref true
  and iterations_match_throughput = ref true in
  (* Count one window's samples, checking percentile ordering as we go. *)
  let window_count = function
    | None -> 0
    | Some (s : Metrics.Latency_summary.t) ->
      if not (percentiles_ordered s) then all_percentiles_ordered := false;
      s.count
  in
  let rec loop reads =
    if (!total_submits >= expected_submit
        && !total_cancels >= expected_cancel)
       || reads >= 25
    then return ()
    else (
      let%bind (m : Metrics.t) = read_metrics pipe in
      connected_sessions := m.connected_sessions;
      final_request_queue := m.pipe_occupancy.request_queue;
      if m.gc.live_words <= 0 then all_live_words_positive := false;
      let window_submits = window_count m.submit_latency in
      let window_cancels = window_count m.cancel_latency in
      if m.engine_busyness.iterations <> window_submits + window_cancels
      then iterations_match_throughput := false;
      total_submits := !total_submits + window_submits;
      total_cancels := !total_cancels + window_cancels;
      loop (reads + 1))
  in
  let%map () = loop 0 in
  { Metrics_observation.connected_sessions = !connected_sessions
  ; total_submits = !total_submits
  ; total_cancels = !total_cancels
  ; final_request_queue = !final_request_queue
  ; all_percentiles_ordered = !all_percentiles_ordered
  ; all_live_words_positive = !all_live_words_positive
  ; iterations_match_throughput = !iterations_match_throughput
  }
;;

let%expect_test "metric_collector: metrics feed reports sessions, \
                 latencies, and queue"
  =
  with_server
    ~metrics_interval:fast_metrics
    ~symbols:[ Harness.aapl ]
    (fun ~server:_ ~port ->
       (* Alice just logs in (idle); Bob does the trading. Two participants
          means [connected_sessions] should read 2. *)
       let%bind alice = connect_as ~port Harness.alice in
       let%bind bob = connect_as ~port Harness.bob in
       let%bind metrics = subscribe_metrics alice in
       (* Two resting (non-crossing) sells and one cancel: 2 submits and 1
          cancel processed, no fills. *)
       let first = Client_order_id.of_int 0 in
       let%bind () =
         rpc_submit
           bob
           (Harness.sell
              ~price_cents:15100
              ~participant:Harness.bob
              ~client_id:first
              ())
       in
       let%bind () =
         rpc_submit
           bob
           (Harness.sell
              ~price_cents:15200
              ~participant:Harness.bob
              ~client_id:(Client_order_id.of_int 1)
              ())
       in
       let%bind () = rpc_cancel bob first in
       (* Flush Bob's session-feed prints before asserting on metrics. *)
       let%bind () = Async.Scheduler.yield_until_no_jobs_remain () in
       [%expect
         {|
         [for Bob] ACCEPTED client-id=0 id=1 AAPL SELL 100@$151.00 DAY
         [for Bob] ACCEPTED client-id=1 id=2 AAPL SELL 100@$152.00 DAY
         [for Bob] CANCELLED client_id=0 id=1 AAPL remaining=100 reason=PARTICIPANT_REQUESTED
         |}];
       let%bind observation =
         observe_metrics metrics ~expected_submit:2 ~expected_cancel:1
       in
       print_s [%sexp (observation : Metrics_observation.t)];
       [%expect
         {|
         ((connected_sessions 2) (total_submits 2) (total_cancels 1)
          (final_request_queue 0) (all_percentiles_ordered true)
          (all_live_words_positive true) (iterations_match_throughput true))
         |}];
       return ())
;;
