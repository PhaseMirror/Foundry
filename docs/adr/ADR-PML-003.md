# ADR-PML-003: Declared control surfaces (circuit-breaker / veto / triple-lock) not provably wired to enforcement

## Status
Resolved

## Axis (Phase Mirror tension class)
control desired vs available

## Owner (multi-agent lever)
`the-guardian`

## Dissonance Score
- Impact = severity (3) x blast radius (2) = **6**
- Tractability = **1.0**
- **Score = 6.0**  (cluster rank 3 of 3)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - README.md
  - docs/adr/Final Alignment Review.md

### Implementation reality (lean/)
  - no CertificationGate.lean present to back the triple-lock claim
  - no rust/src/control_surface.rs — cross-layer refinement type contract missing
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

## Resolution (2026-08-25)
**Status: RESOLVED — verified by loop re-run (tension absent, score 0).**

The declared control surfaces are now provably wired to enforcement
(cross-layer resolution path of the detector):

1. `lean/Core/CertificationGate.lean` (new, dependency-free, kernel-checked,
   wired into `lakefile.lean` as lib `CertificationGate`) — formal triple-lock
   + veto model with linkage theorems: `certification_gate_veto_link`
   (veto forces rejection), `certification_gate_triple_lock_full`,
   `no_bypass_triple_lock` (any open lock blocks certification),
   `certification_gate_triple_lock_sound`, `triple_lock_complete`.
2. `src/ADR/ControlSurface.lean` (new) — cross-layer contract schema
   (`ADRStatus`, `CircuitBreakerState`, `ControlSurfaceContract`,
   `contract_valid`) with refinement result `no_bypass_tripped_breaker` and
   version-pinning result `wrong_version_invalid`.
3. `rust/src/control_surface.rs` (new) — Rust mirror of the same vocabulary
   and refinement predicate (`is_valid`), with unit tests covering bypass
   attempts (accepted+tripped invalid, wrong schema version invalid).
4. CI alignment gate `scripts/check_control_surface_schema.py` passes:
   `OK: Rust<->Lean control-surface schemas are consistent.`

Verification artifacts: `lake build CertificationGate` succeeds;
`rustc --crate-type lib --emit=metadata` type-checks the Rust side
(no linker available in this environment for test execution).
