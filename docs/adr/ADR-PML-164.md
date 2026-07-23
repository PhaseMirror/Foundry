# ADR-PML-164: Declared control surfaces (circuit-breaker / veto / triple-lock) not provably wired to enforcement

## Status
Proposed

## Axis (Phase Mirror tension class)
control desired vs available

## Owner (multi-agent lever)
`the-guardian`

## Dissonance Score
- Impact = severity (3) x blast radius (8) = **24**
- Tractability = **1.0**
- **Score = 24.0**  (cluster rank 3 of 6)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - README.md
  - docs/SECURITY.md
  - docs/adr/ADR-PML-003.md
  - docs/adr/ADR-PML-004.md
  - docs/adr/ADR-PML-014.md
  - docs/adr/ADR-PML-015.md
  - docs/adr/ADR-PML-024.md
  - docs/adr/ADR-PML-025.md

### Implementation reality (lean/)
  - CertificationGate.lean exists but its linkage to documented veto/triple-lock is unproven
  - see ADR-402-Phase-Mirror-Dissonance.md vs crates/mirror-dissonance/src/physics_rules.rs enforcement gap

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
1. Add Lean proofs linking `CertificationGate` to the documented veto / triple-lock, or manifest the gap explicitly.
2. Add an end-to-end governance test (guardian->examiner->publisher) asserting the control surface cannot be bypassed.
3. Re-run `scripts/phase_mirror_loop.py` and confirm this tension's score decreases.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`
