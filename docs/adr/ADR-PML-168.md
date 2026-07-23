# ADR-PML-168: Formal-verification purity claims contradict the UAC-ALP boundary reality

## Status
Proposed

## Axis (Phase Mirror tension class)
intent vs operating incentives

## Owner (multi-agent lever)
`the-guardian`

## Dissonance Score
- Impact = severity (5) x blast radius (51) = **50**
- Tractability = **4.0**
- **Score = 200.0**  (cluster rank 1 of 6)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - docs/PHASE_MIRROR_DISSONANCE_REPORT_2026-07-22.md:37 — claims [no sorry / sorry-free] “declare "no sorry", "sorry-free", or "axiom-clean".”
  - docs/PHASE_MIRROR_DISSONANCE_REPORT_2026-07-22.md:41 — claims [no sorry / sorry-free] “| `PsiLine.lean` | "no `sorry`/`native_decide`" | 7 sorry blocks |”
  - docs/PHASE_MIRROR_DISSONANCE_REPORT_2026-07-22.md:45 — claims [no sorry / sorry-free] “| `GammaTwo.lean` | "no `sorry`/`native_decide`" | 4 sorry blocks |”
  - docs/PHASE_MIRROR_DISSONANCE_REPORT_2026-07-22.md:46 — claims [no sorry / sorry-free] “| `CosSinAddFormula.lean` | "no `sorry`/`native_decide`" | 1 sorry block |”
  - docs/PHASE_MIRROR_DISSONANCE_REPORT_2026-07-22.md:47 — claims [no sorry / sorry-free] “| `GammaOne.lean` | "no `sorry`/`native_decide`" | 1 sorry block |”
  - docs/PHASE_MIRROR_DISSONANCE_REPORT_2026-07-22.md:48 — claims [no sorry / sorry-free] “| `GammaZeroBracket.lean` | "no `sorry`/`native_decide`" | 1 sorry block |”

### Implementation reality (lean/)
  - 34 `sorry` blocks across 15 lean file(s): lean/Core/F1/Analysis/CosSinAddFormula.lean (1), lean/Core/F1/Analysis/GammaOne.lean (1), lean/Core/F1/Analysis/GammaTwo.lean (3), lean/Core/F1/Analysis/GammaZeroBracket.lean (1), lean/Core/F1/Analysis/PsiLine.lean (7), lean/Core/F1/Analysis/ZetaTwo.lean (1), lean/Core/F1/Governance/GeneticFidelity.lean (1), lean/Core/cultural_math/src/Theorems/BasicTheorems.lean (5), lean/Core/cultural_math/src/Theorems/StabilityTheorems.lean (2), lean/Core/cultural_math/src/Theorems/TensorNetworkTheorems.lean (3), lean/Core/moc/Dissonance.lean (1), lean/Core/phase_mirror_loop_scaffolds/ghost_theorems_misc.lean (3), lean/Core/phase_mirror_loop_scaffolds/invariant_gaps.lean (2), lean/gated/QUANTUM/Quantum.lean (2), lean/test_float.lean (1)

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
1. Update the purity ADR (e.g. ADR-Prime-Move-Deployment-Readiness.md) to segregate the verified UAC math cores from the transitional `ALP` agentic contracts.
2. Run `scripts/honesty_audit.sh`; enforce that every `sorry` is in the manifest and every manifest entry resolves to a real declaration (no stale permits).
3. Downgrade absolute '100% verified / zero sorry' wording to scoped, accurate claims until the proof budget is spent.
4. Re-run `scripts/phase_mirror_loop.py` and confirm this tension's score decreases.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`
