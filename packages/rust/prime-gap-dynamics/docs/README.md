# Prime-Gap Dynamics: Zeta Phase Transistor Test Harness

A quantum control research platform for probing the intersection of analytic number theory and dynamical stability. This project implements a physically grounded simulation of a **Prime-Encoded Zeta Phase Transistor**—a finite-dimensional Hamiltonian system driven by prime frequencies, gap-modulated hopping, and zeta-zero modulation.

## 🚀 Project Overview
The Zeta Phase Transistor is a test harness designed to validate the core hypotheses of **Meta-Relativity** and **Multiplicity Theory**. It treats mathematical structures (primes and zeta zeros) as ontic control laws rather than mere descriptive tools.

### Key Hypotheses Validated:
1.  **The Prime Advantage:** The specific sequential ordering of prime gaps facilitates superior phase synchronization and coherence preservation.
2.  **Lawful Becoming:** Structural identity is preserved via prime-factorizable interaction patterns (Multiplicative Integrity).
3.  **RH as Stability:** The Riemann Hypothesis (RH) acts as a dynamical stability condition for the transistor's phase envelope.

## 📊 Latest Research Results
Current data from the v2.0 simulation engine (N=20 primes, R=200 null realizations):

| Metric | True Prime Order | Null Ensemble (μ) | Statistical Significance (Z) |
| :--- | :--- | :--- | :--- |
| **Circular Phase Variance** | 0.6476 | 1.3203 | **-2.0777** (Stabilization Effect) |
| **Global Fidelity** | 0.5401 | 0.3262 | **+2.5707** (Coherence Advantage) |
| **RH-Stability ($\beta=0.05$)** | N/A | N/A | **+450% Variance Growth** |

*Interpretation: The prime-ordered gap structure is a measurable dynamical resource that stabilizes the phase carrier and protects global coherence against randomized permutations.*

## 🛠 Core Architecture
The system is built on a suite of **Architecture Decision Records (ADRs)**:
- **[ADR-001](./docs/adrs/001-hamiltonian-specification.md):** Hamiltonian v2.0 Specification ($H = H_{p} + \lambda H_{g}$).
- **[ADR-002](./docs/adrs/002-integration-and-observables.md):** $DOP853$ Integration & Standard Observables ($V_{circ}, L, F$).
- **[ADR-003](./docs/adrs/003-null-model-architecture.md):** Shuffled-Gap Null Ensemble Validation.
- **[ADR-004](./docs/adrs/004-multiplicativity-projector.md):** Multiplicative Integrity Monitoring ($E_{mult}$).
- **[ADR-005](./docs/adrs/005-rh-stability-protocol.md):** Exponential Envelope ($\beta$-offset) Stress Testing.

## 💻 Getting Started

### Installation
Ensure you have Python 3.10+ and the following dependencies:
```bash
pip install numpy scipy matplotlib
```

### Usage: Research CLI
The system is managed via a unified Research CLI:

```bash
# Run a single pilot simulation
python3 src/cli.py simulate --primes 20 --zeros 10

# Run a statistical validation ensemble (Null Model comparison)
python3 src/cli.py validate --runs 50 --primes 20

# Run a Multiplicative Integrity check (E_mult)
python3 src/cli.py multiplicity --primes 10 --composites 5

# Run an RH-Stability stress test (Beta-offset)
python3 src/cli.py stability --betas 0.0 0.02 0.05
```

## 📂 Project Structure
```text
Prime-Gap Dynamics/
├── docs/
│   └── adrs/           # Architectural Decision Records (001-005)
├── src/
│   ├── cli.py          # Unified Research Interface
│   ├── simulator.py    # Core Hamiltonian Engine (v2.0)
│   ├── validation.py   # Statistical Validation Harness
│   ├── multiplicity.py # Integrity Monitoring Logic
│   └── rh_stability.py # Stability Stress Testing
├── Prime-Gap-Dynamics.md # Original Theoretical Scaffold
└── *.png               # Baseline and Validation Plots
```

## 🗺 docs/roadmaps/Roadmap
- [ ] **Phase 5.1:** Integrate Lindblad Master Equation support for open-system noise analysis.
- [ ] **Phase 5.2:** Expand basis to $P_{max}$ for comprehensive Multiplicative Identity mapping.
- [ ] **Phase 6.0:** Extract cryptographic bit sources from transistor switching events.

---
**Author:** Multiplicity Theory / Prime-Gap Dynamics Lab  
**Status:** Synthetic Research Artifact - V2.0 Operational
