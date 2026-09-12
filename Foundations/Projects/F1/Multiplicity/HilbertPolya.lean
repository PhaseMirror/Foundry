import Foundations.F1.Multiplicity.Axioms

/-!
# Hilbert–Pólya operator layer

Derived facts about the self-adjoint operator `H` and its spectrum, from the
axioms in `Axioms.lean`.  Nothing here is new mathematics: each theorem is a
mechanical consequence of `H_selfadjoint` and `H_spectrum`.
-/

namespace Multiplicity.RHMultiplicity

/-- A point `1/2 + iγ` of the critical line is a non-trivial zero of ζ iff it
lies in the spectrum of the Hilbert–Pólya operator.  (From `H_spectrum`.) -/
theorem critical_zero_iff_spectrum (γ : Rat) :
    NontrivialZetaZero (mkCplx (1 / 2) γ) ↔ Spectrum H (mkCplx (1 / 2) γ) :=
  (H_spectrum γ).symm

/-- Every spectral point of H on the critical line is a zeta zero. -/
theorem spectral_points_are_zeros (γ : Rat) :
    Spectrum H (mkCplx (1 / 2) γ) → NontrivialZetaZero (mkCplx (1 / 2) γ) :=
  (H_spectrum γ).1

/-- Every zeta zero on the critical line is a spectral point of H. -/
theorem zeros_are_spectral_points (γ : Rat) :
    NontrivialZetaZero (mkCplx (1 / 2) γ) → Spectrum H (mkCplx (1 / 2) γ) :=
  (H_spectrum γ).2

/-- The operator H is self-adjoint (Hilbert–Pólya candidate; Axiom 6). -/
theorem H_is_selfadjoint : IsSelfAdjoint H :=
  H_selfadjoint

/-- RH stated spectrally: every non-trivial zero is a spectral point of H on
the critical line.  This is the statement the manuscript uses to run the
Hilbert–Pólya argument. -/
def RH_via_spectrum : Prop :=
  ∀ z : Cplx, NontrivialZetaZero z → Spectrum H z

end Multiplicity.RHMultiplicity
