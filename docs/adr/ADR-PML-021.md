# ADR-PML-021: Documented Lean theorems missing in the `moc` subsystem (24 gaps)

## Status
Proposed

## Axis (Phase Mirror tension class)
urgency vs capacity

## Owner (multi-agent lever)
`the-examiner`

## Dissonance Score
- Impact = severity (4) x blast radius (24) = **40**
- Tractability = **1.0**
- **Score = 40.0**  (cluster rank 4 of 17)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - docs/MOC.md:30 — asserts `arta_gluing_consistency` exists / is verified
  - docs/MOC.md:61 — asserts `operator_contractive` exists / is verified
  - docs/adr/ADR-066-PIRTM-MOC-Compiler-Production-Readiness.md:103 — asserts `type_check_sound` exists / is verified
  - docs/adr/ADR-066-PIRTM-MOC-Compiler-Production-Readiness.md:108 — asserts `WellTyped` exists / is verified
  - docs/adr/ADR-068-MOC-CRMF-Contraction-Certificate-Production-Ratification.md:77 — asserts `issue_certificate` exists / is verified
  - docs/adr/ADR-068-MOC-CRMF-Contraction-Certificate-Production-Ratification.md:89 — asserts `certificate_issuance_sound` exists / is verified
  - docs/adr/ADR-068-MOC-CRMF-Contraction-Certificate-Production-Ratification.md:96 — asserts `prime_gated_certificate` exists / is verified
  - docs/adr/ADR-068-MOC-CRMF-Contraction-Certificate-Production-Ratification.md:117 — asserts `activate_resonance` exists / is verified

### Implementation reality (lean/)
  - `arta_gluing_consistency` not found among 7997 lean declarations
  - `operator_contractive` not found among 7997 lean declarations
  - `type_check_sound` not found among 7997 lean declarations
  - `WellTyped` not found among 7997 lean declarations

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
1. Manifest the missing theorem(s) `arta_gluing_consistency`, `operator_contractive`, `type_check_sound`, `issue_certificate`, `certificate_issuance_sound`, `prime_gated_certificate`, `activate_resonance`, `resonance_preserves_contraction`, `commutation_f`, `commute`, `commutation_respects_prime_grading`, `resonance_functional`, +7 more as gated `sorry` stubs under `lean/Core/` and register each in `alp_sorry_manifest.json` (run the loop with `--scaffold-proofs`).
2. Add paired Rust/Kani stubs + governance tests in `crates/` per ADR-054 / ADR-045 hybrid boundary policy, so the gap is owned, not silent.
3. File proof-engineering tickets sized by effort; close `sorry`s in priority order from the ranked loop index until this cluster's score trends to 0.
4. Re-run `scripts/phase_mirror_loop.py` and confirm this tension's score decreases.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`
