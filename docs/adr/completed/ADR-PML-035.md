# ADR-PML-035: Analytic-shadow fingerprint missing from the `KernelTelemetry` contract (3 gaps)

## Status
Adopted

## Axis (Phase Mirror tension class)
control desired vs available

## Owner (multi-agent lever)
`the-guardian`

## Dissonance Score
- Impact = severity (4) x blast radius (3) = **12**
- Tractability = **1.0**
- **Score = 12.0**  (cluster rank 1 of 1)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - docs/adr/accepted/ADR-095-PhaseMirror-Kernel-Semantic-Authority.md:20 — asserts kernel emits certified scalars to downstream consumers without recomputation
  - docs/adr/accepted/ADR-096-ACE-PhaseMirror-Kernel-Telemetry-Contract.md:24 — asserts `KernelTelemetry` schema supports backward-compatible extensions for new metrics
  - docs/adr/accepted/ADR-098-ACE-SCN-CSC-PhaseMirror-Production-Implementation.md:30 — asserts Mode-3 wrappers read kernel-defined drift states without recomputing them

### Implementation reality (lean/)
  - `KernelTelemetry` carries only 4 core fields: `xn_kernel`, `wt_max_kernel`, `protection_zeta`, `is_valid_kernel`
  - `mock_zeno_compute_kernel_telemetry` does not populate analytic-shadow metrics
  - `tests/test_kernel_parity.py` exercises only the core parity contract (7 tests), with no coverage for zero-ordinate statistics or GUE-deviation proxies

### Manifested boundary
Leaked (unmanifested): YES — gap is NOT manifested in `alp_sorry_manifest.json` (silent leak risk)

## Decision (the lever)
Resolve the dissonance by extending the `KernelTelemetry` contract with three
analytic-shadow fields and implementing the Riemann–Siegel / Odlyzko-style
pipeline as a first-class, tested part of the production telemetry path. Treat
the missing analytic shadow as `Proposed` until the helper, mock Zeno integration,
and parity tests back it.

## Consequences
- **Positive**: downstream consumers (`run_control_pipeline`, Lean `gaugeFix`, Mode-3 wrappers) can read analytic-shadow fingerprints without recomputing them; the original 1e-9 parity contract on `xn_kernel` remains intact.
- **Negative / Constraints**: added CPU cost from `hardy_z_block` + Newton refinement; the GUE-deviation proxy is a lightweight outlier fraction, not a full Montgomery/GUE histogram comparison.
- **Verification Strategy**: re-run `scripts/phase_mirror_loop.py`; the tension must drop out of the ranked list (score -> 0) once the backing implementation exists, is tested, and the parity contract is preserved.

## Metrics (resolution is confirmed when)
- `compute_zero_shadow_metrics` exists, returns `(first_zero_approx, mean_spacing, gue_deviation)`, and is consumed by `mock_zeno_compute_kernel_telemetry`.
- Parity mode still guarantees `|xn_kernel - X_n| < 1e-9` after the extension.
- `tests/test_kernel_parity.py` contains 4 new analytic-shadow tests and the full suite passes (11 passed).
- `__init__.py` exports the extended contract and evaluator.

## Actionable Levers
1. Extend `KernelTelemetry` dataclass with `first_zero_approx: float = 0.0`, `mean_spacing: float = 1.0`, `gue_deviation: float = 0.0` and bump schema versioning.
2. Implement `compute_zero_shadow_metrics(...)` calling `find_zeros_refined` (sign-change + Newton) on the `hardy_z_block` evaluator to produce refined zero ordinates.
3. Update `mock_zeno_compute_kernel_telemetry` with `include_zero_shadow=True` (default) to populate the three new fields while preserving the 1e-9 parity contract on core drift/protection fields.
4. Add 4 parity tests: population, parity preservation, block-path coverage, and end-to-end pipeline acceptance.
5. Export the extended contract and evaluator from `__init__.py`.
6. Re-run `tests/test_kernel_parity.py` and confirm 11 passed in < 5 s.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`
