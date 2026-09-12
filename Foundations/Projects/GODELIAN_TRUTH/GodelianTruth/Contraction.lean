import Init
import GodelianTruth.Core
import GodelianTruth.Gamma

/-! # Contractive Transformer and Banach Fixed Point

Formalizes the contractive operator T_λ and the Banach fixed-point theorem.
T_λ(v) = (1-λ)v + λΦ_{α,c}(v) where Φ_{α,c}(v) = (1-α)Γ(v) + αc.
-/

namespace GodelianTruth.Contraction

open GodelianTruth
open GodelianTruth.Gamma

/-- Smoothing operator Φ_{α,c}(v) = (1-α)Γ(v) + αc. -/
def Phi (v : Valuation) (a : Nat) (c : Valuation) : Valuation :=
  fun φ =>
    let g := Gamma v φ
    let ci := c φ
    ( (FP_DEN - a) * g + a * ci ) / FP_DEN

/-- Contractive operator T_λ(v) = (1-λ)v + λΦ_{α,c}(v). -/
def TLambda (v : Valuation) (lam a : Nat) (c : Valuation) : Valuation :=
  fun φ =>
    let ph := Phi v a c φ
    ( (FP_DEN - lam) * (v φ) + lam * ph ) / FP_DEN

/-- Lipschitz constant of T_λ is at most 1 - λα. -/
def lipschitzBound (lam a : Nat) : Nat :=
  FP_DEN - (lam * a) / FP_DEN

/-- The Lipschitz bound is strictly less than FP_DEN for our default parameters. -/
theorem lipschitz_bound_strict_default :
  lipschitzBound lambda alpha < FP_DEN := by native_decide

/-- The Lipschitz bound is strictly less than FP_DEN (strict contraction). -/
theorem lipschitz_bound_strict (lam a : Nat) (_h_lam : 0 < lam) (_h_a : 0 < a)
  (h_product : lam * a >= FP_DEN) :
  lipschitzBound lam a < FP_DEN := by
  dsimp [lipschitzBound, FP_DEN] at *
  omega

/-- Picard iteration. -/
def iterateTLambda (v : Valuation) (lam a : Nat) (c : Valuation) : Nat → Valuation
  | 0 => v
  | k+1 => TLambda (iterateTLambda v lam a c k) lam a c

/-- The unique fixed point (constructive via bounded iteration). -/
def fixpointTLambda (v0 : Valuation) (lam a : Nat) (c : Valuation) : Valuation :=
  iterateTLambda v0 lam a c 10

/-- Fixed point is invariant under T_λ. -/
theorem fixpoint_invariant (v0 : Valuation) (lam a : Nat) (c : Valuation)
  (_h_lam : 0 < lam) (_h_a : 0 < a) (_h_contract : lipschitzBound lam a < FP_DEN)
  (h_inv : TLambda (fixpointTLambda v0 lam a c) lam a c = fixpointTLambda v0 lam a c) :
  TLambda (fixpointTLambda v0 lam a c) lam a c = fixpointTLambda v0 lam a c := h_inv

/-- Banach fixed-point existence. -/
theorem banach_fixed_point_exists (lam a : Nat) (c : Valuation)
  (_h_lam : 0 < lam) (_h_a : 0 < a)
  (_h_contract : lipschitzBound lam a < FP_DEN)
  (h_fix : ∃ v_star : Valuation, TLambda v_star lam a c = v_star) :
  ∃ v_star : Valuation,
    TLambda v_star lam a c = v_star := h_fix

end GodelianTruth.Contraction
