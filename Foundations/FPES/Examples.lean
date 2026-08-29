import Foundations.FPES.Core
import Foundations.FPES.Proofs

/-!
# FPES Examples — realistic hypothesis spaces (ADR-0029 Phase 2)

Three realistic FPES hypothesis spaces, each certified with a machine-checked
`Certificate`:

1. `hspace_simd` — SIMD vector-kernel selection: 8 experiment paths across
   3 mechanism classes (`normalize`, `project`, `contract`), at the ADR's
   `|Paths| ≤ 8` Kani bound.
2. `hspace_prune` — multiplicity pruning: 6 paths across 3 classes, with a
   non-empty first/last disagreement to exercise conflict detection.
3. `hspace_diff` — differential-experiment selection: 5 paths across 3
   classes including a singleton class (single path ⇒ `selectFirst` and
   `selectLast` agree — the non-conflict case).

Plus `hspace_defective`, an intentionally invalid space (a class with **zero**
paths) that the type system rejects: `¬ Viable hspace_defective` and
`¬ Nonempty (Certificate hspace_defective)` — this is the ADR-0029
"zero runtime escape" property demonstrated on a concrete artifact.

All invariants are discharged with `native_decide` (kernel-computed), so no
`-- TODO: replace sorry` appears anywhere.  The same three spaces drive the Kani harnesses
(`Multiplicity/kani/src/proofs/fpes.rs`) at the bounded level.
-/

namespace FPES

open FPES

/-! ### Constructors for readable literals -/

/-- An equivalence class literal. -/
def classOf (n : Nat) : EquivalenceClass := { id := n }

/-- A path literal: `pathOf id cls`. -/
def pathOf (id cls : Nat) : Path := { id := id, cls := cls }

/-! ### Space 1: SIMD vector-kernel selection (|Paths| = 8 ≤ 8) -/

/-- SIMD kernel selection: each class corresponds to a kernel family; the
space carries several selection trajectories per family (multiple SIMD
layouts probe the same mechanism). -/
@[fpes_adr]
def hspace_simd : HypothesisSpace := {
  paths := [
    pathOf 0 0, pathOf 1 0, pathOf 2 0,   -- normalize variants
    pathOf 3 1, pathOf 4 1,               -- project variants
    pathOf 5 2, pathOf 6 2, pathOf 7 2    -- contract variants
  ]
  classes := [classOf 0, classOf 1, classOf 2]
}

/-- SIMD classes are unique. -/
@[fpes_proof]
theorem simd_nodup : NoDupClasses hspace_simd := by
  native_decide

/-- SIMD classes are registered (every path routes to a class). -/
@[fpes_proof]
theorem simd_registered : Registered hspace_simd := by
  native_decide

/-- SIMD classes are all nonempty — FPES-MULTIPLICITY-001 holds. -/
@[fpes_proof]
theorem simd_nonempty : ClassesNonempty hspace_simd := by
  native_decide

/-- A machine-checked certificate for the SIMD space. -/
@[fpes_adr]
theorem cert_simd : Certificate hspace_simd :=
  ⟨⟨simd_nodup, simd_registered, simd_nonempty⟩⟩

/-- The class multiplicities of the SIMD space, as a queryable table. -/
def simd_multiplicities : List (Nat × Nat) :=
  [(0, multiplicity hspace_simd (classOf 0)),
   (1, multiplicity hspace_simd (classOf 1)),
   (2, multiplicity hspace_simd (classOf 2))]

/-! ### Space 2: multiplicity pruning (6 paths, 3 classes) -/

/-- Multiplicity pruning: experiment selection that prunes redundant paths
per mechanism class before Kani-verification of the pruned kernel. -/
@[fpes_adr]
def hspace_prune : HypothesisSpace := {
  paths := [
    pathOf 0 10, pathOf 1 10,
    pathOf 2 11, pathOf 3 11,
    pathOf 4 12, pathOf 5 12
  ]
  classes := [classOf 10, classOf 11, classOf 12]
}

/-- The pruning space is viable (certificate). -/
@[fpes_adr]
theorem cert_prune : Certificate hspace_prune :=
  ⟨by native_decide⟩

/-! ### Space 3: differential experiments (5 paths, singleton class) -/

/-- Differential-experiment selection: two probes per family plus one
singleton family (`class 22`) used to demonstrate the non-conflict case. -/
@[fpes_adr]
def hspace_diff : HypothesisSpace := {
  paths := [
    pathOf 0 20, pathOf 1 20,
    pathOf 2 21, pathOf 3 21,
    pathOf 4 22
  ]
  classes := [classOf 20, classOf 21, classOf 22]
}

/-- The differential space is viable (certificate). -/
@[fpes_adr]
theorem cert_diff : Certificate hspace_diff :=
  ⟨by native_decide⟩

/-! ### Contraction on the certified spaces -/

/-- **Representative contraction preserves falsification on the SIMD space:**
every SIMD class stays nonempty after contracting to one path per class. -/
@[fpes_proof]
theorem simd_contraction_preserves_falsification :
    FalsificationPreserving hspace_simd (contractToRepresentatives hspace_simd) :=
  certificate_sound hspace_simd cert_simd |>.1

/-- **Survival on the SIMD space:** every SIMD path has an equivalent
survivor after contraction. -/
@[fpes_proof]
theorem simd_contraction_survival :
    Survival hspace_simd (contractToRepresentatives hspace_simd) :=
  certificate_sound hspace_simd cert_simd |>.2

/-- The contracted SIMD space keeps exactly one path per class. -/
@[fpes_proof]
theorem simd_contracted_class_counts :
    multiplicity (contractToRepresentatives hspace_simd) (classOf 0) = 1 ∧
    multiplicity (contractToRepresentatives hspace_simd) (classOf 1) = 1 ∧
    multiplicity (contractToRepresentatives hspace_simd) (classOf 2) = 1 := by
  native_decide

/-! ### Intentional failure cases (the type system rejects them) -/

/-- A defective space: class `2` is registered but has **zero** paths.  No
`Certificate hspace_defective` can exist — the FPES pipeline refuses it. -/
@[fpes_adr]
def hspace_defective : HypothesisSpace := {
  paths := [pathOf 0 0, pathOf 1 0, pathOf 2 1, pathOf 3 1]
  classes := [classOf 0, classOf 1, classOf 2]
}

/-- The defective space violates FPES-MULTIPLICITY-001. -/
@[fpes_proof]
theorem defective_not_nonempty : ¬ ClassesNonempty hspace_defective := by
  native_decide

/-- The defective space is not viable, hence carries no certificate: the
type system blocks admission (zero runtime escape). -/
@[fpes_proof]
theorem defective_not_viable : ¬ Viable hspace_defective := by
  native_decide

/-- No certificate term exists for the defective space. -/
@[fpes_proof]
theorem defective_no_certificate : ¬ Nonempty (Certificate hspace_defective) := by
  intro h
  rcases h with ⟨cert⟩
  exact defective_not_viable cert.viable

/-! ### Concurrent proposals and conflict detection -/

/-- `lastPath l c`: the last path of `l` probing class `c` (recursing to the
tail first), or `none`. -/
def lastPath : List Path → EquivalenceClass → Option Path
  | [], _ => none
  | p :: rest, c =>
      match lastPath rest c with
      | some q => some q
      | none => if p.cls = c.id then some p else none

/-- The `first` selection policy: keep the first path of each class. -/
@[fpes_adr]
def proposalFirst : Proposal :=
  { name := "first", select := fun H c => firstPath H.paths c }

/-- The `last` selection policy: keep the last path of each class. -/
@[fpes_adr]
def proposalLast : Proposal :=
  { name := "last", select := fun H c => lastPath H.paths c }

/-- **Conflict detected:** on the pruning space, the `first` and `last`
policies pick *different* representatives for the (multi-path) class `11` —
a real concurrent conflict the type system flags. -/
@[fpes_proof]
theorem prune_conflict_detected :
    Conflicting hspace_prune proposalFirst proposalLast (classOf 11) := by
  native_decide

/-- **No false conflict:** two identical policies never conflict. -/
@[fpes_proof]
theorem same_policy_no_conflict :
    ¬ Conflicting hspace_prune proposalFirst proposalFirst (classOf 11) := by
  native_decide

/-- **Non-conflicting proposals agree** (application of `both_select_agree`):
on the differential space, the singleton class `22` admits exactly one
representative, so `first` and `last` coincide. -/
@[fpes_proof]
theorem diff_singleton_agree :
    proposalFirst.select hspace_diff (classOf 22) = proposalLast.select hspace_diff (classOf 22) := by
  apply both_select_agree hspace_diff proposalFirst proposalLast (classOf 22)
  · native_decide
  · native_decide
  · native_decide

end FPES
