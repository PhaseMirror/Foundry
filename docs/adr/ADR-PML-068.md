# ADR-PML-068: ADR Test Driver Ghost — `adr_test` in lakefile points to non-existent module

## Status
Accepted
Proposed

## Axis
urgency vs capacity

## Owner
`the-examiner`

## Dissonance Score
- Impact = severity (3) x blast radius (2) = **6**
- Tractability = **4.0**
- **Score = 24.0**

## Context
`Prime/lean/lakefile.lean:44–46` registers a test driver:

```lean
@[test_driver]
lean_exe adr_test {
  srcDir := "Core"
  root := `ADR.Test
}
```

But `ADR.Test` does not exist. The `Prime/lean/Core/ADR.lean` re-export wrapper
imports `ADR.Test` (among other non-existent modules), and `Prime/lean/Core/ADR/`
does not exist as a directory. Running `lake test` would either silently skip
ADR verification or fail with an opaque import error.

### Manifested boundary
Leaked (unmanifested): YES — the CI surface for ADR governance is completely
absent. The `@[test_driver]` annotation creates the *appearance* of formal
testing without any actual test execution.

## Decision
Either remove the `adr_test` driver entirely (if ADR testing is not yet ready)
or implement `ADR.Test` with a minimal but real test suite that exercises the
`ValidADR` proof on at least one example.

Because the formal methods mandate requires testability, the right choice is to
implement `ADR.Test` with a self-contained harness, then verify it passes.

## Consequences
- **Positive**: CI actually validates ADR governance instead of silently bypassing it.
- **Negative / Constraints**: writing the test suite is gated on solving the
  `ADR.Logics` and `ADR.Core` implementation in ADR-PML-066 and ADR-PML-067.
- **Verification Strategy**: `lake test` must return success for `adr_test`.

## Metrics (resolution is confirmed when)
- `Prime/lean/Core/ADR/Test.lean` exists and compiles.
- `lake test adr_test` passes.
- The test driver no longer produces an opaque import error or silence.

## Actionable Levers
1. Implement `ADR.Core`, `ADR.Logics`, `ADR.Proofs`, `ADR.History`,
   `ADR.Governance`, `ADR.Examples`, `ADR.Export`, `ADR.Test` in
   `Prime/lean/Core/ADR/`.
2. Gate `adr_test` on the existence of at least one `example` theorem.
3. Re-run `scripts/phase_mirror_loop.py`; confirm the axis score reaches 0.

## Links
- Ghost driver: `Prime/lean/lakefile.lean:44`
- Ghost import: `Prime/lean/Core/ADR.lean:16–23`
- Related: `ADR-PML-067` (consequence vacuum)
