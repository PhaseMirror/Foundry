# ADR-PML-072: Dissonance Loop as Ungoverned Meta-Policy — generates ADRs without formal governance

## Status
Accepted
Proposed

## Axis
control desired vs available

## Owner
`the-guardian`

## Dissonance Score
- Impact = severity (4) x blast radius (1) = **4**
- Tractability = **4.0**
- **Score = 16.0**

## Context
`scripts/phase_mirror_loop.py` is an autonomous policy engine that:

1. Scans documents and Lean source for claims.
2. Detects tensions between stated intent and implementation reality.
3. Ranks tensions by impact x tractability.
4. Emits `ADR-PML-NNN` plan ADRs into `docs/adr/`.
5. Updates `state/phase_mirror_loop.json` with dissonance drift.

The loop runs with no `ValidADR` proof, no `ADR.Id` registration, no
`@[adr]` annotation, and no formal traceability. It operates **above** the
formal ADR model rather than *inside* it.

### Manifested boundary
Leaked (unmanifested): YES — the meta-policy engine is entirely ungoverned. A
bug or inprecision in the loop can mutate the official ADR registry without any
formal review.

## Decision
Bring the Phase Mirror Loop inside the formal ADR governance boundary by:

1. Running the loop as a **plugin** inside `ADR.Export` rather than as a
   standalone Python script.
2. Requiring each emitted plan ADR to carry a `@[adr]` attribute and satisfy
   `ValidADR` before being written to disk.
3. Subjecting the loop's own `phase_mirror_loop.json` state to an
   `ADR.History` append-only proof.

Short-term (this sprint): add a Python hook that validates the emitted plan ADR
YAML frontmatter against the `ADRRecord` schema before the file is written.
Medium-term: rewrite the loop as a Lean executable that writes `ADRRecord`
values directly.

## Consequences
- **Positive**: the loop becomes auditable; every plan ADR is machine-checked.
- **Negative / Constraints**: the loop loses its read-only guarantee; any bug
  in the validator could block legitimate gap detection.
- **Verification Strategy**: `lake test` includes a test that the loop's output
  directory contains only `ValidADR`-conforming records.

## Metrics (resolution is confirmed when)
- `phase_mirror_loop.py` emits plan ADRs only after `ValidADR` check.
- `state/phase_mirror_loop.json` carries a Merkle chain hash linked to
  `ADR.History`.
- `lake test` passes an integration test that runs the loop and verifies output
  conformance.

## Actionable Levers
1. Create `Prime/scripts/validate_pml_adr.py` with `ValidADR` schema check.
2. Wire `validate_pml_adr.py` into `phase_mirror_loop.py::emit_plan_adrs`.
3. Add `ADR.Governance.ValidPMLLoopADRSchema` to `ADR/Proofs.lean`.
4. Re-run `phase_mirror_loop.py`; confirm all emitted ADRs pass validation.

## Links
- Ungoverned loop: `Prime/scripts/phase_mirror_loop.py`
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Formal model: `AGENTS.md:28` (traceability)
