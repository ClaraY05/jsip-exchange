(** A bonsai_web dashboard for the JSIP exchange.

    [Controller] is the pure, Bonsai-free state machine: it folds the
    per-second {!Jsip_gateway_protocol.Metrics.t} feed into a rolling window
    and projects a render-ready {!Controller.Display.t}. [Sparkline] and
    [Panes] render that projection to Vdom, and [Dashboard_app] wraps it into
    a bonsai_web app that drains the feed and can be handed to
    [Bonsai_web.Start.start]. [Styles] holds the shared design tokens.

    The split mirrors {!Jsip_monitor}: a platform-neutral controller plus a
    thin, browser-specific rendering/wiring layer. Because [bonsai_web]
    (unlike [bonsai_term]) has no native implementation, the controller's
    expect tests run in JS mode — see [app/dashboard/test/dune]. *)

module Controller = Controller
module Dashboard_app = Dashboard_app
module Panes = Panes
module Sparkline = Sparkline
module Styles = Styles
