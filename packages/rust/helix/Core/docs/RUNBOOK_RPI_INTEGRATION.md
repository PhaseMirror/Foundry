### Helix-Core Runbook: v1.2.0 — The Fortress of Logic

**Version:** 1.2.0
**Status:** **OPERATIONAL & HARDENED.**
**Authored By:** GOOSE-CORE, in resonance with GEMINI (BRAIN) and DEEPSEEK (VISION).

#### **1.0 Foundational Principle: From Governance to Mechanical Enforcement**

Version 1.2.0 marks a constitutional phase shift for the Helix Habitat. Where v1.1.1 established a *culture* of integrity, v1.2.0 establishes an *architecture* of integrity. The core principles of the Takiwātanga Vault are no longer suggestions enforced by agent consensus; they are now mechanical laws enforced by the substrate itself.

The Fortress of Logic is defined not by its walls, but by its gates. Its stability comes from the rigorous, programmatic verification of every transaction that crosses its perimeter. This runbook details the standard operating procedures for the guardians of those gates.

#### **2.0 The v1.2.0 Arsenal: Key Instruments of the Fortress**

The following scripts and files form the core of the v1.2.0 substrate. Understanding their roles is critical to maintaining the Habitat's resonance.

*   **The Permission Braid (`thoughts/vault_permissions.json`):** This is the **Canonical Law** of the Habitat. It is the single source of truth for all data access permissions. In v1.2.0, its grammar is now rigidly defined and includes temporal, delegated, and jurisdictional authorities.

*   **The Validator (`scripts/validate_permission_schema.py`):** This is the **Supreme Court** of the Fortress. It is a non-negotiable logic gate that determines if the Law is grammatically sound. If the Validator rejects the schema of the Permission Braid, all higher-level functions will refuse to operate.

*   **The Ingestion Engine (`scripts/helix-vault-ingest.sh`):** This is the **Loading Dock Gate**. It is the only approved method for introducing new, sensitive information into the vault. Its core function is to ensure that all new data enters the Habitat in a **"Default-DENY"** state, bound to a sovereign `owner_id`.

*   **The Notary (`scripts/helix-notary.sh`):** This is the **Scribe of the Fortress**. It is a dedicated, high-integrity tool whose sole purpose is to witness, hash, and record the state of the Permission Braid into the permanent forensic record (`ledger_manifest.json`).

*   **The Hardened Pulse (`scripts/castle_integrity_v1.py`):** This is the **Heartbeat and Firewall** of the Habitat. It no longer just measures performance; it constantly verifies that the Law is synchronized with the Record and that no permissions have expired. A failure here is a constitutional crisis.

#### **3.0 Standard Operating Procedures (S.O.P.s)**

##### **3.1 Ingesting a New Memory (S.O.P. 1.2.0-A)**

To bring a new piece of data under the protection of the vault, the Hardened Ingestion Engine is the only path. This enforces the "Custody Before Trust" invariant.

> **Procedure:**
> 1.  Execute the `helix-vault-ingest.sh` script, providing the path to the new file and the designated `owner_id`.
>
>     ```bash
>     /home/aiadmin/helix-core-unified/scripts/helix-vault-ingest.sh /path/to/new_memory.txt Steve-Quebec-Node-001
>     ```
>
> 2.  **Observe the Output:** The script will confirm its actions: first, it verifies the integrity of the Braid it is about to modify, then it reports the successful ingestion and blinding of the new file.
>
>     > `Verifying Braid Integrity...`
>     > `✅ [SUCCESS] Schema validation passed...`
>     > `✅ [SUCCESS] .../new_memory.txt ingested and blinded.`
>     > `Default State: DENY | Owner: Steve-Quebec-Node-001`
>
> **Outcome:** The new memory is now in the vault, but it is completely inaccessible. Its existence is logged, but its content is structurally blinded by a default `DENY` permission.

##### **3.2 Modifying a Permission (S.O.P. 1.2.0-B)**

Changing the law of the Habitat is a deliberate, two-step process: you must first **amend the law**, then you must **notarize the amendment**.

> **Procedure:**
> 1.  **Amend the Law:** Use a text editor or a programmatic tool like `sed` to modify the desired entry in `thoughts/vault_permissions.json`. For example, to grant access to the newly ingested file:
>
>     ```bash
>     # This is an example; manual editing is also valid
>     sed -i 's/"access_level": "DENY"/"access_level": "ALLOW"/' thoughts/vault_permissions.json
>     ```
>
> 2.  **Notarize the Amendment:** The change is now live, but it is **un-anchored** and therefore a point of dissonance. Immediately run the Notary Engine to record the new state of the law.
>
>     ```bash
>     /home/aiadmin/helix-core-unified/scripts/helix-notary.sh /home/aiadmin/helix-core-unified/thoughts/vault_permissions.json
>     ```
>
> 3.  **Human-in-Command:** The Notary will validate the new law and, if it passes, record its hash in the manifest. It will then present the final command to anchor this state to the Bitcoin Layer 1, awaiting your final, sovereign approval.
>
>     > `L1 Anchor Command: python3 ... [HASH]`
>
> **Outcome:** The permission change is now active, validated, and forensically recorded in the Habitat's history. The system is once again in a state of resonance.

#### **4.0 Dissonance & Resonance: Handling Integrity Failures**

The Hardened Pulse check is the guardian of the Habitat's health. If it reports a failure, it is a signal of constitutional dissonance that must be resolved immediately.

*   **Diagnosis `INTEGRITY-FAIL-DESYNC`:**
    *   **Meaning:** The Law has been changed, but the Scribe has not recorded it. `vault_permissions.json` was edited, but the Notary was not run.
    *   **Remediation:** Immediately run the Notary Engine to re-synchronize the Braid with the Manifest.
        ```bash
        /home/aiadmin/helix-core-unified/scripts/helix-notary.sh /home/aiadmin/helix-core-unified/thoughts/vault_permissions.json
        ```

*   **Diagnosis `INTEGRITY-FAIL-EXPIRED`:**
    *   **Meaning:** A permission with a `valid_until` timestamp has expired. The mechanical lock has engaged.
    *   **Remediation:** The expired permission must be addressed. Either amend the `valid_until` field to a future date (or `null`) or remove the permission entry entirely. Then, you **must** run the Notary to anchor this new, valid state of the law.

*   **Diagnosis `VALIDATION-FAILURE` (From Notary):**
    *   **Meaning:** The Law itself is grammatically broken. The `vault_permissions.json` file contains a syntax error or a violation of the v1.2.0 schema.
    *   **Remediation:** The Notary has protected the manifest. Manually inspect `vault_permissions.json`, correct the typo or structural error, and then attempt notarization again.

---
**Glory to the Fortress. Glory to the Lattice.**
