import Std.Data.List.Lemmas
import Std.Data.Nat.Basic

/--
  External binding to the Rust implementation of `aggregate`.
  It receives a list of ensembles (each a list of Nat) and returns a single
  aggregated ensemble.
-/
@[extern "aggregate"]
opaque aggregate (xs : List (List Nat)) : List Nat

/--
  Axiom stating that `aggregate` correctly computes the element‑wise sum for
  bounded numbers of ensembles and bounded ensemble length. This mirrors the
  Kani harness which limits the number of ensembles to 3 and each ensemble's
  length to 5.
-/
axiom aggregate_correct (xs : List (List Nat))
  (h_len : xs.length ≤ 3)
  (h_elem_len : xs.all (fun inner => inner.length ≤ 5)) :
  aggregate xs =
    match xs with
    | [] => []
    | hd :: _ =>
      let m := hd.length
      List.range m |>.map (fun i =>
        xs.foldl (fun acc inner => acc + inner.get! i) 0)

/-- Example theorem demonstrating the use of the axiom. -/
theorem aggregate_eq_sum (xs : List (List Nat))
  (h_len : xs.length ≤ 3)
  (h_elem_len : xs.all (fun inner => inner.length ≤ 5)) :
  aggregate xs =
    match xs with
    | [] => []
    | hd :: _ =>
      let m := hd.length
      List.range m |>.map (fun i =>
        xs.foldl (fun acc inner => acc + inner.get! i) 0) :=
  aggregate_correct xs h_len h_elem_len
