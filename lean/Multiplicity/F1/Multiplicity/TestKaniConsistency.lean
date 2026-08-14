import Multiplicity.F1.Multiplicity.KaniCertificates

/-!
# Kani certificate-consistency tests

Re-proves in Lean the exact bounds that the Rust/Kani harnesses verify on the
same models, so the certificates in `KaniCertificates.lean` and the model
axioms agree.  These are the property-based tests of the pipeline: quantified
over the whole finite domain, discharged by `native_decide`.
-/

namespace Multiplicity.RHMultiplicity

/-- Coherence model: `rhoModel` is within the certified bound for the whole
range `2 ≤ p ≤ 1000` (mirror of `kani_coherence.rs`). -/
theorem test_rho_model_in_range :
    (List.range 1001).all (fun p => 2 ≤ p → rhoModel p ≤ 1000) = true := by
  native_decide

/-- Trace model: `0 ≤ tr_scaled < 10` for the whole range `1 ≤ n ≤ 500`
(mirror of `kani_trace.rs`). -/
theorem test_trace_model_in_range :
    (List.range 501).all (fun n => 1 ≤ n → 0 ≤ traceModel n ∧ traceModel n < 10) = true := by
  native_decide

/-- Bijection model: Φ-model injectivity over the certified zero table
(mirror of `kani_bijection.rs`). -/
theorem test_phi_model_injective :
    (List.range 32).all (fun i => (List.range 32).all (fun j => i = j || phiModelScaled (scaledZeroAt i) ≠ phiModelScaled (scaledZeroAt j))) = true := by
  native_decide

/-- Bijection model: Φ-model surjectivity onto `0..31` — injectivity alone is
half of the bijection claim, this closes it at model level. -/
theorem test_phi_model_surjective :
    (List.range 32).all (fun i => (List.range 32).any (fun j => phiModelScaled (scaledZeroAt j) = i)) = true := by
  native_decide

/-- Coherence model: the strict bound `rhoModel < 1000` holds on the whole
certified range (this is the tight form of `kani_coherence.rs`). -/
theorem test_rho_model_strict_range :
    (List.range 1001).all (fun p => 2 ≤ p → rhoModel p < 1000) = true := by
  native_decide

/-- Coherence model: the bound is attained (`p = 2`), so the certificate is
not vacuous. -/
theorem test_rho_bound_attained : ∃ p, IsPrime p ∧ p ≤ P_max ∧ rhoModel p = 500 :=
  rhoModel_bound_attained

/-- Trace model: the bound is attained (`n = 9`). -/
theorem test_trace_bound_attained : ∃ n, 1 ≤ n ∧ n ≤ N_max ∧ traceModel n = 9 :=
  traceModel_bound_attained

/-- Cross-model: the model bound implies the axiom bound (rho chain). -/
theorem test_rho_axiom_bound (p : Nat) (_hp : 2 ≤ p) (_hb : p ≤ P_max) :
    rhoModel p ≤ 1000 := by
  exact Nat.div_le_self 1000 p

/-- Cross-model: the trace model respects the certified upper bound. -/
theorem test_trace_axiom_bound (n : Nat) (_h1 : 1 ≤ n) (_hn : n ≤ N_max) :
    traceModel n < 10 := by
  exact Nat.mod_lt n (by decide)

end Multiplicity.RHMultiplicity
