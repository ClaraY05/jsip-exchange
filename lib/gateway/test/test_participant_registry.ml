open! Core
open Jsip_types
open Jsip_gateway

(** Tests for {!Participant_registry}: the server-local, additive name<->id
    store from Part 4 Exercise 3. These pin down the three properties the
    dispatcher relies on — dense ids assigned from zero, additive interning
    (a reconnecting participant keeps its id), and an id->name round trip. *)

let alice = Participant.of_string "Alice"
let bob = Participant.of_string "Bob"

let%expect_test "intern assigns dense ids from zero" =
  let registry = Participant_registry.create () in
  let alice_id = Participant_registry.intern registry alice in
  let bob_id = Participant_registry.intern registry bob in
  print_s
    [%message "" (alice_id : Participant_id.t) (bob_id : Participant_id.t)];
  [%expect {| ((alice_id 0) (bob_id 1)) |}]
;;

let%expect_test "intern is additive: the same name returns the same id" =
  let registry = Participant_registry.create () in
  let first = Participant_registry.intern registry alice in
  (* Interleave a different participant, then re-intern Alice. *)
  let (_ : Participant_id.t) = Participant_registry.intern registry bob in
  let again = Participant_registry.intern registry alice in
  print_s [%message "" (first : Participant_id.t) (again : Participant_id.t)];
  [%expect {| ((first 0) (again 0)) |}]
;;

let%expect_test "name recovers the participant an id was interned from" =
  let registry = Participant_registry.create () in
  let alice_id = Participant_registry.intern registry alice in
  print_s [%sexp (Participant_registry.name registry alice_id : Participant.t)];
  [%expect {| Alice |}]
;;

let%expect_test "id_of_name is None for a never-interned name" =
  let registry = Participant_registry.create () in
  print_s
    [%sexp
      (Participant_registry.id_of_name registry alice
       : Participant_id.t option)];
  [%expect {| () |}]
;;
