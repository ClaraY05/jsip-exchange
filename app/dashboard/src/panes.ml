open! Core
open! Bonsai_web
open Jsip_types
module Display = Controller.Display
module Series = Controller.Series

let div ?(attrs = []) children = Vdom.Node.div ~attrs children
let span ?(attrs = []) children = Vdom.Node.span ~attrs children
let text = Vdom.Node.text

(* --- formatting --- *)

let round2 f = Float.round_nearest (f *. 100.) /. 100.
let fmt_int = function Some n -> Int.to_string_hum n | None -> "—"

let fmt_ms = function
  | Some f -> [%string "%{round2 f#Float} ms"]
  | None -> "—"
;;

let depths = function
  | [] -> "—"
  | ds -> String.concat ~sep:" " (List.map ds ~f:Int.to_string)
;;

(* The most recent present value in a series (its rightmost [Some]). *)
let series_latest (s : Series.t) : float option =
  Array.fold s ~init:None ~f:(fun acc x ->
    match x with Some _ -> x | None -> acc)
;;

(* --- small building blocks --- *)

let stat ~label ~value =
  div
    ~attrs:[ Styles.stat ]
    [ span ~attrs:[ Styles.stat_label ] [ text label ]
    ; span ~attrs:[ Styles.stat_value ] [ text value ]
    ]
;;

let card ~title ~accent children =
  let heading = div ~attrs:[ Styles.card_title; accent ] [ text title ] in
  div ~attrs:[ Styles.card ] (heading :: children)
;;

let caption s = span ~attrs:[ Styles.stat_label ] [ text s ]

(* --- panes --- *)

let memory_pane (m : Display.Memory.t) =
  card
    ~title:"Process memory"
    ~accent:Styles.c_memory
    [ Sparkline.view ~line:Styles.s_memory m.live_words
    ; stat ~label:"live words" ~value:(fmt_int m.live_words_latest)
    ; stat ~label:"heap words" ~value:(fmt_int m.heap_words_latest)
    ; stat ~label:"top heap words" ~value:(fmt_int m.top_heap_words_latest)
    ; stat
        ~label:"major collections"
        ~value:(fmt_int m.major_collections_latest)
    ]
;;

let latency_row ~label ~color ~line ~y_max series =
  div
    ~attrs:[ Styles.latency_row ]
    [ span ~attrs:[ Styles.latency_label; color ] [ text label ]
    ; div
        ~attrs:[ Styles.latency_chart ]
        [ Sparkline.view ~height:22. ~y_min:0. ~y_max ~line series ]
    ; span
        ~attrs:[ Styles.latency_value ]
        [ text (fmt_ms (series_latest series)) ]
    ]
;;

let latency_pane ~title (l : Display.Latency.t) =
  let series_max s =
    Array.filter_map s ~f:Fn.id |> Array.max_elt ~compare:Float.compare
  in
  let y_max =
    List.filter_map [ l.p50_ms; l.p90_ms; l.p99_ms ] ~f:series_max
    |> List.max_elt ~compare:Float.compare
    |> Option.value ~default:1.
  in
  card
    ~title
    ~accent:Styles.c_p90
    [ latency_row
        ~label:"p50"
        ~color:Styles.c_p50
        ~line:Styles.s_p50
        ~y_max
        l.p50_ms
    ; latency_row
        ~label:"p90"
        ~color:Styles.c_p90
        ~line:Styles.s_p90
        ~y_max
        l.p90_ms
    ; latency_row
        ~label:"p99"
        ~color:Styles.c_p99
        ~line:Styles.s_p99
        ~y_max
        l.p99_ms
    ; stat ~label:"orders / sec (latest)" ~value:(fmt_int l.count_latest)
    ]
;;

let pipe_pane (p : Display.Pipe_occupancy.t) =
  let market_data_rows =
    List.map p.market_data_queues_latest ~f:(fun (symbol, ds) ->
      stat ~label:[%string "  %{symbol#Symbol}"] ~value:(depths ds))
  in
  let session_rows =
    List.map p.session_queues_latest ~f:(fun (participant, d) ->
      stat
        ~label:[%string "  %{participant#Participant}"]
        ~value:(Int.to_string d))
  in
  card
    ~title:"Pipe occupancy"
    ~accent:Styles.c_queue
    ([ caption "inbound request queue"
     ; Sparkline.view ~line:Styles.s_queue p.request_queue
     ; stat ~label:"request queue" ~value:(fmt_int p.request_queue_latest)
     ; stat ~label:"audit subscribers" ~value:(depths p.audit_queues_latest)
     ; caption "market-data queues by symbol"
     ]
     @ market_data_rows
     @ [ caption "session queues" ]
     @ session_rows)
;;

let engine_pane (e : Display.Engine_busyness.t) =
  card
    ~title:"Matching-engine busyness"
    ~accent:Styles.c_engine
    [ caption "iterations / sec"
    ; Sparkline.view ~line:Styles.s_engine e.iterations
    ; stat ~label:"iterations (latest)" ~value:(fmt_int e.iterations_latest)
    ; caption "max inter-iteration gap"
    ; Sparkline.view ~line:Styles.s_engine e.max_gap_ms
    ; stat ~label:"max gap (latest)" ~value:(fmt_ms e.max_gap_ms_latest)
    ]
;;

let header (d : Display.t) =
  let item label value =
    span
      [ caption [%string "%{label}: "]
      ; span ~attrs:[ Styles.stat_value ] [ text value ]
      ]
  in
  div
    ~attrs:[ Styles.header_bar ]
    [ span
        ~attrs:[ Styles.header_title ]
        [ text "JSIP Exchange — Live Metrics" ]
    ; item "sessions" (Int.to_string d.connected_sessions)
    ; item "history" [%string "%{d.window_len#Int}s"]
    ]
;;

let dashboard_view (d : Display.t) : Vdom.Node.t =
  let body =
    if d.window_len = 0
    then
      div ~attrs:[ Styles.waiting ] [ text "Waiting for the metrics feed…" ]
    else
      div
        ~attrs:[ Styles.grid ]
        [ memory_pane d.memory
        ; latency_pane ~title:"Submit-order latency" d.submit_latency
        ; latency_pane ~title:"Cancel-order latency" d.cancel_latency
        ; pipe_pane d.pipe_occupancy
        ; engine_pane d.engine_busyness
        ]
  in
  div ~attrs:[ Styles.page ] [ header d; body ]
;;
