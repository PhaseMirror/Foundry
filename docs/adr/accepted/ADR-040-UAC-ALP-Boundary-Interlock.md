# ADR-040: UAC–ALP Boundary Formal Interlock & Proof-Debt Gatekeeper

**Status:** Accepted  
**Date:** 2026-08-25  
**Deciders:** Principal Formal Methods Engineer, Sedona Spine Governance Council, UAC Security Team  
**Context:** Unified Access Control (UAC), Axiom-Clean Lawful Proofs (ALP), Hardware Interlocks, Manifest Gating  

---

## 1. Context & Problem Statement

The Unified Access Control (UAC) layer mediates all state mutations, ledger anchors, and operational lever triggers across the Multiplicity Sovereign Core. If an unverified proof debt (`sorry` skeleton) or non-axiom-clean mathematical assumption could silently cross the UAC boundary without strict cryptographic and theorem-checked gating, the integrity guarantees of the entire downstream stack would collapse.

To prevent silent privilege escalation or axiom leakage, the boundary between UAC and ALP must enforce:
1. **Zero-Proof-Debt Gating:** Any permission token referencing active proof debt in `alp_sorry_manifest.json` must be rejected immediately.
2. **Axiom-Clean Proof Verification:** State mutation authorization strictly requires an axiom-clean ALP witness certificate (`isAxiomClean = true`).
3. **Hardware Interlock Latching:** Any drift warning or resonance violation asserted by monitoring circuits (`uac_safety_interlock.sv`) must latch the system into `L0_HALT`.
4. **Reversible PETC Signature:** Prime-encoded language units must be strictly reversible (`Reassemble(Decompose(s)) == s`).

---

## 2. Decision

We establish and ratify the **UAC–ALP Boundary Gatekeeper** spanning:
- **Lean 4 Formal Specification:** [`ADR/Theorems/UacAlpBoundary.lean`](../../ADR/Theorems/UacAlpBoundary.lean)
- **Rust Runtime Engine:** [`packages/rust/uac-gatekeeper`](../../packages/rust/uac-gatekeeper/)
- **Hardware Interlock Module:** [`packages/circuits/uac_safety_interlock.sv`](../../packages/circuits/uac_safety_interlock.sv)

### Formally Verified Invariants:
1. **`no_authorization_with_proof_debt` (INV-UAC-01):**
   $$\forall \tau \in \text{Tokens}, \text{ProofDebt}(\tau) > 0 \implies \text{UACAuthorize}(\sigma, \tau) = (\text{L0\_HALT}, \text{false})$$
2. **`authorization_requires_axiom_clean` (INV-UAC-02):**
   $$\text{UACAuthorize}(\sigma, \tau, c).2 = \text{true} \implies c.\text{isAxiomClean} = \text{true}$$
3. **`interlock_latches_on_violation` (INV-UAC-03):**
   $$\text{rhoViolation} = \text{true} \lor \text{driftWarning} = \text{true} \implies \text{evaluateInterlock}(\sigma) = \text{L0\_HALT}$$
4. **`decompose_reassemble_identity` (INV-UAC-04):**
   $$\text{reassembleTokens}(\text{decomposeGraphemes}(s)) = s$$

---

## 3. Runtime Gatekeeper Engine (`uac-gatekeeper`)

The runtime gatekeeper in [`packages/rust/uac-gatekeeper`](../../packages/rust/uac-gatekeeper/) implements:
- **`ManifestValidator`:** Ingests `alp_sorry_manifest.json` and evaluates residual proof debt against expiry dates and governor keys.
- **`InterlockClient`:** Co-verifies hardware state with latched fault behavior.
- **`UacAlpGatekeeper`:** Evaluates access tokens against proof debt and generates SHA-256 `BoundaryWitness` certificates on lawful transitions.

---

## 4. Compliance & Verification Matrix

| Invariant | Lean 4 Theorem | Rust Unit Test | Status |
|---|---|---|---|
| **INV-UAC-01** | `no_authorization_with_proof_debt` | `test_inv_uac_01_proof_debt_rejection` | **VERIFIED (Fail-Closed)** |
| **INV-UAC-01b** | `no_authorization_uncertified` | `test_inv_uac_01b_uncertified_lever_rejection` | **VERIFIED (Fail-Closed)** |
| **INV-UAC-02** | `authorization_requires_axiom_clean` | `test_inv_uac_02_axiom_cleanness_required` | **VERIFIED (Axiom-Clean)** |
| **INV-UAC-03** | `interlock_latches_on_violation` | `test_inv_uac_03_hardware_interlock_latching` | **VERIFIED (Latched L0_HALT)** |
| **INV-UAC-04** | `decompose_reassemble_identity` | `test_inv_uac_04_petc_reversibility` | **VERIFIED (Reversible)** |
| **Manifest Audit** | `lake build` | `test_manifest_validator_loading` | **VERIFIED (Axiom Hygiene)** |
