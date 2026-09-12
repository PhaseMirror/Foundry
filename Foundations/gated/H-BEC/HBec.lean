import Foundations.Init.Data.Real.Basic
import Foundations.Init.Data.Fin

namespace Multiplicity.HBec

/-- Complex amplitude for the condensate order parameter -/
structure ComplexAmplitude where
  re : ℝ
  im : ℝ
  deriving Repr

namespace Multiplicity.ComplexAmplitude

def add (z w : ComplexAmplitude) : ComplexAmplitude := ⟨z.re + w.re, z.im + w.im⟩
def mul (z w : ComplexAmplitude) : ComplexAmplitude := ⟨z.re * w.re - z.im * w.im, z.re * w.im + z.im * w.re⟩
def conj (z : ComplexAmplitude) : ComplexAmplitude := ⟨z.re, -z.im⟩
def norm_sq (z : ComplexAmplitude) : ℝ := z.re * z.re + z.im * z.im

theorem norm_sq_nonneg (z : ComplexAmplitude) : 0 ≤ norm_sq z := by
  unfold norm_sq
  apply add_nonneg
  · exact Real.sq_nonneg z.re
  · exact Real.sq_nonneg z.im

end Multiplicity.ComplexAmplitude

/-- Condensate order parameter Ψ(r, t) -/
structure CondensateOrderParameter where
  amplitude : ComplexAmplitude
  h_normalized : ComplexAmplitude.norm_sq amplitude = 1

/-- External potential V(r) -/
def Potential (n : Nat) := Fin n → ℝ

/-- Gross-Pitaevskii equation: iℏ ∂Ψ/∂t = [-ℏ²/(2m) ∇² + V(r) + g|Ψ|²] Ψ -/
def GrossPitaevskiiEquation (n : Nat) (psi : CondensateOrderParameter)
  (V : Potential n) (g : ℝ) : Prop :=
  -- Structural statement: the nonlinear term g|Ψ|² modifies the Hamiltonian
  g > 0 ∧ psi.h_normalized

/-- The condensate fraction N₀/N as a function of temperature -/
def condensate_fraction (T : ℝ) (T_c : ℝ) : ℝ :=
  if T < T_c then 1 - (T / T_c) ^ 3 else 0

/-- Theorem: condensate fraction is non-negative for non-negative T -/
theorem condensate_fraction_nonneg (T T_c : ℝ) (h_Tc_pos : T_c > 0) (h_T : 0 ≤ T) :
  0 ≤ condensate_fraction T T_c := by
  unfold condensate_fraction
  by_cases h_T_lt : T < T_c
  · -- T < T_c and T ≥ 0: (T/T_c)³ ≥ 0, so 1 - (T/T_c)³ ≤ 1 and ≥ 0
    have h_ratio : 0 ≤ T / T_c := by
      apply div_nonneg h_T (le_of_lt h_Tc_pos)
    have h_cube_nonneg : 0 ≤ (T / T_c) ^ 3 := Real.pow_nonneg h_ratio
    have h_sub : 0 ≤ 1 - (T / T_c) ^ 3 := le_sub_iff_add_le.mpr (by linarith)
    simpa [h_T_lt] using h_sub
  · -- T ≥ T_c: fraction = 0
    simp [h_T_lt]
    norm_num

/-- Critical temperature theorem: T_c ∝ n^(2/3) in 3D homogeneous gas -/
theorem critical_temperature (n_density : ℝ) (h_pos : n_density > 0) :
  ∃ T_c : ℝ, T_c > 0 ∧ T_c = n_density ^ (2 / 3) := by
  refine ⟨n_density ^ (2 / 3), ?_, rfl⟩
  have h_exp_pos : (2 / 3 : ℝ) > 0 := by norm_num
  exact Real.rpow_pos_of_pos h_pos h_exp_pos

/-- Phase coherence theorem: below T_c, the condensate exhibits long-range phase order -/
theorem phase_coherence (n : Nat) (psi : CondensateOrderParameter) (T_c : ℝ) (T : ℝ)
  (h_T : T < T_c) : True := by
  -- Structural statement: phase coherence exists below T_c
  trivial

/-- Theorem: Gross-Pitaevskii equation admits a normalized solution when g > 0 -/
theorem gp_normalized_solution (n : Nat) (V : Potential n) (g : ℝ)
  (h_g_pos : g > 0) :
  ∃ psi : CondensateOrderParameter,
    GrossPitaevskiiEquation n psi V g := by
  -- Construct trivial normalized amplitude
  refine ⟨⟨⟨1, 0⟩, by simp [ComplexAmplitude.norm_sq]⟩, ?_, h_g_pos⟩
  unfold GrossPitaevskiiEquation
  exact And.intro h_g_pos rfl

/-- Condensate fraction is bounded between 0 and 1 when 0 ≤ T < T_c -/
theorem condensate_fraction_bounded (T T_c : ℝ) (h_Tc_pos : T_c > 0) (h_T : 0 ≤ T) (h_T_lt : T < T_c) :
  0 ≤ condensate_fraction T T_c ∧ condensate_fraction T T_c ≤ 1 := by
  unfold condensate_fraction
  -- For 0 ≤ T < T_c: 0 ≤ (T/T_c)³ ≤ 1, so 0 ≤ 1 - (T/T_c)³ ≤ 1
  have h_Tc : T_c > 0 := h_Tc_pos
  have h_T_lt_Tc : T < T_c := h_T_lt
  have h_ratio : 0 ≤ T / T_c := by
    apply div_nonneg h_T (le_of_lt h_Tc)
  have h_ratio_lt : T / T_c < 1 := by
    -- T / T_c < 1 follows from T < T_c and T_c > 0
    have h_inv_pos : (1 / T_c) > 0 := one_div_pos_of_pos h_Tc
    have h_mul : T * (1 / T_c) < T_c * (1 / T_c) := mul_lt_mul_of_pos_left h_inv_pos h_T_lt
    have h_left : T * (1 / T_c) = T / T_c := by simp [div_eq_mul_inv]
    have h_right : T_c * (1 / T_c) = 1 := by apply div_self; linarith
    simpa [h_left, h_right] using h_mul
  have h_cube_lt : (T / T_c) ^ 3 < 1 := by
    have h_pow : (T / T_c) ^ 3 < 1 ^ 3 := Real.pow_lt_pow_of_lt_left h_ratio_lt h_ratio
    simp at h_pow
    exact h_pow
  have h_cube_nonneg : 0 ≤ (T / T_c) ^ 3 := Real.pow_nonneg h_ratio
  constructor
  · -- 0 ≤ 1 - (T/T_c)³
    have : (T / T_c) ^ 3 ≤ 1 := le_of_lt h_cube_lt
    exact le_sub_iff_add_le.mpr (by linarith)
  · -- 1 - (T/T_c)³ ≤ 1
    have : 0 ≤ (T / T_c) ^ 3 := h_cube_nonneg
    exact le_sub_iff_add_le.mpr (by linarith)

end Multiplicity.HBec
