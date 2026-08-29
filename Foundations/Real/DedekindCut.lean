import Foundations.Rat.Basic

namespace Foundations.Real

/-- A Dedekind cut: a subset of Q representing a real number. -/
structure DedekindCut where
  carrier : Rat → Prop

instance : Membership Rat DedekindCut where
  mem (x : DedekindCut) (r : Rat) := x.carrier r

theorem ext {x y : DedekindCut} (h : ∀ r, r ∈ x ↔ r ∈ y) : x = y := by
  have hc : x.carrier = y.carrier := by
    funext r
    exact propext (h r)
  cases x; cases y; congr

def ofRat (r : Rat) : DedekindCut where
  carrier p := p < r

instance : Coe Rat DedekindCut := ⟨ofRat⟩

/-! ## Cut Order -/

def cutLe (x y : DedekindCut) : Prop := ∀ p, p ∈ x → p ∈ y

def cutLt (x y : DedekindCut) : Prop := cutLe x y ∧ ∃ p, p ∈ y ∧ p ∉ x

instance : LE DedekindCut := ⟨cutLe⟩
instance : LT DedekindCut := ⟨cutLt⟩

/-- Cuts that are Leq and Geq are equal. -/
theorem le_antisymm {x y : DedekindCut} (hxy : x ≤ y) (hyx : y ≤ x) : x = y := by
  apply ext; intro r; exact ⟨fun h => hxy r h, fun h => hyx r h⟩

/-- Pre-order reflexivity of Dedekind cuts. -/
theorem le_refl (x : DedekindCut) : x ≤ x := by
  intro p hp; exact hp

/-- Pre-order transitivity of Dedekind cuts. -/
theorem le_trans (x y z : DedekindCut) (hxy : x ≤ y) (hyz : y ≤ z) : x ≤ z := by
  intro p hp; exact hyz p (hxy p hp)

end Foundations.Real
