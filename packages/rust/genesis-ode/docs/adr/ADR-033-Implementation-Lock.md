# ADR-033: BRA Cost Implementation, Builder Gating & Paired-History Validation

*Status*: Proposed
*Date*: 2026-06-18
*Author*: Ryan van Gelder (Phase Mirror) with Chris Beckingham (CDL)
*Depends on*: ADR-001, ADR-002, ADR-003, `BRA_Telemetry.lean`, `Builder.lean`

## Context
ADR-003 embedded the BRA cost metric into `ShrapnelMap`. Governance now requires concrete enforcement of this metric in the Builder admission process and a formal validation that internal reconstruction histories have strictly lower BRA cost than overlay histories.

## Decision
1. **Builder integration** – use `computeBraGatedProposal` and `admitBuilderProposal` from `Builder.lean`. Proposals are accepted only when:
   - `braCost < policy.budgetBraThreshold`
   - `tetherTension ≥ 0.70`
2. **Paired‑history separation test** – add `tests/BRA_SeparationTest.lean` proving `cost_internal < cost_overlay` for identical terminal states.
3. **Python‑Lean bridge** – extend the Python builder engine (`genesis_governance/builder/lean_bridge.py`) to invoke the Lean functions, serialize/deserialize proposals, and enforce the gate at runtime.
4. **Policy parameter** – introduce `budgetBraThreshold` (default 5.0) in `BuilderPolicy` (Python side) and expose it to Lean via a generated `TetherPolicy`.

## Consequences
- **Positive**: Recomputational autonomy becomes an observable, enforceable governance signal; the system can automatically reject high‑cost overlay proposals.
- **Negative**: Minor runtime overhead for the Lean bridge and a modest increase in test suite time.
- **Trade‑off**: Stronger internal vs. overlay distinction at the cost of additional tooling complexity.

## Compliance
- No external `mathlib` or `sorry` statements are used; all Lean code is provably correct.
- ADR‑003 remains unchanged; this ADR only ratifies the concrete implementation.

## Review Process
- **Review horizon**: 7 days.
- **Owner**: Joint (Ryan van Gelder & Chris Beckingham).
- **Acceptance criteria**:
  1. `Builder.lean` compiles with the new functions.
  2. `tests/BRA_SeparationTest.lean` passes.
  3. Python bridge successfully calls Lean and respects the gate.

## Links
- ADR‑001: Core scalar invariants
- ADR‑002: Formalize mathematics in Lean
- ADR‑003: Embed BRA cost metric
- `src/BRA_Telemetry.lean`
- `src/Builder.lean`
- `src/ScalarCore.lean`
