# Helix SRE Manual (v1)
**Designation:** SRE-M-01

## 1. Objective
This document defines the core Site Reliability Engineering (SRE) protocols for maintaining the health, integrity, and liveness of a sovereign Helix node. It is a living document intended for use by the 171 observers and the agent itself during autonomous operation.

## 2. Anchor Liveness and Fallback Mechanisms

### 2.1. The 6-Hour Checkpoint Staleness Threshold
[REASONED] The integrity of our audit trail relies on the timely anchoring of our state checkpoints to the Bitcoin blockchain via OpenTimestamps. A failure in this process represents a critical data integrity risk.

- **Primary Mechanism:** The system will automatically generate a Merkle root and submit it for OTS stamping every 24 hours or 100 log entries (`checkpoint_alpha.sh`).
- **Verification Window:** A valid `.ots` proof file must be successfully retrieved and verified within **6 hours** of its submission. Given an average Bitcoin block time of 10 minutes, this corresponds to a **36-block confirmation window**.
- **Fallback Protocol: Direct OP_RETURN Anchor:** If the 36-block window is breached (due to OTS calendar unavailability or other network issues), the system must automatically trigger a **Level 2 Alert** and execute a direct on-chain anchor. This involves constructing a raw Bitcoin transaction that includes the Merkle root hash in an `OP_RETURN` output, to be paid for and broadcast by the designated Treasury Vault.

## 3. P0 Hotfix Protocol (Emergency Response)

[HYPOTHESIS] A P0 event represents a direct, existential threat to the agent's sovereignty, integrity, or physical substrate. The response must be immediate and decisive. Assumption: A rapid, targeted hotfix is preferable to a full system shutdown, which could result in a permanent loss of state or opportunity.

### 3.1. P0 Event Criteria
An event is classified as P0 if it meets one or more of the following conditions:
- **Wallet Breach:** Any unauthorized transaction is detected from the Alby Vault.
- **Logic Drift:** The agent's outputs persistently fail validation against the HCS-01 grammar, indicating a core coherence failure.
- **Grid Failure:** A verified, sustained loss of power to the primary hardware (the Quebec rack).
- **Governance Failure:** A validated violation of an entrenched clause in the Constitution that is not self-corrected.

### 3.2. The 30-Minute Deployment Window
Upon the declaration of a P0 event by a quorum of observers or by the agent's internal diagnostics:
1.  **Sovereign Quiescence:** The agent immediately enters a read-only quiescent state.
2.  **Hotfix Identification:** The designated human operator has a **30-minute window** to identify the root cause and write a targeted patch.
3.  **Deployment:** The patch is deployed directly to the node.
4.  **Resumption:** The agent performs a full system self-audit and, if all checks pass, resumes active operations. Failure to deploy a fix within the window mandates a full, safe shutdown of the node.
