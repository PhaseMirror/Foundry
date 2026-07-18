# ADR-PML-037: `gaugeFix` positivity theorem and shadow-aware Mode-3 wrapper not yet formalized in Lean (3 gaps)

## Status
Proposed

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
  - docs/adr/proposed/ADR-PML-036.md:43 — asserts the Mode-3 wrapper becomes shadow-aware when `effective_eta` is modulated by spectral statistics
  - docs/adr/accepted/ADR-095-PhaseMirror-Kernel-Semantic-Authority.md:20 — asserts kernel emits certified scalars to downstream consumers without recomputation
  - docs/adr/accepted/ADR-096-ACE-PhaseMirror-Kernel-Telemetry-Contract.md:24 — asserts `KernelTelemetry` schema supports backward-compatible extensions for new metrics

### Implementation reality (lean/)
  - `F1Surface/Lean/Control/GaugeFix.lean` defines `gaugeFix` but does not prove positivity preservation under the natural invariants of the extended `KernelTelemetry`
  - `atlasM_Mode3_wrapper` does not use `gue_deviation` or `mean_spacing` in the `eta` bound
  - No Lean theorem guarantees that `(gaugeFix kt).gamma > 0 ∧ (gaugeFix kt).scale > 0` when `mean_spacing > 0` and `0 ≤ gue_deviation ≤ 1`

### Manifested boundary
Leaked (unmanifested): YES — gap is NOT manifested in `alp_sorry_manifest.json` (silent leak risk)

## Decision (the lever)
Resolve the dissonance by adding the `gaugeFix_positivity` theorem to the Lean
formalization and extending `atlasM_Mode3_wrapper` to use the analytic-shadow
fields in the `eta` bound. Treat the missing formal guarantees as `Proposed`
until the theorems are proved and the shadow-aware wrapper is implemented.

## Consequences
- **Positive**: formal guarantee that `gaugeFix` never produces invalid Arakelov parameters when fed with realistic analytic-shadow inputs; Mode-3 feasibility map becomes shadow-aware in the verified layer.
- **Negative / Constraints**: the log-bound in `gaugeFix_positivity` currently assumes `first_zero_approx > 1`; weakening to `> 0` requires a tighter bound. The Mode-3 wrapper update must preserve the existing `distance_to_span ≤ eta` invariant.
- **Verification Strategy**: re-run `scripts/phase_mirror_loop.py`; the tension must drop out of the ranked list (score -> 0) once the Lean proofs exist and the wrapper is updated.

## Metrics (resolution is confirmed when)
- `gaugeFix_positivity` theorem exists in `F1Surface/Lean/Control/GaugeFix.lean` with all assumptions stated and proved.
- `atlasM_Mode3_wrapper` uses `gue_deviation` and `mean_spacing` to modulate `eta`.
- `lake build` succeeds on the updated Lean module.
- Python parity tests confirm the 1e-9 parity contract remains intact after the wrapper update.

## Actionable Levers
1. Prove `gaugeFix_positivity` in `F1Surface/Lean/Control/GaugeFix.lean` using `Real.exp_pos`, `inv_pos`, `mul_pos`, and a conservative log bound.
2. Update `atlasM_Mode3_wrapper` to compute `shadow_eta = eta * spacing_factor * dissonance_damp` using `mean_spacing` and `gue_deviation`.
3. Export the positivity result from the Lean module.
4. Add a Python mirror test for the shadow-aware `effective_eta` calculation (parity against Lean output).
5. Re-run `lake build` and `tests/test_kernel_parity.py` to confirm no regressions.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`
