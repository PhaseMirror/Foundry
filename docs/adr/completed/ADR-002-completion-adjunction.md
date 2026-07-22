---
status: completed
date: 2026-07-21
decision-maker: PhaseMirror Team
---

# ADR-002: Completion Adjunction

## Context

The completion from partial to total UC system must satisfy a universal property to be well-defined.

## Decision

Define the completion as the left adjoint to the forgetful functor:
- **C : PartialUC → UC** (free completion)
- **U : UC → PartialUC** (forgetful)
- **C ⊣ U** (adjunction)

The completion is constructed via:
1. Free term algebra over the carrier
2. Lawful congruence (smallest equivalence relation)
3. Quotient by the congruence

## Consequences

- Guarantees the completion is the "best possible" total system
- Any map from a partial system to a total system factors through the completion
- Enables compositional reasoning about defects
