import Foundations.Peano.Peano
import Foundations.Nat.Order
import Foundations.Nat.Arith

namespace Foundations.Order

/-!
# Partial Orders and Lattices

Basic order-theoretic definitions and properties.
-/

/-! ## Partial Order -/

class POrder (α : Type) where
  le : α → α → Prop
  lt : α → α → Prop
  le_refl : ∀ a, le a a
  le_antisymm : ∀ a b, le a b → le b a → a = b
  le_trans : ∀ a b c, le a b → le b c → le a c
  lt_iff_le_not_le : ∀ a b, lt a b ↔ le a b ∧ ¬ le b a

/-! ## Lattice -/

class Lattice (α : Type) extends POrder α where
  sup : α → α → α
  inf : α → α → α
  le_sup_left : ∀ a b, POrder.le a (sup a b)
  le_sup_right : ∀ a b, POrder.le b (sup a b)
  sup_le : ∀ a b c, POrder.le a c → POrder.le b c → POrder.le (sup a b) c
  inf_le_left : ∀ a b, POrder.le (inf a b) a
  inf_le_right : ∀ a b, POrder.le (inf a b) b
  le_inf : ∀ a b c, POrder.le a b → POrder.le a c → POrder.le a (inf b c)

/-! ## Bounded Lattice -/

class BoundedLattice (α : Type) extends Lattice α where
  bot : α
  top : α
  bot_le : ∀ a, POrder.le bot a
  le_top : ∀ a, POrder.le a top

/-! ## Nat as a lattice -/

def natLattice : Lattice Nat where
  le := Nat.le
  lt := Nat.lt
  le_refl := Nat.le_refl
  le_antisymm _ _ := Nat.le_antisymm
  le_trans _ _ _ := Nat.le_trans
  lt_iff_le_not_le _ _ := ⟨fun h => ⟨Nat.le_of_lt h, Nat.not_le.mpr h⟩,
    fun ⟨h₁, h₂⟩ => Nat.not_le.mp h₂⟩
  sup := Nat.max
  inf := Nat.min
  le_sup_left := Nat.le_max_left
  le_sup_right := Nat.le_max_right
  sup_le _ _ _ h₁ h₂ := Nat.max_le.mpr ⟨h₁, h₂⟩
  inf_le_left := Nat.min_le_left
  inf_le_right := Nat.min_le_right
  le_inf _ _ _ h₁ h₂ := Nat.le_min.mpr ⟨h₁, h₂⟩

end Foundations.Order
