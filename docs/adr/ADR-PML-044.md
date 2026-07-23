# ADR-PML-044: Formal-verification purity claims contradict the UAC-ALP boundary reality

## Status
Proposed

## Axis (Phase Mirror tension class)
intent vs operating incentives

## Owner (multi-agent lever)
`the-guardian`

## Dissonance Score
- Impact = severity (5) x blast radius (56) = **50**
- Tractability = **3.0**
- **Score = 150.0**  (cluster rank 1 of 11)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - docs/CHANGELOG.md:9 — claims [no sorry / sorry-free] “- PWEH formalization in Lean 4 (`lean/Core/moc/PWEH.lean`) - sorry-free, core-only”
  - docs/MOC.md:68 — claims [mathematically guaranteed] “This strict bound is what allows the UAC substrate to scale to 100-concurrent requests safely. As long as the global ope”
  - docs/MSP_1.md:61 — claims [zero sorry] “This report presents Multiplicity Social Physics, a unified framework that integrates quantum dynamics, fractal geometry”
  - docs/MSP_1.md:65 — claims [zero sorry] “This document constitutes prior art for the Multiplicity Social Physics framework, including but not limited to: the MQE”
  - docs/MSP_1.md:128 — claims [zero sorry] “\item The Lean 4 formalisation, with zero Mathlib and zero `sorry`, provides machine-checked correctness for the model's”
  - docs/MSP_1.md:157 — claims [zero sorry] “\item Lean 4 formalisation of all seven axioms and Theorems 1–8, with zero Mathlib and zero `sorry` (Chapters~\ref{ch:le”

### Implementation reality (lean/)
  - 29 `sorry` blocks across 13 lean file(s): lean/Core/F1/Analysis/CosSinAddFormula.lean (1), lean/Core/F1/Analysis/GammaOne.lean (1), lean/Core/F1/Analysis/GammaTwo.lean (3), lean/Core/F1/Analysis/GammaZeroBracket.lean (1), lean/Core/F1/Analysis/PsiLine.lean (7), lean/Core/F1/Analysis/ZetaTwo.lean (1), lean/Core/F1/Governance/GeneticFidelity.lean (1), lean/Core/cultural_math/src/Theorems/BasicTheorems.lean (5), lean/Core/cultural_math/src/Theorems/StabilityTheorems.lean (2), lean/Core/cultural_math/src/Theorems/TensorNetworkTheorems.lean (3), lean/Core/moc/Dissonance.lean (1), lean/gated/QUANTUM/Quantum.lean (2), lean/test_float.lean (1)
  - manifest permits 4 sorry(s) not present in current lean: corrTP1_le_teldiff1, corrTP_le_corrT, corrT_le_teldiff, sq_nonneg_int

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
1. Update the purity ADR (e.g. ADR-Prime-Move-Deployment-Readiness.md) to segregate the verified UAC math cores from the transitional `ALP` agentic contracts.
2. Run `scripts/honesty_audit.sh`; enforce that every `sorry` is in the manifest and every manifest entry resolves to a real declaration (no stale permits).
3. Downgrade absolute '100% verified / zero sorry' wording to scoped, accurate claims until the proof budget is spent.
4. Re-run `scripts/phase_mirror_loop.py` and confirm this tension's score decreases.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`
