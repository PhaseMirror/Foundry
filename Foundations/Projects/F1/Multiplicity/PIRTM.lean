import Foundations.F1.Multiplicity.Axioms

/-!
# PIRTM layer

Definitions and derived facts about the tensor sheaf 𝒯_∞(ℙ) and the operator
family Λ_m, from the axioms in `Axioms.lean`.
-/

namespace Multiplicity.RHMultiplicity

/-- The p-th prime fibre under Λ_m: `Λ_m(𝒯_∞(p))`. -/
noncomputable def PrimeFiber (p : Nat) : TInfinity Nat := LambdaM (Basis p)

/-- Recursive coherence, restated on fibres. -/
theorem coherence_iff_fibres_real :
    recursive_coherence ↔ ∀ p : Nat, SpectrumReal (PrimeFiber p) := by
  rfl

/-- A coherence witness at a single fibre. -/
theorem coherence_implies_fibre_real (h : recursive_coherence) (p : Nat) :
    SpectrumReal (PrimeFiber p) :=
  h p

/-- The sheaf is well-typed as a Hilbert sheaf (Axiom 1): Λ_m maps fibres to
fibres, so `PrimeFiber` is a legitimate operator object. -/
theorem sheaf_hilbert_structure : IsHilbertSheaf TInfinity :=
  TInfinity_hilbert_sheaf

end Multiplicity.RHMultiplicity
