# Zeta-Schrödinger Dynamics (Lean 4)

## Overview
This is a self-contained, formal verification project implementing the **Zeta-Schrödinger Dynamics** for the Phase Mirror-Legal framework. The project proves the strict contraction mapping of the coupled ODE/operator dynamics under the Sedona Spine Mandate.

Crucially, this project uses **strictly zero `Mathlib` tactics** (e.g., no `ring`, no `field_simp`). All algebraic simplifications and inequality bounds are proven by hand using core equality rewrites (`rw`) and `calc` blocks to ensure a transparent, independently auditable provenance chain.

## Architecture
The formalization is structured into three layers to maintain portability across Rust → WASM builds:
1. **Core Algebraic Lemmas**: Handcrafted proofs for arithmetic operations (distributivity, associativity, sub-additivity) situated in `/Algebra/Core.lean`.
2. **Operator Skeletons**: Pure Lean structures representing linear operators with explicit bounds (e.g., `GammaMOp`) situated in `/System/Operators.lean`.
3. **Contraction Theorem**: The fully explicit `calc` proof combining the operator domains and geometric logic without automation situated in `/System/ContractionFull.lean`.

## Build Instructions

1. Ensure you have **Lean 4** and **Lake** installed via `elan`.
2. Build the project to verify all proofs:
   ```bash
   lake build
   ```
3. To confirm that the proofs contain zero unresolved stubs (`sorry`), you can run:
   ```bash
   grep -rnw '.' -e "sorry"
   ```
   *(If nothing is returned, the proof is fully verified).*

## Output
The core verification artifact is intended to be exported via `lean --export-wasm` into a WASM module, serving as a cryptographic proof-witness to the execution layer.
