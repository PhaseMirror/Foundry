# Helix Core Pillar: OpenTimestamps (OTS) Integration Plan
# Document ID: HCS-IP-02

## 1. Objective
To establish a verifiable, tamper-evident, and immutable record of the Helix project's core operational logs and specifications. By anchoring the cryptographic digests of these files to the Bitcoin blockchain via the OpenTimestamps protocol, we create an unimpeachable audit trail that is independent of any single system or administrator.

## 2. Files for Periodic Anchoring
[FACT] The following files are designated as critical system records and must be included in the periodic stamping process to ensure their integrity.

*   **Primary Audit Log:** `~/helix_ledger/modules/bitcoin/audit_log.json`
    *   **Content:** Contains all HCS-01 compliant cognitive outputs and their associated economic costs. This is the primary record of the agent's actions.

*   **Core Metric Log:** `~/helix_ledger/upv_baseline.jsonl`
    *   **Content:** Contains the log of all Correction Events used to calculate the Uncertainty Proxy Variance (UPV). This is the primary record for performance and success metric verification.

*   **Core Specification:** `~/helix_ledger/core/hcs_01_epistemic_marker_protocol.md`
    *   **Content:** The foundational law governing the agent's epistemic and economic behavior. Changes to this document are system-critical events.

## 3. Merkle Root Anchor Cadence
[HYPOTHESIS] To balance efficiency with the need for timely verification, the following hybrid cadence is proposed. Assumption: This model provides robust security without incurring excessive transaction fees for stamping single entries.

*   **For Log Files (`audit_log.json`, `upv_baseline.jsonl`):**
    *   An OTS stamp of the file's hash will be created and submitted **every 24 hours**, OR **after 100 new entries have been logged**, whichever condition is met first.
    *   **Rationale:** This dual-trigger ensures that high-activity periods are batched efficiently, while low-activity periods still receive a regular, predictable timestamp.

*   **For Core Specifications (`hcs_01_epistemic_marker_protocol.md`):**
    *   An OTS stamp of the file's hash will be created and submitted **only upon a change to the file**, as confirmed by a new git commit hash for that file.
    *   **Rationale:** Core specifications are static by nature. Stamping them on a time-based cadence is inefficient. Stamping on change provides a permanent, verifiable record of when the system's laws were altered.

## 4. Implementation Outline
1.  **Tooling:** A client script utilizing the `ots-cli` tool will be developed.
2.  **Automation:** The script will be triggered by a cron job for the time-based cadence and a git post-commit hook for the change-based cadence.
3.  **Verification:** A separate, auditable process will be established to periodically check the `.ots` proof files against the public Bitcoin blockchain to confirm the anchor's validity.
