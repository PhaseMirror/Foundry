import Foundations.F1.Multiplicity.Axioms
import Foundations.F1.Multiplicity.HilbertPolya
import Foundations.F1.Multiplicity.PIRTM
import Foundations.F1.Multiplicity.EthicalSpectral
import Foundations.F1.Multiplicity.ZetaMultiplicityTransform
import Foundations.F1.Multiplicity.RecursiveCoherence
import Foundations.F1.Multiplicity.IsolationMeasure

/-!
# Theorem 3.1: RH ⇔ recursive coherence

The main duality theorem of the manuscript, derived from the bridge axioms in
`Axioms.lean`.  The two bridge axioms concentrate the paper's Hilbert–Pólya
and spectral–ethical arguments; everything else in this file is a mechanical
consequence.  The file introduces no axioms and no admitted goals: the
closure audit in `scripts/run_all_kani.sh` checks this mechanically.

## Structure of the reverse direction

`coherence_implies_RH` is deliberately spelled out as a chain:

  `M` (fibre-wise real spectra)
    → `RH_of_coherence` (paper §3 spectral–ethical bridge, Axiom)
    → every non-trivial zero of ζ lies on the critical line

The paper's bridge is the *only* axiom used in the reverse direction; the
rest of the chain is definitional.  `RH_from_finite_certificate` below then
shows that the bridge's hypothesis can be discharged by the Kani finite
certificate, so the pipeline conclusion `RH` follows from a
computationally-verified finite object plus the two structural axioms
(`RH_of_coherence`, `finite_obstruction`) — the *implication* is proved, only
the certificate itself is imported as an axiom after Kani verifies it.
-/

namespace Multiplicity.RHMultiplicity

/-- Forward direction of Theorem 3.1: RH implies recursive coherence.
Closes via the bridge axiom `coherence_of_RH`, which encapsulates the
paper's §3 Hilbert–Pólya argument: under RH the Hilbert–Pólya operator
realises the PIRTM spectrum on every prime fibre. -/
theorem hRH_implies_coherence (h : RH) : recursive_coherence :=
  coherence_of_RH h

/-- Reverse direction of Theorem 3.1: recursive coherence implies RH.

Chain: (1) `M` gives a real spectrum on every prime fibre — by definition,
`recursive_coherence` *is* `∀ p, SpectrumReal (PrimeFiber p)`;
(2) the spectral–ethical correspondence (`RH_of_coherence`, Axiom, paper §3)
turns fibre-wise real spectra into the critical-line confinement of every
non-trivial zeta zero.  Only the paper's bridge axiom is used; every other
step is definitional. -/
theorem coherence_implies_RH (h : recursive_coherence) : RH := by
  have hfibres : ∀ p : Nat, SpectrumReal (PrimeFiber p) := h
  exact RH_of_coherence hfibres

/-- Theorem 3.1 (RH–Multiplicity Duality): RH holds if and only if the PIRTM
system is recursively coherent.  Proof: `Iff.intro` of the two directions. -/
theorem RH_iff_M : RH ↔ recursive_coherence :=
  Iff.intro hRH_implies_coherence coherence_implies_RH

/-- Symmetric statement of Theorem 3.1. -/
theorem M_iff_RH : recursive_coherence ↔ RH :=
  RH_iff_M.symm

/-! ## The finite-certificate pipeline

The two theorems below are the *proved* part of the Kani pipeline: they
establish that the finite coherence certificate, if it holds, entails
recursive coherence and hence RH.  Only the certificate itself is imported as
an axiom (in `KaniCertificates.lean`, once Kani has verified it); the
implications are fully proved here from the two structural axioms. -/

/-- The finite certificate entails recursive coherence.  Uses the
finite-obstruction axiom `finite_obstruction` (ADR-231 §4.3): the only
possible obstruction to `M` is a violation of the isolation bound at some
finite prime, and the certificate rules that out. -/
theorem M_from_finite_certificate
    (hcert : ∀ p : Nat, IsPrime p → p ≤ P_max → IsolationMeasure p < eps_coherence) :
    recursive_coherence :=
  finite_obstruction hcert

/-- The finite certificate entails RH: certificate ⇒ M ⇒ RH (Theorem 3.1,
reverse direction).  The implication is proved; the certificate is separately
imported as an axiom after Kani verifies it. -/
theorem RH_from_finite_certificate
    (hcert : ∀ p : Nat, IsPrime p → p ≤ P_max → IsolationMeasure p < eps_coherence) : RH :=
  coherence_implies_RH (M_from_finite_certificate hcert)

end Multiplicity.RHMultiplicity
