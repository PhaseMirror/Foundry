# ADR-PML-002: Documented Lean theorems missing in the `general` subsystem (48 gaps)

## Status
Proposed

## Axis (Phase Mirror tension class)
urgency vs capacity

## Owner (multi-agent lever)
`the-examiner`

## Dissonance Score
- Impact = severity (4) x blast radius (48) = **40**
- Tractability = **1.0**
- **Score = 40.0**  (cluster rank 2 of 14)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - docs/PIRTM_SPEC.md:181 — asserts `successor_contractivity_correct` exists / is verified
  - docs/adr/accepted/ADR-065-ACE-Runtime-Production-Hardening.md:80 — asserts `ace_preserves_invariants` exists / is verified
  - docs/adr/accepted/ADR-065-ACE-Runtime-Production-Hardening.md:88 — asserts `budget_exhaustion_detected` exists / is verified
  - docs/adr/accepted/ADR-078-Sovereign-Stack-TwinBinding-TEE-Attestation.md:76 — asserts `global_contraction_margin` exists / is verified
  - docs/adr/accepted/ADR-078-Sovereign-Stack-TwinBinding-TEE-Attestation.md:84 — asserts `check_twin_binding` exists / is verified
  - docs/adr/accepted/ADR-078-Sovereign-Stack-TwinBinding-TEE-Attestation.md:93 — asserts `twin_binding_contractive` exists / is verified
  - docs/adr/accepted/ADR-078-Sovereign-Stack-TwinBinding-TEE-Attestation.md:116 — asserts `lambda_trace_atom_valid` exists / is verified
  - docs/adr/accepted/ADR-078-Sovereign-Stack-TwinBinding-TEE-Attestation.md:122 — asserts `lambda_trace_atom_sound` exists / is verified

### Implementation reality (lean/)
  - `successor_contractivity_correct` not found among 8218 lean declarations
  - `ace_preserves_invariants` not found among 8218 lean declarations
  - `budget_exhaustion_detected` not found among 8218 lean declarations
  - `global_contraction_margin` not found among 8218 lean declarations

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
1. Manifest the missing theorem(s) `successor_contractivity_correct`, `ace_preserves_invariants`, `budget_exhaustion_detected`, `global_contraction_margin`, `check_twin_binding`, `twin_binding_contractive`, `lambda_trace_atom_valid`, `lambda_trace_atom_sound`, `noise_decay`, `exponential_decay`, `decay_strictly_decreasing`, `prime_weighted_qft`, +32 more as gated `sorry` stubs under `lean/Core/` and register each in `alp_sorry_manifest.json` (run the loop with `--scaffold-proofs`).
2. Add paired Rust/Kani stubs + governance tests in `crates/` per ADR-054 / ADR-045 hybrid boundary policy, so the gap is owned, not silent.
3. File proof-engineering tickets sized by effort; close `sorry`s in priority order from the ranked loop index until this cluster's score trends to 0.
4. Re-run `scripts/phase_mirror_loop.py` and confirm this tension's score decreases.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`
