# v1.3.0 Research: Atomic Handshake Specification
**Date:** 2026-01-21
**Status:** SPECIFICATION DRAFTED

This document outlines the architectural requirements for the v1.3.0 "Resilient Fortress" baseline, focusing on the implementation of a STRICT, atomic handshake for all permissioned operations.

### 1. [FACT] Operational Mode: STRICT (Notarize-then-Switch)
The v1.3.0 baseline mandates a "Strict" operational mode. This is a non-negotiable, system-wide invariant. All permission checks must verify the notarized state of the Permission Braid *before* granting access or capability. The principle is that the AI operates on the **Ledger (the record of the law)**, not the **Braid (the law itself)**.

### 2. [FACT] The Core Invariant
No capability token, temporary access credential, or permissioned action may be granted or executed without a corresponding, verified `PERMISSION_BRAID_STATE` hash present in the `ledger_manifest.json`. The physical state of `vault_permissions.json` is considered untrusted until it has been successfully notarized.

### 3. [REASONED] The Epoch Pointer
To implement this, the system will use an "Epoch Pointer." This is not a new file, but a dynamic variable determined at runtime.
*   **Logic:** Before any permissioned action, the system must first read `ledger_manifest.json` and find the hash of the latest successful `PERMISSION_BRAID_STATE` transaction. This hash is the **"Valid Epoch."**
*   **Handshake:** The system then calculates the current hash of `vault_permissions.json`.
*   **Validation:** Access is only granted if `current_hash == Valid_Epoch_hash`. If they do not match, the system knows it is in a DESYNC state, even without running the full integrity pulse.

### 4. [HYPOTHESIS] The Skip-Gate (Custodian Override)
A direct "override" that bypasses the Epoch check would violate the core principle of v1.3.0. Therefore, a true override is not possible. The only permissible "emergency" action is a **Forced Re-Notarization**.
*   **Procedure:** If a Custodian must force a change, they edit the `vault_permissions.json` file and then *must* successfully run the `helix-notary.sh` script.
*   **Constitutional Breach Logging:** If the `helix-notary.sh` script is modified or bypassed to force an invalid state, this would be a **Constitutional Breach**. The v1.3.0 integrity pulse will be enhanced to detect such tampering (e.g., by hashing the notary script itself). A breach will trigger an immediate, non-recoverable **Sovereign Lockdown (Quarantine)**, with the reason logged as "CONSTITUTIONAL-BREACH-TOOL-TAMPERING." This makes the cost of an override a full system halt and manual forensic recovery.
