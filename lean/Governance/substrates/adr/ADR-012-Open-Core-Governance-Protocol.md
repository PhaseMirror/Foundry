# ADR-012: Open Core vs. Governance Protocol Separation

## Status
Proposed

## Context
The MOC v2 architecture consists of a formally verified mathematical core (MOC/PIRTM/CRMF) and higher-order governance orchestration (L0–L3). Previous iterations risked coupling these layers, potentially introducing dissonance where governance policy could bypass core formal invariants.

## Decision
We enforce a strict separation between the **Open Core** (the formal generator layer) and the **Governance Protocol** (the orchestration layer).

### Architectural Contract

1.  **Open Core (The "Source of Truth"):**
    - **Responsibilities:** Generate `OperatorWord` terms, perform deterministic normalization `NF(Q, p)`, and prove `StabilityCertificate` (ACE + Resonance).
    - **Invariants:** Immutable, formal, and open-source.
2.  **Governance Protocol (The "Orchestrator"):**
    - **Responsibilities:** Consume `StabilityCertificate` streams, apply policy (L1 Audit, RSL limits, Phase Mirror dissonance resolution), and generate `LayerCertificate` attestations.
    - **Invariants:** Cannot modify core; can only reject transitions that fail layer-specific policies.
3.  **Provable Binding:**
    - The core emits `StabilityCertificate`.
    - Governance emits `LayerCertificate`.
    - Rust runtime executes only binary artifacts that embed *both* proofs via the `verify_witness` gate.

## Verification
- Formal proof `crmf_governance_bound` ensures no governance decision can be made without an underlying core stability proof.
- CI/CD pipeline enforces attestation chain (Core Cert + Layer Cert) for all production binary deployment.
- Runtime PEP (Policy Enforcement Point) rejects any execution lacking the full attestation chain.

<!-- LawfulRecursionVersion:1.0 -->
