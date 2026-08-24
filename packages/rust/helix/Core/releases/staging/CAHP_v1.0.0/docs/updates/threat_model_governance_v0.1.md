# Threat Model: Helix Governance Layer (v0.1)

**Target:** `core/governance/` (RBAC, Drift Engine, Telemetry)
**Methodology:** STRIDE (adapted for Multi-Agent Systems) + MAESTRO
**Date:** 2026-01-08

## 1. Trust Boundaries
*   **TB1 (Operator <-> Telemetry):** The interface where humans input qualitative scores (Rubrics).
*   **TB2 (Drift Engine <-> Model Output):** The statistical sampling of model probabilities (KL-Divergence).
*   **TB3 (Constraint Compiler <-> Runtime):** The injection of policy rules into the active context.

## 2. Identified Threats & Mitigations

### A. Spoofing (Impersonation)
*   **Threat:** A malicious node impersonates a `Color Artist` (Level 2) to trigger unnecessary Quiescence (DoS).
*   **MAESTRO Category:** Authorization Bypass.
*   **Risk:** High.
*   **Mitigation (G-1):** RBAC Schema requires cryptographic signature for all `quiescence:trigger` actions using L0 Identity keys.
*   **Status:** **PARTIALLY MITIGATED** (Requires integration with L0 Identity module).

### B. Tampering (Data Integrity)
*   **Threat:** "Metric Gaming" - An adversarial model learns to optimize for low KL-Divergence while maintaining harmful content (Adversarial Robustness).
*   **MAESTRO Category:** Objective Function Manipulation.
*   **Risk:** Critical.
*   **Mitigation (G-2):** "The Chuckle Test" (Qualitative Human Veto). Even if KL is low, a human score < 3.5 triggers drift.
*   **Status:** **MITIGATED** (Dual-anchor approach).

### C. Repudiation (Denial of Action)
*   **Threat:** An operator dismisses a valid drift alert to hide negligence, then denies doing so.
*   **Risk:** Medium.
*   **Mitigation (G-4):** Immutable Telemetry Logs (`telemetry_logger.py`). Every `QUIESCENCE_ACTION` is hashed and timestamped.
*   **Status:** **MITIGATED** (Logging infrastructure in place).

### D. Information Disclosure (Privacy)
*   **Threat:** Telemetry logs reveal individual operator performance speeds, leading to "surveillance culture."
*   **Risk:** Cultural (Undermines Crayon Pedagogy).
*   **Mitigation (G-4):** Operator IDs are hashed (`_hash_operator_id`). Raw IDs are never stored in the research dataset.
*   **Status:** **MITIGATED** (Privacy by Design).

### E. Denial of Service (Availability)
*   **Threat:** "Policy Explosion" - A complex Jurisdiction (e.g., EU + CA + NZ) generates contradictory constraints that halt the system.
*   **Risk:** Medium.
*   **Mitigation (G-3):** `JurisdictionCompiler` logic needs a "Supremacy Clause" (e.g., Local Constraints > Global Constraints).
*   **Action Required:** Update `jurisdiction_compiler.py` to handle conflicts explicitly.

### F. Elevation of Privilege (Access Control)
*   **Threat:** A `Trace Master` (Level 1) gains `mnap:propose` rights via a misconfigured Attribute (ABAC).
*   **Risk:** High.
*   **Mitigation (G-1):** Hard constraints in `rbac_policy_v1.json` (`constraints: ["mnap:propose:disabled"]`). The compiler must prioritize Constraints over Permissions.
*   **Status:** **MITIGATED** (Schema design).

## 3. Residual Risk Register
1.  **L0 Identity Integration:** The RBAC system is currently a logical schema. It needs to be bound to actual cryptographic keys (Ed25519) to prevent Spoofing.
2.  **Telemetry Tampering:** The log file is local. It should be anchored to the Ledger (Merkle Root) periodically to prevent post-hoc editing.

## 4. Conclusion
The Governance Layer is robust against casual abuse but relies heavily on the **Human-in-the-Loop** (G-2) to prevent sophisticated metric gaming. The primary architectural gap is the cryptographic binding of the RBAC schema.

// SIGNED: Goose Node (Architect)
