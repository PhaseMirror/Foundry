# DRMM Parity Roadmap: Rust (drmm_rs) vs. Python (drmm)

This document outlines the strategic plan to bring the Rust implementation (`drmm(rs)`) to feature parity with the canonical Python implementation (`drmm`).

## 1. Status Quo Assessment

| Component | Python (`drmm`) Status | Rust (`drmm_rs`) Status | Priority |
| :--- | :--- | :--- | :--- |
| **Primes** | Comprehensive (`sympy`) | Basic (`primes.rs`) | Medium |
| **Operators (Xi, Lambda)** | Full Implementation | Basic (`operators.rs`) | High |
| **Spectral Analysis** | NumPy/SciPy based | Hand-rolled FFT (`spectral.rs`) | Low |
| **Optimizer (Phase 1)** | Production-ready | Basic integration | High |
| **Meta-Ensemble & VDJ** | Python Parity (`agi_os_twin_parity.py`) | Production-ready (`umc-parom`, `agi-os-twin`) | COMPLETED |
| **Clinical Validator** | Python Parity (`clinical_validation.py`) | Production-ready (`agi-os-twin`) | COMPLETED |
| **Tensor Core** | `tensor_core.py` (Prime-indexed) | **MISSING** | High |
| **Moonshine** | `moonshine.py` (Modular forms) | **MISSING** | Medium |
| **Feedback Loops** | `feedback_loops.py` (Entropic) | **MISSING** | Medium |
| **Langlands** | `langlands.py` (Automorphic duals) | **MISSING** | Low |

---

## 2. Phase 1: Mathematical Core & Tensor Foundation (High Priority)

The goal is to implement the underlying algebraic structures that support the recursive operators.

- **[ ] Port `tensor_core.py` to `src/tensor_core.rs`**
  - Implement `prime_indexed_tensor` using `ndarray`.
  - Implement Frobenius normalization and basic spectral decompositions.
- **[ ] Enhance `src/primes.rs`**
  - Replace basic prime checks with a more robust generator or integrate a crate like `num-prime` (already used in `umc-parom`).
- **[ ] Align `src/operators.rs` with `src/operators.py`**
  - Ensure `Xi` initialization and evolution logic matches the Python reference exactly.
  - Implement `LambdaM` (Multiplicity Constant) field dynamics.

## 3. Phase 2: Optimizer & Feedback Parity (High Priority)

Aligning the training/optimization logic for production use cases.

- **[ ] Complete `src/optimizer.rs`**
  - Port EMA (Exponential Moving Average) smoothing for `Lambda_m`.
  - Implement full diagnostic history tracking (parity with `test_optimizer_phase1.py`).
- **[ ] Port `feedback_loops.py` to `src/feedback.rs`**
  - Implement `EntropicFeedbackLoop` (Entropy gradients).
  - Implement `EthicalModulator` (Nonlinear saturation filters).
  - Implement `ConvergenceController`.

## 4. Phase 3: Advanced Symmetries & Moonshine (Medium Priority)

Implementing the "meta-mathematical" aspects of the project.

- **[ ] Port `moonshine.py` to `src/moonshine.rs`**
  - Implement `MoonshineOperator` using Bessel functions (via `statrs` or `gsl` bindings).
  - Implement modular waveform modulation.
- **[ ] Port `langlands.py` to `src/langlands.rs`**
  - Implement `AutomorphicForm` transformations.
  - Implement `GaloisTensor` (twisting and Frobenius morphisms).

## 5. Phase 4: Validation & Benchmarking

- **[ ] Cross-Language Test Suite**
  - Create a set of JSON-based test vectors produced by Python to be verified by Rust.
  - Port all 20 Python tests to Rust integration tests.
- **[ ] Performance Benchmarking**
  - Compare execution time for 1000 steps of Moonshine-modulated recursion between Python and Rust.

---

## Technical Recommendations

- **Crate Selection**: Use `ndarray` for tensor ops, `ndarray-linalg` for spectral analysis, and `num-prime` for canonical primes.
- **Error Handling**: Use `thiserror` to define project-specific mathematical errors (e.g., `InvarianceViolation`).
- **Serialization**: Use `serde` to ensure test vectors can be easily shared between Python and Rust.
