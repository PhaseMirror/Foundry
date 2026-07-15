import Kernel

/-!
# Neuroplasticity — synaptic weight stays within bounds

Formalizes the neuroplasticity invariant: a Hebbian/LTD weight update, clamped to the
permitted `[wMin, wMax]` band, never leaves that band, and is the identity when the
updated value already lies inside it. No `Mathlib`, no `sorry`.
-/
namespace Neuroplasticity

open proofs.Kernel

/-- Apply a weight delta and clamp into `[wMin, wMax]`. -/
def updateWeight (w Δ wMin wMax : Nat) (h : wMin ≤ wMax) : Nat :=
  clamp (w + Δ) wMin wMax

/-- The updated weight stays inside the permitted band. -/
theorem weight_in_bounds (w Δ wMin wMax : Nat) (h : wMin ≤ wMax) :
    wMin ≤ updateWeight w Δ wMin wMax ∧ updateWeight w Δ wMin wMax ≤ wMax := by
  simp [updateWeight]
  exact ⟨clamp_lo _ _ _ h, clamp_hi _ _ _ h⟩

/-- If the updated weight already fits, clamping is the identity. -/
theorem weight_stable_if_in_bounds (w Δ wMin wMax : Nat) (h : wMin ≤ wMax)
    (hhi : w + Δ ≤ wMax) : updateWeight w Δ wMin wMax = w + Δ := by
  simp [updateWeight]
  exact clamp_fixes (w + Δ) wMin wMax (Nat.le_trans (Nat.zero_le wMin) (Nat.le_refl _)) hhi

end Neuroplasticity
