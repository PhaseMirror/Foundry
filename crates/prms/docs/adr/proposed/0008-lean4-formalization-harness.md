# ADR-008: Lean 4 Formalization & Test Harness for PRMS

## Status
**Proposed**

## Context
The Prime-Recursive Multiplicity Substrate (PRMS) requires "transparent lawfulness" (as per ADR-001). While Rust provides type safety and runtime checks, complex mathematical properties like **Banach Contraction Mapping** ($k < 1$) and **Lyapunov Stability** of the DAE state require formal verification to ensure no edge cases violate the spectral stability of the engine.

We need a unified harness that combines:
1.  **Rust Unit Tests:** Local logic and API verification.
2.  **Lean 4 Proofs:** Formal verification of mathematical invariants.
3.  **Numerical Benchmarks:** Verification of convergence in practice.
4.  **Auto-Result Compilation:** A unified report generator for the Zeta-ROS audit layer.

## Decision
We will implement a multi-stage integration strategy for Lean 4 formalization in PRMS.

### 1. Phased Integration Strategy

#### Phase 1: Sidecar Verification (CLI Integration)
- **Structure:** Create `prms/formal/` containing a Lean 4 project (Lake).
- **Harness:** A Rust integration test module (`prms/tests/formal_harness.rs`) will use `std::process::Command` to trigger `lake build` and verify that theorems are checked.
- **Reporting:** Use `lean-checker` or custom JSON output to feed results into the `AuditReceipt`.

#### Phase 2: Deep FFI Integration (Native Bindings)
- **Structure:** Utilize Lean 4's C-ABI export.
- **Harness:** Rust `build.rs` will link the compiled Lean library.
- **Runtime Proofs:** Enable "Proof-Carrying Logic" where specific runtime state transitions (e.g., PETC signature changes) trigger a Lean-verified checker in-process.

#### Phase 3: WASM/Certificate Export (Sedona Spine Alignment)
- **Structure:** Lean proofs generate proof certificates or are compiled to WASM.
- **Universal Validation:** Both the Rust engine and the TypeScript SDK can validate the lawfulness of a PRMS state transition using the same WASM-based verifier.

### 2. Auto-Result Compilation (The Lawfulness Reporter)
We will introduce a `LawfulnessAggregator` that:
- Collects `cargo test --json` output.
- Collects `lake build` verification logs.
- Executes `DAEState` stability benchmarks.
- Compiles a unified `PRMS_LAW_REPORT.json` containing hashes, proof statuses, and convergence metrics.

### 3. Proof Targets
- **Contractor Convergence:** Formally prove $\sum_{p_i \in P_N} \Lambda_m p_i^\alpha < 1$ for given $\alpha, \Lambda_m$.
- **PETC Signature Invariance:** Prove that $\Sigma(T_1) = \Sigma(T_2)$ is preserved under specific tensor transformations.
- **DAE Passivity:** Prove the Lyapunov function $H(\Delta) = \frac{1}{2}\Delta^2$ is non-increasing.

## Decision Drivers
- **Zero Drift:** Aligning with Sedona Spine Mandate.
- **Traceability:** Every spectral decision must have a formal provenance chain.
- **Performance:** Avoiding runtime overhead by prioritizing compile-time/AOT proof validation.

## Consequences
### Positive
- **Mathematical Infallibility:** Core stability logic is formally proven.
- **Unified Auditing:** Zeta-ROS gets a single artifact representing the total lawfulness of the system.
### Negative
- **Build Complexity:** Managing Lean 4 toolchains alongside Rust.
- **Skill Gap:** Requires Lean 4 expertise for ongoing maintenance.

## Implementation Plan
1.  **Scaffold `prms/formal`**: Initialize Lake project with `mathlib4` dependency.
2.  **Implement `prms/src/lawfulness.rs`**: Core aggregator logic.
3.  **Update `prms/tests/prms_tests.rs`**: Add hook for formal verification.
4.  **Create `scripts/compile_results.py`**: (Or Rust equivalent) to generate the final report.
