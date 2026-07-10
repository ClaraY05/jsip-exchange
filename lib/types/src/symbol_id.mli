(** A compact integer handle for a trading symbol, carried on the wire.

    Where {!Symbol} is the human-readable string form of an instrument
    (["AAPL"]), a [Symbol_id.t] is the integer the exchange uses in orders,
    fills, books, and events — small and cheap on the wire.

    This type is deliberately {b pure data}: it carries an int and renders as
    that int ([to_string] is [Int.to_string], sexps show the number).
    Recovering the human-readable name from an id is a {e consumer-side}
    concern — the Phase 2 symbol directory — and is intentionally NOT built
    into this type, so [lib/types] stays free of any name registry.
    Validating that an id is in range for a particular exchange is the
    {e server's} job, not this type's. *)

open! Core

type t = private int [@@deriving sexp, bin_io, compare, equal, hash]

include Comparable.S with type t := t
include Hashable.S with type t := t

(** The raw integer handle. *)
val to_int : t -> int

(** Wrap a raw integer as an id. *)
val of_int : int -> t

(** Render the id as its decimal integer (no name recovery). *)
val to_string : t -> string
