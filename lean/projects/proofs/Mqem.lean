import Kernel

/-!
# Mqem — quantum error mitigation reduces the estimation error

Formalizes the MQEM invariant: a single mitigation step moves the noisy estimate one
unit toward the truth and strictly decreases the (discrete) error measure. No
`Mathlib`, no `sorry`.
-/
namespace Mqem

open proofs.Kernel

/-- Absolute error `|e - t|` over `Nat`. -/
def errMeasure (e t : Nat) : Nat := if e ≤ t then t - e else e - t

/-- One mitigation step: nudge the estimate one unit toward the truth. -/
def stepToward (e t : Nat) : Nat := if e ≤ t then e + 1 else e - 1

/-- A mitigation step strictly reduces the error whenever the estimate is off. -/
theorem mitigate_reduces (e t : Nat) (h : errMeasure e t > 0) :
    errMeasure (stepToward e t) t < errMeasure e t := by
  simp [errMeasure, stepToward]
  split <;> omega

end Mqem
