import Core.ComplexKappa.Core

open Real

namespace ComplexKappa

/-- Contraction rate derived from the zeta‑comb amplitude. -/

def contraction_rate (ε σ γ : Real) : Real :=
  ε ^ 2 * Real.exp (-2 * σ * γ ^ 2)

/--
  A concrete interval‑arithmetic bound for the spectral attractor contraction.
  Assuming the amplitude ε is at most 1 and the dispersion σ is non‑negative,
  the contraction rate does not exceed 1.
-/
theorem spectral_attractor_contracts
    (ε σ γ : Real)
    (hε : 0 ≤ ε) (hε_le : ε ≤ 1) (hσ : 0 ≤ σ) :
    contraction_rate ε σ γ ≤ 1 := by
  dsimp [contraction_rate]
  have hpos : 0 ≤ ε ^ 2 := by
    have : 0 ≤ ε := hε
    have : 0 ≤ ε * ε := mul_nonneg this this
    simpa [pow_two] using this
  have hexp_le_one : Real.exp (-2 * σ * γ ^ 2) ≤ 1 := by
    have hneg : -2 * σ * γ ^ 2 ≤ (0 : Real) := by
      have hσ_nonneg : 0 ≤ σ := hσ
      have hγ_sq_nonneg : 0 ≤ γ ^ 2 := by
        have : 0 ≤ γ * γ := mul_self_nonneg γ
        simpa [pow_two] using this
      have : 0 ≤ 2 * σ * γ ^ 2 := mul_nonneg (by norm_num) (mul_nonneg hσ_nonneg hγ_sq_nonneg)
      have : -2 * σ * γ ^ 2 ≤ 0 := by
        simpa [neg_mul, mul_comm] using (neg_nonpos.mpr this)
      simpa using this
    exact Real.exp_le_one.2 hneg
  have : ε ^ 2 * Real.exp (-2 * σ * γ ^ 2) ≤ ε ^ 2 * (1 : Real) :=
    mul_le_mul_of_nonneg_left hexp_le_one hpos
  calc
    contraction_rate ε σ γ = ε ^ 2 * Real.exp (-2 * σ * γ ^ 2) := rfl
    _ ≤ ε ^ 2 * (1 : Real) := this
    _ ≤ (1 : Real) := by
      have : ε ^ 2 ≤ (1 : Real) := by
        have : ε ≤ (1 : Real) := hε_le
        have : ε ^ 2 ≤ 1 ^ 2 := pow_le_pow_of_le_one (by norm_num) hε_le (by norm_num)
        simpa using this
      exact mul_le_of_one_le_left (by norm_num) this

end ComplexKappa
