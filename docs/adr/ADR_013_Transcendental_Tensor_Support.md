# ADR 013: Transcendental Functions and Tensor Type Boundaries

## Executive Summary

As the Universal Atomic Calculator (UAC) Substrate transitions to a `v1.0.0-uac` production-hardened kernel, the pre-production PIRTM language surface must be expanded to support physical wave approximations and complex multi-dimensional resonance limits. 

The next major expansion encompasses two crucial dimensions:
1. **Transcendental Functions:** Inclusion of `sin`, `cos`, and `log` into the prime-indexed recursion AST.
2. **Tensor Types:** Extension of the underlying `!pirtm.stratum` type system to N-dimensional tensor manifolds (e.g. `!pirtm.tensor<f64, 3x3>`).

**Decision:** We will incrementally extend the PIRTM AST, MLIR generation, and formal Lean 4 contractivity proofs to support transcendental operations and rigid tensor boundaries while maintaining the zero-sorry guarantees of the UAC kernel.

## Implementation Roadmap

The implementation is phased to isolate mathematical risk (Lean proofs) from compiler engineering risk (MLIR lowering).

### Phase 1: AST Extension (Low Complexity)
- **Goal:** Add transcendental nodes to the AST and parser without modifying the MLIR lowering step.
- **Action:** Introduce `Expr.sin`, `Expr.cos`, and `Expr.log` to `crates/pirtm-stdlib/Lean/TypeChecker.lean` and the Rust frontend. 
- **Type Signature:** `Γ ⊢ e : stratum ⇒ Γ ⊢ sin(e) : stratum`

### Phase 2: Formal Contractivity Proofs (High Complexity)
- **Goal:** Prove that transcendental evaluations remain strictly contractive within the MOC Hilbert space.
- **Action:** Define Lipschitz bounds in Lean 4. For example, prove that $| \sin(x) - \sin(y) | \le | x - y |$ preserves $\lambda_p < 1$ under prime-weighted recursive descent. Logarithmic bounds must handle domain singularities near zero to prevent Sedona Spine divergence.

### Phase 3: MLIR Lowering and Intrinsics (Medium Complexity)
- **Goal:** Compile the new AST nodes down to LLVM.
- **Action:** Expand the MLIR visitor in the PIRTM compiler to map `Expr.sin` and `Expr.cos` to the standard `math.sin` and `math.cos` dialects, which will then seamlessly lower to LLVM intrinsics (`libm`).

### Phase 4: Tensor Type System (High Complexity)
- **Goal:** Introduce multi-dimensional tensors.
- **Action:** Expand `Type` in `TypeChecker.lean` from a monomorphic `stratum` to include parametric tensors. Map this into MLIR's built-in `tensor` dialect (`!pirtm.tensor<f64, NxM>`).

### Phase 5: Governance & Telemetry Hooks (Medium Complexity)
- **Goal:** Ensure transcendental overhead does not violate the 920ns/5000ns latency thresholds or artificially spike the 5D anomaly telemetry (`thermal_slope`, `entropy`).
- **Action:** Update benchmarks and invoke `test_anomaly_injector.py` with dense tensor payload limits to calibrate the `ANOMALY_GOV_THRESHOLD`.

## Resolution
This incremental approach explicitly guards the Triple-Lock and Sedona Spine invariants. Work will immediately begin on Phase 1 (AST expansion) and Phase 2 (Lean 4 proofs).
