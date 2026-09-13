# ADR-041: CI/CD Pipeline Trust Chain & Release Witness Bootstrapping

**Status:** Accepted  
**Date:** 2026-08-25  
**Deciders:** Principal Formal Methods Engineer, Sedona Spine Governance Council, Release Engineering  
**Context:** Cryptographic Provenance, Continuous Integration, Multi-Substrate Release Attestation  

---

## 1. Context & Problem Statement

In mission-critical formal methods architectures, verifying individual components in isolation is insufficient; the deployment and delivery pipeline itself must form a tamper-evident, cryptographically verifiable trust chain. Without automated witness bootstrapping in CI/CD:
1. Binary artifacts or test logs could be modified post-verification without invalidating build statuses.
2. Unverified upstream code changes could slip past release boundaries.
3. The Sedona Spine ledger would lack an immutable cryptographic anchor tying source code commits to machine-checked Lean 4 proofs and Rust execution traces.

---

## 2. Decision

We ratify the **Multiplicity Trust Chain & Release Witness Bootstrapping Pipeline**:
$$\text{Git Commit SHA} \longrightarrow \text{Source Merkle Tree} \longrightarrow \text{Lean Axiom Audit} \longrightarrow \text{Test Evidence} \longrightarrow \text{UnifiedWitness Signature}$$

### Core Architecture:
1. **Source Merkle Leaves:** Cryptographic SHA-256 hashes of all governed mathematical modules (`Care.lean`, `ADR/Theorems/`, `Projects/ECHO_BRAID`, `packages/rust/uac-gatekeeper`, `uac_safety_interlock.sv`, `alp_sorry_manifest.json`).
2. **Axiom Audit Verification:** Hard-assertion that governed modules depend solely on the foundational Lean 4 kernel (`propext`, `Quot.sound`) with zero `sorry` skeletons.
3. **Automated Witness Emission:** Execution of [`scripts/generate_release_witness.py`](../../scripts/generate_release_witness.py) on every CI run, outputting `release_witness.json` and appending to the persistent Archivum ledger (`witnesses.jsonl`).
4. **CI/CD Build Artifact Gating:** Upload and validation of `release_witness.json` in [`.github/workflows/build.yml`](../../.github/workflows/build.yml).

---

## 3. Witness Schema Specification

```json
{
  "witness_type": "MultiplicityReleaseAttestation",
  "version": "1.0.0",
  "governance_status": "RATIFIED_AXIOM_CLEAN",
  "git_commit": "<SHA-40>",
  "timestamp_epoch": 1787702400,
  "timestamp_iso": "2026-08-25T23:20:00Z",
  "axiom_hygiene": {
    "is_clean": true,
    "propext_quot_sound_only": true,
    "governed_modules_checked": 9
  },
  "source_merkle_leaves": {
    "Care.lean": "...",
    "ADR/Theorems/CareViability.lean": "...",
    "ADR/Theorems/UacAlpBoundary.lean": "...",
    "Projects/ECHO_BRAID/EchoBraid/Core.lean": "...",
    "Projects/ECHO_BRAID/EchoBraid/Proofs.lean": "...",
    "packages/rust/uac-gatekeeper/src/lib.rs": "...",
    "packages/circuits/uac_safety_interlock.sv": "...",
    "alp_sorry_manifest.json": "..."
  },
  "certified_subsystems": [
    { "subsystem": "ECHO_BRAID", "adr": "ADR-039", "status": "PASS" },
    { "subsystem": "UAC_ALP_BOUNDARY", "adr": "ADR-040", "status": "PASS" }
  ],
  "release_witness_signature": "<SHA256(canonical_json)>"
}
```

---

## 4. Consequences & Guarantees

| Property | Level | Enforcement Mechanism |
|---|---|---|
| **Traceability** | Cryptographic | Git Commit SHA mapped directly to Release Witness |
| **Axiom Cleanliness** | Kernel-Checked | Automated scan for zero `sorryAx` |
| **Tamper Evidence** | SHA-256 Signature | Merkle-leaves hash verification |
| **Audit Persistence** | Continuous | Archivum `witnesses.jsonl` ledger anchoring |
| **CI Fail-Closed Gate** | Hard Halt | Any discrepancy aborts build & artifact release |
