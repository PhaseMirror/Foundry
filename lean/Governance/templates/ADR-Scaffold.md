# ADR-XXX: [Short Descriptive Title]

**Status:** [Proposed | Accepted | Superseded]
**Date:** [YYYY-MM-DD]
**Owner:** [Substrates | Clinical | Governance]

## 1. Context & Tension
What is the clinical, infrastructure, or cryptographic challenge we are solving? 
What is the tension between velocity and integrity that this decision addresses?

## 2. Decision: The Implementation Approach
What is the chosen technical approach? Explicitly state the mapping to the `Ξ-Constitutional-Core` mandate.

## 3. Governance Mapping (Regulatory Compliance)
*   **Security Posture**: How does this impact our TEE/mTLS boundary?
*   **Compliance Control**: Specifically map this to a control within 45 CFR §164.312 (e.g., Access Control, Audit Controls, Transmission Security).

## 4. Consequences
*   **Performance**: What is the impact on $\Pi_{\text{Global}}$ or $R_{sc}$?
*   **Risk**: What is the "blast radius" if this component fails?

## 5. Verification Plan
How will this decision be stress-tested within the `agios-staging-package-t25` test harness? 
(e.g., "Must pass 10^5 randomized ingestion cycles without integrity violation").
