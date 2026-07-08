open! Core

module Build_list = struct
  (* [acc @ [ x ]] copies the whole accumulator each step -> O(n^2)
     allocation. *)
  let silly xs =
    let rec build_list list acc =
      match list with [] -> acc | hd :: tl -> build_list tl acc @ [ hd ]
    in
    build_list xs []
  ;;

  (* Prepend (O(1) per step) then reverse once -> O(n) allocation. Same
     result. *)
  let non_silly xs =
    let rec build_list list acc =
      match list with [] -> acc | hd :: tl -> build_list tl (hd :: acc)
    in
    let rec reverse list acc =
      match list with [] -> acc | hd :: tl -> reverse tl (hd :: acc)
    in
    reverse (build_list xs []) []
  ;;
end

module First_match = struct
  (* Allocate a fresh list of *every* match, then throw all but the head
     away. *)
  let silly xs ~f = List.hd (List.filter xs ~f)

  (* Stop at the first match; allocate nothing but the returned [Some]. *)
  let non_silly xs ~f = List.find xs ~f
end
