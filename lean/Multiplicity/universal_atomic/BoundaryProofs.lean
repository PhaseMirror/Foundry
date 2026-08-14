import Multiplicity.universal_atomic.SQD
import Multiplicity.universal_atomic.Circuits

namespace Multiplicity.UAC.BoundaryProofs

-- 1. Combinatorial Evaluation (C-SQD)
-- Proves that the exact structural algorithm evaluates securely for boundary states.
theorem computeHamming_zero_base (n : Nat) : Multiplicity.UAC.SQD.computeHamming n 0 = 1 := by
  cases n <;> rfl

-- 2. Q-SQD Stability Monotonicity
-- Proves that if an orbital is stable at a given standard error (se1), 
-- it remains strictly stable at any larger standard error (se2) representing higher tolerance.
theorem stability_monotonicity_se (f_hat_scaled q se1 se2 : Int) (b_val lambda scale : Nat) 
  (h_se : se1.natAbs ≤ se2.natAbs) :
  Multiplicity.UAC.SQD.checkStability f_hat_scaled q se1 b_val lambda scale = true →
  Multiplicity.UAC.SQD.checkStability f_hat_scaled q se2 b_val lambda scale = true := by
  intro h
  unfold Multiplicity.UAC.SQD.checkStability at *
  simp only [decide_eq_true_eq] at *
  have h_bound : lambda * se1.natAbs * b_val ≤ lambda * se2.natAbs * b_val := by
    apply Nat.mul_le_mul_right
    apply Nat.mul_le_mul_left
    exact h_se
  omega

-- 3. ZK Circuit Bounds Overflow Proof
-- Re-affirms the formal proof that maximal 80-bit inputs (2^80) multiplied by scalar constants 
-- definitively remain below the BN128 Prime Field limits.
theorem zK_circuit_bounds_overflow_safe (delta xi : Nat) 
  (h_delta : delta < 2^80) (h_xi : xi < 2^80) :
  (10 * delta) < Multiplicity.UAC.Circuits.BN128_PRIME ∧ (3 * xi) < Multiplicity.UAC.Circuits.BN128_PRIME :=
  Multiplicity.UAC.Circuits.drift_bound_no_overflow delta xi h_delta h_xi

end Multiplicity.UAC.BoundaryProofs
