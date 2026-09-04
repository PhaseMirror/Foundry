import ADR.Core
import ADR.Proofs
import ADR.Examples
import ADR.Migrated
import ADR.Export

/-!
# Architecture Decision Records (ADR) — Test Harness

This module implements the runnable test harness and property verification suite for ADRs.
It checks:
1. Positive validation of sample production records and registry invariants.
2. Invariant preservation under supersession lifecycle transitions.
3. Property-based verification over finite test suites.
4. Intentional negative failure cases caught by Lean's type system and computable deciders.
5. Export pipeline execution to `docs/adr/`.
-/

namespace ADR.Test

open ADR
open ADR.Examples
open ADR.Export

/-! ## 1. Positive Type-Checked Tests -/

-- Verify that the sample registry satisfies all invariants by construction
#check (sampleRegistry : ADRRegistry)
#check (sample_unique_ids : (sampleADRList.map ADR.id).Nodup)
#check (sample_acyclic : StrictAcyclic sampleADRList)
#check (adr001_consequence_entailment : Entails [adr001_P, .implies adr001_P adr001_Q] adr001_Q)
#check (adr004_consequence_entailment : Entails [adr004_P, .implies adr004_P adr004_Q] adr004_Q)
#check (adr005_consequence_entailment : Entails [adr005_P, .implies adr005_P adr005_Q] adr005_Q)
#check (adr006_consequence_entailment : Entails [adr006_P, .implies adr006_P adr006_Q] adr006_Q)
#check (adr007_consequence_entailment : Entails [adr007_P, .implies adr007_P adr007_Q] adr007_Q)
#check (adr008_consequence_entailment : Entails [adr008_P, .implies adr008_P adr008_Q] adr008_Q)
#check (adr009_consequence_entailment : Entails [adr009_P, .implies adr009_P adr009_Q] adr009_Q)
#check (adr010_consequence_entailment : Entails [adr010_P, .implies adr010_P adr010_Q] adr010_Q)

/-! ## 2. Property-Based / Universal Invariant Verification -/

/-- Property test: For all valid transitions from Proposed to Accepted, target supersession is none. -/
theorem prop_proposed_to_accepted_target_none (s' : ADRStatus) (w : Option ADRId)
    (h : ValidTransition .Proposed s' w) (_hAcc : s' = .Accepted) :
    w = none := by
  cases h with
  | proposeToAccept => rfl
  | proposeToDeprecate => contradiction

/-- Property test: For all valid transitions from Accepted to Superseded, successor ID must be provided. -/
theorem prop_accepted_to_superseded_has_successor (s' : ADRStatus) (w : Option ADRId)
    (h : ValidTransition .Accepted s' w) (_hSup : s' = .Superseded) :
    ∃ nid, w = some nid := by
  cases h with
  | acceptToSupersede nid => exact ⟨nid, rfl⟩
  | acceptToDeprecate => contradiction

/-! ## 3. Intentional Failure Cases (Caught at Verification Boundary) -/

/-- Negative Case 1: Attempting to create a self-superseding record is provably rejected. -/
def cyclicSelfADR : ADR where
  id := "ADR-FAIL-01"
  title := "Illegal Cyclic Self-Supersession"
  status := .Accepted
  context := "Testing cycle detection."
  decision := "Supersede self directly."
  consequences := []
  supersedes := some "ADR-FAIL-01"
  links := []

theorem cyclic_self_is_not_acyclic :
    ¬ StrictAcyclic [cyclicSelfADR] := by
  intro hAcyclic
  have hRel : SupersedesRel [cyclicSelfADR] "ADR-FAIL-01" "ADR-FAIL-01" := by
    exact ⟨cyclicSelfADR, by simp [cyclicSelfADR], rfl, rfl⟩
  have hCycle : ∃ parent, SupersedesRel [cyclicSelfADR] "ADR-FAIL-01" parent ∧
                          ProvenancePath [cyclicSelfADR] parent "ADR-FAIL-01" :=
    ⟨"ADR-FAIL-01", hRel, ProvenancePath.refl "ADR-FAIL-01"⟩
  exact hAcyclic "ADR-FAIL-01" hCycle

/-- Negative Case 2: Conflicting accepted decisions are caught by `ConflictsWith`. -/
def adrConflictingA : ADR where
  id := "ADR-900"
  title := "Mutate Engine Invariant A"
  status := .Accepted
  context := "Context"
  decision := "EnableDistributedWrites"
  consequences := []
  supersedes := none
  links := []

def adrConflictingB : ADR where
  id := "ADR-901"
  title := "Mutate Engine Invariant B"
  status := .Accepted
  context := "Context"
  decision := "NOT(EnableDistributedWrites)"
  consequences := []
  supersedes := none
  links := []

theorem intentional_conflict_detected :
    ConflictsWith adrConflictingA adrConflictingB := by
  refine ⟨by decide, rfl, rfl, Or.inr rfl⟩

/-- **Negative Case 3: Compound-formula contradictions are caught semantically.**
The claims `WritesEnabled ∧ AuditEnabled` and `¬WritesEnabled` cannot hold
jointly under any environment. -/
def compoundClaimA : PropTerm :=
  .and (.atom "EnableDistributedWrites") (.atom "AuditLogEnabled")

def compoundClaimB : PropTerm :=
  .not (.atom "EnableDistributedWrites")

theorem compound_claims_contradictory :
    Contradictory compoundClaimA compoundClaimB := by
  intro env hconj
  simp only [compoundClaimA, compoundClaimB, PropTerm.evalB] at hconj
  cases h : env "EnableDistributedWrites" with
  | false => rw [h] at hconj; simp at hconj
  | true => rw [h] at hconj; simp at hconj

/-- The *same* pair of decisions passes the syntactic `ConflictsWith` check —
neither decision string is shaped `NOT(...)`. This is precisely the gap the
semantic claim layer closes: only the registry-level `noClaimConflicts`
invariant rejects this pair. -/
def adrCompoundA : ADR where
  id := "ADR-910"
  title := "Distributed Writes With Audit Log"
  status := .Accepted
  context := "Negative test context."
  decision := "EnableDistributedWrites AND AuditLogEnabled"
  consequences := []
  supersedes := none
  links := []

def adrCompoundB : ADR where
  id := "ADR-911"
  title := "Prohibit Distributed Writes"
  status := .Accepted
  context := "Negative test context."
  decision := "NOT EnableDistributedWrites"
  consequences := []
  supersedes := none
  links := []

theorem syntactic_check_misses_compound_conflict :
    ¬ ConflictsWith adrCompoundA adrCompoundB := by
  intro ⟨_, _, _, hdisj⟩
  rcases hdisj with h | h <;>
    exact absurd h (by decide)

/-! ## 4. Export Determinism Verification -/

/-- The union of the production Examples registry and the migrated ADR slice.
This is what `lake test` exports to `docs/adr/`. The merge is order-stable: the
Examples registry is authoritative for IDs 001–010; the migrated slice adds
ADR-0040/0041/0043/0057–0061 with no overlap. -/
def mergedList : List ADR := sampleRegistry.adrs ++ ADR.Migrated.migratedList

/-- IDs in the merged list are unique. The two halves have disjoint ID sets:
Examples uses "ADR-001"…"ADR-010", Migrated uses "ADR-0040/0041/0043/0057-0061".
Discharged by `decide` over the literal list. -/
theorem merged_unique_ids : (mergedList.map ADR.id).Nodup := by
  set_option maxRecDepth 4096 in decide

/-- Acyclicity of the merged list: discharged by induction on the
`ProvenancePath` witness, using the fact that the migration slice has
no `supersedes` edges. The structural induction lifts every step of the
path from `mergedList` to `sampleADRList`, then `sample_acyclic` closes. -/
theorem merged_acyclic : StrictAcyclic mergedList := by
  intro aid ⟨parent, hRel, hPath⟩
  rcases hRel with ⟨a, ham, ha_id, ha_sup⟩
  rcases (List.mem_append.1 ham) with ha | ha
  · -- Examples case: lift the cycle to `sampleADRList` and apply `sample_acyclic`.
    -- The lift relies on the structural induction on `hPath` below.
    have hsrel : SupersedesRel sampleADRList aid parent := ⟨a, ha, ha_id, ha_sup⟩
    -- Lift `hPath : ProvenancePath mergedList parent aid` to
    -- `ProvenancePath sampleADRList parent aid` by induction.
    -- Pin the `adrs` parameter so unification lands on `sampleADRList`.
    have hpath' : ProvenancePath sampleADRList parent aid :=
      ProvenancePath.rec
        (motive := fun a b _p => ProvenancePath sampleADRList a b)
        (fun x => ProvenancePath.refl (adrs := sampleADRList) x)
        (fun child inter _parent hRelStep hPathTail ih =>
          match hRelStep with
          | ⟨a', ham', ha'_id, ha'_sup⟩ =>
            match List.mem_append.1 ham' with
            | Or.inl ha' => ProvenancePath.step child inter _ ⟨a', ha', ha'_id, ha'_sup⟩ ih
            | Or.inr ha'' =>
              have hnone : a'.supersedes = none := ADR.Migrated.migrated_no_supersedes a' ha''
              False.elim (by simp [hnone] at ha'_sup))
        hPath
    exact sample_acyclic aid ⟨parent, hsrel, hpath'⟩
  · -- Migration case: no record in the migration slice has a `supersedes` edge.
    have hnone : a.supersedes = none := ADR.Migrated.migrated_no_supersedes a ha
    exact False.elim (by simp [hnone] at ha_sup)

/-- Existence of superseded targets: discharged by hand. -/
theorem merged_supersedes_exist :
    ∀ a ∈ mergedList, ∀ sid, a.supersedes = some sid → ∃ t ∈ mergedList, t.id = sid := by
  intro a ham sid hsup
  rcases (List.mem_append.1 ham) with ha | ha
  · rcases sample_supersedes_exist a ha sid hsup with ⟨t, ht, hid⟩
    exact ⟨t, List.mem_append_left _ ht, hid⟩
  · have hnone : a.supersedes = none := ADR.Migrated.migrated_no_supersedes a ha
    exact False.elim (by simp [hnone] at hsup)

/-- Superseded status consistency: discharged by hand. -/
theorem merged_superseded_status_consistent :
    ∀ a ∈ mergedList, ∀ sid, a.supersedes = some sid →
      ∃ t ∈ mergedList, t.id = sid ∧ t.status = .Superseded := by
  intro a ham sid hsup
  rcases (List.mem_append.1 ham) with ha | ha
  · rcases sample_superseded_status_consistent a ha sid hsup with ⟨t, ht, hid, hst⟩
    exact ⟨t, List.mem_append_left _ ht, hid, hst⟩
  · have hnone : a.supersedes = none := ADR.Migrated.migrated_no_supersedes a ha
    exact False.elim (by simp [hnone] at hsup)

/-- The merged registry, with all invariants discharged by explicit proof. -/
def mergedRegistry : ADRRegistry where
  adrs := mergedList
  uniqueIds := merged_unique_ids
  acyclic := merged_acyclic
  supersedesExist := merged_supersedes_exist
  supersededStatusConsistent := merged_superseded_status_consistent
  noConflicts := no_conflicts_of_list_check mergedList (by set_option maxRecDepth 4096 in decide)
  claims := sampleRegistry.claims
  claimsOwnedByAccepted := by
    intro c hc
    rcases sample_claims_owned_by_accepted c hc with ⟨a, ha, hid, hst⟩
    exact ⟨a, List.mem_append_left _ ha, hid, hst⟩
  noClaimConflicts := by
    intro c₁ hc₁ c₂ hc₂ _ hcon
    have h1 : c₁.claim.evalB envP2C = true := sample_claim_eval_true c₁ hc₁
    have h2 : c₂.claim.evalB envP2C = true := sample_claim_eval_true c₂ hc₂
    have hJoint : (c₁.claim.evalB envP2C && c₂.claim.evalB envP2C) = true := by
      simp [h1, h2]
    exact hcon envP2C hJoint

/-- Snapshot exported artifacts as raw bytes for cross-run comparison. -/
def snapshotExports (reg : ADRRegistry) (dir : System.FilePath) :
    IO (List (String × ByteArray)) := do
  let names := "README.md" :: "registry.json" :: reg.adrs.flatMap (fun a => [s!"{a.id}.md", s!"{a.id}.html", s!"{a.id}.json"])
  let mut snaps : List (String × ByteArray) := []
  for n in names do
    let bytes ← IO.FS.readBinFile (dir / n)
    snaps := (n, bytes) :: snaps
  return snaps.reverse

/-- **TEST: Export determinism.** Two consecutive runs of `exportADRSet` must
produce byte-for-byte identical output. This is the local counterpart of the
CI gate `git diff --exit-code docs/adr/`: the generator contains no timestamps,
random identifiers, or iteration-order dependence. -/
def runExportDeterminismTest : IO UInt32 := do
  IO.print "[TEST 5/5] Export determinism (byte-identical across runs) ... "
  exportADRSet mergedRegistry "docs/adr"
  let snap1 ← snapshotExports mergedRegistry "docs/adr"
  exportADRSet mergedRegistry "docs/adr"
  let snap2 ← snapshotExports mergedRegistry "docs/adr"
  if snap1.length == 0 then
    IO.println "FAILED (no exported files found)"
    return 1
  for ((n1, b1), (n2, b2)) in snap1.zip snap2 do
    if n1 != n2 || b1 != b2 then
      IO.println s!"FAILED (byte mismatch at {n1})"
      return 1
  IO.println s!"PASSED ({snap1.length} files byte-identical across runs)"
  return 0

/-! ## 5. Test Suite Main Runner -/

def runAllTests : IO UInt32 := do
  IO.println "============================================================"
  IO.println "Running ADR Formal Governance Verification Test Suite"
  IO.println "============================================================"

  -- Test 1: Registry Invariants
  IO.print "[TEST 1/5] Checking Merged Registry Invariants ... "
  let n := mergedRegistry.adrs.length
  if n == 19 then
    IO.println "PASSED (19 ADRs verified: 10 Examples + 9 Migrated; Unique IDs, Acyclicity, No Conflicts)"
  else
    IO.println s!"FAILED (expected 19 ADRs, found {n})"
    return 1

  -- Test 2: Consequence Entailment Logic
  IO.print "[TEST 2/5] Verifying Embedded Consequence Entailment ... "
  IO.println "PASSED (Modus Ponens and Conjunction Soundness verified)"

  -- Test 3: Negative Invariant Rejections
  IO.print "[TEST 3/5] Verifying Negative Failure Rejections ... "
  IO.println "PASSED (Cycle detected, Syntactic conflict caught)"

  -- Test 4: Semantic Conflict Layer
  IO.print "[TEST 4/5] Verifying Semantic Conflict Detection ... "
  IO.println "PASSED (Compound contradiction caught, syntactic blind spot demonstrated)"

  -- Test 5: Export Generator Determinism
  let rc ← runExportDeterminismTest
  if rc != 0 then
    return rc

  IO.println "============================================================"
  IO.println "ALL ADR GOVERNANCE TESTS PASSED (0 failures, proofs complete)"
  IO.println "============================================================"
  return 0

end ADR.Test

/-- Test runner entrypoint executable. -/
def main : IO UInt32 := ADR.Test.runAllTests
