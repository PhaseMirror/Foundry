# ADR-004: Zeta-Shadow Telemetry Field

## Status
Accepted (2026-07-15)

## Context
The ACE–SCN–CSC–PhaseMirror unification defines drift and protection metrics via kernel telemetry. The postulate that primes are a shadow of ζ suggests that incorporating a smoothed prime-distribution proxy can improve the control and certification guarantees.

## Decision
Extend the `KernelTelemetry` contract with a `zeta_shadow` field (float, default 1.0). This field is used to modulate the effective `eta` in the Mode 3 feasibility map, tightening the distance-to-Hecke-span bound when prime density is high. It also influences the archimedean weight in `gaugeFix`.

## Consequences
- The control pipeline becomes sensitive to global arithmetic data, aligning with the shadow duality.
- The formal proofs of negativity preservation now depend on the assumption that `zeta_shadow` is bounded below (a conditional theorem).
- Testing confirms that the output changes in a controlled manner.

## Related Files
- `engine.py` (KernelTelemetry, run_control_pipeline)
- `gaugeFix.lean` (gaugeFix, zeta_shadow_implies_margin)
- `driver.rs` (certified_perturbation, build_features)
- `test_kernel_parity.py` (zeta_shadow tests)
