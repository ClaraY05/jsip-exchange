(** Exchange commands for centralizing command parsing

    Centralizing implementation of command-line interfaces, handling buy/sell
    commands and book and subscribe commands *)

open! Core
open Jsip_types

type t =
  | Submit of Order.Request.t
  | Book of Symbol_id.t
  | Subscribe of Symbol_id.t
  | Cancel of Client_order_id.t

type verb =
  | Buy
  | Sell
  | Book
  | Subscribe
  | Cancel
[@@deriving string]

(** [{Command}] *)

(** Parse a text command into an order request. A human types the symbol as a
    {b name} (e.g. [BOOK AAPL]); [directory] resolves it to the
    {!Symbol_id.t} the wire carries. Returns [Error] with a human-readable
    message if the input is malformed. Can set [default_participant] for
    clients that already know their identity. *)
val parse
  :  ?default_participant:Participant.t
  -> directory:Symbol_directory.t
  -> string
  -> t Or_error.t
