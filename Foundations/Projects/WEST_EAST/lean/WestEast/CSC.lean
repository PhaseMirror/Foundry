import WestEast.Types

set_option autoImplicit false

/-!
# Conscious Symbol Calculus (CSC)
Formal properties of coherence norms, prime-power scaling, and phase gauge invariance.
-/

namespace WestEast

/-- Scaled prime-power coherence contribution: kappa * k * amp^2 / log_p. -/
def symbol_power_coherence (kappa k amp log_p : Nat) : Nat :=
  if log_p > 0 then (kappa * k * (amp * amp)) / log_p else 0

/-- Theorem: Zero lawfulness weight (kappa = 0) yields zero coherence norm. -/
theorem zero_lawfulness_zero_coherence (k amp log_p : Nat) :
    symbol_power_coherence 0 k amp log_p = 0 := by
  dsimp [symbol_power_coherence]
  split
  · have h0 : 0 * k * (amp * amp) = 0 := by omega
    rw [h0]
    exact Nat.zero_div log_p
  · rfl

/-- Theorem: Monotonicity of coherence norm under increased amplitude. -/
theorem coherence_monotone_amplitude (kappa k amp1 amp2 log_p : Nat)
    (h_amp : amp1 ≤ amp2) :
    symbol_power_coherence kappa k amp1 log_p ≤ symbol_power_coherence kappa k amp2 log_p := by
  dsimp [symbol_power_coherence]
  split
  · rename_i h_log
    have h_sq : amp1 * amp1 ≤ amp2 * amp2 := by
      exact Nat.mul_le_mul h_amp h_amp
    have h_mul : kappa * k * (amp1 * amp1) ≤ kappa * k * (amp2 * amp2) := by
      exact Nat.mul_le_mul_left (kappa * k) h_sq
    exact Nat.div_le_div_right h_mul
  · exact Nat.le_refl 0

end WestEast
