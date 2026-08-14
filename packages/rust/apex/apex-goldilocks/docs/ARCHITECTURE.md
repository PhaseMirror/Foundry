# Architecture: Apex-Goldilocks Stack

This document outlines the high-performance, exact-arithmetic architecture of the Apex-Goldilocks workspace, built according to the **Sedona Spine** mandate.

## 1. Design Philosophy

The stack is designed to meet or exceed the computational purpose of legacy models by replacing heuristic floating-point logic with **strictly exact mathematical proof**. It operates as a verified transformer of combinatorial structures into computational narratives.

### Core Pillars:
- **Exactness**: Zero reliance on `f32/f64` for core kernels.
- **Contractivity**: All dynamical system updates are certified to be strictly non-inflationary.
- **Standalone Integrity**: Internalized dependencies ensure a self-contained, reproducible environment.

## 2. Structural Layers

### L0: The Foundation (Goldilocks Zone)
- **Crates**: `apex-goldilocks-core`, `goldilocks`.
- **Function**: Defines the **12,288-cell Boundary Lattice**. Implements prime field arithmetic and combinatorial distribution invariants (R96).
- **Invariant**: No direct floating-point usage.

### L1: The Kernel ($\pi$-kernel)
- **Packages**: `apex-pikernel`.
- **Function**: Implements the projection-first update loop.
    - **ACE Safety**: Weighted $\ell_1$-ball projection via exact bisection.
    - **Certificates**: Continuous generation of **SlopeUB** and **GapLB** to guarantee stability.
    - **RNS**: Lane-wise parallel modular arithmetic for high-dimensional throughput.

### L2: The Runtime (EchoBraid)
- **Crates**: `multiplicity-runtime`, `pirtm-compiler`.
- **Function**: Orchestrates **Governance-as-Compilation**.
    - **PIRTM-lang**: Formal grammar for admissible operator sequences.
    - **Harness**: Neural-hologram adaptation via veto-enforced certification.
    - **Ledger**: Cryptographic commitments (SHA-256/Poseidon) for every transition.

### L3: The Interface (Desktop)
- **App**: `src/` (React/Tauri).
- **Function**: Provides human-readable narrative and statistical heuristics.
    - **Stability Dashboard**: Real-time visualization of exact stability margins.
    - **MUB Audit**: spectral drift detection using Fast Walsh-Hadamard Transform (FWHT).

## 3. The Multiplicity Functor

The stack implements a strong monoidal functor $F: (A, \otimes) \to (C, \oplus)$ mapping from the **Atom Category** (hologram compute units) to the **Prime Channel Category** (runtime graded channels). This mapping ensures that any computation performed in the hologram layer is faithfully and provably represented in the prime-graded runtime.

---

## 4. Invariant Enforcement
All transformations must satisfy the **Sedona Spine** provenance chain:
**Declarative Policy** → **Cryptographic Event Log** → **Kernel Computation** → **Narrative Logic**.
