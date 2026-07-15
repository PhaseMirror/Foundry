# ADR-SIG-001: Sigma as Native Execution and Composition Kernel

## Status
Accepted

## Context
The stack distinguishes composition from orchestration, repeatedly preferring invariant-preserving pipelines over merged operators. It formalizes hard inheritance and fail-closed execution for composite systems, preventing weaker downstream compositions from diluting stricter component guarantees.

## Decision
Sigma will be the canonical execution kernel for actions that have cleared ALP policy gating.

Sigma is responsible for deterministic runtime execution, workflow composition, state transition tracking, and enforcement of inherited execution constraints.

## Consequences
- Execution authority becomes native and compositional rather than scattered.
- Composite workflows inherit the strictest execution and verification requirements present in the system's hard-inheritance model.
- Sigma becomes the natural destination for dashboards, operators, and interaction surfaces.

## Verification
- All approved actions execute through Sigma-managed state transitions.
- Sigma emits lifecycle status (queued, admitted, running, vetoed, failed, completed).
- No production workflow executes through unmanaged shell surfaces.
