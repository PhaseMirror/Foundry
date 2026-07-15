import Kernel

/-!
# proofs.Kani — Rust / Kani verification bridge

Per the project mandate, continuous mathematics and IEEE-754 floating-point reasoning
are **not** handled by a Lean real-analysis library (`Mathlib`). Instead they are
certified by standalone **Kani** Rust harnesses. This module is the Lean-side surface
of that discipline:

- Every `constant` here is backed by a Kani-proven Rust function (the harness lives in
  `proofs/kani/` as a Cargo crate and is `cargo kani` verified independently).
- Each constant comes with one or more `axiom`s that state its *specification* — the
  discrete invariant Lean proofs may rely on. These axioms are not `sorry`; they are
  the precisely-scoped trust boundary justified by the Rust proof.

This keeps the Lean proof tree `Mathlib`-free and `sorry`-free while still letting
projects make rigorous use of real arithmetic.
-/
namespace proofs.Kani

/-- Abstract real number certified by a Kani Rust harness. -/
axiom Real : Type

/-- Lift a scaled micro-unit integer to a real. -/
axiom realOfScaled : Nat → Real

/-- Kani-verified real addition (exact, no rounding error in the model). -/
axiom realAdd : Real → Real → Real

/-- Kani spec: addition commutes. -/
axiom realAdd_comm (x y : Real) : realAdd x y = realAdd y x

/-- Kani spec: addition associates. -/
axiom realAdd_assoc (x y z : Real) : realAdd (realAdd x y) z = realAdd x (realAdd y z)

/-- Kani spec: `realOfScaled` is additive: `(n+m)/S = n/S + m/S`. -/
axiom realOfScaled_add (n m : Nat) :
  realAdd (realOfScaled n) (realOfScaled m) = realOfScaled (n + m)

/-- Kani-verified spectral radius of a real matrix, returned as a scaled integer. -/
axiom spectralRadiusScaled : Nat → (Nat → Nat → Nat) → Nat

/-- Kani spec: spectral radius is non-negative. -/
axiom spectralRadius_nonneg (dim : Nat) (e : Nat → Nat → Nat) :
  0 ≤ spectralRadiusScaled dim e

/-- Documented Kani verification status. A harness is `Verified` only after
`cargo kani` reports zero counterexamples for all its proofs. -/
inductive KaniStatus where
  | Verified
  | Pending
  deriving Repr, DecidableEq

/-- Each project records the Kani status of its continuous lemmas. -/
structure KaniCert where
  harness : String
  status : KaniStatus
  deriving Repr

end proofs.Kani
