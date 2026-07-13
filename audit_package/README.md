# PIRTM/MOC External Audit Package

This directory contains the necessary artifacts for an independent, third-party formal security audit of the Universal Atomic Calculator (UAC) Substrate and the Sedona Spine governance kernel.

## Audit Scope

The primary objective is to verify that the Triple-Lock governance system, the GOV_HASH attestation chain, and the underlying mathematical contractivity models (MOC) are robust against narrative dissonance, semantic drift, and adversarial utilization spikes.

### In-Scope Artifacts
1. **Triple-Lock Implementation:** Review the Guardian / Examiner / Publisher consensus flow.
2. **GOV_HASH Pipeline:** Verify that `observability/anomaly_model.pkl` is cryptographically sealed by `build.rs` and bound to the `.sig` manifest.
3. **PIRTM Contractivity:** Independently compile and verify all Lean 4 files under `pirtm-*` and `moc-*` to ensure zero use of `sorry` or `native_decide` escapes.
4. **Resonance Limits (CRMF):** Review the Sedona Spine boundary that guarantees a `SIG_GOV_KILL` when the PhaseMirror telemetry vector exceeds threshold `0.0006`.

### Out-of-Scope
- The high-level PIRTM language surface (grammar, parser, MLIR frontend), which is explicitly classified as research-grade per ADR-012.

## Success Criteria
- Independent reproduction of the Lean 4 build environment passing all proofs without cheating.
- Red-team validation confirming that substituting a modified `anomaly_model.pkl` results in a definitive build/runtime panic.
- Cryptographic verification of the Cosign signatures for the multi-arch `ghcr.io/multiplicity/uac` images.
