# Architecture Decision Record (ADR): Rust/Kani for Executable Formal Verification (The "Mathlib-Free" Pivot)

## 1. Context and Problem Statement
The PhaseMirror ecosystem, centered around the **Rust Sedona Spine Engine**, relies on profound mathematical models (e.g., Zeta-Multiplicity Operator Systems, L-functions, Spectral Bound Renormalizations). 
Traditionally, proving invariants about continuous mathematics, complex analysis, and linear algebra requires Lean's `Mathlib`. However, `Mathlib` is notoriously heavy, relies heavily on classical axioms, and produces non-canonical representations that are exceptionally hostile to extraction (C/Rust FFI) and high-performance execution.

We need a way to **formally verify our physical and mathematical invariants** without sacrificing the raw SIMD/BLAS performance and determinism of the Rust execution environment.

## 2. Decision: The Lean Core + Rust/Kani Pipeline
**We will completely replace the use of Lean's `Mathlib` with Rust/Kani symbolic execution.** 

This institutes a strict division of labor across the stack:
- **Lean 4 (Mathlib-Free Core)**: Acts solely as the **lightweight type-theoretic specification layer**. Lean will define the structural shapes, the interfaces, and the axiomatic invariants (e.g., `distinct_primes_commute`). It provides the "golden reference" contract.
- **Rust + Kani (The Verifier)**: Acts as the **executable verification layer**. The Sedona Spine will implement the numerics (e.g., using `ndarray` or `nalgebra` with `f64`). **Kani (the Rust model checker)** will be used to symbolically execute these functions and prove that they never violate the bounds and invariants established by the Lean core.

## 3. How Kani Replaces Mathlib

Wherever we would traditionally write a 500-line Mathlib proof about analytic bounds, we will now write a Kani symbolic harness:

| Traditional Mathlib Approach | New Rust/Kani Paradigm |
| :--- | :--- |
| **Real / Complex Analysis**: Cauchy sequences, open sets, topological proofs of continuity. | **Numerical Safety**: Kani symbolic execution proving that `f64` matrices never hit `NaN`, `Inf`, or trigger divide-by-zero panics in the relevant `t` intervals. |
| **Spectral Radius Proofs**: Deep algebraic proofs of matrix norms converging for $\Re(s) > \sigma$. | **Bounds Harness (`kani::assert!`)**: Kani symbolically tests `compute_spectral_radius()` across all valid truncated prime bounds and asserts the spectral radius strictly obeys the Lean-specified limit threshold. |
| **Commutativity ($[O_p, O_q] = 0$)**: Tensor product algebras in Lean. | **Memory Disjointness**: Kani checks that the Rust parallel iterators processing prime blocks do not have memory aliasing or race conditions, proving commutativity at the hardware level. |

## 4. Implementation Strategy & Stack Integration

### Step 1: FFI Contract Generation
- **Action**: Use Lean 4's `@[extern]` bindings and export capabilities to generate a deterministic C-header mapping Lean structures to Rust `#[repr(C)]` structs. 
- **Goal**: Ensure the Rust memory layout is mechanically guaranteed to match the Lean definition (e.g., `ZmosSystem` mapping to a continuous `Array<Array<f64>>`).

### Step 2: Kani Harness for Initialization and Commutativity
- **Action**: Write a Kani harness for `ZmosSystem::new()`.
- **Goal**: Prove that indexing maps do not alias across prime buffers, formally guaranteeing the `distinct_primes_commute` axiom.

### Step 3: Kani Harness for Spectral Bounds (RG Condition)
- **Action**: Implement a bounded symbolic harness over `compute_entropy_rs()` and the local modes $O_p(t)$.
- **Goal**: Prove that the Rust exponentiation $O_p p^{-s}$ mathematically respects the $\Delta(t)$ proximity bounds and never triggers overflow.

### Step 4: Trace and PSD Invariants
- **Action**: Implement `S(s,t)` in Rust. Use Kani to prove `Trace(\rho) == 1.0` (within IEEE 754 float epsilon tolerances) and that the matrix is positive semi-definite (PSD).
- **Goal**: Remove runtime bounds-checking from the Sedona Spine's critical path, knowing the invariants are proven ahead-of-time.

## 5. Consequences & Next Steps
- **Pros**: Orders of magnitude faster execution. Direct memory verification. Extremely lean theorem prover footprint. Completely unified stack under the Rust Sedona Spine mandate.
- **Cons**: Requires learning to write symbolic harnesses in Kani; bounded model checking requires careful restriction of input sizes to prevent state explosion.

### Immediate Action Item
Do we approve this ADR? If so, the immediate next technical step is deciding whether to use **manual `bindgen`/`cxx` wrappers** or direct **`repr(C)` bridging** to connect the Lean `extern` signatures to the Rust implementation so we can begin writing the first Kani harness.
