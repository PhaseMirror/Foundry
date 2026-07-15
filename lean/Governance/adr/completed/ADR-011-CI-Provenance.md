# ADR-011: CI/CD Provenance & GitHub Action Hardening

**Status:** Proposed
**Date:** 2026-06-16
**Owner:** Substrates / Examiner

## 1. Context & Tension
We must bridge the gap between our local "Gold Master" (t25) and a remote CI/CD environment (GitHub Actions) without compromising the integrity seal of our cryptographic codebase or leaking sensitive mTLS infrastructure.

## 2. Decision: Versioned Provenance
We will implement a "Manifest-Anchored" CI/CD pipeline:
1. **Air-Gap Integrity**: No local mTLS credentials are stored in the repo. CI uses ephemeral GitHub Environment Secrets injected at runtime.
2. **Checksum Enforcement**: All critical build artifacts must match checksums recorded in `/compliance/manifest.json`. The CI build *must fail* if the generated artifact hash deviates from the anchored manifest.
3. **Hardened Verification**: The CI workflow executes the Dual-Prover harness as the primary gate for PR merges.

## 3. Governance Mapping (Regulatory Compliance)
*   **Security Posture**: CI/CD environment operates in an isolated enclave with no persistent access to production mTLS infrastructure.
*   **Compliance Control**: **45 CFR §164.312(d) Person or Entity Authentication**. Automates verification that build agents are authorized and running sanctioned code topologies.

## 4. Consequences
*   **Velocity**: Slight slowdown due to mandatory checksum/proof verification.
*   **Risk**: High protection against supply chain attacks and unauthorized modification of the proving backend topology.

## 5. Verification Plan
The workflow (`.github/workflows/verify.yml`) will:
1. Build the target codebase.
2. Calculate artifact hash.
3. Compare against `/compliance/manifest.json`.
4. Run the Dual-Prover test harness to verify constraint parity.
