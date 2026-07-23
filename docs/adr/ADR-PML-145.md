# ADR-PML-145: Documented physical/mathematical invariants asserted as guaranteed but risk not owned

## Status
Proposed

## Axis (Phase Mirror tension class)
risk claimed vs risk owned

## Owner (multi-agent lever)
`the-publisher`

## Dissonance Score
- Impact = severity (4) x blast radius (24) = **40**
- Tractability = **3.0**
- **Score = 120.0**  (cluster rank 2 of 6)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - README.md:74 — | `sigma/` | Sigma kernel (ADR-062): L_eff < 1.0 AND drift <= tau_r, Blake3 witness, Kani verification |
  - README.md:167 — | `sigma_kernel/` | `SpectralState`, `SigmaKernelInvariant` (L_eff < 1.0 AND drift <= tau_R), dissonance classifier |
  - docs/MOC.md:68 — This strict bound is what allows the UAC substrate to scale to 100-concurrent requests safely. As long as the global ope
  - docs/PIRTM_SPEC.md:166 — 2. **Runtime checks** in the WardMonitor (ρ drift threshold). Telemetry tests enforce `ANOMALY_GOV_THRESHOLD < 0.85` for
  - docs/adr/ADR-PML-003.md:23 — - README.md:74 — | `sigma/` | Sigma kernel (ADR-062): L_eff < 1.0 AND drift <= tau_r, Blake3 witness, Kani verification 

### Implementation reality (lean/)
  - threshold symbols referenced in lean declarations: l_eff, r_sc, rsc, tau_r, threshold

### Manifested boundary
Leaked (unmanifested): no

## Decision (the lever)
Resolve the dissonance by manifesting the gap and closing it with a verified
artifact rather than letting the claimed guarantee stand unbacked. Treat the
unproven claim as `Proposed` until a Lean proof (or a manifested `sorry` + Rust
stub, per `alp_sorry_manifest.json`) backs it.

## Consequences
- **Positive**: claimed guarantees become auditable; silent leaks into policy
  decisions are eliminated; the UAC-ALP boundary stays honest on every CI run.
- **Negative / Constraints**: temporary downgrade of the marketing-grade claim
  until the proof lands; added CI surface for the manifested stub.
- **Verification Strategy**: re-run `scripts/phase_mirror_loop.py`; the tension
  must drop out of the ranked list (score -> 0) once the backing proof exists
  and the manifest is reconciled.

## Metrics (resolution is confirmed when)
- The cited theorem/invariant exists in `lean/` and compiles free of unmanifested `sorry`.
- OR the gap is explicitly listed in `alp_sorry_manifest.json` with a paired Rust stub + governance test.
- Dissonance score for this axis trends to 0 on subsequent loop runs.

## Actionable Levers
1. Encode the documented invariant as a Lean `def`/`theorem` threshold and prove the bound; reference it from the enforcing crate.
2. Wire the Sigma Kernel breach emission into `crates/mirror-dissonance/src/physics_rules.rs` so the claimed circuit-breaker actually traps (per ADR-402).
3. Re-run `scripts/phase_mirror_loop.py` and confirm this tension's score decreases.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`
