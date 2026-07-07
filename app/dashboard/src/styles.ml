open! Core
open! Bonsai_web

(** Design tokens and layout for the dashboard, as a ppx_css stylesheet.

    Each class below surfaces as a [Vdom.Attr.t] (e.g. {!card}) that the
    render code applies via [~attrs] — there are no raw CSS strings or
    [Vdom.Attr.create "style"] calls. ppx_css hashes the class names for
    scoping and appends the stylesheet to the page when this module loads.

    The six accent hues each come in a [c_*] (text [color]) and an [s_*] (SVG
    [stroke]) variant so one hue can tint both a card title and its
    sparkline; [sparkline_line] holds the stroke geometry common to every
    sparkline. *)

include
  [%css
  stylesheet
    {|
  .page {
    min-height: 100vh;
    margin: 0;
    background: lch(4% 1 265);
    color: lch(96% 1 250);
    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
    font-size: 13px;
  }

  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
    gap: 14px;
    padding: 14px;
  }

  .card {
    background: lch(11% 1.5 265);
    border: 1px solid lch(20% 3 265);
    border-radius: 8px;
    padding: 14px;
    display: flex;
    flex-direction: column;
    gap: 10px;
  }

  .card_title {
    font-weight: 600;
    letter-spacing: 0.02em;
    text-transform: uppercase;
    font-size: 11px;
  }

  .stat {
    display: flex;
    justify-content: space-between;
    gap: 12px;
  }

  .stat_label {
    color: lch(52% 3 260);
    font-size: 11px;
  }

  .stat_value {
    font-variant-numeric: tabular-nums;
    color: lch(96% 1 250);
  }

  .header_bar {
    display: flex;
    gap: 18px;
    align-items: baseline;
    padding: 12px 14px;
    border-bottom: 1px solid lch(20% 3 265);
    color: lch(72% 3 260);
  }

  .header_title {
    font-variant-numeric: tabular-nums;
    color: lch(96% 1 250);
    font-weight: 600;
    font-size: 15px;
  }

  .waiting {
    padding: 48px;
    text-align: center;
    color: lch(52% 3 260);
  }

  .latency_row {
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .latency_label {
    font-size: 11px;
    width: 28px;
  }

  .latency_chart {
    flex: 1;
    min-width: 0;
  }

  .latency_value {
    font-variant-numeric: tabular-nums;
    color: lch(96% 1 250);
    width: 72px;
    text-align: right;
  }

  .sparkline_svg {
    display: block;
  }

  .sparkline_line {
    fill: none;
    stroke-width: 1.5;
    vector-effect: non-scaling-stroke;
    stroke-linejoin: round;
  }

  .c_memory { color: lch(70% 45 155); }
  .c_queue  { color: lch(68% 48 300); }
  .c_engine { color: lch(70% 40 200); }
  .c_p50    { color: lch(66% 42 240); }
  .c_p90    { color: lch(76% 70 90); }
  .c_p99    { color: lch(60% 62 25); }

  .s_memory { stroke: lch(70% 45 155); }
  .s_queue  { stroke: lch(68% 48 300); }
  .s_engine { stroke: lch(70% 40 200); }
  .s_p50    { stroke: lch(66% 42 240); }
  .s_p90    { stroke: lch(76% 70 90); }
  .s_p99    { stroke: lch(60% 62 25); }
|}]
