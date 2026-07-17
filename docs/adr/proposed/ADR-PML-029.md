# ADR-PML-029: Documented Lean theorems missing in the `archivum` subsystem (4 gaps)

## Status
Proposed

## Axis (Phase Mirror tension class)
urgency vs capacity

## Owner (multi-agent lever)
`the-examiner`

## Dissonance Score
- Impact = severity (4) x blast radius (4) = **16**
- Tractability = **1.0**
- **Score = 16.0**  (cluster rank 12 of 17)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - docs/adr/ADR-067-Archivum-Immutable-Ledger-Production-Deployment.md:76 — asserts `append` exists / is verified
  - docs/adr/ADR-067-Archivum-Immutable-Ledger-Production-Deployment.md:84 — asserts `ledger_append_only` exists / is verified
  - docs/adr/ADR-067-Archivum-Immutable-Ledger-Production-Deployment.md:95 — asserts `ledger_tamper_evident` exists / is verified
  - docs/adr/ADR-067-Archivum-Immutable-Ledger-Production-Deployment.md:104 — asserts `witness_uniqueness` exists / is verified

### Implementation reality (lean/)
  - `append` not found among 7997 lean declarations
  - `ledger_append_only` not found among 7997 lean declarations
  - `ledger_tamper_evident` not found among 7997 lean declarations
  - `witness_uniqueness` not found among 7997 lean declarations

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
1. Manifest the missing theorem(s) `append`, `ledger_append_only`, `ledger_tamper_evident`, `witness_uniqueness` as gated `sorry` stubs under `lean/Core/` and register each in `alp_sorry_manifest.json` (run the loop with `--scaffold-proofs`).
2. Add paired Rust/Kani stubs + governance tests in `crates/` per ADR-054 / ADR-045 hybrid boundary policy, so the gap is owned, not silent.
3. File proof-engineering tickets sized by effort; close `sorry`s in priority order from the ranked loop index until this cluster's score trends to 0.
4. Re-run `scripts/phase_mirror_loop.py` and confirm this tension's score decreases.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`
