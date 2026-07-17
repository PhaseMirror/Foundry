# ADR-070: Ξ-Compiler Production Implementation

## Status
**Adopted**

## Context
The publication `publications/The Ξ-Compiler/` describes a **compiler for the Ξ (Xi) language**—the theoretical foundation for the Multiplicity Sovereign Core's formal specification layer. The Ξ-Compiler translates high-level multiplicity-theoretic constructs into executable code (Rust/WASM/Lean).

Currently, the Ξ-Compiler exists only as a publication with a LaTeX template. There is **no implementation** in `Prime/crates/` or `Prime/lean/`. The `compiler` crate in `Prime/crates/` is the PIRTM/MLIR compiler, not the Ξ-Compiler.

The Ξ-Compiler is a **high-value target** because:
- It is the **theoretical bridge** between mathematical publications and production code
- It would allow researchers to write multiplicity-theoretic specifications that compile directly to verified Rust/Lean/WASM
- It enables the **Sovereign Stack** to maintain a single source of truth from publication to deployment

## Decision
We will implement the Ξ-Compiler as a **production-grade, formally verified compiler** from the Ξ language to Rust/WASM/Lean, with the following mandates:

### 1. Language Specification in Lean 4
- Define `Prime/lean/XICOMPILER/XiLang.lean` with:
  - `XiExpr` — inductive AST for Ξ programs
  - `XiType` — type system including prime-indexed types, multiplicity types, and contraction types
  - `TypeCheck : Context → XiExpr → XiType → Prop` — typing judgment
- Prove:
  - `xi_type_sound`: Well-typed Ξ programs do not violate PIRTM contractivity bounds.
  - `xi_type_complete`: All well-formed Ξ expressions have a principal type.
  - `xi_compiles_to_safe_rust`: The Rust codegen preserves Ξ types and invariants.

### 2. Compiler Implementation in Rust
- Create `Prime/crates/xi-compiler/` with:
  - `lexer/` — Ξ lexical analysis
  - `parser/` — Ξ parser producing `XiExpr` AST
  - `type_checker/` — Rust implementation of `TypeCheck`, mirroring the Lean proof
  - `codegen/` — Rust/WASM/Lean code generation
  - `cli/` — Command-line interface for compilation
- The compiler must:
  - Accept `.xi` source files
  - Output verified Rust code that compiles with `cargo build`
  - Output Lean 4 proof scripts that compile with `lake build`
  - Output WASM modules that pass `wasm-pack` validation

### 3. Kani Verification
- Implement Kani harnesses in `Prime/crates/xi-compiler/tests/kani/` proving:
  - `proof_parser_sound`: The Rust parser only accepts expressions that type-check in Lean 4.
  - `proof_codegen_preserves_types`: Generated Rust code preserves Ξ types.
  - `proof_wasm_output_valid`: Generated WASM modules pass structural validation.

### 4. CI/CD and Integration
- CI must run `lake build` on `Prime/lean/XICOMPILER/` and `cargo kani -p xi-compiler` on every PR.
- The Guardian lock must verify compiled output before deployment.
- The Examiner lock must audit the compilation trace.
- The Publisher lock must sign compiled artifacts into the `Archivum` ledger.

## Formal Proof Obligations

### 1. Ξ Type Soundness
```lean
namespace ADR.XiCompiler

inductive XiType
  | Prime (p : ℕ)
  | Multiplicity (n : ℕ)
  | Contraction (bound : ℝ)
  | Tensor (dims : List Nat)
  deriving Repr, DecidableEq

inductive XiExpr
  | Const (n : ℤ)
  | PrimeLit (p : ℕ)
  | MultiplicityLit (n : ℕ)
  | Add (e₁ e₂ : XiExpr)
  | Contract (e : XiExpr) (bound : ℝ)
  deriving Repr

inductive TypeCheck : List (String × XiType) → XiExpr → XiType → Prop
  | tc_const : TypeCheck ctx (XiExpr.Const n) XiType.Contraction 1.0
  | tc_prime {p} : Nat.Prime p → TypeCheck ctx (XiExpr.PrimeLit p) (XiType.Prime p)
  | tc_multiplicity {n} : TypeCheck ctx (XiExpr.MultiplicityLit n) (XiType.Multiplicity n)
  | tc_add {ctx e₁ e₂ τ₁ τ₂} :
      TypeCheck ctx e₁ τ₁ → TypeCheck ctx e₂ τ₂ → τ₁ = τ₂ →
      TypeCheck ctx (XiExpr.Add e₁ e₂) τ₁
  | tc_contract {ctx e τ b} :
      TypeCheck ctx e τ → TypeCheck ctx (XiExpr.Contract e b) (XiType.Contraction b)

@[proof]
theorem xi_type_sound (ctx : List (String × XiType)) (e : XiExpr) (τ : XiType)
  (h : TypeCheck ctx e τ) :
  well_typed e := by
  induction h <;> simp [well_typed] <;> aesop

end ADR.XiCompiler
```

### 2. Rust Parser Contract
```rust
// crates/xi-compiler/src/parser.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum XiType {
    Prime(u64),
    Multiplicity(u64),
    Contraction(f64),
    Tensor(Vec<usize>),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum XiExpr {
    Const(i64),
    PrimeLit(u64),
    MultiplicityLit(u64),
    Add(Box<XiExpr>, Box<XiExpr>),
    Contract(Box<XiExpr>, f64),
}

#[derive(Debug, thiserror::Error)]
pub enum TypeError {
    #[error("type mismatch: expected {expected:?}, got {actual:?}")]
    TypeMismatch { expected: XiType, actual: XiType },
    #[error("not a prime: {0}")]
    NotPrime(u64),
}

pub fn type_check(
    ctx: &[(String, XiType)],
    expr: &XiExpr,
) -> Result<XiType, TypeError> {
    match expr {
        XiExpr::Const(_) => Ok(XiType::Contraction(1.0)),
        XiExpr::PrimeLit(p) => {
            if !is_prime(*p) { return Err(TypeError::NotPrime(*p)); }
            Ok(XiType::Prime(*p))
        }
        XiExpr::MultiplicityLit(n) => Ok(XiType::Multiplicity(*n)),
        XiExpr::Add(e1, e2) => {
            let t1 = type_check(ctx, e1)?;
            let t2 = type_check(ctx, e2)?;
            if t1 == t2 { Ok(t1) } else {
                Err(TypeError::TypeMismatch { expected: t1, actual: t2 })
            }
        }
        XiExpr::Contract(e, b) => {
            type_check(ctx, e)?;
            Ok(XiType::Contraction(*b))
        }
    }
}
```

## Consequences

### Positive
- **Publication-to-Code Bridge**: The Ξ-Compiler closes the loop between theoretical publications and production deployments.
- **Formally Verified Pipeline**: Lean 4 proofs guarantee that compiled code preserves mathematical invariants.
- **Multi-Target Output**: Single Ξ source compiles to Rust, WASM, and Lean, eliminating drift.
- **Research Velocity**: Researchers can write Ξ specifications and immediately get verified implementations.

### Negative
- **Greenfield Effort**: The Ξ-Compiler is entirely new; there is no existing Rust crate or Lean module to build upon.
- **Language Design Risk**: The Ξ language specification is not frozen; changes to the language break the compiler.
- **Complex Codegen**: Generating correct Rust/WASM/Lean from a typed AST requires sophisticated code generation and optimization passes.

## Implementation Steps

1. **Publish Ξ language spec** based on `publications/The Ξ-Compiler/templatePRIME.tex`.
2. **Define `XiLang.lean`** with `XiExpr`, `XiType`, and `TypeCheck`.
3. **Prove type soundness** in `Prime/lean/adr-governance/ADR/XiCompilerProofs.lean`.
4. **Create `Prime/crates/xi-compiler/`** with lexer, parser, type checker, and codegen.
5. **Implement Kani harness** proving parser and codegen soundness.
6. **Wire Triple-Lock integration**: Guardian → compilation approval → Examiner → output verification → Publisher → `Archivum`.
7. **Update CI** to enforce `lake build` + `cargo kani -p xi-compiler`.
8. **Emit Archivum witness** `XiCompileProof` on every compilation.

## References
- `publications/The Ξ-Compiler/templatePRIME.tex` — Publication template (to be expanded)
- `Prime/crates/compiler/` — PIRTM/MLIR compiler (related)
- `Prime/crates/pirtm-stdlib/` — PIRTM standard library
- ADR-066 (PIRTM/MOC Compiler) — Language surface governance
- ADR-064 (MatrixEngine) — Tensor kernel formalization
- `Prime/lean/MOC/` — MOC Lean module
- ADR-002 (Sedona Spine) — Path of Integrity
