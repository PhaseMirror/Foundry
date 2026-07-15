# ADR-PML-005: Documented Lean theorems missing in the `bindu-rta` subsystem (15 gaps)

## Status
Proposed

## Axis (Phase Mirror tension class)
urgency vs capacity

## Owner (multi-agent lever)
`the-examiner`

## Dissonance Score
- Impact = severity (4) x blast radius (15) = **40**
- Tractability = **1.0**
- **Score = 40.0**  (cluster rank 5 of 17)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - docs/adr/ADR-043-Rta-Morphism-and-Bindu.md:26 — asserts `fit_fixed_point_is_bindu` exists / is verified
  - docs/adr/ADR-043-Rta-Morphism-and-Bindu.md:107 — asserts `resonance_score` exists / is verified
  - docs/adr/ADR-043-Rta-Morphism-and-Bindu.md:108 — asserts `operator_norm` exists / is verified
  - docs/adr/ADR-043-Rta-Morphism-and-Bindu.md:110 — asserts `contraction_holds` exists / is verified
  - docs/adr/ADR-043-Rta-Morphism-and-Bindu.md:135 — asserts `fit_non_expansive` exists / is verified
  - docs/adr/ADR-043-Rta-Morphism-and-Bindu.md:140 — asserts `fit_resonance_increases` exists / is verified
  - docs/adr/ADR-043-Rta-Morphism-and-Bindu.md:145 — asserts `fit_fixed_point_convergence` exists / is verified
  - docs/adr/ADR-043-Rta-Morphism-and-Bindu.md:156 — asserts `testState` exists / is verified

### Implementation reality (lean/)
  - `fit_fixed_point_is_bindu` not found among 7997 lean declarations
  - `resonance_score` not found among 7997 lean declarations
  - `operator_norm` not found among 7997 lean declarations
  - `contraction_holds` not found among 7997 lean declarations

### Manifested boundary
Leaked (unmanifested): YES — gap is NOT manifested in `alp_sorry_manifest.json` (silent leak risk)

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
1. Manifest the missing theorem(s) `fit_fixed_point_is_bindu`, `resonance_score`, `operator_norm`, `contraction_holds`, `fit_non_expansive`, `fit_resonance_increases`, `fit_fixed_point_convergence`, `testState`, `lowResState`, `fittedState`, `badUpdate`, `finiteStates` as gated `sorry` stubs under `lean/Core/` and register each in `alp_sorry_manifest.json` (run the loop with `--scaffold-proofs`).
2. Add paired Rust/Kani stubs + governance tests in `crates/` per ADR-054 / ADR-045 hybrid boundary policy, so the gap is owned, not silent.
3. File proof-engineering tickets sized by effort; close `sorry`s in priority order from the ranked loop index until this cluster's score trends to 0.
4. Re-run `scripts/phase_mirror_loop.py` and confirm this tension's score decreases.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`
