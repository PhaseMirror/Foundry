# ADR-PML-036: Analytic-shadow fields present in `KernelTelemetry` but not fed back into `effective_eta` / Mode-3 wrapper (3 gaps)

## Status
Adopted

## Axis (Phase Mirror tension class)
control desired vs available

## Owner (multi-agent lever)
`the-guardian`

## Dissonance Score
- Impact = severity (3) x blast radius (3) = **9**
- Tractability = **1.0**
- **Score = 9.0**  (cluster rank 1 of 1)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - docs/adr/proposed/ADR-PML-035.md:43 — asserts downstream consumers can read analytic-shadow fingerprints without recomputing them
  - docs/adr/proposed/ADR-PML-035.md:55 — asserts `compute_zero_shadow_metrics` is consumed by `mock_zeno_compute_kernel_telemetry`
  - docs/adr/accepted/ADR-096-ACE-PhaseMirror-Kernel-Telemetry-Contract.md:24 — asserts `KernelTelemetry` schema supports backward-compatible extensions for new metrics

### Implementation reality (lean/)
  - `KernelTelemetry` carries `first_zero_approx`, `mean_spacing`, `gue_deviation` but `run_control_pipeline` does not use them to modulate `effective_eta`
  - `effective_eta = eta / (1.0 + telemetry.zeta_shadow)` ignores the three analytic-shadow fields entirely
  - Mode-3 feasibility map (`enforce_feasibility_map` mode=3) receives `effective_eta` unchanged, so spectral statistics have no effect on the distance-to-Hecke-span bound

### Manifested boundary
Leaked (unmanifested): YES — gap is NOT manifested in `alp_sorry_manifest.json` (silent leak risk)

## Decision (the lever)
Resolve the dissonance by feeding the analytic-shadow fields back into the
control pipeline so that `effective_eta` (and optionally `effective_epsilon`)
are modulated by spectral statistics. Treat the missing feedback loop as
`Proposed` until the mapping is implemented, tested, and the parity contract
is preserved.

## Consequences
- **Positive**: the Mode-3 wrapper becomes shadow-aware; high `gue_deviation` damps `effective_eta` (more conservative perturbations), while `mean_spacing` and `first_zero_approx` inject global/local spectral information into archimedean normalization.
- **Negative / Constraints**: coefficients must remain small to avoid instability; the GUE-deviation proxy is a lightweight outlier fraction, not a full histogram comparison.
- **Verification Strategy**: re-run `scripts/phase_mirror_loop.py`; the tension must drop out of the ranked list (score -> 0) once the feedback mapping is implemented and tested.

## Metrics (resolution is confirmed when)
- `effective_eta` in `run_control_pipeline` depends on `gue_deviation`, `mean_spacing`, and/or `first_zero_approx`.
- Mode-3 feasibility map produces different `effective_eta` values when analytic-shadow inputs change.
- Parity tests confirm the 1e-9 parity contract on `xn_kernel` remains intact.
- `tests/test_kernel_parity.py` passes with the updated feedback logic.

## Actionable Levers
1. Update `run_control_pipeline` to compute `effective_eta = eta / (1.0 + zeta_shadow) * spacing_factor * dissonance_damp` where `spacing_factor = mean_spacing` and `dissonance_damp = 1 - gue_deviation * 0.15`.
2. Optionally modulate `effective_epsilon = epsilon * max(0.0, 1.0 - xn_kernel - zero_correction)` using `first_zero_approx`.
3. Add a parity test verifying that `effective_eta` changes when `gue_deviation` or `mean_spacing` change while other inputs are held constant.
4. Re-run `tests/test_kernel_parity.py` and confirm all tests pass.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`
