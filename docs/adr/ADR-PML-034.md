# ADR-PML-034: Documented Lean theorems missing in the `general` subsystem (31 gaps)

## Status
Proposed

## Axis (Phase Mirror tension class)
urgency vs capacity

## Owner (multi-agent lever)
`the-examiner`

## Dissonance Score
- Impact = severity (4) x blast radius (31) = **40**
- Tractability = **1.0**
- **Score = 40.0**  (cluster rank 2 of 11)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - docs/adr/completed/ADR-090-Mathlib-Sorry-Elimination-Plan.md:34 — asserts `Init` exists / is verified
  - docs/adr/completed/ADR-115-UCC-Production-Grade Implementation.md:252 — asserts `unit` exists / is verified
  - docs/adr/completed/ADR-115-UCC-Production-Grade Implementation.md:280 — asserts `associator` exists / is verified
  - docs/adr/completed/ADR-115-UCC-Production-Grade Implementation.md:310 — asserts `completion_adjunction` exists / is verified
  - docs/adr/completed/ADR-115-UCC-Production-Grade Implementation.md:333 — asserts `free_one_generator_is_nno` exists / is verified
  - docs/adr/completed/ADR-115-UCC-Production-Grade Implementation.md:353 — asserts `compositional_defect` exists / is verified
  - docs/adr/completed/ADR-115-UCC-Production-Grade Implementation.md:369 — asserts `morphism_soundness` exists / is verified
  - docs/adr/completed/ADR-PML-051-Post-Quantum-Signatures.md:149 — asserts `DilithiumVerifySound` exists / is verified

### Implementation reality (lean/)
  - `Init` not found among 6978 lean declarations
  - `unit` not found among 6978 lean declarations
  - `associator` not found among 6978 lean declarations
  - `completion_adjunction` not found among 6978 lean declarations

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
1. Manifest the missing theorem(s) `unit`, `associator`, `completion_adjunction`, `free_one_generator_is_nno`, `compositional_defect`, `morphism_soundness`, `kramers_kronig`, `ward_identity_implies_bianchi`, `complex_kappa_part_i`, `gue_deviation_bounded`, `complex_kappa_consistency_window`, `inner_sym`, +9 more as gated `sorry` stubs under `lean/Core/` and register each in `alp_sorry_manifest.json` (run the loop with `--scaffold-proofs`).
2. Add paired Rust/Kani stubs + governance tests in `crates/` per ADR-054 / ADR-045 hybrid boundary policy, so the gap is owned, not silent.
3. File proof-engineering tickets sized by effort; close `sorry`s in priority order from the ranked loop index until this cluster's score trends to 0.
4. Re-run `scripts/phase_mirror_loop.py` and confirm this tension's score decreases.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`
