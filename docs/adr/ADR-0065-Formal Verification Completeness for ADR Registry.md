# ADR-0065: Formal Verification Completeness for the ADR Registry

**Status:** Accepted

## Context

The project maintains two parallel ADR governance layers:

1. **Markdown ledger** (`docs/adr/`) — human-readable decision records with Context, Decision, Consequences, and Traceability sections, tracked in `registry.json`.
2. **Lean formal model** (`ADR/`) — machine-checkable types, proofs, and a test harness (`ADR.Test`) that verifies registry invariants (immutability, acyclicity, traceability, non-conflict).

ADR-0010 (Axiom-Clean Kernel Boundary) mandates: *"Zero untracked proof debt is permitted on the main branch."* The `ADR/` test harness is the enforcement mechanism for this policy within the formal governance layer.

**Completed (2026-09-14):** Two of four action items from this ADR have been discharged:

1. ✓ **`sorry` eliminated.** `ADR/Test.lean:16` now uses `all_accepted_acyclic` directly — the acyclicity invariant is now genuinely verified by the test driver.
2. ✓ **ADR-0013 through ADR-0016 formalized.** Added as `def` records in `ADR.Examples.Governance` namespace; `allAcceptedADRs` expanded from 11 to 15 records; all invariant theorems (`all_accepted`, `all_accepted_unique_ids`, `all_accepted_no_supersedes`, `all_accepted_acyclic`, `all_accepted_no_conflicts`, `allAcceptedRegistry`) updated to include the new records.

**Remaining open:**

1. **README index drift.** The project root `README.md` says `accepted/ — 40 markdown` but `docs/adr/accepted/` is now empty (all 16 records moved to `completed/`). The `docs/adr/README.md` table has been updated to reflect the new locations and statuses.

These gaps undermine the trust guarantee of the formal layer: a test driver that passes while a critical invariant is untested provides false confidence, equivalent to an axiom-clean kernel boundary with a hidden `sorry`.

## Decision

1. **Immediately replace the `sorry` in `ADR/Test.lean:18`** with either a complete proof (preferred) or an explicit `exitNow` with a tracked TODO and a CI gate that fails on new `sorry` introductions. **← DONE (2026-09-14)**
2. **Expand `allAcceptedADRs`** to include all Completed/Accepted ADRs: ADR-0013 through ADR-0016 must be added as `def` records in `ADR.Examples` or `ADR.Migrated` with full invariant discharge. ADR-002 through ADR-010 must either be formalized or explicitly excluded with a documented rationale. **← DONE for 0013–0016; 002–010 already formalized in `sampleRegistry` but unified registry not yet created**
3. **Adopt the Formalization Completeness Policy**: Every ADR that reaches Completed or Accepted status in `docs/adr/` must have a corresponding `def` in `ADR.Examples` or `ADR.Migrated` within one release cycle. Exceptions require a documented waiver in `registry.json` under a new `formalizationWaiver` field.
4. **Fix the README index**: Change `accepted/ — 40 markdown` to reflect the actual state (currently 0); adopt a generated index from `registry.json` rather than a hand-maintained count. **← DONE for 0013–0028 in completed/; global index still pending**

## Consequences

* The `ADR/Test.lean` test driver now exercises a real acyclicity proof (`all_accepted_acyclic`), providing genuine assurance that no supersession cycles exist in the 15-record `allAcceptedADRs` set.
* ADR-0013 through ADR-0016 gain full machine-checkable status proofs in `allAcceptedADRs` and `allAcceptedRegistry`.
* ADR-002 through ADR-010 are formally represented via `sampleRegistry` in `ADR.Examples` (verified `ADRRegistry` with all invariants discharged).
* A `unifiedRegistry` combining `sampleADRList` and `allAcceptedADRs` (25 records) is now defined in `ADR/Examples.lean` with all invariants verified, eliminating the dual-registry gap.
* The Formalization Completeness Policy (item 3) is NOT yet adopted — it would mandate a single unified registry as the sole source of truth.
* The README index (item 4) is NOT yet fixed globally — `docs/adr/README.md` still says `accepted/ — 40 markdown` with 0 files in that directory.
* Existing `ADR.Migrated` records (0040, 0041, 0043, 0057-0061, 0064) are unaffected; they already discharge all registry invariants.

## Rationale

ADR-0010 establishes that untracked proof debt is a hard violation. The `sorry` in the test harness is precisely such a violation: it is a proof obligation that affects runtime behavior (the test driver is invoked by `lake test` and CI), it is untracked, and it provides false positive assurance.

The formalization completeness policy follows from the project's core architecture: the Lean formal model is the **single source of truth** for ADR governance (per `ADR/README.md`). When markdown ADRs exist outside this model, they are provisional until formalized.

## Traceability & Artifact Links

* **[Delivered — Lean]** `ADR/Test.lean:16` — test driver now uses `all_accepted_acyclic` (sorry eliminated 2026-09-14)
* **[Delivered — Lean]** `ADR/Examples.lean:787` — `allAcceptedADRs` expanded to 15 records (0013–0016 added 2026-09-14)
* **[Delivered — Lean]** `ADR/Examples.lean:849` — `unifiedRegistry` combining 25 ADRs, all invariants verified (2026-09-14)
* **[Delivered — Lean]** `ADR/Core.lean` — `StrictAcyclic` predicate and `ProvenancePath` inductive
* **[Delivered — Lean]** `ADR/Proofs.lean` — acyclicity and immutability theorems
* **[Delivered — Rust/Kani]** `packages/rust/crmf/` — Kani-verified implementations for ADR-0013 through ADR-0016
* **[Related ADR]** ADR-0010 — Axiom-Clean Kernel Boundary and Manifested Proof Debt Policy
* **[Related ADR]** ADR-0013 — UOR Civic Infrastructure (formalized 2026-09-14)

## Appendix: Concrete Action Items

| Priority | Action | Status | Owner | Deadline |
|---|---|---|---|---|
| P0 | Replace `sorry` in `ADR/Test.lean:18` with complete proof or `exitNow` + CI gate | **✓ DONE** (2026-09-14) | — | Immediate |
| P0 | Add ADR-0013 through ADR-0016 to `ADR.Examples.Governance` | **✓ DONE** (2026-09-14) | — | This release |
| P1 | Audit ADR-002 through ADR-010 for formalization | **AUDITED**: formalized in `sampleRegistry`; `unifiedRegistry` created combining both sets | — | This release |
| P1 | Create unified registry combining both verified registries | **DONE**: `unifiedRegistry` in `ADR/Examples.lean:849` | — | This release |
| P1 | Fix README index drift (`accepted/ — 40 markdown` → 0 files) | Open — per-entry links updated; global count not yet fixed | — | Next release |
| P1 | Add `formalizationWaiver` field to `registry.json` schema | Open | — | Next release |
| P2 | Add CI check: `grep -r 'sorry' ADR/` fails build if any remain in test paths | Open | — | Next release |
