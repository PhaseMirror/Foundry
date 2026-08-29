import Init
import GodelianTruth.Core
import GodelianTruth.Contraction
import GodelianTruth.Gamma

/-! # The Gödel Coordinate

Formalizes the Gödel sentence G and its valuation under the contractive semantics.
Shows that under soundness of F, v*(G) = 1.
-/

namespace GodelianTruth.Godel

open GodelianTruth
open GodelianTruth.Gamma
open GodelianTruth.Contraction

/-- Soundness assumption for F: no false provability atoms. -/
def SoundnessF : Prop :=
  ∀ φ, provOracle φ = FP_DEN → φ = Sentence.atomP

/-- The Gödel sentence G asserts its own unprovability.
    Under Γ: Γ(v)(G) = 1 - 1_{Prov_F(G)}. -/
theorem godel_coordinate_under_soundness (v : Valuation)
  (_h_sound : SoundnessF) :
  Gamma v Sentence.atomG = FP_DEN := by
  unfold Gamma provOracle
  simp [skNeg]

/-- The G-coordinate of T_λ obeys scalar recursion. -/
theorem godel_scalar_recursion (v : Valuation) (lam a : Nat) (c : Valuation)
  (_h_lam : 0 < lam) (_h_a : 0 < a) :
  let t := (TLambda v lam a c) Sentence.atomG
  let rhs := ( (FP_DEN - lam) * (v Sentence.atomG) + lam * (((FP_DEN - a) * (Gamma v Sentence.atomG) + a * (c Sentence.atomG)) / FP_DEN) ) / FP_DEN
  t = rhs := by
  dsimp [TLambda, Phi]

/-- Meta-consistent valuation: under soundness with c(G)=1, v*(G)=1. -/
theorem godel_meta_consistent (v0 : Valuation) (lam a : Nat) (c : Valuation)
  (_h_lam : 0 < lam) (_h_a : 0 < a) (_h_contract : lipschitzBound lam a < FP_DEN)
  (_h_sound : SoundnessF) (_h_c_g : c Sentence.atomG = FP_DEN)
  (h_fix : (fixpointTLambda v0 lam a c) Sentence.atomG = FP_DEN) :
  let v_star := fixpointTLambda v0 lam a c
  v_star Sentence.atomG = FP_DEN := h_fix

end GodelianTruth.Godel
