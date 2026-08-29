import Multiplicity.Fold.Core
import Multiplicity.Fold.Proofs
import Multiplicity.Fold.Examples

/-!
# Fold Theory Test Harness (ADR-0032)

Run with `lake run fold_test` (or, from the repository root,
`make fold-test`).

Three test categories:

1. **Positive proofs** — the canonical histories (`history_pipeline`,
   `history_parallel`, `history_composite`) carry kernel-checked
   `Admissible` seals, and ν-values match both the direct computation and
   the disjoint-composition product law.
2. **Intentional failure cases** — `history_unlawful` (`A₂ ∘ A₇`, boundary
   gap `5 > θ*`) and `history_nested_unlawful` (unlawful inner node) are
   rejected by the closure axioms; the composite label `4` fails the
   prime-index basis; conflicting racing proposals cannot be sequenced.
   These are *type-level* rejections: no sealed registry record can even be
   constructed over an unlawful history (zero runtime escape).
3. **Property-based checks** — ∀-theorems (linear criterion, geometry
   separation, conflict irreflexivity, seal soundness) hold for *every*
   history / pair / extension / registry record; a finite enumeration
   re-checks all three example histories.

No `-- TODO: replace sorry`, no `admit`, no mathlib import — mirroring
`Multiplicity.FPES.Test` (ADR-0029).
-/

namespace Fold

/-! ### Property-based theorems (∀ over all fold words) -/

/-- **Property:** for every history, the recursive gate coincides with the
consecutive-pair linear scan. -/
@[fold_proof]
theorem property_linear_criterion (w : FoldWord) :
    Admissible w ↔ chainMax (flatten w) ≤ thetaStar :=
  admissible_iff_chainMax w

/-- **Property:** for every pair of histories, emergent distance vanishes
exactly when the exponent profiles coincide. -/
@[fold_proof]
theorem property_geometry_separation (u v : FoldWord) :
    dProfile u v = 0 ↔ ∀ p, exponents u p = exponents v p :=
  dProfile_eq_zero_iff u v

/-- **Property:** for every extension proposal, self-conflict never occurs
(no false positives in race detection). -/
@[fold_proof]
theorem property_no_self_conflict (e : Extension) : ¬ Conflicting e e :=
  no_self_conflict e

/-- **Property:** every registered ADR's seal is reconstructible from the
record itself — status transitions cannot corrupt audit trails. -/
@[fold_proof]
theorem property_seal_soundness (a : RegisteredADR) : Admissible a.history :=
  seal_soundness a

/-- **Property (finite enumeration):** all three canonical histories pass
the admissibility gate. -/
@[fold_proof]
theorem prop_all_examples_admissible :
    [history_pipeline, history_parallel, history_composite].all
      (fun w => decide (Admissible w)) = true := by native_decide

/-- **Property (finite enumeration):** bracketing changes the word, never
the flat prime sequence nor its multiplicity. -/
@[fold_proof]
theorem prop_bracketing_invariant :
    history_pipeline ≠ history_parallel
      ∧ flatten history_pipeline = flatten history_parallel
      ∧ nu history_pipeline = nu history_parallel := by native_decide

/-! ### Bool checks (runtime-decidable mirror of the proofs) -/

/-- All three canonical histories are sealed. -/
def check_examples_admissible : Bool :=
  [history_pipeline, history_parallel, history_composite].all
    (fun w => decide (Admissible w))

/-- Both unlawful histories are rejected by the closure axioms. -/
def check_unlawful_rejected : Bool :=
  !decide (Admissible history_unlawful)
    && !decide (Admissible history_nested_unlawful)

/-- Non-associativity: same flat word, different trees. -/
def check_nonassociative : Bool :=
  history_pipeline != history_parallel
    && flatten history_pipeline == flatten history_parallel

/-- ν of the pipeline matches the direct arithmetic computation. -/
def check_nu_pipeline : Bool :=
  decide (nu history_pipeline = 8) && decide (nu history_parallel = 8)

/-- ν of the composite matches the disjoint-composition product law. -/
def check_nu_composite : Bool :=
  decide (nu history_composite = 16)

/-- Racing proposals A/B on base `A₃` are flagged as conflicting. -/
def check_conflict_detected : Bool :=
  decide (Conflicting proposalA proposalB)

/-- Identical proposals never conflict (no false positives). -/
def check_no_false_conflict : Bool :=
  !decide (Conflicting proposalA proposalA)

/-- Sequencing B after A's result is blocked (halt-at-T=0 discipline). -/
def check_sequencing_blocked : Bool :=
  !decide (Applies { base := Extension.result proposalA, next := proposalB.next })

/-- Proposal B is rejected outright while A applies cleanly. -/
def check_gate_asymmetry : Bool :=
  decide (Applies proposalA) && !decide (Applies proposalB)

/-- Deprecation preserves the seal on F001's history. -/
def check_seal_survives_deprecation : Bool :=
  decide (Admissible adrF001_deprecated.history)

/-- Geometry identifies same-profile histories across different bracketings. -/
def check_geometry_identification : Bool :=
  decide (dProfile history_pipeline history_parallel = 0)

/-- Geometry separates distinct profiles at distance exactly 3. -/
def check_geometry_separation : Bool :=
  decide (dProfile history_pipeline history_unlawful = 3)

/-- The contractive kernel strictly contracts towards the fixed point. -/
def check_orbit_contractive : Bool :=
  kernOrbit 40 3 == 5 && kernOrbit 40 6 == 0

/-! ### Main test runner -/

/-- Run the Fold Theory test suite; returns 0 on success, 1 on any failure. -/
def main : IO UInt32 := do
  IO.println "Running Fold Theory Test Harness (ADR-0032)..."
  IO.println ""

  let ok (name : String) (cond : Bool) : IO Bool := do
    if cond then
      IO.println s!"✓ {name}"
      pure true
    else
      IO.println s!"✗ {name}"
      pure false

  let mut pass : Bool := true

  -- Positive proofs
  pass := (← ok "All three canonical histories carry Admissible seals" check_examples_admissible) && pass
  pass := (← ok "ν(pipeline) = ν(parallel) = 8 (arithmetic shadow)" check_nu_pipeline) && pass
  pass := (← ok "ν(composite) = 16 = 4·4 (disjoint product law)" check_nu_composite) && pass
  pass := (← ok "kernOrbit contracts 40 ↦ 5 ↦ … ↦ 0" check_orbit_contractive) && pass

  -- Intentional failure cases (type-system rejected)
  pass := (← ok "Unlawful histories rejected: A₂∘A₇ and (A₃∘A₇)∘A₅" check_unlawful_rejected) && pass
  pass := (← ok "Proposal B rejected outright, A applies cleanly" check_gate_asymmetry) && pass
  pass := (← ok "Sequencing across conflicting proposals blocked" check_sequencing_blocked) && pass

  -- Conflict detection
  pass := (← ok "Racing proposals A/B detected as Conflicting" check_conflict_detected) && pass
  pass := (← ok "No false conflict between identical proposals" check_no_false_conflict) && pass

  -- Registry / audit trail
  pass := (← ok "Deprecation preserves F001's seal" check_seal_survives_deprecation) && pass

  -- Emergent geometry
  pass := (← ok "d_F(pipeline, parallel) = 0 (same profile)" check_geometry_identification) && pass
  pass := (← ok "d_F(pipeline, unlawful) = 3 (separated profiles)" check_geometry_separation) && pass

  -- Non-associativity
  pass := (← ok "Bracketing is extra structure: same flat word, distinct trees" check_nonassociative) && pass

  IO.println ""
  IO.println s!"flatten pipeline = {repr (flatten history_pipeline)}"
  IO.println s!"flatten parallel = {repr (flatten history_parallel)}"
  IO.println s!"θ* = {thetaStar} (= Λ_m − 1 = {LambdaM} − 1)"
  IO.println ""

  -- The following are guaranteed by the *existence* of these theorems in
  -- Multiplicity.Fold.Proofs / .Examples (they type-checked or the module
  -- would not have imported):
  IO.println "Kernel-checked at import time (no -- TODO: replace sorry):"
  IO.println "  - defect_eq_chainMax       : Θ(w) = chainMax (flatten w)"
  IO.println "  - admissible_iff_chainMax  : Admissible w ↔ chainMax (flatten w) ≤ θ*"
  IO.println "  - nu_comp_mul              : ν(u ⊙ v) = ν u · ν v (disjoint supports)"
  IO.println "  - orbit_stable             : F^[k](C) = C"
  IO.println "  - dProfile_eq_zero_iff     : d_F(u,v) = 0 ↔ equal exponent profiles"
  IO.println "  - conflicting_not_mergeable: conflicting races cannot be sequenced"
  IO.println "  - four_not_valid_gen       : ¬ ValidGen 4 (type-level basis rejection)"
  IO.println ""

  if pass then
    IO.println "All Fold Theory tests passed."
    return 0
  else
    IO.println "Fold Theory test failures detected."
    return 1

end Fold

/-- Root entry point (Lake `lean_exe fold_test` links `_root_.main`). -/
def main : IO UInt32 := Fold.main
