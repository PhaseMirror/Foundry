import Init
import GodelianTruth.Core
import GodelianTruth.Gamma
import GodelianTruth.Contraction
import GodelianTruth.Godel
import GodelianTruth.PrimeSieved
import GodelianTruth.LawfulSchedules
import GodelianTruth.Conservative

/-! # Godelian Truth Proofs

Aggregates key theorems across all modules.
-/

namespace GodelianTruth.Proofs

open GodelianTruth
open GodelianTruth.Gamma
open GodelianTruth.Contraction
open GodelianTruth.Godel
open GodelianTruth.PrimeSieved
open GodelianTruth.LawfulSchedules
open GodelianTruth.Conservative

/-- Core parameters are valid. -/
theorem params_valid :
  0 < lambda ∧ lambda < FP_DEN ∧
  0 < alpha ∧ alpha < FP_DEN ∧
  contractionFactor < FP_DEN := by native_decide

/-- Contraction factor is positive. -/
theorem contraction_positive :
  0 < contractionFactor := by native_decide

/-- Γ is well-defined on all sentences. -/
theorem gamma_well_defined (v : Valuation) (h_v : ∀ φ, validFP (v φ)) (φ : Sentence) :
  validFP ((Gamma v) φ) := Gamma.gamma_valid v h_v φ

/-- Strong Kleene connectives are well-defined. -/
theorem sk_well_defined (x y : Nat) (h_x : validFP x) (h_y : validFP y) :
  validFP (skAnd x y) ∧ validFP (skOr x y) := by
  unfold validFP skAnd skOr
  omega

/-- π(10) = 4. -/
theorem pi_ten_correct : pi 10 = 4 := pi_ten

/-- π(20) = 8. -/
theorem pi_twenty_correct : pi 20 = 8 := pi_twenty

/-- isPrime is correct for 2. -/
theorem isPrime_2 : isPrime 2 = true := by native_decide

/-- isPrime is correct for 3. -/
theorem isPrime_3 : isPrime 3 = true := by native_decide

/-- isPrime is correct for 4. -/
theorem notPrime_4 : isPrime 4 = false := by native_decide

/-- Lipschitz bound is strict. -/
theorem lipschitz_strict :
  lipschitzBound lambda alpha < FP_DEN := by
  apply lipschitz_bound_strict lambda alpha (by native_decide) (by native_decide) (by native_decide)

/-- Conservative extension holds (skeleton). -/
theorem conservative_skeleton :
  ConservativeExtension := conservative_over_F

end GodelianTruth.Proofs
