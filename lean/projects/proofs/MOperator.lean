import Kernel

/-!
# MOperator — linearity of the discrete Mellin-style transform

Formalizes the M-Operator's core property: the transform is linear in its input
function. No `Mathlib`, no `sorry`.
-/
namespace MOperator

open proofs.Kernel

/-- Discrete transform `T[f](s) = Σₙ f(n)·s` over a sample set. -/
def transform (f : Nat → Nat) (s : Nat) (ns : List Nat) : Nat :=
  lsum (ns.map fun n => f n * s)

/-- Linearity: T[f+g] = T[f] + T[g]. -/
theorem transform_linear (ns : List Nat) (s : Nat) (f g : Nat → Nat) :
    transform (fun n => f n + g n) s ns =
    transform f s ns + transform g s ns := by
  simp [transform]
  induction ns <;> simp [*]

/-- Homogeneity: T[k·f] = k·T[f]. -/
theorem transform_scale (ns : List Nat) (s k : Nat) (f : Nat → Nat) :
    transform (fun n => k * f n) s ns = k * transform f s ns := by
  simp [transform]
  induction ns <;> simp [*]

end MOperator
