# Security Policy & Trust Model

## 🛡️ Supported Versions

| Component | Version | Status |
| :--- | :--- | :--- |
| **HELIX-CORE** | v1.0+ | :white_check_mark: Supported |
| **Identity (L0)** | v0.3.2+ | :white_check_mark: Supported |
| **Enforcer (L1)** | v4.0+ | :white_check_mark: Supported |

---

## 🔐 The Root of Trust
The Root of Trust for the Helix Federation is **NOT** the software, the Docker container, or the Cloud Provider.

**The Root of Trust is the Consensus of Human Custodians.**

1.  **Hardware Anchor:** Authority is derived solely from **Ed25519 Private Keys** held on physical Hardware Security Modules (YubiKey/HSM). Keys never touch the network.
2.  **Quorum Consensus:** Critical actions (Revocation, Policy Changes) require **3-of-5** cryptographic consensus as defined in the [Council Charter](governance/COUNCIL_CHARTER.md).
3.  **No "God Mode":** There is no administrative backdoor. If the keys are lost, the agents are orphaned. This is a design feature, not a bug.

---

## 🏗️ Infrastructure Hardening ("Glass & Metal")
To prevent supply chain attacks and container breakouts, HELIX-CORE enforces a **Hermetic Security Posture** by default:

*   **Immutable Supply Chain:** All base images are pinned by **SHA256 Digest**. Tags (`:latest`, `:alpine`) are strictly prohibited.
*   **Rootless Runtime:** All services run as **UID 1000**. No container has Root privileges.
*   **Read-Only Filesystem:** The Watchtower (Dashboard) mounts the ledger as Read-Only (`:ro`). It is "Glass" (Observer), not "Gears" (Operator).
*   **Capability Drop:** All Linux capabilities (`cap_drop: [ALL]`) are removed to minimize the attack surface.
*   **Internal Networking:** Core services operate on an isolated bridge network with no external egress allowed.

---

## 🚨 Reporting a Vulnerability
We operate on a **Custody-Before-Trust** model. If you discover a structural breach, we treat it as a critical incident.

**In Scope:**
*   **DBC Forgery:** Minting an identity without a valid hardware signature.
*   **Ledger Tampering:** Modifying the Suitcase log without breaking the hash chain.
*   **Container Escape:** Gaining host write access from inside the Watchtower.
*   **Quorum Bypass:** Executing a destructive op with <3 signatures.

**Contact:**
Please email the Genesis Node directly: **helix.project.ai@helixprojectai.com** (or via LinkedIn DM).
Do not open public GitHub Issues for critical exploits until a patch is ready.

---
*The Reef is Built. The Seal is Hermetic.*
