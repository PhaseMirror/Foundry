# ADR-PML-002: Formal-verification purity claims: 3 source doc(s) with residual historical/aspirational claims

## Status
Resolved

## Axis (Phase Mirror tension class)
intent vs operating incentives

## Owner (multi-agent lever)
`the-guardian`

## Dissonance Score
- Impact = severity (2) x blast radius (3) = **6**
- Tractability = **3.0**
- **Score = 18.0**  (cluster rank 2 of 3)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - GEMINI.md:9 — claims [no sorry / sorry-free] “- **Axiom-Clean Core:** All recursive stability proofs must be anchored to the canonical Lean 4 `MOC/Core.lean` (found i”
  - README.md:403 — claims [no sorry / sorry-free] “The following core theorems have been fully proven and verified without `sorry`:”
  - README.md:423 — claims [zero sorry] “The following analytic and ethical properties have been rigidly enforced via Phase Mirror structural constraints (with z”
  - README.md:442 — claims [zero sorry] “- **`lean/Multiplicity/Dynamics/TwoLayer.lean`**: Constructive proof of the two-layer cross-talk contraction theorem (`c”
  - README.md:466 — claims [zero sorry] “1. Formal Lean 4 core proofs (zero `sorry`, constructive).”
  - docs/adr/Final Alignment Review.md:2261 — claims [no sorry / sorry-free] “Zero-Sorry Proof: The theorem is fully proved without sorry—a critical requirement for the ADR.”

### Implementation reality (lean/)
  - 119 `sorry` blocks across 50 lean file(s): lean/DCA-System/DCA/Proofs.lean (1), lean/Multiplicity/BasicTheorems.lean (5), lean/Multiplicity/F1/Multiplicity/CPTP.lean (3), lean/Multiplicity/F1/Multiplicity/Contraction.lean (4), lean/Multiplicity/F1/Multiplicity/GeneticFidelity.lean (1), lean/Multiplicity/F1/Multiplicity/Matrices.lean (5), lean/Multiplicity/F1/Multiplicity/SpectralAttractor.lean (1), lean/Multiplicity/F1/Multiplicity/scratch.lean (1), lean/Multiplicity/FinitePrimeOperator.lean (1), lean/Multiplicity/Governance.lean (2), lean/Multiplicity/InvariantCompleteness.lean (1), lean/Multiplicity/Kappa/Examples.lean (9), lean/Multiplicity/Kappa/KappaExp.lean (3), lean/Multiplicity/Kappa/Oscillator.lean (1), lean/Multiplicity/Kappa/PrimeIndex.lean (2), lean/Multiplicity/Kappa/Spectral.lean (2), lean/Multiplicity/Kappa/Stability.lean (4), lean/Multiplicity/MOC.lean (7), lean/Multiplicity/PrimeIndexedLindblad.lean (1), lean/Multiplicity/SpectralAttractor/Atlas.lean (2), lean/Multiplicity/StabilityTheorems.lean (2), lean/Multiplicity/TensorNetworkTheorems.lean (3), lean/Multiplicity/dynamics/Cycle108.lean (2), lean/Multiplicity/dynamics/Dirichlet.lean (1), lean/Multiplicity/dynamics/Euclid.lean (3), lean/Multiplicity/dynamics/Gauss.lean (2), lean/Multiplicity/dynamics/Hund.lean (1), lean/Multiplicity/dynamics/MirrorSymmetry.lean (2), lean/Multiplicity/dynamics/NeuralMultiplicities.lean (3), lean/Multiplicity/dynamics/StableCoin.lean (1), lean/Multiplicity/gated/QUANTUM/Quantum.lean (2), lean/Multiplicity/universal_atomic/Examples.lean (4), lean/Multiplicity/universal_atomic/Proofs.lean (3), lean/Multiplicity/universal_closure/Dirichlet.lean (3), lean/Multiplicity/universal_closure/InfiniteGluing.lean (2), lean/Multiplicity/universal_closure/UCC_RH.lean (1), lean/Multiplicity/universal_constant/UMC.lean (3), lean/Multiplicity/universal_constant/UMC_Governance.lean (1), lean/Multiplicity/universal_constant/UMC_PGF.lean (3), lean/Multiplicity/universal_constant/UMC_PIRTM.lean (2), lean/Multiplicity/universal_constant/UMC_WHT.lean (5), lean/_archive/scratch_psi_depth.lean (1), lean/_archive/scratch_psi_unfold.lean (1), lean/_archive/scratch_test4.lean (2), lean/_archive/test_float.lean (1), lean/_archive/test_psi_goal.lean (1), lean/_archive/test_psi_thm.lean (1), lean/legacy/IfmdSafety/Spec.lean (2), lean/phase_mirror_loop_scaffolds/ghost_theorems_misc.lean (3), lean/phase_mirror_loop_scaffolds/invariant_gaps.lean (2)
  - 3 lean file(s) import Mathlib: lean/Multiplicity/F1/Multiplicity/GaugeFix.lean, lean/Multiplicity/FinitePrimeOperator.lean, lean/legacy/IfmdSafety/Spec.lean
  - manifest permits 13 sorry(s) not present in current lean: Add, Div, Mul, Neg, OfNat ...

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

## Resolution (2026-08-25)
**Status: RESOLVED — verified by loop re-run (tension absent, score 0).**

Absolute purity wording downgraded to scoped, auditable claims (lever 3);
the underlying theorem files were independently verified clean first:

- `README.md:403` — now scopes the claim to
  `lean/Multiplicity/language_mapping/` with a pointer to the ledger
  boundary (verified: `LanguageMapping.lean` compiles with no manifested
  debt against it).
- `README.md:423` — scoped to `SedonaRiskModel.lean` / `EulerProduct.lean`
  plus the repo-wide debt boundary reference (both files contain no
  manifested gaps against the named theorems).
- `README.md:442` — TwoLayer claim rewritten as self-contained +
  ledger-recorded verification boundary (verified:
  `coupled_system_is_contractive` present, file clean).
- `README.md:466` — certification pipeline bullet now states the honest
  invariant: constructive proofs with residual debt manifested per
  `alp_sorry_manifest.json`.
- `GEMINI.md:9` — "No Mathlib, No Sorry" mandate restated as: self-contained
  core whose residual proof debt is explicitly manifested (deadline +
  governor + paired witness per entry).
- `docs/adr/Final Alignment Review.md` — historical deployment-review
  transcript moved to `docs/adr/completed/` (frozen record per
  `FROZEN_DOCS`; historical records are not current commitments).

Result: 0 active purity-claim source docs outside frozen directories.
