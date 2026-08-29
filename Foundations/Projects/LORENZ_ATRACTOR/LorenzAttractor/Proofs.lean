import LorenzAttractor.Core
import LorenzAttractor.Dynamics
import LorenzAttractor.FeedbackTensor

/-! # LorenzAttractor.Proofs

Machine-checked formal verification theorems in Lean 4 for the Multiplicity-Enhanced Lorenz Attractor:
1. `time_advances_monotonically`: Discrete time coordinate advances strictly monotonically (+1).
2. `theoretical_trace_negative`: Jacobian trace is strictly negative for physical parameter regimes.
3. `prime_params_strictly_positive`: Prime-based parameter encodings guarantee positivity.
4. `clamp_bounds_x`: Absorbing ball clamping strictly bounds x-axis coordinate.
5. `clamp_bounds_y`: Absorbing ball clamping strictly bounds y-axis coordinate.
6. `clamp_bounds_z`: Absorbing ball clamping strictly bounds z-axis coordinate.
7. `jacobian_trace_exact`: Evaluated Jacobian trace matches theoretical trace for all phase space points.
8. `lorenz_origin_velocity_zero`: The origin (0,0,0) is a classical stationary equilibrium.
9. `prime_parameters_preserve_dissipativity`: Prime parameter spaces strictly satisfy volume contraction.
10. `stability_integral_monotonic`: Stability functional is monotonically non-decreasing over time.
-/

namespace LorenzAttractor

/-- Helper lemma: Int.ofNat of positive Nat is strictly positive Int. -/
theorem int_ofNat_pos_of_pos {n : Nat} (h : n > 0) : (Int.ofNat n : Int) > 0 := by
  cases n with
  | zero => contradiction
  | succ m =>
    dsimp [Int.ofNat]
    omega

/-- Theorem 1: Temporal coordinate strictly advances by +1 on each unified step.
    Prevents closed cyclic loops in state evolution space. -/
theorem time_advances_monotonically (st : LorenzState) (params : LorenzParams) (gain : Int) :
    (unifiedStep st params gain).time = st.time + 1 := by
  rfl

/-- Theorem 2: For any parameter regime with sigma >= 0 and beta >= 0,
    the theoretical Jacobian trace -(sigma + FP_DEN + beta) is strictly negative. -/
theorem theoretical_trace_negative (params : LorenzParams)
    (h_sigma : params.sigma >= 0)
    (h_beta_pos : params.betaNum / params.betaDen >= 0) :
    theoreticalTrace params < 0 := by
  dsimp [theoreticalTrace, FP_DEN]
  omega

/-- Theorem 3: Prime parameter encodings p1, p2, p3 >= 2 guarantee positive fixed-point parameters. -/
theorem prime_params_strictly_positive (p : PrimeLorenzParams)
    (hp1 : p.p1 >= 2) (hp2 : p.p2 >= 2) (hp3 : p.p3 >= 2) :
    (primeToLorenzParams p).sigma > 0 ∧
    (primeToLorenzParams p).rho > 0 ∧
    (primeToLorenzParams p).betaNum > 0 := by
  dsimp [primeToLorenzParams]
  have h_den_pos : FP_DEN > 0 := by decide
  have hp1_pos : p.p1 > 0 := by omega
  have hp2_pos : p.p2 > 0 := by omega
  have hp3_pos : p.p3 > 0 := by omega
  have h1 : p.p1 * FP_DEN > 0 := Nat.mul_pos hp1_pos h_den_pos
  have h2 : p.p2 * FP_DEN > 0 := Nat.mul_pos hp2_pos h_den_pos
  have h3 : p.p3 * FP_DEN > 0 := Nat.mul_pos hp3_pos h_den_pos
  exact ⟨int_ofNat_pos_of_pos h1, int_ofNat_pos_of_pos h2, int_ofNat_pos_of_pos h3⟩

/-- Theorem 4: Clamping operator strictly confines x-axis coordinate within maxBound. -/
theorem clamp_bounds_x (p : LorenzPoint) (maxBound : Int) (h_bound : maxBound >= 0) :
    (clampPoint p maxBound).x <= maxBound ∧ (clampPoint p maxBound).x >= -maxBound := by
  dsimp [clampPoint]
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

/-- Theorem 5: Clamping operator strictly confines y-axis coordinate within maxBound. -/
theorem clamp_bounds_y (p : LorenzPoint) (maxBound : Int) (h_bound : maxBound >= 0) :
    (clampPoint p maxBound).y <= maxBound ∧ (clampPoint p maxBound).y >= -maxBound := by
  dsimp [clampPoint]
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

/-- Theorem 6: Clamping operator strictly confines z-axis coordinate within maxBound. -/
theorem clamp_bounds_z (p : LorenzPoint) (maxBound : Int) (h_bound : maxBound >= 0) :
    (clampPoint p maxBound).z <= maxBound ∧ (clampPoint p maxBound).z >= -maxBound := by
  dsimp [clampPoint]
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

/-- Theorem 7: Evaluated Jacobian trace identically matches the theoretical trace. -/
theorem jacobian_trace_exact (p : LorenzPoint) (params : LorenzParams) :
    jacobianTrace (evaluateJacobian p params) = theoreticalTrace params := by
  dsimp [jacobianTrace, evaluateJacobian, theoreticalTrace]
  omega

/-- Theorem 8: The classical origin point (0, 0, 0) is a stationary equilibrium point. -/
theorem lorenz_origin_velocity_zero (params : LorenzParams) :
    lorenzVelocity ⟨0, 0, 0⟩ params = ⟨0, 0, 0⟩ := by
  dsimp [lorenzVelocity, fpMulInt, FP_DEN]
  congr 1
  · omega
  · omega
  · omega

/-- Theorem 9: Any prime-encoded parameter set with p1, p2, p3 >= 2 satisfies volume contraction Tr(J) < 0. -/
theorem prime_parameters_preserve_dissipativity (p : PrimeLorenzParams)
    (hp1 : p.p1 >= 2) (hp2 : p.p2 >= 2) (hp3 : p.p3 >= 2) :
    theoreticalTrace (primeToLorenzParams p) < 0 := by
  have hpos := prime_params_strictly_positive p hp1 hp2 hp3
  dsimp [theoreticalTrace, primeToLorenzParams, FP_DEN]
  have h_sigma : (Int.ofNat (p.p1 * 1000) : Int) > 0 := hpos.1
  have h_beta : (Int.ofNat (p.p3 * 1000) : Int) > 0 := hpos.2.2
  omega

/-- Theorem 10: Stability functional S(t) accumulation is monotonically non-decreasing. -/
theorem stability_integral_monotonic (st : LorenzState) (params : LorenzParams) (gain : Int) :
    (unifiedStep st params gain).stabilityIntegral >= st.stabilityIntegral := by
  dsimp [unifiedStep]
  have : st.stabilityIntegral <= st.stabilityIntegral +
    ((if computeSpectralMultiplicity st.point params < 0 then
        (Int.ofNat FP_DEN + (-computeSpectralMultiplicity st.point params) / 10).toNat
      else FP_DEN) * DT_FP.toNat) / FP_DEN := Nat.le_add_right _ _
  exact this

end LorenzAttractor
