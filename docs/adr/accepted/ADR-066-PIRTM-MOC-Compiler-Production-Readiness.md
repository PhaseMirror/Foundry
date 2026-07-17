# ADR-066: PIRTM/MOC Compiler Production Readiness

## Status
**Adopted**

## Context
The existing `Prime/docs/adr/0004-pirtm-compiler.md` defines PIRTM Compiler Implementation (Phase B) but is **21 lines of prose** with no formal proof obligations, no compiler specification, and no verification requirements. 

The `Prime/docs/adr/ADR_012_PIRTM_MOC_Language_Surface_Readiness.md` correctly identifies that the PIRTM/MOC compute language is currently **pre-production / research-grade** while the UAC substrate is production-ready. The compiler stack spans:
- `crates/compiler/` — MLIR-based PIRTM compiler
- `crates/lexer/` — Lexical analysis
- `crates/parser/` — PIRTM parser
- `crates/mlir/` — MLIR dialect and lowering
- `crates/pirtm-stdlib/` — Standard library
- `crates/pirtm-invariants/` — Invariant enforcement
- `crates/c-pirtm/` — C bindings

The language surface lacks:
- A frozen grammar specification
- Denotational semantics
- A Lean-verified type checker
- A certified compiler correctness proof

This creates a **soundness gap**: the Rust/LLVM/MLIR stack may compile programs that violate PIRTM's core contractivity guarantees, and there is no mechanized way to detect such violations before runtime.

## Decision
We will ratify a **two-tier production readiness model** for the PIRTM/MOC stack:

### Tier 1: UAC Substrate (Production-Ready)
- The UAC substrate (Rust engine + WASM SDK + Lean 4 kernel proofs) is **already production-ready** per ADR-012.
- All changes to `crates/core/`, `crates/engine/`, `crates/pirtm-stdlib/` (runtime library only) must maintain the zero-sorry Lean 4 proof boundary.
- The UAC substrate remains frozen under the `uac-substrate` tag; no language-surface changes are permitted without ADR ratification.

### Tier 2: PIRTM/MOC Language Surface (Pre-Production)
- The high-level PIRTM/MOC language (parser, lexer, type checker, compiler) remains **pre-production** until:
  - A frozen grammar specification is published
  - A Lean 4 verified type checker is implemented
  - A compiler correctness proof (or at minimum, a Kani-verified lowering pass) is completed
  - The stdlib is complete and zero-sorry

### 3. Formal Specification in Lean 4
- Create `Prime/lean/PIRTM/Compiler.lean` defining:
  - `PirtmExpr` — inductive AST for PIRTM programs
  - `PirtmType` — type system (stratum, tensor types, transcendental functions)
  - `TypeCheck : Context → PirtmExpr → PirtmType → Prop` — typing judgment
  - `WellTyped` — wrapper proposition `∃ τ, TypeCheck ctx e τ`
- Prove:
  - `type_check_sound`: If `TypeCheck ctx e τ`, then `e` does not violate PIRTM contractivity bounds.
  - `type_check_complete`: All well-formed PIRTM expressions have a unique principal type.
  - `compiler_preserves_types`: MLIR lowering preserves the typing judgment.

### 4. Rust Verification
- Implement Kani harnesses in `crates/compiler/tests/kani/` proving:
  - `proof_parser_preserves_types`: The Rust parser only accepts expressions that would type-check in Lean 4.
  - `proof_mlir_lowering_sound`: MLIR lowering does not introduce type errors.
  - `proof_stdlib_contractive`: All stdlib functions preserve `c < 1.0`.

### 5. CI/CD Gating
- CI must enforce:
  - `lake build` on `Prime/lean/PIRTM/` and `Prime/lean/adr-governance/`
  - `cargo kani -p compiler -p pirtm-stdlib` on all PRs touching the language surface
  - `lake exe adr_test` (Lean ADR test harness) must pass
  - `--reject-sorry` flag on all PIRTM/MOC Lean modules

## Formal Proof Obligations

### 1. Type Checker Soundness
```lean
namespace ADR.Pirtm

inductive PirtmType
  | Stratum
  | Tensor (dims : List Nat)
  | Transcendental (fn : String) (arg : PirtmType)
  deriving Repr, DecidableEq

inductive PirtmExpr
  | Const (n : ℤ)
  | Var (name : String)
  | Add (e₁ e₂ : PirtmExpr)
  | Sin (e : PirtmExpr)
  | Cos (e : PirtmExpr)
  | Log (e : PirtmExpr)
  deriving Repr

inductive TypeCheck : List (String × PirtmType) → PirtmExpr → PirtmType → Prop
  | tc_const {ctx} : TypeCheck ctx (PirtmExpr.Const n) PirtmType.Stratum
  | tc_var {ctx name τ} : (name, τ) ∈ ctx → TypeCheck ctx (PirtmExpr.Var name) τ
  | tc_add {ctx e₁ e₂ τ₁ τ₂} :
      TypeCheck ctx e₁ τ₁ → TypeCheck ctx e₂ τ₂ → τ₁ = τ₂ →
      TypeCheck ctx (PirtmExpr.Add e₁ e₂) τ₁
  | tc_sin {ctx e τ} :
      TypeCheck ctx e PirtmType.Stratum →
      TypeCheck ctx (PirtmExpr.Sin e) (PirtmType.Transcendental "sin" PirtmType.Stratum)
  | tc_cos {ctx e τ} :
      TypeCheck ctx e PirtmType.Stratum →
      TypeCheck ctx (PirtmExpr.Cos e) (PirtmType.Transcendental "cos" PirtmType.Stratum)
  | tc_log {ctx e τ} :
      TypeCheck ctx e PirtmType.Stratum →
      TypeCheck ctx (PirtmExpr.Log e) (PirtmType.Transcendental "log" PirtmType.Stratum)

@[proof]
theorem type_check_sound (ctx : List (String × PirtmType)) (e : PirtmExpr) (τ : PirtmType)
  (h : TypeCheck ctx e τ) :
  well_formed e := by
  induction h <;> simp [well_formed] <;> aesop

def WellTyped (ctx : List (String × PirtmType)) (e : PirtmExpr) : Prop :=
  ∃ τ, TypeCheck ctx e τ

end ADR.Pirtm
```

### 2. Compiler Preserves Types (Rust Contract)
```rust
// crates/compiler/src/lib.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum PirtmType {
    Stratum,
    Tensor(Vec<usize>),
    Transcendental { fn_name: String, arg: Box<PirtmType> },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum PirtmExpr {
    Const(i64),
    Var(String),
    Add(Box<PirtmExpr>, Box<PirtmExpr>),
    Sin(Box<PirtmExpr>),
    Cos(Box<PirtmExpr>),
    Log(Box<PirtmExpr>),
}

#[derive(Debug, thiserror::Error)]
pub enum TypeError {
    #[error("type mismatch: expected {expected:?}, got {actual:?}")]
    TypeMismatch { expected: PirtmType, actual: PirtmType },
    #[error("undefined variable: {name}")]
    UndefinedVar { name: String },
}

pub fn type_check(
    ctx: &[(String, PirtmType)],
    expr: &PirtmExpr,
) -> Result<PirtmType, TypeError> {
    match expr {
        PirtmExpr::Const(_) => Ok(PirtmType::Stratum),
        PirtmExpr::Var(name) => ctx.iter()
            .find(|(n, _)| n == name)
            .map(|(_, t)| t.clone())
            .ok_or_else(|| TypeError::UndefinedVar { name: name.clone() }),
        PirtmExpr::Add(e1, e2) => {
            let t1 = type_check(ctx, e1)?;
            let t2 = type_check(ctx, e2)?;
            if t1 == t2 { Ok(t1) } else {
                Err(TypeError::TypeMismatch { expected: t1, actual: t2 })
            }
        }
        PirtmExpr::Sin(e) | PirtmExpr::Cos(e) | PirtmExpr::Log(e) => {
            type_check(ctx, e)?;
            Ok(PirtmType::Transcendental {
                fn_name: match expr {
                    PirtmExpr::Sin(_) => "sin".into(),
                    PirtmExpr::Cos(_) => "cos".into(),
                    PirtmExpr::Log(_) => "log".into(),
                    _ => unreachable!(),
                },
                arg: Box::new(PirtmType::Stratum),
            })
        }
    }
}
```

## Consequences

### Positive
- **Mechanical Soundness**: The Lean-verified type checker guarantees that no well-typed PIRTM program can violate contractivity bounds.
- **Two-Tier Safety**: The UAC substrate remains production-hardened while the language surface evolves under formal review.
- **Kani-Verified Compiler**: Rust-level model checking catches memory safety and logic bugs in the parser/MLIR lowering.
- **Audit-Ready Provenance**: Every compilation unit emits a `PirtmCompileProof` to `Archivum`.

### Negative
- **Formalization Overhead**: Designing a Lean-verified type checker for a language with transcendental functions and tensor types is a significant research effort.
- **Two-Tier Complexity**: Developers must understand which tier their changes affect; mistakes (e.g., modifying the parser without ADR ratification) could violate the pre-production boundary.
- **Latency**: Type checking + Kani verification adds compile-time overhead. The CI pipeline will be slower.

## Implementation Steps

1. **Define `Pirtm.lean`** in `Prime/lean/PIRTM/` with `PirtmExpr`, `PirtmType`, and `TypeCheck`.
2. **Prove type checker theorems** in `Prime/lean/adr-governance/ADR/PirtmProofs.lean`.
3. **Implement `crates/compiler/` type checker** in Rust, mirroring the Lean judgment.
4. **Implement Kani harness** proving parser and lowering soundness.
5. **Freeze UAC substrate** under `uac-substrate` tag; mark language surface as pre-production.
6. **Update CI** to enforce `lake build` + `cargo kani -p compiler -p pirtm-stdlib` + `--reject-sorry`.
7. **Emit Archivum witness** `PirtmCompileProof` on every compilation.
8. **Publish grammar spec** and `MOC.md` as formal documents.

## References
- `Prime/docs/adr/0004-pirtm-compiler.md` — Legacy PIRTM Compiler ADR (to be superseded)
- `Prime/docs/adr/ADR_012_PIRTM_MOC_Language_Surface_Readiness.md` — Two-tier readiness classification
- `Prime/docs/adr/ADR_013_Transcendental_Tensor_Support.md` — Transcendental and tensor type roadmap
- `Prime/crates/compiler/` — MLIR-based PIRTM compiler
- `Prime/crates/pirtm-stdlib/` — PIRTM standard library
- `Prime/crates/mlir/` — MLIR dialect
- `Prime/lean/PIRTM/` — Lean PIRTM formalization (to be expanded)
- ADR-004 (Lifebushido Triadic Scaling) — Dependent type patterns
- ADR-064 (MatrixEngine) — Tensor kernel formalization
