(** Benchmarks for the order book and matching engine.

    Run with: dune exec lib/order_book/bench/bench_order_book.exe -- -ascii
    -quota 5

    These benchmarks measure the core operations of the exchange and are
    designed to give you meaningful feedback on the performance of the system
    and the effect of any optimizations you make.

    {2 How to read the results}

    Core_bench reports time per operation in nanoseconds. Lower is better.
    Focus on:
    - [find_match]: the hot path — called on every incoming order
    - [submit_ioc_cross]: end-to-end order submission with a fill
    - [add/remove]: book mutation performance
    - [best_price]: how fast you can query the BBO

    {2 Tips for meaningful benchmarks}

    {ul
     {- Use [-quota 5] or higher for stable results (5 seconds per bench). }
     {- Run on a quiet machine (no heavy background processes). }
     {- Compare before/after by saving results:

       {v
          dune exec lib/order_book/bench/bench_order_book.exe -- -ascii -quota 5 > before.txt
          # ... make your changes ...
          dune exec lib/order_book/bench/bench_order_book.exe -- -ascii -quota 5 > after.txt
          diff before.txt after.txt
       v}
    }
    } *)

open! Core
open Core_bench
open Jsip_types
open Jsip_order_book

(* ---------------------------------------------------------------- *)
(* Setup helpers *)
(* ---------------------------------------------------------------- *)

let aapl = Symbol_id.of_int 0
let alice = Participant.of_string "Alice"
let bob = Participant.of_string "Bob"

(* One shared generator for the whole benchmark. Every resting Day order is
   registered by the engine under [(participant, client_order_id)] with
   [Hashtbl.add_exn], so ids must never repeat across helpers or bench
   bodies. A single monotonic generator guarantees that; each call site still
   pulls its id with [Client_order_id.Generator.next client_gen]. *)
let client_gen = Client_order_id.Generator.create ()

(** Build a book with [n] resting sell orders on AAPL, returning the book and
    its id generator so callers can keep minting non-colliding order ids.

    By default each order rests at a distinct price ([min_price + i], in
    cents), giving a realistic spread for [find_match]/[best_price]
    benchmarks. With [~is_same:true] every order instead rests at the single
    price [min_price], stacking the whole side at one level — the
    pathological input for [snapshot], which must then collapse them into a
    single aggregated [Level.t]. *)
let book_with_n_asks ?(min_price = 10_000) ?(is_same = false) n =
  let book = Order_book.create aapl in
  let gen = Order_id.Generator.create () in
  for i = 1 to n do
    let price = if is_same then min_price else min_price + i in
    let order =
      Order.create
        { client_order_id =
            Client_order_id.of_int
              (Client_order_id.Generator.next client_gen)
        ; symbol_id = aapl
        ; participant = bob
        ; side = Sell
        ; price = Price.of_int_cents price
        ; size = Size.of_int 100
        ; time_in_force = Day
        }
        ~order_id:(Order_id.Generator.next gen)
    in
    Order_book.add book order
  done;
  book, gen
;;

(** Build a matching engine with [n] resting sells on AAPL. *)
let engine_with_n_asks ?(min_price = 10_000) n =
  let engine = Matching_engine.create [ aapl ] in
  for i = 1 to n do
    ignore
      (Matching_engine.submit
         engine
         { client_order_id =
             Client_order_id.of_int
               (Client_order_id.Generator.next client_gen)
         ; symbol_id = aapl
         ; participant = bob
         ; side = Sell
         ; price = Price.of_int_cents (min_price + i)
         ; size = Size.of_int 100
         ; time_in_force = Day
         }
       : Exchange_event.t list)
  done;
  engine
;;

(** Build a matching engine that trades [n] distinct symbols (ids
    [0 .. n-1]), each with an empty book. This is the fixture for the
    symbol-lookup benchmark: with no resting orders, the only cost in a
    [Matching_engine.book] call is resolving the id to its book, so the
    benchmark measures that lookup and nothing else. Since Exercise 4 the id
    is a small int indexing a plain [Order_book.t array], so the lookup is a
    bounds check plus one array index — no hashing, no [Symbol.Map] tree
    walk. Returns the engine and the symbol list so a caller can pick one to
    look up. *)
let engine_with_n_symbols n =
  let symbols = List.init n ~f:Symbol_id.of_int in
  Matching_engine.create symbols, symbols
;;

(* ---------------------------------------------------------------- *)
(* Order_book micro-benchmarks *)
(* ---------------------------------------------------------------- *)

let bench_find_match ~n =
  let min_price = 10_000 in
  let book, gen = book_with_n_asks ~min_price n in
  (* Incoming buy at a price that matches the best ask *)
  let incoming =
    Order.create
      { client_order_id =
          Client_order_id.of_int (Client_order_id.Generator.next client_gen)
      ; symbol_id = aapl
      ; participant = alice
      ; side = Buy
      ; price = Price.of_int_cents (min_price + n)
      ; size = Size.of_int 100
      ; time_in_force = Ioc
      }
      ~order_id:(Order_id.Generator.next gen)
  in
  Bench.Test.create ~name:[%string "find_match (n=%{n#Int})"] (fun () ->
    ignore (Order_book.find_match book incoming : Order.t option))
;;

let bench_find_match_no_cross ~n =
  let min_price = 10_000 in
  let book, gen = book_with_n_asks ~min_price n in
  (* Incoming buy at a price below all asks — no match possible *)
  let incoming =
    Order.create
      { client_order_id =
          Client_order_id.of_int (Client_order_id.Generator.next client_gen)
      ; symbol_id = aapl
      ; participant = alice
      ; side = Buy
      ; price = Price.of_int_cents (min_price - 1)
      ; size = Size.of_int 100
      ; time_in_force = Ioc
      }
      ~order_id:(Order_id.Generator.next gen)
  in
  Bench.Test.create ~name:[%string "find_match_miss (n=%{n#Int})"] (fun () ->
    ignore (Order_book.find_match book incoming : Order.t option))
;;

let bench_best_bid_offer ~n =
  let book, _gen = book_with_n_asks n in
  Bench.Test.create ~name:[%string "best_bid_offer (n=%{n#Int})"] (fun () ->
    ignore (Order_book.best_bid_offer book : Bbo.t))
;;

let bench_add_remove ~n =
  (* Pre-build the book, then measure add+remove cycle *)
  let min_price = 10_000 in
  let book, gen = book_with_n_asks ~min_price n in
  let order =
    Order.create
      { client_order_id =
          Client_order_id.of_int (Client_order_id.Generator.next client_gen)
      ; symbol_id = aapl
      ; participant = alice
      ; side = Sell
      ; price = Price.of_int_cents (min_price + 500)
      ; size = Size.of_int 100
      ; time_in_force = Day
      }
      ~order_id:(Order_id.Generator.next gen)
  in
  let oid = Order.order_id order in
  Bench.Test.create ~name:[%string "add+remove (n=%{n#Int})"] (fun () ->
    Order_book.add book order;
    Order_book.remove book oid)
;;

(* Time [snapshot] over a book built by [make_book]. [snapshot] walks the
   whole side aggregating runs of equal price into [Level.t]s, so its cost
   scales with the number of resting orders — the [same_price] and
   [distinct_price] fixtures bracket the two extremes of that walk. *)
let bench_snapshot_of ~name make_book =
  let book = make_book () in
  Bench.Test.create ~name (fun () ->
    ignore (Order_book.snapshot book : Book.t))
;;

let bench_snapshot ~n =
  bench_snapshot_of
    ~name:[%string "snapshot_same_price (n=%{n#Int})"]
    (fun () -> fst (book_with_n_asks ~is_same:true n))
;;

let bench_snapshot_distinct ~n =
  bench_snapshot_of
    ~name:[%string "snapshot_distinct_price (n=%{n#Int})"]
    (fun () -> fst (book_with_n_asks n))
;;

(* ---------------------------------------------------------------- *)
(* Symbol Lookup Time *)
(* ---------------------------------------------------------------- *)
(* Time the engine's pure id->book lookup ([Matching_engine.book]) over an
   engine trading [n] symbols. *)
let bench_lookup ~n =
  let engine, symbols = engine_with_n_symbols n in
  let target = List.random_element_exn symbols in
  Bench.Test.create ~name:[%string "symbol_lookup (n=%{n#Int})"] (fun () ->
    ignore (Matching_engine.book engine target : Order_book.t option))
;;

(* ---------------------------------------------------------------- *)
(* Matching engine end-to-end benchmarks *)
(* ---------------------------------------------------------------- *)

let bench_submit_ioc_cross ~n =
  (* Measure submitting an IOC order that crosses the best ask. This is the
     most common hot path: order in, fill out. We re-seed a resting order
     after each iteration to keep the book state consistent. *)
  let min_price = 10_000 in
  let max_price = 20_000 in
  let engine = engine_with_n_asks ~min_price n in
  let next_price = ref (min_price + 1) in
  Bench.Test.create
    ~name:[%string "submit_ioc_cross (n=%{n#Int})"]
    (fun () ->
       let events =
         Matching_engine.submit
           engine
           { client_order_id =
               Client_order_id.of_int
                 (Client_order_id.Generator.next client_gen)
           ; symbol_id = aapl
           ; participant = alice
           ; side = Buy
           ; price = Price.of_int_cents max_price
           ; size = Size.of_int 100
           ; time_in_force = Ioc
           }
       in
       ignore (events : Exchange_event.t list);
       (* Re-seed: add back a resting sell to replace the one we consumed *)
       ignore
         (Matching_engine.submit
            engine
            { client_order_id =
                Client_order_id.of_int
                  (Client_order_id.Generator.next client_gen)
            ; symbol_id = aapl
            ; participant = bob
            ; side = Sell
            ; price = Price.of_int_cents !next_price
            ; size = Size.of_int 100
            ; time_in_force = Day
            }
          : Exchange_event.t list);
       next_price := !next_price + 1;
       if !next_price > max_price then next_price := min_price + 1)
;;

let bench_submit_ioc_no_match ~n =
  let min_price = 10_000 in
  let engine = engine_with_n_asks ~min_price n in
  Bench.Test.create ~name:[%string "submit_ioc_miss (n=%{n#Int})"] (fun () ->
    ignore
      (Matching_engine.submit
         engine
         { client_order_id =
             Client_order_id.of_int
               (Client_order_id.Generator.next client_gen)
         ; symbol_id = aapl
         ; participant = alice
         ; side = Buy
         ; price = Price.of_int_cents (min_price - 1)
         ; size = Size.of_int 100
         ; time_in_force = Ioc
         }
       : Exchange_event.t list))
;;

let bench_submit_sweep ~n =
  (* Measure an aggressive order that sweeps through the entire book.
     Re-seeds the book after each sweep. This is worst-case: every resting
     order is visited and filled. *)
  let engine = ref (engine_with_n_asks n) in
  Bench.Test.create ~name:[%string "submit_sweep_%{n#Int}_levels"] (fun () ->
    ignore
      (Matching_engine.submit
         !engine
         { client_order_id =
             Client_order_id.of_int
               (Client_order_id.Generator.next client_gen)
         ; symbol_id = aapl
         ; participant = alice
         ; side = Buy
         ; price = Price.of_int_cents 99_999
         ; size = Size.of_int (n * 100)
         ; time_in_force = Ioc
         }
       : Exchange_event.t list);
    (* Re-seed entire book *)
    engine := engine_with_n_asks n)
;;

(* ---------------------------------------------------------------- *)
(* Allocation measurement *)
(* ---------------------------------------------------------------- *)

let bench_find_match_alloc ~n =
  let min_price = 10_000 in
  let book, gen = book_with_n_asks ~min_price n in
  let incoming =
    Order.create
      { client_order_id =
          Client_order_id.of_int (Client_order_id.Generator.next client_gen)
      ; symbol_id = aapl
      ; participant = alice
      ; side = Buy
      ; price = Price.of_int_cents (min_price + n)
      ; size = Size.of_int 100
      ; time_in_force = Ioc
      }
      ~order_id:(Order_id.Generator.next gen)
  in
  (* Measure minor-heap allocations *)
  let measure_alloc f =
    Gc.compact ();
    let before = (Gc.stat ()).minor_words in
    for _ = 1 to 1000 do
      f ()
    done;
    let after = (Gc.stat ()).minor_words in
    (after -. before) /. 1000.0
  in
  let words_per_call =
    measure_alloc (fun () ->
      ignore (Order_book.find_match book incoming : Order.t option))
  in
  Bench.Test.create
    ~name:
      (sprintf "find_match_alloc (n=%d, %.1f words/call)" n words_per_call)
    (fun () -> ignore (Order_book.find_match book incoming : Order.t option))
;;

(* ---------------------------------------------------------------- *)
(* Wire payload size *)
(* ---------------------------------------------------------------- *)
(* Exercise 4 pushed the symbol onto the wire as a [Symbol_id.t] int instead
   of a [Symbol.t] string. [bin_size_t] is the exact number of bytes bin-prot
   writes for a value, so it turns "the wire got smaller" into a number.

   Every message below carries exactly one symbol field, and bin-prot just
   concatenates fields — so swapping that one field from a string name to an
   int id shrinks the whole message by exactly the difference between the two
   encodings, independent of the other fields. That per-symbol delta, times
   every order and every streamed event, is the bandwidth this exercise buys.

   This is a byte count, not a timing, so it prints a report rather than
   running under core_bench. *)

let sample_symbol_name = Symbol.of_string "AAPL"

let sample_level : Level.t =
  { price = Price.of_int_cents 15_000; size = Size.of_int 100 }
;;

let sample_bbo : Bbo.t = { bid = Some sample_level; ask = Some sample_level }

let sample_request : Order.Request.t =
  { client_order_id = Client_order_id.of_int 0
  ; symbol_id = aapl
  ; participant = alice
  ; side = Buy
  ; price = Price.of_int_cents 15_000
  ; size = Size.of_int 100
  ; time_in_force = Day
  }
;;

let sample_fill : Fill.t =
  { fill_id = 1
  ; symbol_id = aapl
  ; price = Price.of_int_cents 15_000
  ; size = Size.of_int 100
  ; aggressor_order_id = Order_id.of_string "1"
  ; aggressor_client_order_id = Client_order_id.of_int 0
  ; aggressor_participant = alice
  ; aggressor_side = Buy
  ; resting_order_id = Order_id.of_string "2"
  ; resting_client_order_id = Client_order_id.of_int 0
  ; resting_participant = bob
  }
;;

let sample_book : Book.t =
  { symbol_id = aapl
  ; bids = [ sample_level ]
  ; asks = [ sample_level ]
  ; bbo = sample_bbo
  }
;;

let sample_event : Exchange_event.t = Exchange_event.Fill sample_fill

let print_payload_sizes () =
  let name_bytes = Symbol.bin_size_t sample_symbol_name in
  let id_bytes = Symbol_id.bin_size_t aapl in
  let saved_per_symbol = name_bytes - id_bytes in
  printf
    "symbol as name (%s) : %d bytes\n"
    (Symbol.to_string sample_symbol_name)
    name_bytes;
  printf "symbol as id         : %d bytes\n" id_bytes;
  printf "saved per symbol     : %d bytes\n\n" saved_per_symbol;
  printf "%-26s %10s %10s %8s\n" "message" "id (now)" "name" "saved";
  (* Each message holds one symbol field, so the pre-Exercise-4 (string) size
     is just the current size plus that one field's delta. *)
  let row name current_bytes =
    printf
      "%-26s %10d %10d %8d\n"
      name
      current_bytes
      (current_bytes + saved_per_symbol)
      saved_per_symbol
  in
  row "Order.Request.t" (Order.Request.bin_size_t sample_request);
  row "Book.t" (Book.bin_size_t sample_book);
  row "Fill.t" (Fill.bin_size_t sample_fill);
  row "Exchange_event.t (Fill)" (Exchange_event.bin_size_t sample_event)
;;

(* ---------------------------------------------------------------- *)
(* Main *)
(* ---------------------------------------------------------------- *)

let () =
  let sizes = [ 10; 50; 100; 500 ] in
  let tests =
    List.concat
      [ (* Order book micro-benchmarks at various sizes *)
        List.map sizes ~f:(fun n -> bench_find_match ~n)
      ; List.map sizes ~f:(fun n -> bench_find_match_no_cross ~n)
      ; List.map sizes ~f:(fun n -> bench_best_bid_offer ~n)
      ; [ bench_add_remove ~n:100 ]
      ; (* Matching engine end-to-end *)
        List.map sizes ~f:(fun n -> bench_submit_ioc_cross ~n)
      ; List.map sizes ~f:(fun n -> bench_submit_ioc_no_match ~n)
      ; List.map [ 10; 50; 100 ] ~f:(fun n -> bench_submit_sweep ~n)
      ; (* Allocation awareness *)
        [ bench_find_match_alloc ~n:100 ]
      ]
  in
  let snapshot_tests =
    List.concat
      [ List.map sizes ~f:(fun n -> bench_snapshot ~n)
      ; List.map sizes ~f:(fun n -> bench_snapshot_distinct ~n)
      ]
  in
  let lookup_sizes = [ 10; 100; 1_000; 10_000 ] in
  let lookup_tests = List.map lookup_sizes ~f:(fun n -> bench_lookup ~n) in
  Command_unix.run
    (Command.group
       ~summary:"JSIP order-book benchmarks"
       [ "existing", Bench.make_command tests
       ; "snapshot", Bench.make_command snapshot_tests
       ; "symbol-lookup", Bench.make_command lookup_tests
       ; ( "payload-size"
         , Command.basic
             ~summary:"Wire payload size per message: int id vs string name"
             (Command.Param.return print_payload_sizes) )
       ])
;;
