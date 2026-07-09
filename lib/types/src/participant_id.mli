(** A small integer handle for a participant, interned by the server.

    Where {!Participant} is the human-readable name a client logs in with
    ([Participant.of_string "Alice"]), a [Participant_id.t] is the interned
    integer the server keys its own lookup tables by. It is {b server-local in
    use}: unlike {!Symbol_id}, it is never placed on the wire — the client only
    ever sees the {!Participant} name. The mapping between the two is owned by
    the server's participant registry.

    The type is a [private int]: any module may read the raw integer (via
    {!to_int} or the coercion [(id :> int)] — handy for indexing a dense array),
    but only {!of_int} can construct one. Ids are minted by the server's
    registry and treated as opaque handles everywhere else. *)

open! Core

type t = private int [@@deriving sexp_of, compare, equal, hash]

include Comparable.S_plain with type t := t
include Hashable.S_plain with type t := t

(** The underlying integer. *)
val to_int : t -> int

(** Mint an id from a raw integer. Intended for the participant registry, which
    owns id assignment; other code should treat ids as opaque handles. *)
val of_int : int -> t
