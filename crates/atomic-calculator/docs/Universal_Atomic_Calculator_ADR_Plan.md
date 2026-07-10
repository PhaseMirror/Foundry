# Architecture Decision Record (ADR) Plan: Universal Atomic Calculator (UAC)

## 1. Title
Production-Grade Implementation of the Universal Atomic Calculator (UAC) Framework

## 2. Status
Proposed

## 3. Context
The Universal Atomic Calculator (UAC) is a computational framework that utilizes neutral atoms (e.g., $^{87}$Sr and $^{133}$Cs) as high-dimensional qudits ($d > 2$) rather than binary qubits. The framework demonstrates significant advantages in quantum self-simulation, specifically achieving:
- **3.32x Resource Compression** via native d-level fermionic encoding.
- **5.4x Error Correction Efficiency** using the Hyperfine Subspace Error Correction (HSEC) protocol.
- **20-30% Faster Convergence** using the Multiplicity-Adaptive Variational Quantum Eigensolver (MA-VQE).

To move from phase 1 software simulation to a production-grade implementation, we need to architect a robust, scalable system that integrates these novel protocols with existing cloud quantum platforms and classical orchestration layers.

## 4. Key Architectural Decisions to be Made

The ADR plan outlines the specific Architecture Decision Records (ADRs) that must be resolved to achieve a production-grade implementation.

### ADR-001: Quantum Hardware Platform Selection
* **Context**: The UAC requires precise control over nuclear spin manifolds.
* **Options**: 
  * Atom Computing ($^{87}$Sr, $d=10$)
  * Infleqtion ($^{133}$Cs, $d=16$)
  * Custom M³A (Multi-Manifold Modular Array) Heterogeneous integration ($^{87}$Sr + $^{171}$Yb)
* **Goal**: Select the primary hardware backend for the initial production rollout, balancing qudit dimension availability with gate fidelity and cloud access.

### ADR-002: HSEC (Hyperfine Subspace Error Correction) Implementation
* **Context**: HSEC relies on using auxiliary manifolds for error detection without projective readout.
* **Options**:
  * Implement HSEC natively via low-level hardware pulse control APIs (e.g., Pulser).
  * Abstract HSEC into a middleware layer that compiles logical error-corrected gates into physical qudit pulses.
* **Goal**: Define the software-hardware boundary for intrinsic error correction.

### ADR-003: Qudit-Classical Feedback Interface (QCFI) Orchestration
* **Context**: QCFI requires real-time, bidirectional feedback to dynamically reconfigure qudit dimensions (e.g., $d=16 \leftrightarrow d=8$).
* **Options**:
  * Tightly coupled FPGA-based control system collocated with the QPU.
  * Edge-compute node executing fast classical optimization algorithms.
* **Goal**: Minimize latency in the feedback loop to ensure coherence times are not exceeded during adaptive dimension shifting.

### ADR-004: MA-VQE Compiler Architecture
* **Context**: Compiling molecular Hamiltonians directly into qudit subspaces requires a new compiler toolchain.
* **Options**:
  * Extend existing frameworks (Qiskit/TKET) with custom qudit transpilation passes.
  * Build a standalone multiplicity-aware compiler tailored specifically for UAC's generalized Jordan-Wigner ($JW_d$) transformations.
* **Goal**: Optimize the translation of chemical structures (e.g., FeS clusters) into minimal gate-depth physical qudit instructions.

## 5. Implementation Phases

### Phase 1: Foundation and Simulation Parity (Months 1-3)
* Resolve ADR-004 and finalize the MA-VQE compiler design.
* Implement software-in-the-loop testing using noiseless and noisy qudit simulators.
* Validate the 3.32x compression for small molecules (e.g., $LiH$, $H_2O$).

### Phase 2: Hardware Integration and HSEC (Months 4-7)
* Resolve ADR-001 and ADR-002.
* Establish secure cloud or on-premise connections to the chosen neutral-atom provider.
* Execute hardware-native calibration of the auxiliary subspaces for error detection.
* Demonstrate single-qudit HSEC capabilities on physical hardware.

### Phase 3: Closed-Loop QCFI Integration (Months 8-10)
* Resolve ADR-003.
* Deploy the classical orchestrator for real-time dimension reconfiguration.
* Benchmark dynamic subspace shifting under induced noise.

### Phase 4: Production Scale "Killer App" (Months 11-12+)
* Execute the end-to-end simulation of an Iron(II) Sulfide (FeS) cluster.
* Target: Ground-state energy within 15 mHa using < 40 physical qudits.
* Finalize production APIs for external client access (Quantum Chemistry as a Service).

## 6. Consequences
* **Positive**: Secures early intellectual property around dynamic qudit dimensioning and intrinsic error correction; establishes a moat against qubit-only platforms.
* **Negative/Risks**: High dependence on the maturity and API access levels of neutral-atom hardware providers; control complexity scaling ($d^2$) may require significant machine learning overhead for pulse calibration.
