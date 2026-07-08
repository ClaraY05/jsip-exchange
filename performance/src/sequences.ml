open! Core

module List_seq = struct
  (* A [ref] so that [set] can update in place and return [unit], per the
     [.mli]. The list stores elements in index order: position [i] in the
     list is index [i]. Positional [set] is O(n) either way -- that's the
     point of the comparison. *)
  type t = int list ref

  let create () : t = ref []

  (* Three cases, following the [.mli]: out of range raises, [key = length]
     appends, and [key < length] replaces the element already there. *)
  let set t ~key ~data =
    let len = List.length !t in
    if key < 0 || key > len
    then
      raise_s
        [%message "List_seq.set: index out of range" (key : int) (len : int)]
    else if key = len
    then t := !t @ [ data ]
    else t := List.mapi !t ~f:(fun i x -> if i = key then data else x)
  ;;

  let get t key = List.nth !t key
end

module Dynarray_seq = struct
  type t = int Dynarray.t

  let create () : t = Dynarray.create ()

  let set t ~key ~data =
    let len = Dynarray.length t in
    match key < 0 || key > len with
    | true ->
      raise_s
        [%message
          "Dynarray_seq.set: index out of range" (key : int) (len : int)]
    | false ->
      (match key = len with
       | false -> Dynarray.set t key data
       | true -> Dynarray.add_last t data)
  ;;

  let get t key =
    match key < 0 || key >= Dynarray.length t with
    | true -> None
    | false -> Some (Dynarray.get t key)
  ;;
end
