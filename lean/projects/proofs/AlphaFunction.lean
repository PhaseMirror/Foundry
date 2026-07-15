import Kernel

/-!
# AlphaFunction — bounded activation over scaled integers

Formalizes the core invariant of the Alpha activation function: saturation into a
closed `[0, cap]` band. No `Mathlib`, no `sorry`.
-/
namespace AlphaFunction

open proofs.Kernel

/-- Alpha activation: saturate the pre-activation into `[0, cap]`. -/
def alpha (x cap : Nat) : Nat := saturate x cap

/-- The activation never exceeds its cap. -/
theorem alpha_bounded (x cap : Nat) : alpha x cap ≤ cap := saturate_le x cap

/-- Saturation is idempotent (re-application is stable). -/
theorem alpha_idempotent (x cap : Nat) :
    alpha (alpha x cap) cap = alpha x cap := saturate_of_le _ _ (saturate_le x cap)

/-- Below the cap the function is the identity. -/
theorem alpha_fixes (x cap : Nat) (h : x ≤ cap) : alpha x cap = x := saturate_of_le x cap h

end AlphaFunction
