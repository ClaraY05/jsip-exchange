open! Bonsai_web

(** Renders a {!Controller.Display.t} into the dashboard's Vdom: a header bar
    plus one card per pane (memory, submit/cancel latency, pipe occupancy,
    matching-engine busyness) laid out in a responsive grid. When the window
    is still empty it renders a "waiting for feed" state instead. *)
val dashboard_view : Controller.Display.t -> Vdom.Node.t
