import Init

/-! # Low-Complexity Attractor — Core Types

Formalizes foundational types for the low-complexity attractor study:
state vectors, attractor candidates (φ, e, prime-indexed), safety sets,
and basic dynamical system primitives.
-/

namespace LowComplexityAttractor.Core

open Nat

/-- Golden ratio φ = (1 + sqrt(5)) / 2. -/
def phi : Float := (1.0 + Float.sqrt 5.0) / 2.0

/-- Euler's number e. -/
def eulersE : Float := Float.exp 1.0

/-- Attractor candidate type. -/
inductive Attractor where
  | phi
  | e
  | primeIndexed (p : Nat)
  deriving Repr

/-- State vector x ∈ ℝ^d. -/
structure State where
  dim : Nat
  values : List Float
  deriving Repr

/-- Proposal function output u = f_θ(x). -/
structure Proposal where
  values : List Float
  deriving Repr

/-- Safety set S = {u : ‖Bu‖₁ ≤ κ, ‖u‖₂ ≤ r}. -/
structure SafetySet where
  B : List (List Float)
  kappa : Float
  r : Float
  deriving Repr

/-- ACE certificate (gap lower bound, slope upper bound). -/
structure ACECertificate where
  gapLB : Float
  slopeUB : Float
  deriving Repr

/-- Dynamics mode. -/
inductive DynamicsMode where
  | cubicRepair
  | linear
  | custom
  deriving Repr

/-- Verified core properties. -/
theorem phi_gt_one : phi > 1.0 := by native_decide
theorem e_gt_one : eulersE > 1.0 := by native_decide

end LowComplexityAttractor.Core
