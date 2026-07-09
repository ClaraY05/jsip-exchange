open! Core
open Jsip_types

(* Additive name<->id store. Two halves kept in sync by [intern]:

   - [name_to_id]: hashes the participant name to its id. A string hash is
     unavoidable here — the name is the thing we're handed at the login edge.
   - [id_to_name]: recovers the name for display. Because ids are dense and
     assigned in order from 0, this is a growable array indexed *by the id
     itself* — an O(1), no-hash reverse lookup that can only grow. (This is
     the Exercise 0b lesson: a dense integer key wants an array, not a
     hashtable.) Its length doubles as the id counter: the next id to assign
     is exactly the current [Dynarray.length], so there is no separate
     counter that could drift out of sync with the array.

   The store is additive: it only ever grows, so an id stays valid for the
   whole run and a reconnecting participant is interned back to the same id. *)
type t =
  { name_to_id : Participant_id.t Participant.Table.t
  ; id_to_name : Participant.t Dynarray.t
  }

let create () =
  { name_to_id = Participant.Table.create ()
  ; id_to_name = Dynarray.create ()
  }
;;

let id_of_name t name = Hashtbl.find t.name_to_id name

let name t id =
  match Dynarray.get t.id_to_name (Participant_id.to_int id) with
  | name -> name
  | exception _ ->
    raise_s
      [%message
        "Participant_registry.name: id not in registry"
          (id : Participant_id.t)]
;;

let intern t name : Participant_id.t =
  match Hashtbl.find t.name_to_id name with
  | Some participant_id -> participant_id
  | None ->
    let participant_id =
      Participant_id.of_int (Dynarray.length t.id_to_name)
    in
    Hashtbl.add_exn t.name_to_id ~key:name ~data:participant_id;
    Dynarray.add_last t.id_to_name name;
    participant_id
;;
