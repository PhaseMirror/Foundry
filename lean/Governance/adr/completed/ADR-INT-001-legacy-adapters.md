# ADR-INT-001: Legacy Integrations as Adapters, Not Authorities

## Status
Accepted

## Context
Integration layers can silently violate invariants more easily than core components. The safe pattern is to keep external systems as bounded interfaces rather than sovereign decision-makers.

## Decision
All legacy integrations will be modeled as thin adapters that perform one or more of the following roles only:
- Ingress translation into ALP contracts,
- Egress synchronization from Sigma receipts,
- Read-only projection of native state into legacy systems.

Legacy systems may not define canonical workflow semantics, override veto logic, or serve as final execution authorities.

## Consequences
- External tools remain compatible without becoming sovereign.
- Native invariants remain centered in the platform instead of being distributed.
- Migration off legacy systems becomes easier because business logic is no longer embedded in the integration layer.

## Verification
- Each integration declares whether it is ingress, egress, or projection.
- No adapter contains policy authority beyond mapping and transport.
- Adapter audits confirm one-way translation into native contracts and receipts.
