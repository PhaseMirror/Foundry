// ADR: Integration of Prime Move Sequence Audit Macro with materia_commons

# ADR 002: Integration of Prime Move Sequence Audit Macro with materia_commons

## Context
`materia_commons` is the shared library of common utilities, data models, and policies used across the Phase Mirror suite. To ensure consistent audit handling, the **Prime Move Sequence Audit Macro** must be integrated with `materia_commons` so that all agents, regardless of subsystem, can invoke the macro through a common interface.

## Decision
Introduce a new module `materia_commons.audit.prime_move_sequence` that provides:
1. A wrapper function `runPrimeMoveAudit` that delegates to the Sedona Spine engine via the SDK.
2. Exported type definitions for the audit payload (e.g., `MoveSequence`, `AuditRecord`).
3. A compliance validator that checks the payload against the `[PRESERVATION ALERT]` protocol.
4. Documentation linking back to **ADR‑001** (the macro specification).

### Implementation Steps
- Add `materia_commons/audit/prime_move_sequence.md` documenting the API.
- Update `materia_commons/src/audit/prime_move_sequence.lean` (or appropriate language) to expose the wrapper.
- Modify the build script to ensure the new module is compiled and linked.
- Add CI linting rule that any new move‑sequence implementation must import `materia_commons.audit.prime_move_sequence`.

## Consequences
- Uniform audit entry points across all subsystems, eliminating duplicate implementations.
- Enforces the **Zero Drift** and **Policy‑Driven Variation** mandates.
- Simplifies future extensions; changes to the macro only need to be made in one place.

## Related Policies
- **Sedona Spine Mandate** – all audit data must flow through the engine.
- **Agent Operational Integrity** – logging must follow the required provenance chain.
- **ADR‑001** – defines the macro itself.

---
*Created to satisfy the request for an ADR plan to integrate the Prime Move Sequence Audit Macro with materia_commons.*
