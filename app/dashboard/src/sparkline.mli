open! Core
open! Bonsai_web

(** A fixed-size inline-SVG sparkline for one
    {!Jsip_dashboard_controller.Controller.Series.t}.

    [None] entries break the line into separate segments instead of plotting
    a false zero, so a second with no data reads as a gap. The y-axis
    auto-scales to the present values unless [y_min]/[y_max] pin it (pass a
    shared range to make several sparklines directly comparable, e.g. the
    three latency percentiles). The svg fills its container's width and
    scales non-uniformly, so callers control size via the surrounding layout.

    [line] is the ppx_css stroke-colour class for the plotted line (e.g.
    {!Styles.s_p50}); the shared stroke geometry lives in
    {!Styles.sparkline_line}. *)
val view
  :  ?width:float (** viewBox width; default 260. *)
  -> ?height:float (** viewBox height; default 40. *)
  -> ?y_min:float
  -> ?y_max:float
  -> line:Vdom.Attr.t
  -> float option array
  -> Vdom.Node.t
