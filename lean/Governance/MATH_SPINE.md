# The Math Spine: agi-os Formal Foundations

This document maps the mathematical infrastructure of agi-os. Each module below is governed by a formal invariant that precedes and constrains its implementation.

## 📊 Governance Dashboard

| Module | Invariant | Status |
|---|---|---|
| [`multiplicity/`](../multiplicity/) | Prime-indexed identities compose via operator multiplication without loss of uniqueness. | `[OPEN]` / `[TESTED/CI]` ![CI](https://img.shields.io/badge/CI-enforced-brightgreen) |
| [`lean4/`](../lean4/) | Supermodule spectral radius $\rho < 1$ guarantees global system stability. | `[OPEN]` ![Status](https://img.shields.io/badge/status-spec--only-orange) |
| [`pirtm/`](../pirtm/) | Recursive feedback loops are contractive under the Λ-multiplier bound. | `[PROVEN]` / `[TESTED/CI]` ![CI](https://img.shields.io/badge/CI-enforced-brightgreen) |
| [`mtpi/`](../mtpi/) | Identity is a unique prime product; nullification is a division operation. | `[OPEN]` / `[TESTED/CI]` ![CI](https://img.shields.io/badge/CI-enforced-brightgreen) |
| [`packages/circuits/core/`](../packages/circuits/core/) | State transitions preserve topological invariants if $\delta < 0.3$. | `[PROVEN]` / `[TESTED/CI]` ![CI](https://img.shields.io/badge/CI-enforced-brightgreen) |
| [`engine/`](../engine/) | Prime-indexed recurrence remains stable under composition. | `[OPEN]` / `[TESTED/CI]` ![CI](https://img.shields.io/badge/CI-enforced-brightgreen) |
| `MKT Gate` | Lawfulness threshold must be derived from MKT Jones bridge (0.83). | `[CLOSED]` ![Status](https://img.shields.io/badge/status-closed--0.95--frozen-red) |
| `Watchdog` | Transition order must be resolved by hysteresis (Article VII §7.1). | `[OPEN]` ![Status](https://img.shields.io/badge/status-pending-orange) |
| [`packages/zrsd/`](../packages/zrsd/) | Refinement trajectories are monotonically convergent toward the ethical manifold. | `[OPEN]` ![Status](https://img.shields.io/badge/status-spec--only-orange) |

## 📊 Lawfulness Coverage Index

This index tracks which layers defend the core system-wide laws.

| Core Law | Lean Proof (L0) | ZK Circuit (L1) | Forge Invariant (L1) | Integrity Score | Next Pressure |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Identity Uniqueness** | `[PROVEN]` | `[OPEN]` | `[TESTED/CI]` | **2/3** | ZK Identity Circuit |
| **Nullifier Correctness** | `[OPEN]` | `[TESTED/CI]` | `[TESTED/CI]` | **2/3** | Lean Nullifier Lemma |
| **Replay Resistance** | `[OPEN]` | `[OPEN]` | `[TESTED/CI]` | **1/3** | ZK Nullifier Constraint |
| **State Monotonicity** | `[OPEN]` | `[TESTED/CI]` | `[TESTED/CI]` | **2/3** | Lean Monotonicity Lemma |
| **Access Integrity** | `[OPEN]` | `n/a` | `[TESTED/CI]` | **1/2** | ZK Access Constraint |
| **Drift Bound ($\delta < 0.3$)** | `[LEAN-PIRTM-001]` | `[TESTED/CI]` | `n/a` | **3/3** | **STABLE** |
| **Adversarial Robustness** | `[OPEN]` | `[OPEN]` | `[TESTED/LOCAL]` | **1/3** | PEV Hashing (ADR-002) |
| **Contraction ($\gamma < 1$)** | `[LEAN-PIRTM-001]` | `[OPEN]` | `[TESTED/CI]` | **2/3** | ZK Pilot (ADR-003) |
| **Robustness ($\epsilon < \epsilon_{max}$)** | `[LEAN-PIRTM-003]` | `[OPEN]` | `[TESTED/CI]` | **2/3** | ZK Robustness Proof |

---

## 1. Multiplicity Theory ([`multiplicity/`](../multiplicity/))
**Invariant:** Prime-indexed identities compose via operator multiplication without loss of uniqueness.
**Role:** Defines the "Multiplicity Space" where users and systems are modeled as composite prime values.
**Status:** 
- `[OPEN]` in [`lean4/AffineCore/MTPI/PrimeWord.lean:L10`](../lean4/AffineCore/MTPI/PrimeWord.lean) (`theorem prime_word_injectivity`).
- `[TESTED/CI]` in `agi_os/multiplicity/tests`; enforced in CI workflow `Math & Substrate Integrity / Run Multiplicity Theory tests`.

## 2. AffineCore ([`lean4/`](../lean4/))
**Invariant:** The supermodule spectral radius $\rho(C \cdot \text{diag}(\gamma)) < 1$ guarantees global system stability.
**Role:** Provides machine-checkable Lean 4 proofs for the existence and uniqueness of stable fixed points in the execution engine.
**Status:** `[OPEN]` in [`lean4/AffineCore/Stability/Supermodule.lean:L51`](../lean4/AffineCore/Stability/Supermodule.lean) (`theorem supermodule_stability_lemma`).

## 3. PIRTM: Prime-Indexed Recursive Tensor Machine ([`pirtm/`](../pirtm/))
**Invariant:** Recursive feedback loops are contractive under the Λ-multiplier bound.
**Role:** The core spectral engine that translates multiplicity operators into stable tensor dynamics.
**Status:** 
- `[PROVEN]` in [`lean4/AffineCore/MTPI/PIRTM_Stable.lean:L22`](../lean4/AffineCore/MTPI/PIRTM_Stable.lean) (`theorem mtpi_stability_guarantee`).
- `[TESTED/CI]` in `agi_os/packages/pirtm/tests`; enforced in CI workflow `Math & Substrate Integrity / Run PIRTM Core tests`.

## 4. MTPI: Meta-Theorem of Prime Identity ([`mtpi/`](../mtpi/))
**Invariant:** Identity is a unique prime product, and nullification is a division operation in the prime field.
**Role:** The protocol layer for verifiable, zero-knowledge identity management and "conscious sovereignty."
**Status:** 
- `[OPEN]` in [`lean4/AffineCore/MTPI/SolidityModel.lean:L31`](../lean4/AffineCore/MTPI/SolidityModel.lean) (`theorem solidity_transition_conformance`).
- `[TESTED/CI]` in `agi_os/mtpi/test`; enforced in CI workflow `Groth16 Circuits & Contracts / Run full Forge contract tests`.

## 5. Drift-Bounded Circuits ([`packages/circuits/core/`](../packages/circuits/core/))
**Invariant:** State transitions preserve topological invariants if the drift parameter $\delta < 0.3$.
**Role:** Zero-knowledge circuits (Circom/Groth16) that generate proofs of lawfulness for every state update.
**Status:** 
- `[PROVEN]` in [`lean4/AffineCore/MTPI/DriftBound.lean:L38`](../lean4/AffineCore/MTPI/DriftBound.lean) (`theorem drift_bounded_lawfulness`).
- `[TESTED/CI]` in [`packages/circuits/core/root.test.js:L118`](../packages/circuits/core/root.test.js); enforced in CI workflow `Groth16 Circuits & Contracts / Run circuit tests (CI-gated)`.

## 6. Recursive Execution Core ([`engine/`](../engine/))
**Invariant:** Prime-indexed recurrence remains stable under composition.
**Role:** Coordinates the interaction between the Multiplicity KB and the PIRTM spectral engine.
**Status:** 
- `[OPEN]` in [`lean4/AffineCore/MoldingModularity.lean:L17`](../lean4/AffineCore/MoldingModularity.lean) (`theorem molding_invariant_preservation`).
- `[TESTED/CI]` in `agi_os/engine/src/*.test.ts`; enforced in CI workflow `ci / Run JS/TS tests`.

## 7. ZRSD: Zero-Knowledge Resonant Search Dynamics ([`packages/zrsd/`](../packages/zrsd/))
**Invariant:** Refinement trajectories are monotonically convergent toward the ethical manifold.
**Role:** Governed machine learning loops (formerly CCRE) that refine parameters without breaking substrate-level safety bounds.
**Status:** `[OPEN]`. Formalization planned for Phase 5 (`Resonance.lean`) and Phase 8 (`EthicalConvergence.lean`).

## 8. MKT Jones Gate (Governance)
**Invariant:** Lawfulness threshold $\theta = 0.83$ is valid iff $c_0 = \ln|J_{MKT}(W_{3_1})|_{s=i} = \ln 10$.
**Role:** Prevents arbitrary tuning of safety constants by mandating topological derivation.
**Status:** 
- `[CLOSED]` (2026-05-10): **MKT Jones Bridge is refuted for this regime**; $\ln|J_{MKT}| = 25.20$ vs Target $2.30$.
- **Action**: Threshold frozen at 0.95. Spectral per-knot fitting (ADR-100) governs instead.
- `[OPEN]` in [`docs/adr/XICRITIQUE4-LINDBLAD-PT-PROOF.md`](adr/XICRITIQUE4-LINDBLAD-PT-PROOF.md).
- `[OPEN]` in [`docs/adr/XICRITIQUE8-THRESHOLD-ZK-PROOF.md`](adr/XICRITIQUE8-THRESHOLD-ZK-PROOF.md).
- `[TESTED/CI]` in `agi_os/multiplicity/tests/test_mkt_gate.py`.

## 9. Transition Order Watchdog (Infrastructure)
**Invariant:** State transitions satisfy the arithmetic Feynman path integral (Article VII §7.1).
**Role:** Diagnostic flag gating the validity of 🟡 tri-state seals based on topological curvature.
**Status:**
- `[OPEN]` in [`docs/adr/XICRITIQUE4-TRANSITION-CURVATURE-PROOF.md`](adr/XICRITIQUE4-TRANSITION-CURVATURE-PROOF.md).
- `[OPEN]` in [`docs/adr/XICRITIQUE8-TRANSITION-ZK-PROOF.md`](adr/XICRITIQUE8-TRANSITION-ZK-PROOF.md).
- `[TESTED/CI]` in `agi_os/multiplicity/tests/test_telemetry.py` (ADR-104 Telemetry enabled).
- `[TESTED/LOCAL]` via `hysteresis_measure.py` (Day 14).

## 10. Adversarial Invariants (Hardening)
**Invariant:** $I_{\text{complete}}(s)$ is injective over the semantic state space (ADR-002).
**Role:** Protects the substrate against deliberate state corruption, oscillation masking, and trajectory drift.
**Status:** 
- `[OPEN]` in [`docs/adr/ADR-002-ADVERSARIAL-HARDENING.md`](adr/ADR-002-ADVERSARIAL-HARDENING.md).
- `[TESTED/LOCAL]` via `test_day14_dryrun.py` (simulated attacks).
- `[TESTED/CI]` integration pending Phase 5 completion.

---
**Note on Status:** These invariants are binding specifications. Code that violates its module's governing invariant is considered a defect. Proofs marked `[PROVEN]` have machine-checkable Lean 4 counterparts.

See [**ADR-001**](adr/ADR-001-math-first-contract.md) for the binding contract, [**MATH_GLOSSARY.md**](MATH_GLOSSARY.md) for canonical definitions, and [**docs/proof-obligations/**](proof-obligations/) for detailed formalization briefs.
