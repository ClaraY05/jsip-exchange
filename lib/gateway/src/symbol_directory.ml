open! Core
open Jsip_types

(* Fixed name<->id bimap for symbols. Unlike {!Participant_registry}, the
   symbol set is known in full up front (the server's symbol list; the
   directory a client fetches once at connect), so this never grows and both
   halves are built together:

   - [name_to_id]: hashes a symbol name to its id. Used at the parse edge,
     where a human hands us a name ([BOOK AAPL]).
   - [id_to_name]: recovers the name for display. Ids are dense from 0 (id
     [i] names the [i]th symbol), so this is a plain array indexed *by the id
     itself* — an O(1), no-hash reverse lookup (the Exercise 0b lesson: a
     dense integer key wants an array, not a hashtable).

   Symbol ids stay internal to the wire; this directory is the readability
   layer that lets the client and monitor turn them back into names. *)
type t =
  { name_to_id : Symbol_id.t Symbol.Table.t
  ; id_to_name : Symbol.t array
  }

let of_names_exn names =
  let id_to_name = Array.of_list names in
  let name_to_id = Symbol.Table.create () in
  Array.iteri id_to_name ~f:(fun i name ->
    Hashtbl.add_exn name_to_id ~key:name ~data:(Symbol_id.of_int i));
  { name_to_id; id_to_name }
;;

let to_pairs t =
  Array.to_list t.id_to_name
  |> List.mapi ~f:(fun i name -> name, Symbol_id.of_int i)
;;

let of_pairs_exn pairs =
  let name_to_id = Symbol.Table.create () in
  List.iter pairs ~f:(fun (name, id) ->
    Hashtbl.add_exn name_to_id ~key:name ~data:id);
  let id_to_name =
    List.sort pairs ~compare:(fun (_, a) (_, b) -> Symbol_id.compare a b)
    |> List.map ~f:fst
    |> Array.of_list
  in
  { name_to_id; id_to_name }
;;

let id_of_name t name = Hashtbl.find t.name_to_id name

let name t id =
  let i = Symbol_id.to_int id in
  match i >= 0 && i < Array.length t.id_to_name with
  | true -> Some t.id_to_name.(i)
  | false -> None
;;
