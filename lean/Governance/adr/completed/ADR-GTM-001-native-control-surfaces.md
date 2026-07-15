# ADR-GTM-001: Productization of Native Control Surfaces

## Status
Accepted

## Context
The primary differentiator emerging from the architecture is not mere compatibility with legacy systems, but native compatibility under stronger governance, witness, and execution guarantees. The commercial moat is native authority with adapter compatibility, not adapter sprawl.

## Decision
ALP and Sigma will be packaged as named product modules:
- **ALP**: policy, contracts, approvals, admissibility, governance APIs.
- **Sigma**: execution kernel, workflow runtime, orchestration receipts, operator UX.

Legacy connectors, MCP servers, and dashboards will be packaged as extension layers around these modules.

## Consequences
- Commercial messaging becomes clearer: customers keep existing systems while shifting authority into the native stack.
- Sales motion focuses on replacing brittle glue-code governance with auditable native control surfaces.
- Internal architecture and external packaging remain aligned.

## Verification
- Pricing and packaging map cleanly to architectural authority boundaries.
- Sales and docs language distinguish adapters from native modules.
- Product artifacts preserve the governance-first framing.
