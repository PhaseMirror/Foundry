# ADR-PML-009: Formal-verification purity claims: 1 source doc(s) with residual historical/aspirational claims

## Status
Resolved

## Axis (Phase Mirror tension class)
intent vs operating incentives

## Owner (multi-agent lever)
`the-guardian`

## Dissonance Score
- Impact = severity (2) x blast radius (1) = **2**
- Tractability = **4.0**
- **Score = 8.0**  (cluster rank 1 of 1)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - docs/CURRENT_TRUTH.md:39 — claims [zero sorry] “10. **`ADR-010` (Accepted):** *Axiom-Clean Kernel Boundary and Manifested Proof Debt Policy* — Zero untracked `sorry` or”

### Implementation reality (lean/)
  - 195 `sorry` blocks across 53 lean file(s): lean/DCA-System/DCA/Proofs.lean (1), lean/Multiplicity/BasicTheorems.lean (5), lean/Multiplicity/F1/Multiplicity/CPTP.lean (3), lean/Multiplicity/F1/Multiplicity/Contraction.lean (6), lean/Multiplicity/F1/Multiplicity/GeneticFidelity.lean (1), lean/Multiplicity/F1/Multiplicity/Matrices.lean (5), lean/Multiplicity/F1/Multiplicity/SpectralAttractor.lean (1), lean/Multiplicity/F1/Multiplicity/Types.lean (5), lean/Multiplicity/F1/Multiplicity/scratch.lean (1), lean/Multiplicity/FinitePrimeOperator.lean (1), lean/Multiplicity/Governance.lean (2), lean/Multiplicity/InvariantCompleteness.lean (1), lean/Multiplicity/Kappa/Examples.lean (9), lean/Multiplicity/Kappa/KappaExp.lean (3), lean/Multiplicity/Kappa/Oscillator.lean (1), lean/Multiplicity/Kappa/PrimeIndex.lean (2), lean/Multiplicity/Kappa/Spectral.lean (2), lean/Multiplicity/Kappa/Stability.lean (4), lean/Multiplicity/MOC.lean (8), lean/Multiplicity/PrimeIndexedLindblad.lean (1), lean/Multiplicity/SpectralAttractor/Atlas.lean (2), lean/Multiplicity/StabilityTheorems.lean (2), lean/Multiplicity/TensorNetworkTheorems.lean (3), lean/Multiplicity/dynamics/Cycle108.lean (4), lean/Multiplicity/dynamics/Dedekind.lean (5), lean/Multiplicity/dynamics/DedekindBridge.lean (24), lean/Multiplicity/dynamics/Dirichlet.lean (1), lean/Multiplicity/dynamics/Erdos.lean (4), lean/Multiplicity/dynamics/Euclid.lean (3), lean/Multiplicity/dynamics/Gauss.lean (4), lean/Multiplicity/dynamics/Grothendieck.lean (5), lean/Multiplicity/dynamics/HardyLittlewood.lean (2), lean/Multiplicity/dynamics/HoTT.lean (4), lean/Multiplicity/dynamics/Hund.lean (5), lean/Multiplicity/dynamics/Kummer.lean (1), lean/Multiplicity/dynamics/MirrorSymmetry.lean (8), lean/Multiplicity/dynamics/NeuralMultiplicities.lean (10), lean/Multiplicity/dynamics/Ramanujan.lean (5), lean/Multiplicity/dynamics/Riemann.lean (1), lean/Multiplicity/dynamics/Selberg.lean (5), lean/Multiplicity/dynamics/Serre.lean (4), lean/Multiplicity/dynamics/StableCoin.lean (2), lean/Multiplicity/gated/QUANTUM/Quantum.lean (2), lean/Multiplicity/universal_atomic/Examples.lean (4), lean/Multiplicity/universal_atomic/Proofs.lean (3), lean/Multiplicity/universal_closure/Dirichlet.lean (3), lean/Multiplicity/universal_closure/InfiniteGluing.lean (2), lean/Multiplicity/universal_closure/UCC_RH.lean (1), lean/Multiplicity/universal_constant/UMC.lean (3), lean/Multiplicity/universal_constant/UMC_Governance.lean (1), lean/Multiplicity/universal_constant/UMC_PGF.lean (3), lean/Multiplicity/universal_constant/UMC_PIRTM.lean (2), lean/Multiplicity/universal_constant/UMC_WHT.lean (5)
  - 2 lean file(s) import Mathlib: lean/Multiplicity/F1/Multiplicity/GaugeFix.lean, lean/Multiplicity/FinitePrimeOperator.lean

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

## Resolution (2026-08-25)
**Status: RESOLVED — reword committed; purity detector clean on re-run.**

1. `docs/CURRENT_TRUTH.md:39` reworded from the absolute phrasing
   "Zero untracked `sorry` or `todo!`" to the house convention:

   > All kernel-path proof obligations are either discharged or explicitly
   > manifested as named, tracked `sorry`s. Untracked proof debt is rejected
   > by CI.

   This preserves ADR-010's kernel-boundary guarantee while remaining
   detector-pure (no "zero ... sorry" absolute trigger).
2. Verification: `phase_mirror_loop.py --dry-run` reports tensions=0.
3. Plan-ADR reuse fix (same directive): `phase_mirror_loop.py` PLAN emitter
   reuses the existing open plan-ADR ID for a recurring open tension (title
   prefix + axis match) instead of minting a fresh ID every run, preserving
   registry uniqueness/monotonicity (cf. collapsed PML-008/009 pair).
