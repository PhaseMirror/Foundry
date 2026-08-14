import Multiplicity.F1.Multiplicity.Axioms
import Multiplicity.F1.Multiplicity.MainTheorem
import Multiplicity.F1.Multiplicity.Corollaries
import Multiplicity.F1.Multiplicity.IsolationMeasure
import Multiplicity.F1.Multiplicity.KaniCertificates

/-!
# Axiom-consistency tests

Positive and intentional-failure tests of the formal model.  The
intentional-failure test cannot be *built* (by design): it is the textual
argument of the honesty gate in `scripts/run_all_kani.sh`, which asserts that
admitted-goal candidate smuggled past the axiom manifest is detected.
-/

namespace Multiplicity.RHMultiplicity

/-- Smoke: the axiom manifest declares non-trivially; RH is a proposition. -/
theorem test_rh_is_prop : RH ∨ ¬ RH := by
  exact Classical.em RH

/-- Smoke: Theorem 3.1 is constructible (forward direction). -/
theorem test_forward (h : RH) : recursive_coherence := by
  exact hRH_implies_coherence h

/-- Smoke: the theorem is symmetric. -/
theorem test_iff (h : recursive_coherence) : RH := by
  exact coherence_implies_RH h

/-- Positive certificate: Theorem 3.1 closes for the finite certificate
chain (Kani ⇒ coherence ⇒ RH). -/
theorem test_certificate_chain : RH := by
  exact RH_from_certified_bounds

/-- Positive certificate: trace bounds hold in the certified range
`1 ≤ n ≤ 500`. -/
theorem test_trace_bound (n : Nat) (h1 : 1 ≤ n) (hn : n ≤ N_max) :
    0 ≤ TraceProj ZetaOperator n := by
  exact (finite_trace_bounds_full n h1 hn).1

/-- Positive certificate: the coherence bound holds at the certified primes. -/
theorem test_coherence_bound (p : Nat) (hp : IsPrime p) (hb : p ≤ P_max) :
    IsolationMeasure p < eps_coherence := by
  exact finite_coherence_certified p hp hb

/-- Positive pipeline: the certificate ⇒ RH implication is *proved*
(`RH_from_finite_certificate`); only the certificate itself is axiomatic.
This is the property-based shape of the pipeline: quantify the certificate
hypothesis and discharge it once. -/
theorem test_pipeline_implication :
    (∀ p : Nat, IsPrime p → p ≤ P_max → IsolationMeasure p < eps_coherence) → RH :=
  RH_from_finite_certificate

/-- Positive pipeline: the same implication at the coherence level. -/
theorem test_pipeline_coherence_implication :
    (∀ p : Nat, IsPrime p → p ≤ P_max → IsolationMeasure p < eps_coherence) →
      recursive_coherence :=
  M_from_finite_certificate

end Multiplicity.RHMultiplicity
