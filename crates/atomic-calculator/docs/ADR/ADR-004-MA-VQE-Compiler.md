# ADR-004: MA-VQE Compiler Architecture

## Status
Proposed

## Context
Compiling molecular Hamiltonians directly into qudit subspaces requires a specialized compiler toolchain capable of handling high-dimensional ($d > 2$) quantum states. Traditional frameworks like Qiskit or TKET are optimized for binary qubits and do not natively support the generalized Jordan-Wigner ($JW_d$) transformations required by the Universal Atomic Calculator (UAC). To achieve the target of 3.32x resource compression for molecules like $LiH$ and $H_2O$, and eventually the $FeS$ cluster, we need a custom compiler that integrates natively with the `QuantumM` monad.

## Decision
We will build a standalone, multiplicity-aware compiler integrated directly into the Rust UAC SDK (`ma_vqe.rs`). This compiler will:
1. Target physical qudits with dimensions $d=10$ (Sr) and $d=16$ (Cs).
2. Apply Generalized Jordan-Wigner transformations to map fermionic operators to qudit instructions.
3. Utilize the SnapKitty `QuantumM` monad's `bind` operation to prune the variational search tree, enforcing the "no-cloning" corollary to destroy failed or unphysical branches.
4. Strictly route all optimization decisions through the Sedona Spine ALP policy gate.

## Consequences
- **Positive**: Directly enables the 3.32x resource compression. Allows us to hit chemical accuracy (< 15 mHa) on complex clusters using < 40 physical qudits.
- **Negative**: Requires maintaining a custom compiler stack separate from mainstream qubit-centric ecosystems, increasing the engineering burden.

## Next Steps
1. Formalize the generalized $JW_d$ transformation in Lean (`Core.lean`).
2. Implement the compiler logic in `ma_vqe.rs` to emit minimal-depth instructions.
3. Extract chemical accuracy thresholds (e.g., 15 mHa) from Lean via `build.rs`.
4. Validate the emitted circuits on $LiH$ targets.
