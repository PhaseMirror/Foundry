# ADR 003: Embed BRA Cost Metric into Governance Tether

*Status*: Proposed
*Date*: 2026-06-19

## Context
The Genesis ODE governance stack now includes the Bounded Recomputational Autonomy (BRA) invariant as a cost functional measuring the effort required for internal reconstruction of geometry states. The existing Exploder/Builder tether (`τ`) regulates the depth of shrapnel fragments used for reconstruction, but lacks a quantitative metric that distinguishes internal integration from overlay borrowing.

## Decision
Introduce a BRA‑derived cost field `braCost : Real` into the `ShrapnelMap` telemetry structure and update the tether gating logic to consider this metric:
- The `τ` gate will reject any builder step whose `braCost` exceeds the configured budget `budgetBra`.
- Internal histories with low `braCost` are classified as **Geometry Integration**; those requiring external generators (high `braCost`) are flagged as **Geometry Overlay**.

The implementation will be added in Lean under `src/BRA_Telemetry.lean` and referenced in the governance harness.

## Consequences
- Provides a measurable, algebraic indicator of recomputational autonomy directly within the governance loop.
- Tightens safety gates without modifying the immutable scalar core (ADR‑001).
- Enables automated tests that verify `ΔBRA > 0` for overlay vs internal histories.

## Links
- ADR‑001: Core scalar invariants
- ADR‑002: Formalize mathematics in Lean
- BRA v2.0 paper (Section 5) for cost functional definition
- Exploder/Builder tether implementation (`src/Builder.lean`)
