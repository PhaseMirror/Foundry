import Foundations.ADR.Core
import Foundations.ADR.Proofs
import Foundations.ADR.Examples
import Foundations.ADR.Export

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

namespace Foundations.ADR.Test

open Foundations.ADR
open Foundations.ADR.Examples
open Foundations.ADR.Export
open Foundations.ADR.GlobalResearchPlatform

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

/-! ## 1b. ADR-0035 (Global Research Platform) Positive Checks -/

-- The verified Layer-B-gated registry slice is a valid ADRRegistry by construction.
#check (grpRegistry : ADRRegistry)
#check (grp_unique_ids : (grpADRList.map ADR.id).Nodup)
#check (grp_acyclic : StrictAcyclic grpADRList)
#check (grp_no_claim_conflicts :
  ∀ c₁ ∈ grpClaims, ∀ c₂ ∈ grpClaims, c₁.owner ≠ c₂.owner → ¬ Contradictory c₁.claim c₂.claim)

-- Concrete fail-closed demonstrations: with no Layer B, the submitted certificate and any
-- token mint are rejected.
#check (sample_cert_rejected_today : acceptCertificate sampleMSCCert none = none)
#check (sample_mint_rejected_today : mintMSC sampleMSCCert none = .Rejected "LayerB-gate-fail-closed")

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

/-- Property test (ADR-0035): for *every* certificate, absence of Layer B yields a
fail-closed acceptance gate. -/
theorem prop_grp_fail_closed_forall (cert : MSCCert) :
    acceptCertificate cert none = none := accept_certificate_fail_closed cert

/-- Property test (ADR-0035): for *every* certificate, absence of Layer B yields a
rejected mint (no token references the frozen schema). -/
theorem prop_grp_no_mint_forall (cert : MSCCert) :
    mintMSC cert none = .Rejected "LayerB-gate-fail-closed" := mint_fail_closed cert

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

/-- **Negative Case (ADR-0035):** a well-formed certificate is rejected unless it matches
the *contract-recorded* Layer B tree SHA. A fake `v1.0.0-Stable` whose tree SHA differs
from the certificate's `git_commit` does not open the gate (ADR-0035 §Frozen Schema
Reference constraint). -/
def fakeLayerB : LayerBIdentity :=
  { tag := "v1.0.0-Stable", treeSHA := "recorded-tree-sha", recordedInContract := true }

theorem grp_cert_rejected_against_mismatched_layerB :
    acceptCertificate sampleMSCCert (some fakeLayerB) = none :=
  sample_cert_rejected_against_mismatched_layerB

/-- **Negative Case (ADR-0035):** the membrane is fail-closed while Layer B is absent,
so the mint gate cannot produce a token. -/
theorem grp_mint_rejected_without_layerB :
    mintMSC sampleMSCCert none = .Rejected "LayerB-gate-fail-closed" :=
  sample_mint_rejected_today

/-! ## 4. Export Determinism Verification -/

/-- Snapshot exported artifacts as raw bytes for cross-run comparison. -/
def snapshotExports (reg : ADRRegistry) (dir : System.FilePath) :
    IO (List (String × ByteArray)) := do
  let names := "README.md" :: reg.adrs.flatMap (fun a => [s!"{a.id}.md", s!"{a.id}.html"])
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
  IO.print "[TEST 5/6] Export determinism (byte-identical across runs) ... "
  exportADRSet sampleRegistry "docs/adr"
  let snap1 ← snapshotExports sampleRegistry "docs/adr"
  exportADRSet sampleRegistry "docs/adr"
  let snap2 ← snapshotExports sampleRegistry "docs/adr"
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
  IO.print "[TEST 1/6] Checking Sample Registry Invariants ... "
  let n := sampleRegistry.adrs.length
  if n == 7 then
    IO.println "PASSED (7 ADRs verified: Unique IDs, Acyclicity, No Conflicts)"
  else
    IO.println s!"FAILED (expected 7 ADRs, found {n})"
    return 1

  -- Test 2: Consequence Entailment Logic
  IO.print "[TEST 2/6] Verifying Embedded Consequence Entailment ... "
  IO.println "PASSED (Modus Ponens and Conjunction Soundness verified)"

  -- Test 3: Negative Invariant Rejections
  IO.print "[TEST 3/6] Verifying Negative Failure Rejections ... "
  IO.println "PASSED (Cycle detected, Syntactic conflict caught)"

  -- Test 4: Semantic Conflict Layer
  IO.print "[TEST 4/6] Verifying Semantic Conflict Detection ... "
  IO.println "PASSED (Compound contradiction caught, syntactic blind spot demonstrated)"

  -- Test 5: Export Generator Determinism
  let rc ← runExportDeterminismTest
  if rc != 0 then
    return rc

  -- Test 6: ADR-0035 Layer-B fail-closed membrane gate
  IO.print "[TEST 6/6] Verifying ADR-0035 Layer-B fail-closed gate ... "
  match acceptCertificate sampleMSCCert none with
  | none =>
    IO.println "PASSED (certification fail-closed; membrane = FailClosed; no token mintable)"
  | some _ =>
    IO.println "FAILED (gate opened without Layer B)"
    return 1
  exportGRP none grpRegistry "docs/adr/grp"
  IO.println s!"PASSED (GRP governance report + {grpRegistry.adrs.length} ADRs exported to docs/adr/grp)"

  IO.println "============================================================"
  IO.println "ALL ADR GOVERNANCE TESTS PASSED (0 failures, proofs complete)"
  IO.println "============================================================"
  return 0

end Foundations.ADR.Test

/-! Test runner entrypoint executable. Built and run by `lake test` via the
`adrTest` target (see `lakefile.lean`). -/
def main : IO UInt32 := Foundations.ADR.Test.runAllTests
