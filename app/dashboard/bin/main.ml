(** Browser entry point for the JSIP dashboard.

    Compiled to JavaScript ([main.bc.js]) by js_of_ocaml and loaded by
    [static/index.html]. [Async_js.init] must run before any Async (the
    drain's deferreds) can make progress; [Start.start] mounts the app on the
    element with id ["app"]. *)

let () =
  Async_js.init ();
  Bonsai_web.Start.start Jsip_dashboard.Dashboard_app.app
;;
