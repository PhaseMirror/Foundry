import MOperator.Core
import MOperator.Algebra
import MOperator.CSLDynamics

/-! # MOperator.Proofs

Machine-checked formal verification theorems in Lean 4 for the Multiplicity Operator (M):
1. `time_advances_monotonically`: Temporal coordinate advances strictly monotonically (+1).
2. `drift_zero_at_target`: Distance from target to itself is identically zero.
3. `clamp_bounds_x`: Absorbing domain clamp confines x-coordinate within [-maxBound, maxBound].
4. `clamp_bounds_y`: Absorbing domain clamp confines y-coordinate within [-maxBound, maxBound].
5. `clamp_bounds_z`: Absorbing domain clamp confines z-coordinate within [-maxBound, maxBound].
6. `cubic_repair_zero_at_target`: Restoring force is identically zero at fixed point target.
7. `linear_repair_zero_at_target`: Linear restoring force is identically zero at target.
8. `bayesian_update_zero_when_joint_zero`: Posterior probability is 0 if joint probability is 0.
9. `bayesian_update_identity`: Posterior probability is 1.0 (FP_DEN) when joint equals evidence.
10. `prime_transformation_monotone`: Multiplicity Operator transformation scales monotonically with prime index.
-/

namespace MOperator

/-- Helper lemma: Int.ofNat of positive Nat is strictly positive Int. -/
theorem int_ofNat_pos_of_pos {n : Nat} (h : n > 0) : (Int.ofNat n : Int) > 0 := by
  cases n with
  | zero => contradiction
  | succ m =>
    dsimp [Int.ofNat]
    omega

/-- Helper lemma: 1D cubic repair at equilibrium is zero. -/
theorem cubic_repair_1d_zero (x : Int) (alpha : Int) : cubicRepair1D x x alpha = 0 := by
  dsimp [cubicRepair1D, fpMulInt, FP_DEN]
  have h_diff : x - x = 0 := by omega
  have h_cube : (0 * 0 / (1000 : Int) * 0 / 1000) = 0 := by rfl
  have h_prod : alpha * 0 = 0 := by omega
  rw [h_diff, h_cube, h_prod]
  rfl

/-- Helper lemma: 1D linear repair at equilibrium is zero. -/
theorem linear_repair_1d_zero (x : Int) (alpha : Int) : 0 - fpMulInt alpha (x - x) = 0 := by
  dsimp [fpMulInt, FP_DEN]
  have h_diff : x - x = 0 := by omega
  have h_prod : alpha * 0 = 0 := by omega
  rw [h_diff, h_prod]
  rfl

/-- Theorem 1: Temporal coordinate strictly advances by +1 on each CSL step.
    Prevents closed cyclic loops in agent state space. -/
theorem time_advances_monotonically (st : AgentState) (target : MVector3) (alpha : Int) :
    (cslStepCubic st target alpha).time = st.time + 1 := by
  rfl

/-- Theorem 2: Distance from fixed point target to itself is identically zero. -/
theorem drift_zero_at_target (target : MVector3) :
    vectorDistSq target target = 0 := by
  dsimp [vectorDistSq, FP_DEN]
  omega

/-- Theorem 3: Clamping operator strictly confines x-axis coordinate within maxBound. -/
theorem clamp_bounds_x (v : MVector3) (maxBound : Int) (h_bound : maxBound >= 0) :
    (clampVector v maxBound).x <= maxBound ∧ (clampVector v maxBound).x >= -maxBound := by
  dsimp [clampVector]
  split
  · rename_i h_gt
    exact ⟨Int.le_refl maxBound, by omega⟩
  · rename_i h_not_gt
    split
    · rename_i h_lt
      exact ⟨by omega, Int.le_refl (-maxBound)⟩
    · rename_i h_not_lt
      constructor
      · omega
      · omega

/-- Theorem 4: Clamping operator strictly confines y-axis coordinate within maxBound. -/
theorem clamp_bounds_y (v : MVector3) (maxBound : Int) (h_bound : maxBound >= 0) :
    (clampVector v maxBound).y <= maxBound ∧ (clampVector v maxBound).y >= -maxBound := by
  dsimp [clampVector]
  split
  · rename_i h_gt
    exact ⟨Int.le_refl maxBound, by omega⟩
  · rename_i h_not_gt
    split
    · rename_i h_lt
      exact ⟨by omega, Int.le_refl (-maxBound)⟩
    · rename_i h_not_lt
      constructor
      · omega
      · omega

/-- Theorem 5: Clamping operator strictly confines z-axis coordinate within maxBound. -/
theorem clamp_bounds_z (v : MVector3) (maxBound : Int) (h_bound : maxBound >= 0) :
    (clampVector v maxBound).z <= maxBound ∧ (clampVector v maxBound).z >= -maxBound := by
  dsimp [clampVector]
  split
  · rename_i h_gt
    exact ⟨Int.le_refl maxBound, by omega⟩
  · rename_i h_not_gt
    split
    · rename_i h_lt
      exact ⟨by omega, Int.le_refl (-maxBound)⟩
    · rename_i h_not_lt
      constructor
      · omega
      · omega

/-- Theorem 6: Cubic repair vector at equilibrium target point is identically zero. -/
theorem cubic_repair_zero_at_target (target : MVector3) (alpha : Int) :
    cubicRepairVector target target alpha = zeroVector := by
  dsimp [cubicRepairVector, zeroVector]
  rw [cubic_repair_1d_zero target.x alpha]
  rw [cubic_repair_1d_zero target.y alpha]
  rw [cubic_repair_1d_zero target.z alpha]

/-- Theorem 7: Linear repair vector at equilibrium target point is identically zero. -/
theorem linear_repair_zero_at_target (target : MVector3) (alpha : Int) :
    linearRepairVector target target alpha = zeroVector := by
  dsimp [linearRepairVector, zeroVector]
  rw [linear_repair_1d_zero target.x alpha]
  rw [linear_repair_1d_zero target.y alpha]
  rw [linear_repair_1d_zero target.z alpha]

/-- Theorem 8: Quantum Bayesian posterior is zero when joint probability is zero. -/
theorem bayesian_update_zero_when_joint_zero (pEvidence : Nat) :
    quantumBayesianUpdate 0 pEvidence = 0 := by
  dsimp [quantumBayesianUpdate]
  split
  · rfl
  · simp

/-- Theorem 9: Quantum Bayesian posterior equals 1.0 (FP_DEN) when joint equals evidence > 0. -/
theorem bayesian_update_identity (pVal : Nat) (h_pos : pVal > 0) :
    quantumBayesianUpdate pVal pVal = FP_DEN := by
  dsimp [quantumBayesianUpdate]
  have h_not_zero : (pVal == 0) = false := by
    apply beq_eq_false_iff_ne.mpr
    omega
  rw [h_not_zero]
  simp
  have : (pVal * FP_DEN) / pVal = FP_DEN := by
    rw [Nat.mul_comm]
    exact Nat.mul_div_cancel FP_DEN h_pos
  exact this

/-- Theorem 10: Prime-indexed leading term scales strictly monotonically with prime index p_i. -/
theorem prime_transformation_monotone (mVal : Int) (p1 p2 : Nat) (h_m : mVal > 0) (h_p : p1 < p2) :
    (Int.ofNat p1) * mVal < (Int.ofNat p2) * mVal := by
  have hp_int : (Int.ofNat p1 : Int) < (Int.ofNat p2 : Int) := by
    exact Int.ofNat_lt.mpr h_p
  exact Int.mul_lt_mul_of_pos_right hp_int h_m

end MOperator
