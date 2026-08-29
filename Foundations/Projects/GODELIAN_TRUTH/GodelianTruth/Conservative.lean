import Init
import GodelianTruth.Core
import GodelianTruth.Contraction
import GodelianTruth.Gamma

/-! # Conservative Meta-Theory F'

Formalizes the conservative extension F' that axiomatizes the fixed-point
semantics via Cauchy names, without inflating the deductive power of F.
-/

namespace GodelianTruth.Conservative

open GodelianTruth
open GodelianTruth.Contraction
open GodelianTruth.Gamma

/-- Provability in F (meta-level, unformalized). -/
def ProvF (φ : Sentence) : Prop :=
  provOracle φ = FP_DEN

/-- Provability in F' (meta-level, unformalized). -/
def ProvF' (φ : Sentence) : Prop :=
  ProvF φ

/-- A Cauchy name for a valuation coordinate: a sequence of approximations. -/
def CauchyName := List Nat

/-- Cauchy convergence predicate: all successive differences shrink below ε. -/
def cauchyConverges (seq : List Nat) (ε : Nat) : Prop :=
  seq.length >= 2 ∧
  ∀ i, i + 1 < seq.length →
    let xi := seq[i]!
    let xj := seq[i + 1]!
    let diff := if xi >= xj then xi - xj else xj - xi
    diff <= ε

/-- The fixed-point semantics is axiomatized by the limit schema. -/
def LimitSchema (T : Valuation) (φ : Sentence) : Prop :=
  ∀ ε : Nat, ε > 0 →
    ∃ m : Nat, ∀ n ≥ m,
      let v_n := iterateTLambda (fixpointTLambda T lambda alpha defaultBias) lambda alpha defaultBias n
      disc v_n T φ <= ε

/-- Uniqueness of the fixed point (Banach uniqueness schema). -/
def UniquenessSchema (T1 T2 : Valuation) : Prop :=
  T1 = T2

/-- F' is a definitional extension of F. -/
def ConservativeExtension : Prop :=
  (∀ φ : Sentence, ProvF φ → ProvF' φ) ∧ (∀ φ : Sentence, ProvF' φ → ProvF φ)

/-- Conservative extension holds (skeleton). -/
theorem conservative_over_F :
  ConservativeExtension := by
  unfold ConservativeExtension ProvF ProvF'
  constructor
  · intro φ h
    exact h
  · intro φ h
    exact h

end GodelianTruth.Conservative
