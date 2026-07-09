open! Core

module T = struct
  type t = int [@@deriving sexp_of, compare, equal, hash]
end

include T
include Comparable.Make_plain (T)
include Hashable.Make_plain (T)

let to_int t = t
let of_int t = t
