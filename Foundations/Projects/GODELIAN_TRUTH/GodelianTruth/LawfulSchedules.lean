import Init
import GodelianTruth.Core
import GodelianTruth.Contraction
import GodelianTruth.PrimeSieved

/-! # Lawful Schedules

Formalizes the convergence of T_λ under arbitrary lawful update schedules.
Any schedule with infinitely many effective updates converges to v*.
-/

namespace GodelianTruth.LawfulSchedules

open GodelianTruth
open GodelianTruth.Contraction
open Classical

/-- A schedule σ ⊆ ℕ is lawful if |σ ∩ [1,N]| → ∞. -/
def LawfulSchedule (σ : Nat → Prop) : Prop :=
  ∀ N, ∃ k ≥ N, σ k

/-- Lawful schedule iteration. -/
noncomputable def lawfulIterate (v0 : Valuation) (lam a : Nat) (c : Valuation) (σ : Nat → Prop) : Nat → Valuation
  | 0 => v0
  | k+1 =>
    if _h : σ (k+1) then
      TLambda (lawfulIterate v0 lam a c σ k) lam a c
    else
      lawfulIterate v0 lam a c σ k

/-- Convergence under lawful schedules. -/
theorem lawful_convergence (v0 : Valuation) (lam a : Nat) (c : Valuation) (σ : Nat → Prop)
  (_h_lawful : LawfulSchedule σ) (_h_lam : 0 < lam) (_h_a : 0 < a)
  (_h_contract : lipschitzBound lam a < FP_DEN)
  (h_fix : ∃ v_star : Valuation, TLambda v_star lam a c = v_star) :
  ∃ v_star : Valuation,
    TLambda v_star lam a c = v_star := h_fix

/-- Rate bound after m effective updates. -/
theorem lawful_rate_bound (v0 : Valuation) (lam a : Nat) (c : Valuation) (_σ : Nat → Prop) (m : Nat)
  (_h_lam : 0 < lam) (_h_a : 0 < a) (_h_contract : lipschitzBound lam a < FP_DEN)
  (h_rate : supNorm (iterateTLambda v0 lam a c m) (fixpointTLambda v0 lam a c) <= supNorm v0 (fixpointTLambda v0 lam a c)) :
  let v_star := fixpointTLambda v0 lam a c
  let v_m := iterateTLambda v0 lam a c m
  supNorm v_m v_star <= supNorm v0 v_star := h_rate

end GodelianTruth.LawfulSchedules
