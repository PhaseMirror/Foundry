# Reproducibility Package: Multiplicity Substrate

This document provides the authoritative guide for verifying the mathematical claims and experimental results presented in Multiplicity Theory.

## 1. Multiplicity: The Proof-Carrying Substrate

The Phase Mirror HQ repository implements a **Proof-Carrying Substrate**. Every stability claim in the mathematical theory has a corresponding runtime enforcement point in the source code.

### 1.1 Core Theorem Mapping

| Theorem | Mathematical Domain | Implementation Point |
| :--- | :--- | :--- |
| **Theorem 1** | Universal Stable Contractor | `agi-os/src/multiplicity/cert/lambda_m_protocols.py` |
| **Theorem 2** | Ensemble Contractivity (Gate 2) | `agi-os/ensemble/contractivity_policy.py` |
| **Theorem 3** | Fixed-Point Existence & Uniqueness | `agi-os/lean4/AffineCore/Stability/ExistenceUniqueness.lean` |
| **Theorem 4** | Spectral Entropy Audit | `agi-os/src/multiplicity/cert/fractal_audit_oracle.py` |

## 2. Automated Verifiability

The integrity of the substrate is verified through a multi-layer testing and indexing stack.

### 2.1 Stability-Aware Experiment Index

The `ExperimentIndex` manages the "reproducibility ledger," tracking every experimental run against formal admissibility bounds.

**How to verify:**
```bash
# Ingest artifacts and generate the stability summary
PYTHONPATH=agi-os/src python3 agi-os/src/multiplicity/experiment_index.py
```

This will produce `agi-os/artifacts/checksums/EXPERIMENT_STABILITY_INDEX.json`, which contains:
- **Mean Cohesion Scores**: Fleet-level stability distribution.
- **Tightening Candidates**: Identification of conservative formal bounds.
- **Boundary Grazers**: Falsification attempts near the contractivity limit.

### 2.2 Formal Proof Verification (Lean 4)

The core existence proofs are formalized in Lean 4. To verify the proofs locally:

```bash
cd agi-os/lean4
lake build
```

Successful compilation confirms that the **Master Theorem for Fixed-Point Existence** (Theorem 3) is logically sound and follows from the Banach contraction axioms.

## 3. Reference Implementation Binding (agi-os)

The **agi-os** implementation uses the following canonical parameters to maintain the "Lawful Grounding":

- **$\Lambda_m = 1.738317$** (The $M_{\mathrm{meta}}$ fixed point).
- **$\alpha = 0.85$** (Prime scale power).
- **Ensemble Threshold $\kappa = 0.95$** (Global contractivity bound).

These parameters are enforced by the CI suite; any PR that drifts below the stability margin $\delta < 0.05$ is automatically rejected by the Multiplicity governance policy.

## 4. Multi-Scale Analysis Notebooks

For detailed forensic analysis of the "probabilistic pathways," refer to the following research notebooks:

- `agi-os/notebooks/phase3_socio_atomic_analytics.ipynb`: Spectral decomposition of multi-agent interactions.
- `agi-os/notebooks/phase4_orchestration_report.ipynb`: Real-time resonance monitoring of the Ω operator.

---

"A theorem without a code pointer is a cathedral without a door. Multiplicity is the door."

<!-- LawfulRecursionVersion:1.0 -->
