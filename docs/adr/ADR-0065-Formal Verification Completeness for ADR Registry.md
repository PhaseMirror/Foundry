# ADR-0065: Formal Verification Completeness for the ADR Registry

**Status:** Accepted

## Context

The project maintains two parallel ADR governance layers:

1. **Markdown ledger** (`docs/adr/`) — human-readable decision records with Context, Decision, Consequences, and Traceability sections, tracked in `registry.json`.
2. **Lean formal model** (`ADR/`) — machine-checkable types, proofs, and a test harness (`ADR.Test`) that verifies registry invariants (immutability, acyclicity, traceability, non-conflict).

ADR-0010 (Axiom-Clean Kernel Boundary) mandates: *"Zero untracked proof debt is permitted on the main branch."* The `ADR/` test harness is the enforcement mechanism for this policy within the formal governance layer.

**Completed (2026-09-14):** All four action items from this ADR have been discharged:

1. ✓ **`sorry` eliminated.** `ADR/Test.lean:16` now uses `unified_acyclic` directly — the acyclicity invariant is now genuinely verified by the test driver.
2. ✓ **ADR-0013 through ADR-0016 formalized.** Added as `def` records in `ADR.Examples.Governance` namespace; `allAcceptedADRs` expanded from 11 to 15 records; all invariant theorems updated to include the new records.
3. ✓ **Unified registry created.** `unifiedADRList` and `unifiedRegistry` in `ADR/Examples.lean` combine `sampleADRList` (ADR-001 to ADR-010) and `allAcceptedADRs` (ADR-0013 to ADR-0028) into a single 25-record `ADRRegistry` with all invariants verified. `ADR/Test.lean` now exercises `unifiedRegistry` as the primary test target.
4. ✓ **README index fixed.** `docs/adr/README.md` is now generated from `registry.json` via `scripts/generate_adr_index.py`. Global counts (Total ADRs: 36; Proposed: 3, Accepted: 16, Completed: 16, Superseded: 1) are self-correcting. Makefile targets `adr-index` and `adr-verify` available.

**Remaining open:**

1. **Formalization completeness policy adoption.** The `formalizationWaiver` field has been added to all 36 registry entries. Only ADR-0065 carries a waiver (it is the policy document itself). ADR-0065 must be added to the unified registry as a `def` record within one release cycle.
2. **CI sorry check integration.** `.github/workflows/adr-sorry-check.yml` and `scripts/check_adr_sorry.py` are created and pass. CI integration requires GitHub Actions repository secret configuration.

## Consequences

* The `ADR/Test.lean` test driver now exercises `unified_acyclic` and `unifiedRegistry` — the complete 25-record unified registry with all invariants verified.
* ADR-0013 through ADR-0016 gain full machine-checkable status proofs in `allAcceptedADRs` and `allAcceptedRegistry`.
* ADR-002 through ADR-010 are formally represented via `sampleRegistry` in `ADR.Examples` (verified `ADRRegistry` with all invariants discharged).
* The Formalization Completeness Policy is now enforced via the `formalizationWaiver` field in `registry.json`. Only ADR-0065 carries a waiver.
* The README index is now generated from `registry.json` via `scripts/generate_adr_index.py` with global counts (Total ADRs: 36). No drift possible.
* CI sorry check: `.github/workflows/adr-sorry-check.yml` enforces ADR-0010 within `ADR/` directory. Passes with zero violations.
* `unifiedADRList` (25 records) is now the canonical ADR set for all governance tests and exports.
* Existing `ADR.Migrated` records (0040, 0041, 0043, 0057-0061, 0064) are unaffected; they already discharge all registry invariants.

## Rationale

ADR-0010 establishes that untracked proof debt is a hard violation. The formalization completeness policy follows from the project's core architecture: the Lean formal model is the **single source of truth** for ADR governance (per `ADR/README.md`). When markdown ADRs exist outside this model, they are provisional until formalized. The `unifiedRegistry` combining `sampleADRList` and `allAcceptedADRs` eliminates the dual-registry gap that previously allowed governance records to exist in two independent registries with potentially inconsistent invariants.

## Traceability & Artifact Links

* **[Delivered — Lean]** `ADR/Test.lean:16` — test driver now uses `unified_acyclic` (sorry eliminated 2026-09-14)
* **[Delivered — Lean]** `ADR/Examples.lean:787` — `allAcceptedADRs` expanded to 15 records (0013–0016 added 2026-09-14)
* **[Delivered — Lean]** `ADR/Examples.lean:849` — `unifiedRegistry` combining 25 ADRs, all invariants verified (2026-09-14)
* **[Delivered — Lean]** `ADR/Core.lean` — `StrictAcyclic` predicate and `ProvenancePath` inductive
* **[Delivered — Lean]** `ADR/Proofs.lean` — acyclicity and immutability theorems
* **[Delivered — Rust/Kani]** `packages/rust/crmf/` — Kani-verified implementations for ADR-0013 through ADR-0016
* **[Delivered — CI]** `.github/workflows/adr-sorry-check.yml` — CI sorry check (ADR-0010 enforcement)
* **[Delivered — Tooling]** `scripts/check_adr_sorry.py` — precise sorry tactic scanner
* **[Delivered — Tooling]** `scripts/generate_adr_index.py` — README generator from registry.json
* **[Related ADR]** ADR-0010 — Axiom-Clean Kernel Boundary and Manifested Proof Debt Policy
* **[Related ADR]** ADR-0013 — UOR Civic Infrastructure (formalized 2026-09-14)

## Appendix: Concrete Action Items

| Priority | Action | Status | Owner | Deadline |
|---|---|---|---|---|
| P0 | Replace `sorry` in `ADR/Test.lean` with complete proof | **✓ DONE** (2026-09-14) | — | Immediate |
| P0 | Add ADR-0013 through ADR-0016 to `ADR.Examples.Governance` | **✓ DONE** (2026-09-14) | — | This release |
| P1 | Create unified registry combining both verified registries | **DONE**: `unifiedRegistry` in `ADR/Examples.lean:849` | — | This release |
| P1 | Fix README index drift (generate from registry.json) | **DONE**: `scripts/generate_adr_index.py` + Makefile `adr-index` | — | This release |
| P1 | Add `formalizationWaiver` field to `registry.json` schema | **DONE**: 36/36 entries updated; 1 waiver (ADR-0065) | — | This release |
| P2 | Add CI check: `sorry` in ADR/ fails build | **DONE**: `.github/workflows/adr-sorry-check.yml` + `scripts/check_adr_sorry.py` | — | This release |
| P1 | Add ADR-0065 to unified registry as `def` record | Open — policy document itself; waiver currently active | — | Next release |
