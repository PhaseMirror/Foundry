# ADR-010: Layer-B Identity Root Topology & Sovereign Core Partitioning

**Status:** Proposed  
**Date:** 2026-08-26  
**Accountable Owner:** Formal-Methods Steward (`PhaseMirror Principal Formal Methods Engineer`)  
**Co-Signatory:** Legal/Governance Steward  
**Context:** Wyoming DUNA Statutory Membrane, Sedona Spine Mandate, Article III Content-Addressed Identity  

---

## 1. Context & Problem Statement

ADR-008 and ADR-0035 establish that Layer B (the immutable Article III content-addressed Git Tree SHA) is the sole prerequisite gate for all on-chain credential minting, ZK code attestation, and public monorepo stability claims.

An exhaustive audit of candidate paths within `PhaseMirror/Foundry` revealed:
1. The historical `lean/Multiplicity/*` tree contains 664 amortized proof debts recorded in `alp_sorry_manifest.json`.
2. The exploratory package `Projects/GODELIAN_TRUTH` contains 7 `admit` skeletons (compiling to `sorryAx`).
3. If any debt-bearing path remains inside the repository tree, the top-level Git Tree SHA is cryptographically contaminated with unverified logic, violating the axiom-clean mandate of the Sedona Spine.

---

## 2. Decision: Option B3 (Physical Extraction & Hermetic Root)

We select **Option B3 (Physical Extraction)** as the canonical topology for the Multiplicity Sovereign Core:
1. **Physical Segregation:** All unverified, exploratory, or Mathlib-dependent modules are permanently extracted to the non-binding archive repository `PhaseMirror/legacy-exploratory`.
2. **Hermetic Lawful Core:** `PhaseMirror/Foundry` retains *only* 100% verified, zero-sorry, zero-Mathlib files.
3. **Empty Manifest:** `alp_sorry_manifest.json` is purged to exactly `{"schema_version": "2.0", "entries": []}`.
4. **No Premature Git Operations:** No `git mv`, force-push, or tag operation is authorized until this ADR is ratified and the verification metric is observed.

---

## 3. Canonical Enumeration of Remaining Lawful Paths

Only the following paths are permitted inside `PhaseMirror/Foundry` post-extraction:

### Formal Mathematical Core (Lean 4)
- `Care.lean`
- `ADR/Core.lean`
- `ADR/Proofs.lean`
- `ADR/Examples.lean`
- `ADR/Export.lean`
- `ADR/Test.lean`
- `ADR/Theorems/CareViability.lean`
- `ADR/Theorems/Homestead_UCC_Care_Bridge.lean`
- `ADR/Theorems/UacAlpBoundary.lean`
- `ADR/Theorems/HardwareInterlock.lean`
- `Projects/ECHO_BRAID/EchoBraid/Core.lean`
- `Projects/ECHO_BRAID/EchoBraid/FloerOperator.lean`
- `Projects/ECHO_BRAID/EchoBraid/BraidFormalism.lean`
- `Projects/ECHO_BRAID/EchoBraid/Contraction.lean`
- `Projects/ECHO_BRAID/EchoBraid/SpectralCoherence.lean`
- `Projects/ECHO_BRAID/EchoBraid/Proofs.lean`
- `Projects/ECHO_BRAID/EchoBraid/Examples.lean`
- `Projects/ECHO_BRAID/EchoBraid/Test.lean`
- `Projects/ECHO_BRAID/EchoBraid/Export.lean`
- `Projects/ECHO_BRAID/EchoBraid/Main.lean`
- `Projects/ADR_0035_PLATFORM/ADR0035/`
- `lakefile.lean`
- `lean-toolchain`

### High-Assurance Runtime Engines (Rust)
- `packages/rust/uac-gatekeeper/`
- `packages/rust/pirtm-parser/`
- `packages/rust/alp/`
- `Projects/ECHO_BRAID/rust/`

### Silicon Hardware Interlocks (SystemVerilog)
- `packages/circuits/uac_safety_interlock.sv`
- `packages/circuits/test_hardware_co_verification.py`

### Governance & Verification Tooling
- `CONTRACT.md`
- `docs/adr/` (ADR-001 through ADR-042)
- `.github/workflows/build.yml`
- `scripts/verify_candidate_tree.sh`
- `scripts/generate_release_witness.py`
- `scripts/final_coherence_audit.py`
- `alp_sorry_manifest.json` (0 entries)

### Explicitly Excluded / Extracted Paths
- `lean/Multiplicity/*` (664 sorry entries) $\to$ Extracted to `legacy-exploratory`
- `Projects/GODELIAN_TRUTH/` (7 `admit` entries) $\to$ Extracted to `legacy-exploratory`
- All legacy unverified crates in `packages/rust/*`

---

## 4. Irreversible Unblocking Metric

Layer B transitions from `Blocked` to `Ratified` if and only if all of the following conditions are simultaneously met on `PhaseMirror/Foundry:main`:

1. **Remote Tree Purity:** Remote HEAD contains strictly the enumerated lawful paths above and zero others.
2. **Zero Debt Ledger:** `alp_sorry_manifest.json` contains `"entries": []`.
3. **Whole-Repository Axiom Cleanliness:** `lake build` succeeds on 100% of files under `--reject-sorry`, with zero `sorry`, zero `admit`, and zero `import Mathlib`.
4. **Deterministic Master Signature:** `scripts/verify_candidate_tree.sh` executes 10/10 gates with 100% pass rate, producing a master coherence signature that matches `SOVEREIGN_CORE_COHERENCE_CERTIFICATE.json`.
5. **Contract Population:** Only after steps 1–4 are observed on the remote is `CONTRACT.md §1.2` populated with the resulting Commit SHA and Tree SHA.

---

## 5. Single Accountability Designation

The **Formal-Methods Steward** is the sole authorized entity responsible for executing the irreversible extraction, verifying the metric on remote HEAD, and certifying the final Article III Tree SHA.
