open! Core
open! Bonsai_web

let default_width = 260.
let default_height = 40.

(* Maps one data point to its (x, y) pixel coordinate inside the [width] x
   [height] SVG box. [view] calls this (through [to_xy]) for every point of
   every run, then hands the coordinates to [polyline]. *)
let project ~width ~height ~lo ~hi ~n i value : float * float =
  let x =
    if n <= 1 then 0. else Float.of_int i /. Float.of_int (n - 1) *. width
  in
  let y = height -. ((value -. lo) /. Float.max 1e-9 (hi -. lo) *. height) in
  x, y
;;

(* Group the series into maximal runs of consecutive [Some] values, each run
   a list of [(index, value)] in order. Runs are separated by [None] gaps so
   the sparkline draws one polyline per run and leaves the gaps blank. *)
let runs (data : float option array) : (int * float) list list =
  let flush run acc =
    if List.is_empty run then acc else List.rev run :: acc
  in
  let final_run, acc =
    Array.foldi data ~init:([], []) ~f:(fun i (run, acc) point ->
      match point with
      | Some value -> (i, value) :: run, acc
      | None -> [], flush run acc)
  in
  List.rev (flush final_run acc)
;;

(* [points] is SVG geometry (not style), so it stays an attribute; the colour
   comes from the [line] class and the shared stroke geometry (width, join,
   non-scaling) from {!Styles.sparkline_line}. *)
let polyline ~line points =
  let points_attr =
    List.map points ~f:(fun (x, y) -> [%string "%{x#Float},%{y#Float}"])
    |> String.concat ~sep:" "
  in
  Vdom.Node.create_svg
    "polyline"
    ~attrs:
      [ Vdom.Attr.create "points" points_attr; Styles.sparkline_line; line ]
    []
;;

let view
  ?(width = default_width)
  ?(height = default_height)
  ?y_min
  ?y_max
  ~line
  data
  =
  let n = Array.length data in
  let present = Array.filter_map data ~f:Fn.id in
  let lo =
    match y_min with
    | Some lo -> lo
    | None ->
      Option.value (Array.min_elt present ~compare:Float.compare) ~default:0.
  in
  let hi =
    match y_max with
    | Some hi -> hi
    | None ->
      Option.value (Array.max_elt present ~compare:Float.compare) ~default:1.
  in
  let to_xy (i, value) = project ~width ~height ~lo ~hi ~n i value in
  let polylines =
    List.map (runs data) ~f:(fun run ->
      polyline ~line (List.map run ~f:to_xy))
  in
  Vdom.Node.create_svg
    "svg"
    ~attrs:
      [ Vdom.Attr.create
          "viewBox"
          [%string "0 0 %{width#Float} %{height#Float}"]
      ; Vdom.Attr.create "preserveAspectRatio" "none"
      ; Vdom.Attr.create "width" "100%"
      ; Vdom.Attr.create "height" [%string "%{height#Float}"]
      ; Styles.sparkline_svg
      ]
    polylines
;;
