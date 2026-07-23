# ADR-PML-065: ADR ID-Space Fragmentation violates formal traceability invariant

## Status
Accepted
Proposed

## Axis
control desired vs available

## Owner
`the-guardian`

## Dissonance Score
- Impact = severity (4) x blast radius (6) = **24**
- Tractability = **4.0**
- **Score = 96.0** (estimated baseline; actual loop ranking pending)

## Context
The project maintains at least six incompatible ADR namespaces that cannot be
resolved under a single `ValidADR` proof:

| Namespace | Range | Format | Lifecycle Owner | Example |
|-----------|-------|--------|-----------------|---------|
| PML-loop | 001–064 | `ADR-PML-NNN` | `phase_mirror_loop.py` | `ADR-PML-055` |
| Formal Lean | 0001– | `ADR-NNNN` | `adr0001.lean` | `ADR-0001` |
| Domain markdown | 001–007 | `ADR-NNN` | package docs | `ADR-004-UCC` |
| F1 markdown | 100–109, 400 | `ADR-NNN` | F1 docs | `ADR-400` |
| Proposed academic | 120–121 | `ADR-NNN` | `proposed/` | `ADR-120` (LaTeX) |
| Alphanumeric | mixed | `ADR-NNN-desc` | ad-hoc | `ADR-004-UCC-blueprint-completion` |

### Manifested Boundary
Leaked (unmanifested): YES — no single `ADR.Id` type unifies these spaces.
A `ValidADR` proof that requires `ADR.id` to be a reconstructible string in a
canonical namespace cannot be discharged across this fragmentation.

## Decision
Adopt a single canonical `ADR.Id` algebraic datatype and migrate all existing
records into it. The canonical form is `ADR.PML.NNNN` for loop-generated
decisions, `ADR.DOM.NNN` for domain-specific decisions, and `ADR.F1.NNN` for
F1-Square formalization decisions. Migration does not require rewriting
historical documents; it requires a namespace prefix convention plus a proof
that every ID obeys the canonical grammar.

## Consequences
- **Positive**: one `ADR.Id` type, one `ValidADR` proof, one traceability invariant.
- **Negative / Constraints**: historical documents retain legacy IDs; the formal
  record carries a `legacyId` field for backward lookup.
- **Verification Strategy**: every `ADRRecord` must satisfy `id_matches_canonical`
  (a regex or dependent-pair proof in `ADR.Core`).

## Metrics (resolution is confirmed when)
- `ADR.Core` defines `ADRId` as a dependent type proving the canonical grammar.
- All existing `adr0001.lean` and `ADR.lean` re-exports compile free of import
  errors.
- `lake test` passes for the `adr_test` driver.
- The dissonance loop score for this axis trends to 0.

## Actionable Levers
1. Define `ADRId` in `Prime/lean/Core/ADR/Core.lean` as `ADR.PML.NNNN | ADR.DOM.NNN | ADR.F1.NNN`.
2. Add `legacyId : Option String` to `ADRRecord` so historical references survive migration.
3. Update `lakefile.lean` roots to point to the new `ADR.Core` module.
4. Re-run `scripts/phase_mirror_loop.py` and confirm this tension exits the ranked list.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Formal scaffold: `Prime/lean/formal/ADR.md`
- Test driver: `Prime/lean/lakefile.lean:44`
