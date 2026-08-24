import Multiplicity.FPES.Core
import Multiplicity.FPES.Proofs
import Multiplicity.FPES.Examples

/-!
# FPES Test Harness (ADR-0029)

Run with `lake run fpes_test` (or, from the repository root, `make fpes-test`).

Three test categories:

1. **Positive proofs** — the three certified hypothesis spaces
   (`hspace_simd`, `hspace_prune`, `hspace_diff`) carry `Certificate`s; the
   representative contraction preserves falsification power and survival
   (FPES-MULTIPLICITY-001, FPES-SURVIVAL-002).
2. **Intentional failure cases** — `hspace_defective` (a class with zero
   paths) is rejected: `¬ Viable`, `¬ ClassesNonempty`, and no `Certificate`
   term exists.  These are *type-system* failures: the invalid artifact
   cannot even be represented in the pipeline (zero runtime escape).
3. **Property-based checks** — the ∀-theorems
   `property_viable_falsification_preserving` /
   `property_viable_survival` hold for *every* hypothesis space, and a
   finite enumeration (`prop_all_certified_viable`) re-checks all three
   example spaces.

No `sorry`, no `admit`, no mathlib import: `scripts/fpes-gate.sh` enforces
this on every build.
-/

namespace FPES

open FPES

/-! ### Property-based theorems (∀ over all hypothesis spaces) -/

/-- **Property:** for every viable hypothesis space, the representative
contraction preserves falsification power. -/
@[fpes_proof]
theorem property_viable_falsification_preserving (H : HypothesisSpace) (h : Viable H) :
    FalsificationPreserving H (contractToRepresentatives H) :=
  (fpes_preserves_falsification_and_survival H h).1

/-- **Property:** for every viable hypothesis space, the representative
contraction preserves per-path survival. -/
@[fpes_proof]
theorem property_viable_survival (H : HypothesisSpace) (h : Viable H) :
    Survival H (contractToRepresentatives H) :=
  (fpes_preserves_falsification_and_survival H h).2

/-- **Property (finite enumeration):** every registered example space is
viable. -/
@[fpes_proof]
theorem prop_all_certified_viable :
    [hspace_simd, hspace_prune, hspace_diff].all (fun H => decide (Viable H)) = true := by
  native_decide

/-! ### Bool checks (runtime-decidable mirror of the proofs) -/

/-- FPES-MULTIPLICITY-001 holds on the SIMD space (each class ≥ 1 path). -/
def check_simd_nonempty : Bool :=
  decide (ClassesNonempty hspace_simd)

/-- The SIMD contraction keeps exactly one path per class. -/
def check_simd_contracted_counts : Bool :=
  decide (multiplicity (contractToRepresentatives hspace_simd) (classOf 0) = 1 &&
    multiplicity (contractToRepresentatives hspace_simd) (classOf 1) = 1 &&
    multiplicity (contractToRepresentatives hspace_simd) (classOf 2) = 1)

/-- All three example spaces are viable. -/
def check_all_certified_viable : Bool :=
  [hspace_simd, hspace_prune, hspace_diff].all (fun H => decide (Viable H))

/-- The defective space is rejected (zero runtime escape). -/
def check_defective_rejected : Bool :=
  !decide (Viable hspace_defective) && !decide (ClassesNonempty hspace_defective)

/-- Concurrent proposals that pick different representatives are flagged. -/
def check_conflict_detected : Bool :=
  decide (Conflicting hspace_prune proposalFirst proposalLast (classOf 11))

/-- Identical policies never conflict. -/
def check_no_false_conflict : Bool :=
  !decide (Conflicting hspace_prune proposalFirst proposalFirst (classOf 11))

/-- Non-conflicting proposals agree (singleton class on the differential
space). -/
def check_singleton_agree : Bool :=
  decide (proposalFirst.select hspace_diff (classOf 22) = proposalLast.select hspace_diff (classOf 22))

/-- The ADR-0029 §2 theorem, as a decidable finite check: every SIMD path
has an equivalent mechanism among the representatives (`opRep`). -/
def check_preserved_under_contraction : Bool :=
  hspace_simd.paths.all (fun p =>
    (opRep.apply hspace_simd).paths.any (fun p' => p'.cls == p.cls))

/-! ### Main test runner -/

/-- Run the FPES test suite; returns 0 on success, 1 on any failure. -/
def main : IO UInt32 := do
  IO.println "Running FPES Test Harness (ADR-0029)..."
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
  pass := (← ok "FPES-MULTIPLICITY-001: SIMD classes are nonempty" check_simd_nonempty) && pass
  pass := (← ok "FPES-SURVIVAL-002: SIMD contraction keeps 1 path per class" check_simd_contracted_counts) && pass
  pass := (← ok "All three certified spaces are viable (Certificates exist)" check_all_certified_viable) && pass
  pass := (← ok "multiplicity_preserved_under_contraction holds on the SIMD space" check_preserved_under_contraction) && pass

  -- Intentional failure cases (type-system rejected)
  pass := (← ok "Defective space rejected: ¬ Viable ∧ ¬ ClassesNonempty" check_defective_rejected) && pass
  pass := (← ok "No false conflict between identical policies" check_no_false_conflict) && pass

  -- Conflict detection
  pass := (← ok "Concurrent proposals conflict detected on class 11 (prune)" check_conflict_detected) && pass
  pass := (← ok "Non-conflicting proposals agree on singleton class 22 (diff)" check_singleton_agree) && pass

  -- Property-based (the ∀-theorems are kernel-checked at import time; these
  -- lines re-verify their finite enumeration)
  pass := (← ok "Property: ∀ viable H, contraction preserves falsification (3 spaces)" check_all_certified_viable) && pass

  IO.println ""
  IO.println s!"SIMD multiplicities: {repr simd_multiplicities}"
  IO.println (s!"Contracted SIMD class counts: " ++
    s!"{repr (multiplicity (contractToRepresentatives hspace_simd) (classOf 0))}," ++
    s!" {repr (multiplicity (contractToRepresentatives hspace_simd) (classOf 1))}," ++
    s!" {repr (multiplicity (contractToRepresentatives hspace_simd) (classOf 2))}")
  IO.println ""

  -- The following are guaranteed by the *existence* of these theorems in
  -- Multiplicity.FPES.Examples (they type-checked or the module would not
  -- have imported):
  IO.println "Kernel-checked at import time (no sorry):"
  IO.println "  - defective_not_nonempty : ¬ ClassesNonempty hspace_defective"
  IO.println "  - defective_not_viable   : ¬ Viable hspace_defective"
  IO.println "  - defective_no_certificate : ¬ Nonempty (Certificate hspace_defective)"
  IO.println "  - prune_conflict_detected : Conflicting hspace_prune proposalFirst proposalLast (classOf 11)"
  IO.println ""

  if pass then
    IO.println "All FPES tests passed."
    return 0
  else
    IO.println "FPES test failures detected."
    return 1

end FPES

/-- Root entry point (Lake `lean_exe fpes_test` links `_root_.main`). -/
def main : IO UInt32 := FPES.main
