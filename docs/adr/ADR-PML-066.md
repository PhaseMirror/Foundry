# ADR-PML-066: Mathlib Exclusion/Inclusion Ghost Policy creates unprovable formal claims

## Status
Accepted
Proposed

## Axis
intent vs operating incentives

## Owner
`the-guardian`

## Dissonance Score
- Impact = severity (5) x blast radius (3) = **15**
- Tractability = **3.0**
- **Score = 45.0** (estimated base; loop-ranking will verify)

## Context
Two governing documents contradict each other on the Mathlib dependency policy:

- `Prime/lean/formal/ADR.md:44` — "No Mathlib dependency (pure Lean4 with Init only)"
- `AGENTS.md:35` — "Lake project with mathlib (latest compatible) as optional but recommended dependency for advanced tactics."

### Implementation reality
In the current `Prime/lean/` corpus:
- `operators_mathlib/` directory exists with filenames explicitly requiring Mathlib
  (`MultiplicityOperator.lean`, `UpdateOperator.lean`).
- `Prime/lean/Core/F1/Square/ADR099.lean:24` mocks `Matrix` and `Submodule` with
  `def Matrix` / `def Submodule` because Mathlib is presumed absent, yet the
  mocks do not prove any algebraic laws (`matrix_mul_assoc`, `submodule_closed`).
- `Prime/scripts/phase_mirror_loop.py:313` already detects `import Mathlib`
  lines and reports `mathlib.by_file` in its evidence output.

### Manifested boundary
Leaked (unmanifested): no — the contradiction is documented but not acted upon.
Any formal proof that requires `Matrix` multiplication or `Submodule` closure
must either use the unverified mocks or be marked `axiom`, violating the zero-
sorry policy.

## Decision
Resolve the duplicate-policy dissonance by keeping the "No Mathlib" constraint
from `formal/ADR.md` and building out the Rust/Kani verification track as the
primary implementation-level guarantee mechanism. The existing hand-rolled mocks
in files like `ADR099.lean` are replaced with formal Rust/Kani harnesses that
verify algebraic laws over bounded domains.

The project commits to:
1. Zero Mathlib imports in all `lean/` code.
2. Rust/Kani harnesses for algebraic laws that Mathlib would otherwise provide
   (matrix multiplication associativity, submodule closure, etc.).
3. Pure Lean4 with Init-only for all mathematical proof scaffolding.
4. Cross-track consistency maintained via the `alp_sorry_manifest.json` pairing
   mechanism (each `sorry` has a paired Rust/Kani witness).

## Consequences
- **Positive**: preserves the pure-Lean verification philosophy; Rust/Kani
  provides concrete implementation-level guarantees that Mathlib alone cannot
  provide for Rust code.
- **Negative / Constraints**: Rust/Kani requires a Rust toolchain and Kani
  installation; the verification surface is limited to concrete bounded domains.
- **Verification Strategy**: `kani` test suite in `Prime/rust/kani/` verifies
  matrix algebra, submodule closure, and other algebraic laws over bounded
  domains; `lake build` + `cargo kani` both pass.

## Metrics (resolution is confirmed when)
- `formal/ADR.md` retains the "No Mathlib" constraint.
- `Prime/rust/kani/` contains harnesses for algebraic laws currently mocked.
- `alp_sorry_manifest.json` entries for mocked laws have paired Rust/Kani witnesses.
- `phase_mirror_loop.py` reports zero Mathlib imports and zero hand-rolled algebraic mocks.

## Actionable Levers
1. Confirm `Prime/lean/formal/ADR.md:44` retains "No Mathlib dependency."
2. Create `Prime/rust/kani/harnesses/` directory with harnesses for:
   - `matrix_mul_assoc` (currently mocked in `ADR099.lean`)
   - `submodule_closure` (currently mocked in `ADR099.lean`)
   - Other algebraic laws from `operators_mathlib/`
3. Update `alp_sorry_manifest.json` to require Rust/Kani pairing for all `sorry`
   blocks that correspond to algebraic laws.
4. Re-run `scripts/phase_mirror_loop.py`; confirm the axis score reaches 0.

## Links
- Ghost policy: `Prime/lean/formal/ADR.md:44`
- Mandate: `AGENTS.md:35` (interpreted as "recommended for advanced tactics" not mandatory)
- Mock evidence: `Prime/lean/Core/F1/Square/ADR099.lean:24–28`
- Sorry manifest: `Prime/lean/alp_sorry_manifest.json`
