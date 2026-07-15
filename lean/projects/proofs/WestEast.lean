import Kernel

/-!
# WestEast — duality composition

Formalizes the West-East duality invariant: function composition is associative, and
an involutive duality map squares to the identity. No `Mathlib`, no `sorry`.
-/
namespace WestEast

open proofs.Kernel

/-- Compose two maps. -/
def compose (f g : Nat → Nat) (x : Nat) : Nat := g (f x)

/-- Composition is associative (West and East orders agree). -/
theorem compose_assoc (f g h : Nat → Nat) (x : Nat) :
    compose (compose f g) h x = compose f (compose g h) x := by simp [compose]

/-- An involutive duality squares to identity. -/
theorem duality_involution (f : Nat → Nat) (h : ∀ x, f (f x) = x) (x : Nat) :
    f (f x) = x := h x

end WestEast
