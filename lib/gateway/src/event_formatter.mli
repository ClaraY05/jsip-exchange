(** Formats exchanges.

    This module defines how exchange events are formatted for display. On a
    production exchange, this would be a binary protocol like FIX for
    performance and interoperability. We use a simple human-readable text
    format for ease of debugging and interactive use.

    {2 Command format}

    Each command is a single line of text:
    {v
    BUY  <symbol> <size> <price> [<time_in_force>] [as <participant>]
    SELL <symbol> <size> <price> [<time_in_force>] [as <participant>]
    v}

    Examples:
    {v
    BUY AAPL 100 150.25
    SELL TSLA 50 200.00 IOC
    BUY AAPL 100 150.00 DAY as Alice
    v}

    Time-in-force defaults to DAY if omitted. Participant defaults to
    "anonymous" if omitted. *)

open! Core
open Jsip_types

(** How to render a symbol id for display. The wire carries only
    {!Symbol_id.t}; pass [Symbol_id.to_string] to show the raw id (server
    logs, tests) or a {!Symbol_directory}-backed lookup to show the name
    (client, monitor). Every formatter below takes one so name recovery stays
    a consumer concern and [lib/types] stays int-only. *)
type render_symbol = Symbol_id.t -> string

(** Format an exchange event as a single line of human-readable text. *)
val format_event : render_symbol:render_symbol -> Exchange_event.t -> string

(** Format a list of events, one per line. *)
val format_events
  :  render_symbol:render_symbol
  -> Exchange_event.t list
  -> string

(** Format a single fill (the body of a [Fill] event). *)
val format_fill : render_symbol:render_symbol -> Fill.t -> string

(** Format a book snapshot — the client's [BOOK] response. Mirrors
    {!Book.to_string} but renders the symbol via [render_symbol]. *)
val format_book : render_symbol:render_symbol -> Book.t -> string

(** A fill from one participant's perspective ("You bought 100 AAPL at …").
    The name-recovering analogue of {!Fill.to_participant_view}, but returns
    a plain [string]: the dispatcher only delivers a fill to its two parties,
    so [participant] is always one of them. Passing a non-party is a
    precondition violation and raises. *)
val format_participant_fill
  :  render_symbol:render_symbol
  -> Fill.t
  -> Participant.t
  -> string
