(** Server-global registry interning participant names to
    {!Participant_id.t}.

    This registry is {b additive} — an id, once assigned, is valid for the
    whole run, so a participant who disconnects and reconnects is interned
    back to the {e same} id.

    Names enter at the login edge and are interned with {!intern}; the server
    keys its own tables by the returned id and resolves back to the name with
    {!name} at display edges. The id never crosses the wire. *)

open! Core
open Jsip_types

type t

(** A fresh, empty registry. One is shared across all connections. *)
val create : unit -> t

(** Intern a name: return its existing id, or assign the next fresh id if
    this is the first time the name has been seen. Repeated calls with the
    same name return the same id. *)
val intern : t -> Participant.t -> Participant_id.t

(** The id [name] was interned to, or [None] if it never has been. *)
val id_of_name : t -> Participant.t -> Participant_id.t option

(** The name [id] was interned from. Raises if [id] was not produced by this
    registry (ids are dense from zero, so an out-of-range id is a bug, not
    ordinary control flow). *)
val name : t -> Participant_id.t -> Participant.t
