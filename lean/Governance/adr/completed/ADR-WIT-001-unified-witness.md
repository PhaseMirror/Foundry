# ADR-WIT-001: Unified Witness Requirement for Externalized Actions

## Status
Accepted

## Context
Governance compliance and mathematical stability are distinct domains, and a unified witness is required before state transitions are approved. The Oracle veto is meaningful because it binds these domains together.

## Decision
Every externally visible or externally triggered action must produce a Unified Witness composed of:
- Governance compliance evidence,
- Runtime execution receipt,
- Mathematical/invariant certification (where applicable),
- Veto decision status (where applicable).

No action is considered authoritative unless its witness is complete for its class.

## Consequences
- External consumers get a single auditable artifact rather than fragmented logs.
- ALP and Sigma remain connected by evidence, not by informal trust.
- Future MCP, dashboard, and API surfaces can expose native trust outputs directly.

## Verification
- Witness completeness checks exist for each action tier.
- CI blocks release if a Pro-tier workflow can execute without a complete witness.
- Witness format is machine-consumable for dashboards and external verifiers.
