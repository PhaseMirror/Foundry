# ADR-PML-002: Formal-verification purity claims contradict the UAC-ALP boundary reality

## Status
Proposed

## Axis (Phase Mirror tension class)
intent vs operating incentives

## Owner (multi-agent lever)
`the-guardian`

## Dissonance Score
- Impact = severity (5) x blast radius (22) = **50**
- Tractability = **4.0**
- **Score = 200.0**  (cluster rank 2 of 17)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - README.md:12 — claims [100% formal verification] “The **Universal Atomic Calculator (UAC)** provides a 100% formally verified, pure-math engine in Lean 4. To bridge pure ”
  - docs/CHANGELOG.md:9 — claims [no sorry / sorry-free] “- PWEH formalization in Lean 4 (`substrates/lean/MOC/PWEH.lean`) - sorry-free, core-only”
  - docs/GEMINI.md:9 — claims [no sorry / sorry-free] “- **Axiom-Clean Core:** All recursive stability proofs must be anchored to the canonical Lean 4 `MOC/Core.lean` (found i”
  - docs/Lambda_Proof_Binding.md:35 — claims [zero sorry] “- A proven theorem (`admissible_implies_civic_minimum`) demonstrating that any state transition successfully verified ag”
  - docs/MOC.md:68 — claims [mathematically guaranteed] “This strict bound is what allows the UAC substrate to scale to 100-concurrent requests safely. As long as the global ope”
  - docs/MSP_1.md:61 — claims [zero sorry] “This report presents Multiplicity Social Physics, a unified framework that integrates quantum dynamics, fractal geometry”

### Implementation reality (lean/)
  - manifest permits 13 sorry(s) not present in current lean: ALP.Archivum.WitnessContract.witness_after_admit_implies_constitution_valid, ALP.Archivum.WitnessContract.witness_after_veto_implies_disallowed, ALP.Candle.PirtmBridge.candle_ignition_sound, ALP.Contracts.NonBypassability.no_unaligned_execution, ALP.Contracts.TrustArbitration.external_blocks_governed_mcp ...

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
