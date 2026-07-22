import CulturalMath.Base
import CulturalMath.Egyptian
import CulturalMath.Chinese
import CulturalMath.Babylonian
import CulturalMath.Vedic
import CulturalMath.Pythagorean
import CulturalMath.Hebrew
import CulturalMath.Islamic
import CulturalMath.Japanese
import CulturalMath.Mayan
import CulturalMath.African
import CulturalMath.Russian
import CulturalMath.NumberTheory
import CulturalMath.GRTF
import CulturalMath.CulturalMath

-- ═══════════════════════════════════════════════════════════════
-- Master check: verify all exported theorems are well-formed.
-- ═══════════════════════════════════════════════════════════════

def main : IO Unit := do
  IO.println "All CulturalMath theorems verified."

-- Base
#check @CulturalMath.cong_refl
#check @CulturalMath.cong_symm
#check @CulturalMath.cong_trans
#check @CulturalMath.cong_add
#check @CulturalMath.cong_mul
#check @CulturalMath.proportional_refl
#check @CulturalMath.proportional_symm
#check @CulturalMath.multiplicityVal_singleton
#check @CulturalMath.triple_345
#check @CulturalMath.triple_51213
#check @CulturalMath.triple_81517

-- Egyptian
#check @CulturalMath.Egyptian.egyptianMul_eq_mul
#check @CulturalMath.Egyptian.proportional_refl
#check @CulturalMath.Egyptian.proportional_symm
#check @CulturalMath.Egyptian.double_eq
#check @CulturalMath.Egyptian.halve_double_even
#check @CulturalMath.Egyptian.empty_decomp_valid

-- Chinese
#check @CulturalMath.Chinese.crt_two_axiom
#check @CulturalMath.Chinese.eigenIterate_fixed
#check @CulturalMath.Chinese.crtFeedback_zero_residue
#check @CulturalMath.Chinese.crtFeedback_bounded

-- Babylonian
#check @CulturalMath.Babylonian.mod60_periodic
#check @CulturalMath.Babylonian.mod60_add
#check @CulturalMath.Babylonian.mod60_mul
#check @CulturalMath.Babylonian.babylonianSqrt_bounded_step
#check @CulturalMath.Babylonian.babylonianCos_periodic
#check @CulturalMath.Babylonian.fromBase60_toBase60

-- Vedic
#check @CulturalMath.Vedic.ekadhikena5_25
#check @CulturalMath.Vedic.ekadhikena5_35
#check @CulturalMath.Vedic.ekadhikena5_45
#check @CulturalMath.Vedic.ekadhikena5_105
#check @CulturalMath.Vedic.nikhilam_correct
#check @CulturalMath.Vedic.vedicFeedback_contracting
#check @CulturalMath.Vedic.shunyam_mod

-- Pythagorean
#check @CulturalMath.Pythagorean.euclid_triple
#check @CulturalMath.Pythagorean.triple_345_gen
#check @CulturalMath.Pythagorean.triple_51213_gen
#check @CulturalMath.Pythagorean.triple_81517_gen
#check @CulturalMath.Pythagorean.tetractys_1
#check @CulturalMath.Pythagorean.tetractys_3
#check @CulturalMath.Pythagorean.tetractys_4
#check @CulturalMath.Pythagorean.tetractysDots_eq
#check @CulturalMath.Pythagorean.tetractysDots_4
#check @CulturalMath.Pythagorean.pythEigen_345
#check @CulturalMath.Pythagorean.pythEigen_51213

-- Hebrew
#check @CulturalMath.Hebrew.gematriaWord_nil
#check @CulturalMath.Hebrew.gematriaWord_cons
#check @CulturalMath.Hebrew.sabbath_periodic
#check @CulturalMath.Hebrew.sabbath_day0
#check @CulturalMath.Hebrew.jubilee_periodic
#check @CulturalMath.Hebrew.binom_zero_right
#check @CulturalMath.Hebrew.binom_self
#check @CulturalMath.Hebrew.binom_4_2
#check @CulturalMath.Hebrew.sefirot_total

-- Islamic
#check @CulturalMath.Islamic.completion_identity
#check @CulturalMath.Islamic.alMuqabala
#check @CulturalMath.Islamic.positional_single

-- Japanese
#check @CulturalMath.Japanese.incircle_345
#check @CulturalMath.Japanese.incircle_51213
#check @CulturalMath.Japanese.newton_fixed
#check @CulturalMath.Japanese.dayOfMonth_periodic
#check @CulturalMath.Japanese.monthNum_periodic
#check @CulturalMath.Japanese.sangakuFractal_decreasing

-- Mayan
#check @CulturalMath.Mayan.mod20_periodic
#check @CulturalMath.Mayan.mod20_add
#check @CulturalMath.Mayan.mod20_mul
#check @CulturalMath.Mayan.mayanZero_add
#check @CulturalMath.Mayan.mayanZero_mul
#check @CulturalMath.Mayan.tzolkin_periodic
#check @CulturalMath.Mayan.haab_periodic
#check @CulturalMath.Mayan.calendarRound_sync
#check @CulturalMath.Mayan.fromBase20_toBase20
#check @CulturalMath.Mayan.vigesimalFractal_contracting
#check @CulturalMath.Mayan.mayanPositional_single

-- African
#check @CulturalMath.African.fractal_selfSimilar
#check @CulturalMath.African.halve_double_even
#check @CulturalMath.African.halve_reduces
#check @CulturalMath.African.halve_converges
#check @CulturalMath.African.symbolicState_nil
#check @CulturalMath.African.symbolicState_cons
#check @CulturalMath.African.cyclicTensor_bounded

-- Russian
#check @CulturalMath.Russian.Vec.add_comm
#check @CulturalMath.Russian.Vec.add_assoc
#check @CulturalMath.Russian.Vec.smul_add
#check @CulturalMath.Russian.lyapunov_bounded
#check @CulturalMath.Russian.stochasticUpdate_monotone
#check @CulturalMath.Russian.boundary_squared_zero
#check @CulturalMath.Russian.continuousGenerator_power

-- Number Theory
#check @CulturalMath.NumberTheory.totient_1
#check @CulturalMath.NumberTheory.divisorSum_1
#check @CulturalMath.NumberTheory.pythDioph_345
#check @CulturalMath.NumberTheory.pythDioph_51213
#check @CulturalMath.NumberTheory.pythDioph_infinitely_many
#check @CulturalMath.NumberTheory.id_multiplicative
#check @CulturalMath.NumberTheory.const1_multiplicative

-- GRTF
#check @CulturalMath.GRTF.Lambda_m_pos
#check @CulturalMath.GRTF.grtf_empty_primes
#check @CulturalMath.GRTF.xiOperator_bounded
#check @CulturalMath.GRTF.cognitiveIntegrity_nonneg
#check @CulturalMath.GRTF.anomaly_detection_complete
#check @CulturalMath.GRTF.constant_treatment_stable
#check @CulturalMath.GRTF.grtf_trivial_solution

-- CulturalMath unified
#check @CulturalMath.modular_universal
#check @CulturalMath.fractal_universal
#check @CulturalMath.pythagorean_universal
#check @CulturalMath.prime_encoding_universal
#check @CulturalMath.foundational_solution
#check @CulturalMath.foundational_nontrivial
#check @CulturalMath.total_multiplicity_positive
