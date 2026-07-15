# ADR-015: Reactivation Sequence & State Restoration

**Status:** Proposed
**Date:** 2026-06-16
**Owner:** Substrates / Examiner Ensemble

## 1. Context & Tension
The t25 archive is an immutable "Gold Master" baseline. Reactivating this state carries the risk of drifting from compliance or inadvertently restoring a stale, vulnerable configuration. We need a deterministic, secure mechanism to "Wake" the system from stasis.

## 2. Decision: The Signed Wake Protocol
We mandate that reactivation is an authenticated, cryptographically signed operation:
1. **The Wake Signal**: Reactivation requires a signal signed by the **Agency Master Key**.
2. **TEE Verification**: The TEE-enclave *must* verify the digital signature of the reactivation token against the embedded Public Master Key *before* unsealing any memory state from the t25 baseline.
3. **Determinism**: The reactivation process must restore the enclave to a known-good, bit-for-bit identical state as the t25 archive, or halt immediately if integrity checks fail.

## 3. Governance Mapping (Regulatory Compliance)
*   **Security Posture**: Protects against unauthorized unsealing of clinical assets and ensures only sanctioned master-key holders can reactivate the system.
*   **Compliance Control**: **45 CFR §164.312(d) Person or Entity Authentication**. Verifies that the reactivation command originates from an authorized entity.

## 4. Consequences
*   **Performance**: Adds negligible latency (signature verification).
*   **Risk**: If the Agency Master Key is compromised, the integrity of the entire stasis-recovery protocol is lost.

## 5. Verification Plan
1. **Signature Failure**: Inject an unsigned or invalidly signed reactivation token; verify the enclave refuses to unseal.
2. **State Parity**: Compare the post-reactivation memory state against the t25 archive checksum; verify 100% parity.
3. **Fail-Closed**: Verify the system halts if any component of the reactivation sequence is interrupted.
