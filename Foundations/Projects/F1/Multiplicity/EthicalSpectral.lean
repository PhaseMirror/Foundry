import Foundations.F1.Multiplicity.Axioms

/-!
# Ethical–Spectral layer

Derived facts about the Ethical–Spectral map Φ, from `Phi_bijective` in
`Axioms.lean`.  These are the bijection facts used by the corollaries.
-/

namespace Multiplicity.RHMultiplicity

/-- Φ is injective (from the bijection axiom). -/
theorem Phi_injective : Injective Phi :=
  Phi_bijective.1

/-- Φ is surjective (from the bijection axiom). -/
theorem Phi_surjective : Surjective Phi :=
  Phi_bijective.2

/-- A right inverse of Φ, obtained from surjectivity. -/
noncomputable def PhiInv (b : Nat) : Nat :=
  Classical.choose (Phi_surjective b)

/-- `Φ (Φ⁻¹ b) = b`: Φ⁻¹ is a right inverse of Φ. -/
theorem PhiInv_right (b : Nat) : Phi (PhiInv b) = b :=
  Classical.choose_spec (Phi_surjective b)

/-- `Φ⁻¹ (Φ a) = a`: Φ⁻¹ is a left inverse of Φ. -/
theorem PhiInv_left (a : Nat) : PhiInv (Phi a) = a :=
  Phi_injective (PhiInv_right (Phi a))

/-- Φ is left-cancellative: images determine arguments. -/
theorem Phi_eq_iff {a b : Nat} : Phi a = Phi b ↔ a = b := by
  constructor
  · intro h
    exact Phi_injective h
  · intro h
    rw [h]

end Multiplicity.RHMultiplicity
