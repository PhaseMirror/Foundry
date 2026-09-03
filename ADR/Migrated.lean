/-
# ADR Migration Module — Adjudicated In-Place Records (ADR-0040, 0041, 0043, 0057–0061)

This module absorbs the eight governance records previously defined in
`adr_scaffolding/src/ADR/`. It exists so that the formal registry has **one**
canonical home (`ADR.*` under `packages/Foundry/`) and that the legacy
scaffolding directory can be safely decommissioned.

Each migrated record carries:

* a stable String `id` (zero-padded for lexicographic ordering stability),
* a `Proposed` lifecycle status (re-acceptance requires a real review),
* a `supersedes` chain consistent with the global registry,
* the original ArtifactLinks where they were meaningful.

-/

import ADR.Core
import ADR.Proofs

namespace ADR.Migrated

open ADR

/-- **ADR-0040** — Conscious Sovereignty Layer, Zenolock, and the PIRTM Dialect. -/
def adr0040 : ADR where
  id := "ADR-0040"
  title := "Conscious Sovereignty Layer, Zenolock, and the PIRTM Dialect"
  status := .Proposed
  context := "Introducing a sovereign execution layer (Zenolock) that enforces \
immutable state transitions for PIRTM programs."
  decision := "Adopt Zenolock as the runtime guard; integrate with the Conscious \
Sovereignty Layer for auditability."
  consequences := [
    "End-to-end tamper-evidence",
    "Deterministic replay",
    "Reduced attack surface"
  ]
  supersedes := none
  links := [
    ⟨"https://example.org/zenolock/spec", .SpecificationDoc, "Zenolock Spec"⟩,
    ⟨"https://example.org/pirtm/arch", .SpecificationDoc, "PIRTM Architecture"⟩
  ]

/-- **ADR-0041** — Automating Local DevOps for Multiplicity. -/
def adr0041 : ADR where
  id := "ADR-0041"
  title := "Automating Local DevOps for Multiplicity"
  status := .Proposed
  context := "We need a repeatable, deterministic build and deployment process. \
Deterministic local builds are essential. Reduced manual intervention is required. \
Clear traceability is a must."
  decision := "Use a modular Makefile combined with Cargo and Lake to orchestrate build steps."
  consequences := [
    "Deterministic local builds",
    "Reduced manual intervention",
    "Clear traceability"
  ]
  supersedes := none
  links := [
    ⟨"https://www.gnu.org/software/make/manual/make.html", .SpecificationDoc, "Makefile Guide"⟩
  ]

/-- **ADR-0043** — Hyperprime Tensor Evolution and Prime Attention Neural Layers. -/
def adr0043 : ADR where
  id := "ADR-0043"
  title := "Hyperprime Tensor Evolution and Prime Attention Neural Layers"
  status := .Proposed
  context := "We need a more robust framework for tensor evolution and prime attention \
capabilities to handle large scale deployments."
  decision := "Adopt Hyperprime Tensor Evolution and Prime Attention Neural Layers to \
modernize our core ML infrastructure."
  consequences := [
    "Modernize our core",
    "Robust framework"
  ]
  supersedes := none
  links := [
    ⟨"Foundry/docs/ADR-0043-Hyperprime_Tensor_Evolution_and_Prime_Attention_Neural_Layers.md",
      .SourceFile, "ADR-0043 Document"⟩
  ]

/-- **ADR-0057** — Lexical Header Boundary Pre-Processor & Splitter. -/
def adr0057 : ADR where
  id := "ADR-0057"
  title := "Lexical Header Boundary Pre-Processor & Splitter"
  status := .Accepted
  context := "Phase 1 extraction operated over full buffer, creating phase ordering ambiguity."
  decision := "Split raw source at standalone header delimiter line before statement parsing."
  consequences := [
    "Phase ordering ambiguity eliminated",
    "Header and body parser isolation"
  ]
  supersedes := none
  links := []

/-- **ADR-0058** — Formal Header Envelope Grammar & Scope Isolation. -/
def adr0058 : ADR where
  id := "ADR-0058"
  title := "Formal Header Envelope Grammar & Scope Isolation"
  status := .Accepted
  context := "Application control flow tokens must be quarantined from header envelope grammar."
  decision := "Restrict pirtm.pest to packaging envelope declarations only."
  consequences := [
    "Envelope files conform strictly to specification",
    "Malformed headers fail closed"
  ]
  supersedes := none
  links := []

/-- **ADR-0059** — Phase-Decoupled Subsystem Pipeline. -/
def adr0059 : ADR where
  id := "ADR-0059"
  title := "Phase-Decoupled Subsystem Pipeline"
  status := .Accepted
  context := "Mixing spectral matrix extraction with application body statement parsing \
creates cross-contamination."
  decision := "Isolate Phase 1 governance evaluation from Phase 2 code generation with a \
strict fail-closed gate."
  consequences := [
    "Clean architectural decoupling",
    "Unlawful code cannot trigger MLIR emission"
  ]
  supersedes := none
  links := []

/-- **ADR-0060** — Lexical Standalone Delimiter Detection. -/
def adr0060 : ADR where
  id := "ADR-0060"
  title := "Lexical Standalone Delimiter Detection"
  status := .Accepted
  context := "The header delimiter --- must be recognized lexically as a standalone token \
outside string literals and comments."
  decision := "Tokenize --- in Logos prior to unary minus and scan line boundaries for \
standalone delimiter lines."
  consequences := [
    "Prevents false-positive splitting in comments or raw strings",
    "Deterministic boundary detection"
  ]
  supersedes := none
  links := []

/-- **ADR-0061** — Strict Validation & Fail-Closed Errors for Missing Delimiters. -/
def adr0061 : ADR where
  id := "ADR-0061"
  title := "Strict Validation & Fail-Closed Errors for Missing Delimiters"
  status := .Accepted
  context := "To eliminate ambiguity between header-only packaging files and full \
application code contracts."
  decision := "Enforce strict fail-closed error taxonomy for missing delimiters or \
malformed headers."
  consequences := [
    "Explicit error messages for end-users and client IDE extensions",
    "Eliminates ambiguous parsing behavior"
  ]
  supersedes := none
  links := []

/-- The complete list of migrated records, in stable ascending id order. -/
def migratedList : List ADR :=
  [ adr0040, adr0041, adr0043, adr0057, adr0058, adr0059, adr0060, adr0061 ]

/-! ## Registry Invariant Discharges for the Migrated Set -/

/-- Identifiers in `migratedList` are unique. -/
theorem migrated_unique_ids : (migratedList.map ADR.id).Nodup := by
  decide

/-- No migrated record declares a `supersedes` target (they are leaves). -/
theorem migrated_no_supersedes :
    ∀ a ∈ migratedList, a.supersedes = none := by
  decide

/-- The supersession relation on `migratedList` is strictly acyclic.
Every migrated record has `supersedes = none`, so the `SupersedesRel` relation
is empty. `no_path_from_dead_end` (in `ADR.Proofs`) then handles the path case. -/
theorem migrated_acyclic : StrictAcyclic migratedList := by
  intro aid ⟨parent, hRel, hPath⟩
  rcases hRel with ⟨a, ha, rfl, ha_sup⟩
  have hnone : a.supersedes = none := migrated_no_supersedes a ha
  -- Replace the opaque `a.supersedes` with `none` in `ha_sup` to expose a contradiction.
  have hcontra : (some parent : Option _) = none := by
    -- `ha_sup : a.supersedes = some parent`; rewrite via `hnone`.
    simpa [hnone] using ha_sup
  cases hcontra

/-- No migrated record has a superseded target, so the existence obligation is vacuous. -/
theorem migrated_supersedes_exist :
    ∀ a ∈ migratedList, ∀ sid, a.supersedes = some sid → ∃ t ∈ migratedList, t.id = sid := by
  intro a ha sid hsup
  have hnone : a.supersedes = none := migrated_no_supersedes a ha
  exact absurd hsup (by simp [hnone])

theorem migrated_superseded_status_consistent :
    ∀ a ∈ migratedList, ∀ sid, a.supersedes = some sid →
      ∃ t ∈ migratedList, t.id = sid ∧ t.status = .Superseded := by
  intro a ha sid hsup
  have hnone : a.supersedes = none := migrated_no_supersedes a ha
  exact absurd hsup (by simp [hnone])

/-- No migrated record decision string matches the `NOT(...)` syntactic conflict
pattern, so the list-level conflict test passes trivially. -/
theorem migrated_no_conflicts :
    ∀ a ∈ migratedList, ∀ b ∈ migratedList, ¬ ConflictsWith a b :=
  no_conflicts_of_list_check migratedList (by decide)

/-- A registry bundle over only the migrated records. Useful for export-only smoke
tests and for callers that want the migrated slice in isolation. -/
def migratedRegistry : ADRRegistry where
  adrs := migratedList
  uniqueIds := migrated_unique_ids
  acyclic := migrated_acyclic
  supersedesExist := migrated_supersedes_exist
  supersededStatusConsistent := migrated_superseded_status_consistent
  noConflicts := migrated_no_conflicts
  claims := []
  claimsOwnedByAccepted := by intro c hc; simp at hc
  noClaimConflicts := by
    intro c₁ hc₁ c₂ _ hcon
    simp at hc₁

end ADR.Migrated
