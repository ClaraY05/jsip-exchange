open! Core
open Jsip_gateway
open Jsip_test_harness

(* Documents the human-readable wire shape of a [Metrics.t]'s components. The
   top-level record additionally carries a [sampled_at : Time_ns.t], whose
   sexp is timezone-dependent, so it is pinned by the bin-shape digest in
   [test_rpc_shapes.ml] rather than shown here. The sub-records below all
   serialize deterministically — note that latency values render as spans
   ([2.5ms]), not raw integers. *)

let%expect_test "Latency_summary sexp" =
  let summary : Metrics.Latency_summary.t =
    { count = 1000
    ; p50 = Time_ns.Span.of_us 120.
    ; p90 = Time_ns.Span.of_ms 2.5
    ; p99 = Time_ns.Span.of_ms 30.
    ; max = Time_ns.Span.of_ms 88.
    }
  in
  print_s [%sexp (summary : Metrics.Latency_summary.t)];
  [%expect
    {| ((count 1000) (p50 120us) (p90 2.5ms) (p99 30ms) (max 88ms)) |}]
;;

let%expect_test "Gc_stats sexp" =
  let gc : Metrics.Gc_stats.t =
    { live_words = 123_456
    ; heap_words = 262_144
    ; top_heap_words = 262_144
    ; minor_collections = 42
    ; major_collections = 7
    ; promoted_words = 9000.
    }
  in
  print_s [%sexp (gc : Metrics.Gc_stats.t)];
  [%expect
    {|
    ((live_words 123456) (heap_words 262144) (top_heap_words 262144)
     (minor_collections 42) (major_collections 7) (promoted_words 9000))
    |}]
;;

let%expect_test "Pipe_occupancy sexp" =
  let occupancy : Metrics.Pipe_occupancy.t =
    { request_queue = 3
    ; audit = [ 0; 12 ]
    ; market_data = [ Harness.aapl, [ 0; 5 ] ]
    ; sessions = [ Harness.alice, 0; Harness.bob, 40 ]
    }
  in
  print_s [%sexp (occupancy : Metrics.Pipe_occupancy.t)];
  [%expect
    {|
    ((request_queue 3) (audit (0 12)) (market_data ((AAPL (0 5))))
     (sessions ((Alice 0) (Bob 40))))
    |}]
;;

let%expect_test "Engine_busyness sexp" =
  let busyness : Metrics.Engine_busyness.t =
    { iterations = 5000; max_inter_iteration_gap = Time_ns.Span.of_ms 12. }
  in
  print_s [%sexp (busyness : Metrics.Engine_busyness.t)];
  [%expect {| ((iterations 5000) (max_inter_iteration_gap 12ms)) |}]
;;
