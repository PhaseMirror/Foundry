import Foundations.F1.Multiplicity.PIRTM
import Foundations.F1.Multiplicity.Axioms

/-!
# Recursive coherence layer

The recursive coherence condition `M` and its consequences, from the axioms in
`Axioms.lean`.
-/

namespace Multiplicity.RHMultiplicity

/-- An operator fibre with real (isometric) spectrum. -/
def IsometricSpectrum (T : TInfinity Nat) : Prop := SpectrumReal T

/-- Under recursive coherence, every prime fibre has an isometric (real)
spectrum. -/
theorem isometry_of_coherence (h : recursive_coherence) (p : Nat) :
    IsometricSpectrum (PrimeFiber p) :=
  h p

/-- Uniform statement: coherence gives the isometry on all fibres at once. -/
theorem coherence_uniform_isometry (h : recursive_coherence) :
    ∀ p : Nat, IsometricSpectrum (PrimeFiber p) :=
  h

end Multiplicity.RHMultiplicity
