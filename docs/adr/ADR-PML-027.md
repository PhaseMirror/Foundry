# ADR-PML-027: Documented Lean theorems missing in the `moc` subsystem (5 gaps)

## Status
Proposed

## Axis (Phase Mirror tension class)
urgency vs capacity

## Owner (multi-agent lever)
`the-examiner`

## Dissonance Score
- Impact = severity (4) x blast radius (5) = **20**
- Tractability = **1.0**
- **Score = 20.0**  (cluster rank 6 of 11)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - docs/adr/completed/ADR-068-MOC-CRMF-Contraction-Certificate-Production-Ratification.md:123 — asserts `resonance_preserves_contraction` exists / is verified
  - docs/adr/completed/ADR_037_MSP2_Lean4_Rust_Implementation.md:76 — asserts `ContextEntailsConsequence` exists / is verified
  - docs/adr/completed/ADR_037_MSP2_Lean4_Rust_Implementation.md:79 — asserts `ValidADREntailment` exists / is verified
  - docs/adr/completed/ADR_037_MSP2_Lean4_Rust_Implementation.md:103 — asserts `SedonaSpineADR` exists / is verified
  - docs/adr/completed/ADR_038_MSP3_Lean4_Rust_Implementation.md:103 — asserts `SystemState_Phase1` exists / is verified

### Implementation reality (lean/)
  - `resonance_preserves_contraction` not found among 6978 lean declarations
  - `ContextEntailsConsequence` not found among 6978 lean declarations
  - `ValidADREntailment` not found among 6978 lean declarations
  - `SedonaSpineADR` not found among 6978 lean declarations

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
1. Manifest the missing theorem(s) `resonance_preserves_contraction` as gated `sorry` stubs under `lean/Core/` and register each in `alp_sorry_manifest.json` (run the loop with `--scaffold-proofs`).
2. Add paired Rust/Kani stubs + governance tests in `crates/` per ADR-054 / ADR-045 hybrid boundary policy, so the gap is owned, not silent.
3. File proof-engineering tickets sized by effort; close `sorry`s in priority order from the ranked loop index until this cluster's score trends to 0.
4. Re-run `scripts/phase_mirror_loop.py` and confirm this tension's score decreases.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`
