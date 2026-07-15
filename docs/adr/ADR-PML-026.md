# ADR-PML-026: Documented Lean theorems missing in the `adr-scaffold` subsystem (8 gaps)

## Status
Proposed

## Axis (Phase Mirror tension class)
urgency vs capacity

## Owner (multi-agent lever)
`the-examiner`

## Dissonance Score
- Impact = severity (4) x blast radius (8) = **32**
- Tractability = **1.0**
- **Score = 32.0**  (cluster rank 9 of 17)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - docs/adr/ADR Prime Moves Scaffolding.md:64 — asserts `E_τ_star` exists / is verified
  - docs/adr/ADR Prime Moves Scaffolding.md:110 — asserts `T_crit` exists / is verified
  - docs/adr/ADR Prime Moves Scaffolding.md:113 — asserts `off_line_zero_impossible_above_critical_height` exists / is verified
  - docs/adr/ADR Prime Moves Scaffolding.md:136 — asserts `RH_analytic_proof` exists / is verified
  - docs/adr/ADR-057-LEAN4_ADR_SCAFFOLDING.md:112 — asserts `isValidTransition` exists / is verified
  - docs/adr/ADR-057-LEAN4_ADR_SCAFFOLDING.md:121 — asserts `accepted_is_irreversible` exists / is verified
  - docs/adr/ADR-057-LEAN4_ADR_SCAFFOLDING.md:131 — asserts `consequencesEntailed` exists / is verified
  - docs/adr/ADR-057-LEAN4_ADR_SCAFFOLDING.md:145 — asserts `ADR_001_Riemann` exists / is verified

### Implementation reality (lean/)
  - `E_τ_star` not found among 7997 lean declarations
  - `T_crit` not found among 7997 lean declarations
  - `off_line_zero_impossible_above_critical_height` not found among 7997 lean declarations
  - `RH_analytic_proof` not found among 7997 lean declarations

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
1. Manifest the missing theorem(s) `off_line_zero_impossible_above_critical_height`, `isValidTransition`, `accepted_is_irreversible`, `consequencesEntailed` as gated `sorry` stubs under `lean/Core/` and register each in `alp_sorry_manifest.json` (run the loop with `--scaffold-proofs`).
2. Add paired Rust/Kani stubs + governance tests in `crates/` per ADR-054 / ADR-045 hybrid boundary policy, so the gap is owned, not silent.
3. File proof-engineering tickets sized by effort; close `sorry`s in priority order from the ranked loop index until this cluster's score trends to 0.
4. Re-run `scripts/phase_mirror_loop.py` and confirm this tension's score decreases.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`
