# ADR: Production-Grade Implementation of Language Mapping

## Status
Proposed

## Context
The project requires a production-grade implementation of the "Regime Detection and Transition Invariance in High-Dimensional Language Mappings" protocol. The protocol determines whether a candidate behavioral partition in large language models is empirically stable enough to serve as the target of mechanistic investigation. The implementation must ensure high reliability, formal verification, and clear separation of concerns.

The core logic is currently placed under `Prime/rust/language-mapping`. To guarantee the strict theoretical constraints (zero drift, integrity paths), we need to formally verify the implementation.

## Decision
We will implement the language mapping protocol using a triad of technologies: **Rust**, **Kani**, and **Lean 4**.

1. **Rust for Core Execution**:
   - The primary execution engine will be written in Rust. Rust provides the necessary performance, memory safety, and concurrency primitives for processing high-dimensional mappings and generating perturbations.
   - The code will remain in `Prime/rust/language-mapping`.

2. **Kani for Bounded Model Checking**:
   - Kani Rust Verifier will be integrated into the Rust codebase.
   - We will write Kani harnesses to verify critical state transitions, memory safety, and invariant preservation within bounded state spaces, specifically ensuring that perturbation generation and boundary detection logic do not panic or exhibit undefined behavior.

3. **Lean 4 for Formal Verification**:
   - Lean 4 will be used to formally prove the higher-level theorems and behavioral invariance properties of the protocol.
   - All Lean 4 code will be strictly separated and housed in `Prime/lean`. This ensures a clean architectural boundary between the executable Rust engine and the mathematical proofs.
   - The Lean proofs will model the state machines and topological boundaries defined by the Rust implementation.

## Consequences

### Positive
- **High Assurance**: The combination of Rust's type system, Kani's bounded model checking, and Lean's interactive theorem proving provides defense-in-depth assurance.
- **Separation of Concerns**: Keeping Lean code in `Prime/lean` avoids cluttering the Rust execution environment and clarifies the boundary between executable code and formal proofs.
- **Alignment with Mandates**: This strict structural integrity aligns with our broader principles of having a verified, drift-free core engine.

### Negative / Risks
- **Complexity**: Managing three distinct ecosystems (Cargo/Rust, Kani, and Lake/Lean4) increases the learning curve and CI/CD complexity.
- **Synchronization**: We must ensure that the Lean 4 specifications accurately reflect the Rust implementation. Any changes to the Rust data structures or logic will require corresponding updates to the Lean models.

## Implementation Plan
1. Establish the Rust crate skeleton in `Prime/rust/language-mapping`.
2. Add Kani dependencies and write initial verification harnesses for core data structures.
3. Initialize a Lean 4 project (via Lake) in `Prime/lean/language_mapping` (if it doesn't already exist).
4. Define the formal equivalence classes and perturbation sets in Lean 4.
5. Setup CI to run `cargo test`, `cargo kani`, and `lake build` to enforce integrity across the triad.
