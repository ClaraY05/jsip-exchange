open! Core
open Jsip_types
open Jsip_gateway

(** Tests for {!Symbol_directory}: the fixed name<->id bimap from Part 4
    Exercise 4 Phase 2. These pin down the two resolutions the client and
    monitor rely on — name->id at parse and id->name at render — plus the
    round trip through the wire form ([to_pairs]/[of_pairs_exn]). *)

let aapl = Symbol.of_string "AAPL"
let tsla = Symbol.of_string "TSLA"
let goog = Symbol.of_string "GOOG"
let directory = Symbol_directory.of_names_exn [ aapl; tsla; goog ]

let%expect_test "of_names_exn assigns dense ids from zero" =
  print_s [%sexp (Symbol_directory.to_pairs directory : (Symbol.t * Symbol_id.t) list)];
  [%expect {| ((AAPL 0) (TSLA 1) (GOOG 2)) |}]
;;

let%expect_test "id_of_name resolves a known symbol, None otherwise" =
  let known = Symbol_directory.id_of_name directory tsla in
  let unknown =
    Symbol_directory.id_of_name directory (Symbol.of_string "ZZZZ")
  in
  print_s
    [%message "" (known : Symbol_id.t option) (unknown : Symbol_id.t option)];
  [%expect {| ((known (1)) (unknown ())) |}]
;;

let%expect_test "name resolves a known id, None for out-of-range" =
  let known = Symbol_directory.name directory (Symbol_id.of_int 2) in
  let out_of_range = Symbol_directory.name directory (Symbol_id.of_int 3) in
  print_s
    [%message "" (known : Symbol.t option) (out_of_range : Symbol.t option)];
  [%expect {| ((known (GOOG)) (out_of_range ())) |}]
;;

let%expect_test "of_pairs_exn round-trips a directory rebuilt from the wire form" =
  (* Shuffle the pairs to prove [of_pairs_exn] does not assume input order. *)
  let scrambled = [ goog, Symbol_id.of_int 2; aapl, Symbol_id.of_int 0; tsla, Symbol_id.of_int 1 ] in
  let rebuilt = Symbol_directory.of_pairs_exn scrambled in
  print_s [%sexp (Symbol_directory.to_pairs rebuilt : (Symbol.t * Symbol_id.t) list)];
  [%expect {| ((AAPL 0) (TSLA 1) (GOOG 2)) |}]
;;
