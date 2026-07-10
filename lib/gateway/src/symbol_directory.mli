(** Bidirectional map between symbol {b names} ({!Symbol.t}) and the interned
    {!Symbol_id.t} that travels on the wire.

    Recovers human-readable names at the edges. The server builds a directory
    from its symbol list and serves it over the [symbol-directory] RPC
    ({!Rpc_protocol.symbol_directory_rpc}); the client and monitor fetch it
    once at connect and mirror it locally. They then resolve

    - {b name -> id at parse}: a human types [BOOK AAPL], {!id_of_name} maps
      it to the id the wire carries; and
    - {b id -> name at render}: an event or book arrives carrying an id,
      {!name} maps it back for display.

    The set of symbols is fixed at construction (unlike the growable
    {!Participant_registry}), so ids are dense from 0 *)

open! Core
open Jsip_types

type t

(** Build a directory from an ordered name list: the [i]th name is given id
    [i]. This is how the server assigns ids from its symbol list. Raises on a
    duplicate name. *)
val of_names_exn : Symbol.t list -> t

(** Rebuild a directory from [(name, id)] pairs — how a client reconstructs
    the server's directory from the RPC response. Raises on a duplicate name. *)
val of_pairs_exn : (Symbol.t * Symbol_id.t) list -> t

(** The [(name, id)] pairs, in id order. This is the wire form the server
    sends over the [symbol-directory] RPC. *)
val to_pairs : t -> (Symbol.t * Symbol_id.t) list

(** The id [name] maps to, or [None] if it is not a known symbol. Used at the
    parse edge to reject unknown symbols. *)
val id_of_name : t -> Symbol.t -> Symbol_id.t option

(** The name [id] maps to, or [None] if the id is out of range. Returns an
    option (rather than raising like {!Participant_registry.name}) because a
    render site should degrade gracefully — print the raw id — rather than
    crash if a client's mirror is somehow stale. *)
val name : t -> Symbol_id.t -> Symbol.t option
