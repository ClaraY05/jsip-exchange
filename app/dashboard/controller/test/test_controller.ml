open! Core
module Metrics = Jsip_gateway_protocol.Metrics
module Controller = Jsip_dashboard_controller.Controller

let span_ms ms = Time_ns.Span.of_ms ms

(* A synthetic snapshot. [live] drives the memory series, [submit_p50] the
   submit-latency series; [cancel] toggles whether a cancel summary is present
   (so we can check the [None]-gap projection). *)
let sample ~second ~live ~submit_p50 ~cancel : Metrics.t =
  { sampled_at = Time_ns.of_span_since_epoch (Time_ns.Span.of_int_sec second)
  ; gc =
      { live_words = live
      ; heap_words = live * 2
      ; top_heap_words = live * 3
      ; minor_collections = 0
      ; major_collections = 0
      ; promoted_words = 0.
      }
  ; submit_latency =
      Some
        { count = 10
        ; p50 = span_ms submit_p50
        ; p90 = span_ms (submit_p50 *. 2.)
        ; p99 = span_ms (submit_p50 *. 3.)
        ; max = span_ms (submit_p50 *. 4.)
        }
  ; cancel_latency =
      (if cancel
       then
         Some
           { count = 1
           ; p50 = span_ms 5.
           ; p90 = span_ms 5.
           ; p99 = span_ms 5.
           ; max = span_ms 5.
           }
       else None)
  ; pipe_occupancy =
      { request_queue = 0; audit = []; market_data = []; sessions = [] }
  ; engine_busyness =
      { iterations = 0; max_inter_iteration_gap = span_ms 0. }
  ; connected_sessions = 1
  }
;;

let feed_all ?(window_capacity = Controller.default_window_capacity) ms =
  List.fold
    ms
    ~init:(Controller.create ~window_capacity)
    ~f:Controller.feed_metrics
;;

(* Print only timezone-independent fields — [latest_sampled_at] renders a
   local-time string, which would make this test machine-dependent. *)
let%expect_test "projects series oldest-first; absent cancel latency -> all None" =
  let c =
    feed_all
      [ sample ~second:0 ~live:100 ~submit_p50:1. ~cancel:false
      ; sample ~second:1 ~live:150 ~submit_p50:2. ~cancel:false
      ]
  in
  let d = Controller.display c in
  print_s
    [%message
      ""
        ~window_len:(d.window_len : int)
        ~live_words:(d.memory.live_words : Controller.Series.t)
        ~submit_p50_ms:(d.submit_latency.p50_ms : Controller.Series.t)
        ~cancel_p50_ms:(d.cancel_latency.p50_ms : Controller.Series.t)
        ~submit_count_latest:(d.submit_latency.count_latest : int option)];
  [%expect {|
    ((window_len 2) (live_words ((100) (150))) (submit_p50_ms ((1) (2)))
     (cancel_p50_ms (() ())) (submit_count_latest (10)))
    |}]
;;

let%test_unit "window is bounded to its own capacity and evicts oldest first" =
  let window_capacity = 3 in
  let many =
    List.init (window_capacity + 2) ~f:(fun i ->
      sample ~second:i ~live:i ~submit_p50:1. ~cancel:false)
  in
  let d = Controller.display (feed_all ~window_capacity many) in
  [%test_result: int] d.window_len ~expect:window_capacity;
  (* Fed 5 snapshots (live 0..4) into a capacity-3 window; the oldest two were
     dropped, so the oldest retained memory reading is live = 2. *)
  [%test_result: float option] d.memory.live_words.(0) ~expect:(Some 2.)
;;
