# ADR 103: ACE Invariant Pass (Spectral Stability)

## Status
Accepted

## Context
Modules must be stable and contractive before linking to ensure system-wide integrity.

## Decision
We implement the ACE Invariant Pass to verify $\sum F_i + \varepsilon < 1$ and $r(\Lambda) < 1 - \varepsilon$.
- Use `SCALE_BASE` (1,000,000) for all fixed-point arithmetic (Sedona Spine "No Floats").
- Extract governance attributes directly from `pirtm.module` (MLIR).
- Materialize Lean 4 formal proofs upon successful check.

## Consequences
- **Pros**: Provides bit-identical stability checks; ensures link-time veto for non-contractive modules.
- **Cons**: Increases link-time complexity; requires Lean 4 toolchain in CI/CD.
- **Sedona Spine Alignment**: Satisfies the governance requirement for formal stability certification and un-bypassable CI/CD gates.
