open! Core
open Jsip_gateway

(* Samples are given as integer milliseconds for readability; [percentiles]
   sorts internally, so the inputs are deliberately unsorted to check this *)
let show_metric_percentiles ms_values =
  let samples =
    Array.of_list_map ms_values ~f:(fun ms ->
      Time_ns.Span.of_ms (Float.of_int ms))
  in
  match Metrics_collector.percentiles samples with
  | None -> print_endline "None"
  | Some (p50, p90, p99, max) ->
    print_s
      [%message
        ""
          (p50 : Time_ns.Span.t)
          (p90 : Time_ns.Span.t)
          (p99 : Time_ns.Span.t)
          (max : Time_ns.Span.t)]
;;

let%expect_test "metrics_collector: empty window has no percentiles" =
  show_metric_percentiles [];
  [%expect {| None |}]
;;

let%expect_test "metrics_collector:  1..100 (reversed) lands on \
                 nearest-rank indices"
  =
  show_metric_percentiles (List.rev (List.range 1 101));
  [%expect {| ((p50 50ms) (p90 90ms) (p99 99ms) (max 100ms)) |}]
;;

let%expect_test "metrics_collector: single sample is every percentile" =
  show_metric_percentiles [ 42 ];
  [%expect {| ((p50 42ms) (p90 42ms) (p99 42ms) (max 42ms)) |}]
;;

let%expect_test "metrics_collector: small odd window" =
  show_metric_percentiles [ 30; 10; 20 ];
  [%expect {| ((p50 20ms) (p90 30ms) (p99 30ms) (max 30ms)) |}]
;;
