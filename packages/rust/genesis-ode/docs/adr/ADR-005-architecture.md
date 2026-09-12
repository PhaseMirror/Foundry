# ADR-001: Architecture Overview

**Status**: Proposed

## Context

The `genesis-ode` substrate provides a Lean formalization of the Bounded Recomputational Autonomy (BRA) framework and associated algebraic structures. It is used by the Phase Mirror legal system to guarantee preservation risk calculations via the Sedona Spine.

## Decision

- The core Lean code resides under `Substrates/lean/genesis-ode/lean`.
- All mathematical definitions, theorems, and proofs are organized into separate modules (`Geometry.lean`, `Bra.lean`, `Impedance.lean`).
- ADRs are stored in `Substrates/lean/genesis-ode/adr/` with a numeric prefix for traceability.

## Consequences

- Improves discoverability of design rationale.
- Facilitates governance via ADR-036 regression policy.
- Enables automated tooling to locate relevant formalizations.
