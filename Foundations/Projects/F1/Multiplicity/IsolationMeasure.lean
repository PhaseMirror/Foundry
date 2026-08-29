import Foundations.F1.Multiplicity.Axioms

/-!
# Isolation measure layer

Derived facts about the isolation measure ρ_Λ, from the axioms in
`Axioms.lean`.  The finite certificates that bound ρ_Λ live in
`KaniCertificates.lean`.
-/

namespace Multiplicity.RHMultiplicity

/-- The paper's asymptotic decay bound implies the certified finite bound on
`p ≤ P_max`: the Kani certificate is a weakening of the infinite claim. -/
theorem asymptotic_implies_certified
    (h : ∀ p : Nat, IsPrime p → IsolationMeasure p < eps_coherence)
    (p : Nat) (hp : IsPrime p) (_hb : p ≤ P_max) :
    IsolationMeasure p < eps_coherence :=
  h p hp

/-- Under the paper's decay bound, the finite-obstruction hypothesis is
satisfied, so recursive coherence follows directly. -/
theorem coherence_from_asymptotic
    (h : ∀ p : Nat, IsPrime p → IsolationMeasure p < eps_coherence) :
    recursive_coherence :=
  finite_obstruction (fun p hp _hb => h p hp)

end Multiplicity.RHMultiplicity
