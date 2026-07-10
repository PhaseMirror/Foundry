import AffineCore.Foundations.BanachSpace
import AffineCore.Foundations.HilbertSchmidt
import AffineCore.Foundations.PrimeSeries

-- Use a Hilbert space H for UpdateOperator components
variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℂ H] [CompleteSpace H]

/--
The update operator with prime-indexed Hilbert-Schmidt components.
Formalizes Theorems A2 and A3.
-/
structure UpdateOperator (H : Type*) [NormedAddCommGroup H]
    [InnerProductSpace ℂ H] [CompleteSpace H] where
  α  : ℕ → ℝ               -- α_{p_i}: prime weights
  π  : ℕ → ℝ               -- π_{p_i}: prime modulators
  M  : ℕ → HilbertSchmidtOperator H H   -- M_t components
  F  : H →L[ℂ] H           -- semantic damping term
  primes : ∀ p, α p ≠ 0 → Nat.Prime p

/--
Convert the update operator's prime components to a PrimeOperatorFamily.
Uses real-to-complex coercion for weights.
-/
def UpdateOperator.toPrimeFamily (U : UpdateOperator H) : PrimeOperatorFamily H where
  weight := fun p => (U.α p * U.π p : ℂ)
  op     := fun p => (U.M p : H →L[ℂ] H)
  support_prime := by
    intro p hp
    apply U.primes p
    intro h_alpha
    simp [h_alpha] at hp

/--
The update operator's action Φ(x) = Xi(U) x + F x.
-/
noncomputable def UpdateOperator.phi (U : UpdateOperator H) (x : H) : H :=
  Xi U.toPrimeFamily x + U.F x

/--
Stability condition: k = ∑' p, |α p * π p| * ‖M p‖_op + ‖F‖_op.
-/
noncomputable def UpdateOperator.contractionConst (U : UpdateOperator H) : ℝ :=
  (∑' p, |U.α p * U.π p| * ‖(U.M p : H →L[ℂ] H)‖) + ‖U.F‖

/--
Theorem A3: If the contraction constant k < 1, then Φ is a Lipschitz map with constant k.
-/
theorem update_operator_lipschitz
    (U : UpdateOperator H)
    (h_summable : Summable (fun p => |U.α p * U.π p| * ‖(U.M p : H →L[ℂ] H)‖)) :
    LipschitzWith (Real.toNNReal U.contractionConst) U.phi := by
  apply LipschitzWith.of_dist_le_mul
  intro x y
  rw [Real.coe_toNNReal]
  · simp_rw [UpdateOperator.phi, dist_eq_norm]
    rw [add_sub_add_comm, ← ContinuousLinearMap.map_sub, ← ContinuousLinearMap.map_sub]
    calc ‖Xi U.toPrimeFamily (x - y) + U.F (x - y)‖
        ≤ ‖Xi U.toPrimeFamily (x - y)‖ + ‖U.F (x - y)‖ := norm_add_le _ _
      _ ≤ ‖Xi U.toPrimeFamily‖ * ‖x - y‖ + ‖U.F‖ * ‖x - y‖ := by
            apply add_le_add
            · exact ContinuousLinearMap.le_opNorm _ _
            · exact U.F.le_opNorm _
      _ = (‖Xi U.toPrimeFamily‖ + ‖U.F‖) * ‖x - y‖ := by ring
      _ ≤ ( (∑' p, ‖U.toPrimeFamily.weight p‖ * ‖U.toPrimeFamily.op p‖) + ‖U.F‖) * ‖x - y‖ := by
            apply mul_le_mul_of_nonneg_right
            · apply add_le_add_right
              apply Xi_bounded
              simp [UpdateOperator.toPrimeFamily]
              exact h_summable
            · exact norm_nonneg _
      _ = U.contractionConst * ‖x - y‖ := by
            simp [UpdateOperator.contractionConst, UpdateOperator.toPrimeFamily]
  · apply add_nonneg
    · apply tsum_nonneg
      intro p; exact mul_nonneg (abs_nonneg _) (norm_nonneg _)
    · exact norm_nonneg _
