import Std.Data.Nat.Lemmas
import Std.Data.Nat.Basic

/--
  External binding to the Rust implementation of `compute_product`.
  The actual binary will be linked when the Lean program is compiled with the
  appropriate FFI flags. For the purposes of verification we treat this as an
  opaque function and assert a correctness axiom below.
-/
@[extern "compute_product"]
opaque compute_product (n : Nat) : Nat

/-- Axiom stating that `compute_product` agrees with the mathematical factorial
    for all `n` up to a reasonable bound (here 20). The bound corresponds to the
    Kani harness which limits `n` to avoid overflow.
-/
axiom compute_product_correct (n : Nat) (h : n ≤ 20) :
  compute_product n = Nat.factorial n

/-- Example theorem using the axiom – for any `n ≤ 20` the result equals the
    factorial, which follows directly from the axiom.
-/
theorem compute_product_eq_factorial (n : Nat) (h : n ≤ 20) :
  compute_product n = Nat.factorial n :=
  compute_product_correct n h
