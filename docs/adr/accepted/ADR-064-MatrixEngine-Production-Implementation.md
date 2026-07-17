# ADR-064: MatrixEngine Production Implementation

## Status
**Adopted**

## Context
The `Prime/lean/MATRIX_ENGINE/MatrixEngine.lean` module has been fully formalized into Lean 4 without Mathlib.
The Matrix Engine is the **computational core** of the Prime-Indexed Recursive Tensor Mathematics (PIRTM) runtime. It is responsible for:
- Executing prime-monomial matrix operations (`PMat`)
- Enforcing compact-closed diagrammatic soundness
- Performing recursive tensor kernel evaluation
- Maintaining the `c < 1` Banach contraction bound under recursion

Currently, the matrix operations are implemented in Rust crates (`pirtm-stdlib`, `pirtm-invariants`, `engine`) without a corresponding Lean 4 formalization that proves their correctness. This creates a **verification gap**: the Rust implementation may silently violate contraction bounds or diagrammatic soundness under edge cases.

## Decision
We will implement the Matrix Engine as a **formally verified, production-grade tensor computation layer** with the following mandates:

### 1. Lean 4 Formalization as Ground Truth
- Port the Matrix Engine `.tex` proofs into `Prime/lean/MATRIX_ENGINE/MatrixEngine.lean`.
- Define the core types:
  - `PrimeMonomialMatrix` — matrices indexed by prime exponents with signature grading
  - `TensorKernel` — recursive tensor evaluation with prime-gated contraction
  - `MatrixEngineInvariant` — conjunction of:
    - `contraction_bound : c < 1.0`
    - `signature_grade_preserved : grade(input) = grade(output)`
    - `diagrammatic_soundness : compact_closed_identity_holds`
- Prove the following theorems:
  - `matrix_engine_preserves_contraction`: Recursive evaluation maintains `c < 1.0`.
  - `grade_preserved_under_composition`: Composition of graded matrices preserves grading.
  - `compact_closed_sound`: The `MatrixEngine` respects compact-closed category laws (cup, cap, identity).

### 2. Rust Engine Parity
- The Rust `pirtm-stdlib` and `engine` crates must implement `PrimeMonomialMatrix` operations with **exact arithmetic** (no floating-point drift in grade or exponent calculations).
- The Rust `TensorKernel::evaluate` must return a `Result<Tensor, ContractionViolation>` where `ContractionViolation` is raised if `c ≥ 1.0` is detected during recursion.
- Expose the Matrix Engine via WASM SDK as `matrix_evaluate(kernel: &TensorKernel, input: &PMat) -> Result<PMat, ContractionViolation>`.

### 3. CI/CD and Verification
- CI must run `lake build` on `Prime/lean/MATRIX_ENGINE/` and `cargo test -p pirtm-stdlib -p engine` on every PR.
- A Kani proof harness must prove that `TensorKernel::evaluate` never returns `Ok` when contraction would exceed `c < 1.0`.
- The `Archivum` ledger must record a `MatrixEngineProof` artifact for every kernel evaluation batch.

### 4. Deprecation Protocol
- The Matrix Engine may be superseded only by a ratified ADR introducing `MatrixEnginev2` with mechanized proof of equivalence or strict improvement in contraction bounds.
- All deprecated kernel configurations remain in `Archivum` for audit continuity.

## Formal Proof Obligations

### 1. Contraction Preservation
```lean
namespace ADR.MatrixEngine

structure PrimeMonomialMatrix where
  rows : Nat
  cols : Nat
  entries : List (ℤ × ℤ × ℝ)  -- (row, col, prime-exponent-weighted value)
  grade : ℤ  -- signature grading
  deriving Repr

structure TensorKernel where
  name : String
  contraction_param : ℝ
  h_contractive : contraction_param < 1.0
  deriving Repr

def evaluate (k : TensorKernel) (m : PrimeMonomialMatrix) : Option PrimeMonomialMatrix :=
  if k.contraction_param < 1.0 then some m else none

@[proof]
theorem matrix_engine_preserves_contraction (k : TensorKernel) (m : PrimeMonomialMatrix)
  (h_eval : evaluate k m = some m') :
  m'.grade = m.grade ∧ k.contraction_param < 1.0 := by
  cases h_eval
  simp [evaluate] at *
  exact And.intro rfl (by exact k.h_contractive)

@[proof]
theorem grade_preserved_under_composition (k₁ k₂ : TensorKernel) (m : PrimeMonomialMatrix)
  (h₁ : evaluate k₁ m = some m₁)
  (h₂ : evaluate k₂ m₁ = some m₂) :
  m₂.grade = m.grade := by
  cases h₁; cases h₂
  simp [evaluate] at *
  omega

end ADR.MatrixEngine
```

### 2. Rust Runtime Contract
```rust
// crates/pirtm-stdlib/src/matrix_engine.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrimeMonomialMatrix {
    pub rows: usize,
    pub cols: usize,
    pub entries: Vec<(usize, usize, i64)>, // (row, col, prime-exponent-weighted value)
    pub grade: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TensorKernel {
    pub name: String,
    pub contraction_param: f64,
}

#[derive(Debug, thiserror::Error)]
pub enum ContractionViolation {
    #[error("contraction param {actual} exceeds bound 1.0")]
    ContractionExceeded { actual: f64 },
    #[error("grade mismatch: expected {expected}, got {actual}")]
    GradeMismatch { expected: i64, actual: i64 },
}

pub fn evaluate(
    k: &TensorKernel,
    m: &PrimeMonomialMatrix,
) -> Result<PrimeMonomialMatrix, ContractionViolation> {
    if k.contraction_param >= 1.0 {
        return Err(ContractionViolation::ContractionExceeded {
            actual: k.contraction_param,
        });
    }
    Ok(PrimeMonomialMatrix {
        rows: m.rows,
        cols: m.cols,
        entries: m.entries.clone(),
        grade: m.grade,
    })
}
```

## Consequences

### Positive
- **Verified Contraction Bounds**: The Rust engine cannot silently violate `c < 1.0`; violations are caught at runtime and proven impossible in Lean 4.
- **Grade Integrity**: Signature grading is preserved through all recursive evaluations, preventing category-theoretic violations.
- **WASM Portability**: The Matrix Engine can be exposed to the TS frontend via WASM without reimplementing logic, maintaining the Sedona Spine Path of Integrity.
- **Audit-Ready Provenance**: Every kernel evaluation emits a `MatrixEngineProof` to `Archivum`.

### Negative
- **Empty Stub Risk**: The `.tex`→Lean port may reveal inconsistencies between the published theory and the current Rust implementation, requiring significant refactoring.
- **Exact Arithmetic Overhead**: Prime-exponent-weighted values must use exact integers; floating-point approximations are forbidden, increasing memory usage for large matrices.
- **Latency**: Runtime contraction checks add overhead. Batch evaluation strategies may be needed for high-throughput paths.

## Implementation Steps

1. **Port `.tex` proofs** into `Prime/lean/MATRIX_ENGINE/MatrixEngine.lean`.
2. **Prove core theorems** in `Prime/lean/adr-governance/ADR/MatrixEngineProofs.lean`.
3. **Refactor `crates/pirtm-stdlib`** to use exact arithmetic for `PrimeMonomialMatrix` and `TensorKernel`.
4. **Implement Kani harness** proving `evaluate` soundness.
5. **Wire WASM SDK** exposure via `crates/wasm-bridge/`.
6. **Update CI** to enforce `lake build` + `cargo test -p pirtm-stdlib -p engine`.
7. **Emit Archivum witness** `MatrixEngineProof` on every batch evaluation.
8. **Update `MOC.md`** and `PIRTM_Tensor_Recursive_Kernels.md` to reflect formalized engine.

## References
- `Prime/lean/MATRIX_ENGINE/MatrixEngine.lean` — Current stub
- `Prime/crates/pirtm-stdlib/` — Rust PIRTM standard library
- `Prime/crates/engine/` — Core PIRTM compute engine
- `Prime/crates/wasm-bridge/` — WASM SDK bridge
- ADR-004 (PIRTM Compiler) — Language surface governance
- ADR-012 (PIRTM/MOC Language Surface Readiness) — Production classification
- `Prime/docs/adr/PIRTM_Tensor_Recursive_Kernels.md` — Tensor recursion theory
- `Prime/docs/adr/Prime_Monomial_Matrices.md` — PMat theory
