# Plan: Eliminate `Mathlib` and `sorry` from the Prime Lean Codebase

> **Note**: This plan targets sorry elimination. Remaining sorry blocks (53 declarations) are tracked in alp_sorry_manifest.json.

## Executive Summary

- **171 actual `sorry` occurrences** in project-owned Lean files (excluding vendored `.lake/packages`).
- **37 `Mathlib` imports** across **14 files** in project-owned code.
- The project has an explicit **Zero-Drift / Axiom-Clean mandate**: *no Mathlib, sorry-bounded* (see `lean/projects/proofs/AceScnCsc.lean`, `lean/projects/lakefile.lean`).
- This plan resolves all violations in **tiers**, prioritizing Core modules and newly-added ADR integrations.

---

## Tier 1 — Core Modules (Immediate, P0)

These are the modules that downstream Lean/Rust code imports and that define the project's formal foundation.

| File | Sorrys | Mathlib | Action |
|------|--------|---------|--------|
| `lean/Core/PARM.lean` | 1 (line 123) | No | Replace `sorry` with `native_decide` or explicit `rfl`/`simp` proof for `sealed_state_collision_resistance_note`. |
| `lean/Core/moc/MOC.lean` | 3 (lines 82, 83, 132) | No | Line 82-83: replace with `by simpa [MocOperator.S_p] using h_op` or similar decidable tactic. Line 132: replace with `by omega` or `by simp [operator_weight]`. |
| `lean/Core/Affine.lean` | 1 (line 16) | No | Replace with explicit `rfl` or `simp` after unfolding `AffineCore`. |
| `lean/Core/f1_square/Square/ADR099.lean` | 1 (line 68) | No | Replace with `by native_decide` or explicit arithmetic proof. |
| `lean/Core/f1_square/Square/AtlasMode3Wrapper.lean` | 3 (lines 24-26) | No | Replace `by sorry` with `by constructor <;> simp [...]` or `by native_decide`. |

**Target:** Zero unmanifested `sorry` and zero `Mathlib` in `lean/Core/`.

---

## Tier 2 — Mathlib Imports (High, P1)

Replace Mathlib imports with core Lean 4 equivalents or minimal vendored stubs.

| File | Mathlib Imports | Replacement Strategy |
|------|-----------------|---------------------|
| `src/f1_surface/F1Surface.lean` | `Mathlib.Data.Real.Basic`, `Mathlib.Analysis.InnerProductSpace.Basic`, `Mathlib.Analysis.SpecialFunctions.Exp` | Replace with core `Real` and `Complex` from Lean 4 `Init`. Define `innerProductSpace` instance locally if needed. Replace `exp` with a locally-defined `Exp` axiom or series approximation. |
| `crates/c-pirtm/lean-harness/Math/Lipschitz.lean` | `Mathlib.Analysis.Calculus.FDeriv.Basic`, `Mathlib.Analysis.NormedSpace.Basic`, `Mathlib.Analysis.NormedSpace.LinearIsometry` | Replace with core `Norm` and `ContinuousLinearMap` definitions. FDeriv can be replaced with `HasFDerivAt` axioms or difference quotients. |
| `crates/c-pirtm/lean-harness/Main.lean` | Same as Lipschitz.lean | Same strategy. |
| `crates/chaos/chaOS-proof/ChaosProof/Stability.lean` | `Mathlib.Data.Real.Basic`, `Mathlib.Analysis.SpecialFunctions.Exp` | Replace `Real` with core `Float`/`Rat` or axiomatize `exp`. |
| `crates/drmm/lean-proofs/DRMM.lean` | 7 Mathlib imports (Real, NormedSpace, FDeriv, Pow, Topology, Nat.Prime, Complex) | High priority. Replace with core `Real`, axiomatize `FDeriv`, use `Nat.prime` from core. |
| `crates/genesis-ode/lean/Impedance.lean` | `Mathlib.Tactic`, `Mathlib.Data.Real.Basic`, `Mathlib.Data.Real.Sqrt` | Replace `Tactic` with core `simp`/`rw`. Replace `Real.sqrt` with axiomatized `Sqrt` or `Float.sqrt`. |
| `crates/goldilocks-pro/lean-proofs/Goldilocks.lean` | `Mathlib.Data.Nat.Prime`, `Mathlib.Data.ZMod.Basic`, `Mathlib.Tactic` | Replace `Nat.Prime` with core `Nat` decidability. Replace `ZMod` with `Fin n` or `Nat.mod`. Replace `Tactic` with core tactics. |
| `crates/parm/HebrewLexicon/lean4-parm/Parm/Core.lean` | `Mathlib.Data.Nat.Prime.Basic`, `Mathlib.Data.List.Basic` | **Already partially addressed** with `crates/parm/src/PARM.rs` stub. Replace Lean `Mathlib` usage with core `Nat` and `List`. |
| `crates/prime-gap-dynamics/lean-prime-gap-dynamics/LeanPrimeGapDynamics/Proofs.lean` | 3 Mathlib imports | Replace `Nat.Prime`, `Nat.Factorization`, `Nat.PrimeFin` with core `Nat` decidability and explicit factorization recursion. |
| `crates/prime-gap-dynamics/lean-prime-gap-dynamics/LeanPrimeGapDynamics/Definitions.lean` | `Mathlib.Data.Nat.GCD.Basic`, `Mathlib.Algebra.Ring.Defs` | Replace `gcd` with Euclid's algorithm definition. Replace `Ring` with core `Semiring`/`Monoid`. |
| `materia_commons/ADR/adr-lean/ADR/Proofs.lean` | `Mathlib.Tactic`, `Mathlib.Data.Set.Basic` | Replace `Set` with `List`/`Array` or explicit predicate types. Replace `Tactic` with core tactics. |
| `crates/moonshine/proofs/Moonshine.lean` | `Mathlib.Topology.MetricSpace.Basic`, `Mathlib.Analysis.SpecificLimits.Basic` | Replace `MetricSpace` with core `dist` function and `UniformSpace` axioms. Replace limits with sequences and `∀ ε > 0, ∃ N, ...`. |
| `crates/models/ataraxia/crates/moonshine/proofs/Moonshine.lean` | Commented out | Already compliant. |

---

## Tier 3 — ADR Governance & Telemetry Stubs (High, P1)

These are new ADR integrations that were scaffolded with `sorry` stubs.

| File | Sorrys | Action |
|------|--------|--------|
| `lean/adr-governance/ADR/ACE/KernelTelemetryContract.lean` | 3 | Replace with explicit `by simp [...]` or `by native_decide` proofs for telemetry validity. |
| `lean/adr-governance/ADR/ACE/PhaseMirrorKernelAuthority.lean` | 2 | Replace with `by constructor <;> simp [...]` or explicit proofs. |
| `lean/adr-governance/ADR/ACE/CSCWitnessBinding.lean` | 1 | Replace with explicit witness construction. |
| `lean/projects/ACE_SCN_CSC/src/ACE_SCN_CSC/SCNConditioning.lean` | 1 | Replace with `by simp [SCNConditioning]` or explicit arithmetic. |
| `lean/projects/ACE–SCN-CSC/src/SCNConditioning.lean` | 4 | Replace with `by omega` or `by simp`. |
| `lean/projects/ACE–SCN-CSC/src/AtlasSCNBridge.lean` | 2 | Replace with `by native_decide` or explicit proof. |
| `lean/projects/ACE–SCN-CSC/src/KernelTelemetry.lean` | 2 | Replace with `by simp [KernelTelemetry]`. |
| `lean/gated/STRATIFIED_GOVERNANCE/StratifiedGovernance.lean` | 1 | Replace with `by simp [StratifiedGovernance]`. |

---

## Tier 4 — Model Proof Stubs (Medium, P2)

These are model-level ADR proof files that all contain a single `sorry` at line 11.

| File | Action |
|------|--------|
| `models/ataraxia/ataraxia_adr/AtaraxiaAdr/Proofs.lean` | Replace `sorry` with `by rfl` or `by simp [AtaraxiaAdr]`. |
| `models/echobraid/echobraid_adr/EchobraidAdr/Proofs.lean` | Same. |
| `models/finton/finton_adr/FintonAdr/Proofs.lean` | Same. |
| `models/generalist/generalist_adr/GeneralistAdr/Proofs.lean` | Same. |
| `models/the-examiner/the_examiner_adr/TheExaminerAdr/Proofs.lean` | Same. |
| `models/the-genius/the_genius_adr/TheGeniusAdr/Proofs.lean` | Same. |
| `models/the-guardian/the_guardian_adr/TheGuardianAdr/Proofs.lean` | Same. |
| `models/the-publisher/the_publisher_adr/ThePublisherAdr/Proofs.lean` | Same. |
| `models/commander/coding_commander_adr/CodingCommanderAdr/Proofs.lean` | Same. |

**Strategy:** These files appear to follow a boilerplate pattern. We can create a shared `ModelProof` template or replace each `sorry` with `by rfl` after verifying the theorem statement is trivially true.

---

## Tier 5 — Crate-Specific Lean Files (Medium, P2)

| File | Sorrys | Action |
|------|--------|--------|
| `crates/atomic-calculator/lean/CRMF_Obligations.lean` | 6 | Replace with `by omega` or `by simp`. Many are `have ... := sorry` patterns that can be discharged by `linarith`. |
| `crates/atomic-calculator/lean/Rta.lean` | 1 | Replace with `by native_decide` or explicit `simp`. |
| `crates/atomic-calculator/lean/Convergence.lean` | 1 | Replace with `by simp [Convergence]`. |
| `crates/atomic-calculator/lean/OperatorWordCalculus.lean` | 1 | Replace with `by simp [OperatorWordCalculus]`. |
| `crates/atomic-calculator/lean/Tests/FiniteModelInstance.lean` | 2 | Replace with `by decide` or `by native_decide`. |
| `crates/atomic-calculator/lean/Tests/FiniteModelDiscrete.lean` | 1 | Replace with `by decide`. |
| `crates/atomic-calculator/lean/test.lean` | 1 | Replace with `by rfl`. |
| `crates/drmm/lean-proofs/DRMM.lean` | 3 | Replace with `by native_decide` or `by simp [DRMM]`. |
| `crates/goldilocks-pro/lean-proofs/Goldilocks.lean` | 2 | Replace with `by simp [Goldilocks]`. |
| `crates/multiplicity/lean/SpectralStability.lean` | 6 | Replace with `by native_decide` or explicit matrix norm proofs. |
| `crates/prime-gap-dynamics/lean-prime-gap-dynamics/LeanPrimeGapDynamics/Proofs.lean` | 3 | Replace with `by simp [PrimeGapDynamics]`. |
| `crates/parm/HebrewLexicon/lean4-parm/Parm/Core.lean` | 2 | Already has Rust fallback. Replace with `by simp_wf; simp [decreasing]`. |
| `materia_commons/meta-theorem/src/SemanticArithmetic/SpectralBridge.lean` | 2 | Replace with `by linarith` or `by norm_num`. |
| `materia_commons/meta-theorem/src/SemanticArithmetic/Proofs.lean` | 2 | Replace with `by rfl` or `by simp`. |
| `materia_commons/meta-theorem/src/SemanticArithmetic/FTA.lean` | 1 | Replace with `by simp [FTA]` or explicit induction. |
| `materia_commons/ADR/ADR_System_Rust_Lean/ADR/CryptoEconomic.lean` | 1 | Replace with `by norm_num` or `by linarith`. |
| `crates/tests/MTPI_Check.lean` | 1 | Replace `sorry : MOC.Configuration 108` with `by native_decide` or explicit constructor. |
| `lean/Core/alp/ADR/PhaseMirror.lean` | 1 (line 91) | Replace `cases r <;> sorry` with `cases r <;> simp [alp_preserves_rta]`. |
| `src/Analytic/AnalyticSkeleton.lean` | 1 (line 31) | Replace with `axiom max_def` or explicit `ite` definition. |
| `src/f1_surface/F1Surface.lean` | 1 (line 26) | Replace with `by native_decide` or explicit spectral margin bound. |
| `src/GapDerivation.lean` | 1 (line 56) | Replace with `by simp [gap_derivation]`. |
| `lean/dynamics/ZenoContractivity.lean` | 1 | Replace with `by simp [ZenoContractivity]`. |
| `lean/dynamics/XIFormal.lean` | 2 | Replace with `by simp [XIFormal]`. |

---

## Tier 6 — CI Enforcement (Ongoing)

1. **Add `lake build` check** that fails on any `sorry` or `Mathlib` import in project-owned files.
2. **Add `scripts/honesty_audit.sh`** integration to CI pipeline.
3. **Add `#check-sorry`** warnings as errors in `lakefile.toml`.

---

## Execution Order

1. **Week 1:** Tiers 1 + 2 (Core modules + Mathlib imports)
2. **Week 2:** Tiers 3 + 4 (ADR governance + model stubs)
3. **Week 3:** Tier 5 (crate-specific files)
4. **Week 4:** Tier 6 (CI enforcement) + audit

---

## Risk Mitigation

- **Do not remove `sorry` before having a replacement proof.** Each `sorry` replacement will be verified with `lake build`.
- **Mathlib replacements** will be validated against the same behavioral contracts as the Rust code (e.g., `sealed_state` parity with Rust).
- **Axiom-clean mandate:** Where a proof is genuinely out of scope, declare an `axiom` with a clear doc comment rather than `sorry`.
