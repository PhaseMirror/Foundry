import Multiplicity.Fold.Proofs

/-!
# Fold Theory Worked Examples — ADR-0032

Concrete, kernel-checked instances of the Fold Theory model: canonical
histories, their seals, their arithmetic multiplicities, a rejected
(unlawful) history, racing extension proposals with conflict detection, a
proof-carrying registry session, and emergent-geometry measurements.

Everything in this module elaborates against the *kernel*: each `theorem`
below is a machine-checked fact, not a runtime assertion.  The companion
`Multiplicity.Fold.Test` harness re-checks these at import time and prints
a summary under `lake run fold_test`.
-/
namespace Fold

/-! ## Canonical histories -/

/-- The sequential pipeline history `A₂ ∘ (A₃ ∘ A₅)` — right-nested
bracketing. -/
@[fold_adr]
def history_pipeline : FoldWord :=
  FoldWord.gen 2 ⊙ (FoldWord.gen 3 ⊙ FoldWord.gen 5)

/-- The parallel-bracketed history `(A₂ ∘ A₃) ∘ A₅` — same flat word as
`history_pipeline`, different generative tree. -/
@[fold_adr]
def history_parallel : FoldWord :=
  (FoldWord.gen 2 ⊙ FoldWord.gen 3) ⊙ FoldWord.gen 5

/-- Four-generator composite `(A₂ ∘ A₃) ∘ (A₅ ∘ A₇)` with disjoint
supports — exercises ν-multiplicativity (ADR-0032 §5). -/
@[fold_adr]
def history_composite : FoldWord :=
  (FoldWord.gen 2 ⊙ FoldWord.gen 3) ⊙ (FoldWord.gen 5 ⊙ FoldWord.gen 7)

/-- An **unlawful** history: `A₂ ∘ A₇` has boundary gap `gap 2 7 = 5 >
θ* = 3`.  The type system admits the word; the closure axioms reject it. -/
@[fold_adr]
def history_unlawful : FoldWord := FoldWord.gen 2 ⊙ FoldWord.gen 7

/-- Bracketing is audited everywhere: an unlawful *inner* node cannot be
rescued by lawful outer bracketing (Lawful Closure).  Here `gap 3 7 = 4 >
θ*`. -/
@[fold_adr]
def history_nested_unlawful : FoldWord :=
  (FoldWord.gen 3 ⊙ FoldWord.gen 7) ⊙ FoldWord.gen 5

/-! ## Non-associativity is preserved by flattening -/

/-- Both bracketings of `[2, 3, 5]` share the same flat prime word. -/
theorem flatten_pipeline : flatten history_pipeline = [2, 3, 5] := rfl

/-- Same flat word for the parallel bracketing. -/
theorem flatten_parallel : flatten history_parallel = [2, 3, 5] := rfl

/-- Yet the histories are distinct terms: **composition is genuinely
non-associative**; the sequential-history tree can never be erased by
re-association. -/
theorem pipeline_ne_parallel : history_pipeline ≠ history_parallel := by
  decide

/-! ## Seals: admissibility of every registered history -/

/-- The pipeline passes the admissibility gate (`Θ = max(2,2) ≤ θ*`). -/
theorem admissible_pipeline : Admissible history_pipeline := by native_decide

/-- The parallel bracketing passes as well. -/
theorem admissible_parallel : Admissible history_parallel := by native_decide

/-- The four-generator composite passes. -/
theorem admissible_composite : Admissible history_composite := by native_decide

/-- The linear criterion agrees with the recursive gate on the pipeline:
only consecutive-pair inspection is needed. -/
theorem pipeline_chainMax_ok : chainMax (flatten history_pipeline) ≤ thetaStar := by
  native_decide

/-- The unlawful history is rejected: its defect is exactly `gap 2 7`,
which evaluates to `5 > θ* = 3`. -/
theorem defect_unlawful_eq : defect history_unlawful = gap 2 7 := rfl

theorem not_admissible_unlawful : ¬ Admissible history_unlawful := by
  intro h
  unfold Admissible at h
  rw [defect_unlawful_eq, show gap 2 7 = 5 from by native_decide,
    show thetaStar = 3 from rfl] at h
  omega

/-- The nested-unlawful history is rejected through its inner node:
`gap 3 7 = 4 > θ*` dominates both boundary terms of the outer node. -/
theorem defect_nested_unlawful_eq :
    defect history_nested_unlawful = max (max (gap 3 7) 0) (gap 7 5) := rfl

theorem not_admissible_nested_unlawful : ¬ Admissible history_nested_unlawful := by
  intro h
  unfold Admissible at h
  rw [defect_nested_unlawful_eq, show gap 3 7 = 4 from by native_decide,
    show gap 7 5 = 2 from by native_decide, show thetaStar = 3 from rfl] at h
  omega

/-- Generator labels must be prime indices: `4` fails the basis invariant,
so no fold word may use it. -/
theorem four_not_valid_gen : ¬ ValidGen 4 := by
  unfold ValidGen PrimeIdx
  rintro ⟨_, hdiv⟩
  have h24 : (2 : Nat) ∣ 4 := ⟨2, by omega⟩
  have h := hdiv 2 h24
  omega

/-! ## Arithmetic multiplicity ν (ADR-0032 §5) -/

/-- ν of the pipeline: divisor-like sub-histories of `[2, 3, 5]` number
`2·2·2 = 8`. -/
theorem nu_pipeline : nu history_pipeline = 8 := by native_decide

/-- Bracketing does not change the arithmetic shadow: the parallel history
has the same multiplicity. -/
theorem nu_parallel : nu history_parallel = 8 := by native_decide

/-- Disjoint supports of the composite's two halves. -/
theorem composite_supports_disjoint :
    ∀ q ∈ flatten (FoldWord.gen 2 ⊙ FoldWord.gen 3),
      countGen (flatten (FoldWord.gen 5 ⊙ FoldWord.gen 7)) q = 0 := by
  intro q hq
  have h23 : q = 2 ∨ q = 3 := by simpa [flatten] using hq
  rcases h23 with rfl | rfl <;> simp [flatten, countGen]

/-- ν multiplies over the disjoint composition — the
Fundamental-Theorem-of-Arithmetic analogue at the level of words. -/
theorem nu_composite_mul :
    nu history_composite
      = nu (FoldWord.gen 2 ⊙ FoldWord.gen 3)
          * nu (FoldWord.gen 5 ⊙ FoldWord.gen 7) :=
  nu_comp_mul _ _ composite_supports_disjoint

/-- Each two-generator half has `ν = 2·2 = 4`. -/
theorem nu_halves : nu (FoldWord.gen 2 ⊙ FoldWord.gen 3) = 4 ∧
    nu (FoldWord.gen 5 ⊙ FoldWord.gen 7) = 4 := by native_decide

/-- Hence the composite has exactly sixteen divisor-like sub-histories,
matching the direct computation. -/
theorem nu_composite : nu history_composite = 16 := by
  rw [nu_composite_mul]
  have ⟨h1, h2⟩ := nu_halves
  rw [h1, h2]

/-! ## Contractive kernel -/

/-- Three kernel folds take state `40` to `5`: strict contraction towards
the stable fixed point. -/
theorem orbit_example : kernOrbit 40 3 = 5 := rfl

/-- The fixed point is absorbing. -/
theorem orbit_fixed_example : kernOrbit 40 6 = 0 := rfl

/-! ## Concurrent proposals and conflicts -/

/-- Racing proposal A: append `A₂` to base `A₃`. -/
def proposalA : Extension := { base := FoldWord.gen 3, next := 2 }

/-- Racing proposal B: append `A₇` to the same base `A₃`. -/
def proposalB : Extension := { base := FoldWord.gen 3, next := 7 }

/-- The proposals conflict: same base, distinct modes, mutually unlawful
(`gap 2 7 = 5 > θ*`). -/
theorem conflictingAB : Conflicting proposalA proposalB :=
  ⟨rfl, by decide, by native_decide⟩

/-- Proposal A itself is a lawful step (`gap 3 2 = 1 ≤ θ*`). -/
theorem proposalA_applies : Applies proposalA := by native_decide

/-- Proposal B is rejected outright (`gap 3 7 = 4 > θ*`). -/
theorem proposalB_rejected : ¬ Applies proposalB := by native_decide

/-- Even after A executes first, B's mode cannot be staged afterwards:
sequencing across conflicting proposals violates the closure axioms. -/
theorem sequencing_blocked :
    ¬ Applies { base := Extension.result proposalA, next := proposalB.next } :=
  conflicting_not_mergeable proposalA proposalB conflictingAB

/-- Identical proposals never conflict (no false positives). -/
theorem no_conflict_with_self : ¬ Conflicting proposalA proposalA :=
  no_self_conflict _

/-! ## Proof-carrying registry session -/

/-- Registration F001: the pipeline history enters the registry sealed.
The `sealProof` field is a proof term — this record could not be built
otherwise. -/
def adrF001 : RegisteredADR :=
  { id := 1, history := history_pipeline, status := .accepted
    sealProof := admissible_pipeline }

/-- Lifecycle transition F001 → deprecated.  Note the record update keeps
`history` and `sealProof` intact: audit trails survive status changes. -/
def adrF001_deprecated : RegisteredADR :=
  { adrF001 with status := .deprecated }

/-- Deprecation never breaks the seal. -/
theorem seal_survives_deprecation :
    Admissible adrF001_deprecated.history := seal_soundness _

/-- Registration F002: the parallel history, independently sealed. -/
def adrF002 : RegisteredADR :=
  { id := 2, history := history_parallel, status := .accepted
    sealProof := admissible_parallel }

/-- The two records govern genuinely different histories despite identical
flat words. -/
theorem records_distinct_histories :
    adrF001.history ≠ adrF002.history := by decide

/-! ### Rejected registration attempt (documentation)

The following does **not** compile — there is no proof term to fill
`sealProof` with:

```lean
def bad : RegisteredADR :=
  { id := 99, history := history_unlawful, status := .accepted
    sealProof := ? }   -- ✗ no term of type `Admissible history_unlawful`
```

The type-level rejection is the whole point of proof-carrying governance:
violating the contract blocks compilation, exactly as in ADR-0029 §
Decision driver 5. -/

/-! ## Emergent geometry d_F (ADR-0032 §6) -/

/-- Pipeline and parallel histories project to the *same* stabilized
configuration: zero emergent distance despite non-associative difference. -/
theorem dPipelineParallelZero :
    dProfile history_pipeline history_parallel = 0 := by native_decide

/-- Distinct profiles are separated: distance `3` from the pipeline to the
unlawful word's profile. -/
theorem dProfile_separated :
    dProfile history_pipeline history_unlawful = 3 := by native_decide

end Fold
