# ADR-004: MA-VQE Compiler Architecture

## Status
Accepted

## Production Implementation (2026-07-18)

All four Next Steps are now discharged and verified by `cargo test -p atomic-calculator`:

1. **Generalized JW_d formalized in Lean** — `lean/Core/atomic_calculator/Core.lean`
   (`UAC.Math.GeneralizedJW`) defines `excitationAngle θ = π/(d-1)`, the Z-parity
   prefix `zParityPrefix`, and `jwTerm`. Proved: `zPrefix_length`
   (`|prefix| = j`), `excitation_angle_matches_rust` (ties the Lean angle to the
   Rust emission), and `jwTerm_shape` (`|jwTerm| = j+1`). Zero-`sorry`.
2. **Compiler logic in `ma_vqe.rs`/`ma_vqe_compiler.rs`** — `compile_jw_circuit`
   emits minimal-depth qudit instructions with adjacent-Z dedup; `evaluate_branch`
   prunes via the `QuantumM` monad (no-cloning corollary). Targets `d=10` (Sr)
   and `d=16` (Cs).
3. **Thresholds extracted from Lean via `build.rs`** — `build.rs` now parses
   `chemicalAccuracyThresholdMhaScaled` from `Core.lean` (panics on drift), so
   the Rust `CHEMICAL_ACCURACY_THRESHOLD_MHA_SCALED = 150000` (15 mHa) is no
   longer hardcoded.
4. **Validated on LiH** — `test_lih_full_compile_meets_accuracy_and_gate` asserts
   the emitted circuit meets chemical accuracy, the ALP gate approves it, and the
   excitation angle equals π/15.

Governance: every compiled circuit is routed through the **Sedona Spine ALP
policy gate** (`src/policy_gate.rs`, mirroring `Sovereign.Policy.Verdict`),
enforcing the 100-qudit hard boundary and rejecting empty/out-of-range circuits.
`qaas_endpoints::execute_simulation` now compiles via `compile_and_gate`, so
FeMoco (CAS(114,114) → ~69 qudits at 3.32×) is ALP-gated end-to-end.

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
