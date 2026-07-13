# PIRTM Language Specification

**Status:** Draft (v0.9) – Pre‑production / Research  
**Version:** 0.9.0  
**Last Updated:** 2026-07-12  
**Classification:** per ADR‑012, the UAC substrate is production‑hardened; the surface language is research‑grade pending independent verification.

---

## 1. Introduction

PIRTM (Phase‑Indexed Recursive Tensor Mathematics / Runtime) is a strongly typed, statically verified, numerically stable language for **prime‑indexed recursive tensor computations** with built‑in governance and cryptographic attestation.

The language is designed to support:
- **Multiplicity calculations** over prime‑indexed Hilbert spaces.
- **Contractivity certificates** for every operator (via Lean proofs).
- **Runtime drift monitoring** via the WardMonitor / Zeno‑Finton system.
- **Immutable audit trails** (Antigrav / Archivum).

The core semantics are grounded in the **MOC** (Multiplicity Operator Calculus) and the **PWEH** (Prime‑Weighted Entropy Hashing) numerical kernel.

---

## 2. Grammar (Syntax)

PIRTM source is a sequence of statements, each terminated by a semicolon (`;`). A program consists of a top‑level block.

### 2.1 Lexical Conventions

- **Identifiers**: `[A-Za-z_][A-Za-z0-9_]*`
- **Integers**: `[0-9]+` (decimal)
- **Prime literals**: `Ap(` `<integer>` `)` – denotes a prime‑indexed operator.
- **Comments**: `//` line comments; `/* */` block comments.

### 2.2 Statements

```ebnf
Program ::= Stmt*

Stmt ::= LetStmt
       | ExprStmt
       | BlockStmt

LetStmt ::= 'let' Identifier '=' Expr ';'

ExprStmt ::= Expr ';'

BlockStmt ::= '{' Stmt* '}'
```

### 2.3 Expressions

```ebnf
Expr ::= Literal
       | Identifier
       | Atom
       | BinaryOp
       | UnaryOp
       | Grouping

Literal ::= Integer

Atom ::= 'Ap(' Integer ')'

BinaryOp ::= Expr ('+' | '-' | '*' | '/' | '^') Expr

UnaryOp ::= ('-' | '!') Expr

Grouping ::= '(' Expr ')'
```

### 2.4 Additional Nodes (Phase Mirror / Sedona Spine)

- **Successor**: `Succ(Expr)` – represents the successor predicate.
- **StratumBoundary**: `Stratum(Expr, Expr)` – models boundary crossing between strata.

These are not yet exposed in the surface grammar but are used internally by the compiler.

---

## 3. Type System

PIRTM is a **monomorphic, statically typed** language with a single core type:

### 3.1 Primitive Types

- **Stratum** (`!pirtm.stratum`) – an element of the prime‑indexed Hilbert space. All expressions evaluate to a stratum value.

### 3.2 Type Environments

Typing judgments are of the form:

```
Γ ⊢ e : τ
```

where `Γ` is a map from identifiers to types.

### 3.3 Typing Rules

| Rule | Premise | Conclusion |
|------|---------|------------|
| **T‑Literal** | `n` is an integer | `Γ ⊢ n : stratum` |
| **T‑Atom** | `p` is a prime > 1 | `Γ ⊢ Ap(p) : stratum` |
| **T‑Var** | `x ∈ dom(Γ)` | `Γ ⊢ x : Γ(x)` |
| **T‑Binary** | `Γ ⊢ e1 : stratum`, `Γ ⊢ e2 : stratum`, `op ∈ {+, -, *, /, ^}` | `Γ ⊢ e1 op e2 : stratum` |
| **T‑Let** | `Γ ⊢ e : stratum`, `Γ[x ↦ stratum] ⊢ body : stratum` | `Γ ⊢ let x = e; body : stratum` |
| **T‑Block** | `∀ stmt ∈ block, Γ ⊢ stmt : stratum` | `Γ ⊢ block : stratum` |

> *Note:* The typing rules are intentionally simple; all expressions produce a stratum. Future extensions may introduce more types (e.g., tensors, functions).

---

## 4. Operational Semantics

PIRTM uses a **small‑step, deterministic** operational semantics. Evaluation reduces an expression to a canonical stratum value (a rational number in the multiplicity space).

### 4.1 Values

A value is a **multiplicity** represented as a rational number (`Rational64` in the implementation). All expressions reduce to a value.

### 4.2 Evaluation Contexts

We define evaluation contexts `E` as a list of reduction frames:

```
E ::= []
    | E + e
    | v + E
    | E - e
    | v - E
    | ...
```

### 4.3 Reduction Rules

| Rule | Premise | Reduction |
|------|---------|-----------|
| **R‑Atom** | `p` is a prime > 1 | `Ap(p) → p` (multiplicity) |
| **R‑Binary** | `v1 op v2` reduces using rational arithmetic | `v1 op v2 → v` |
| **R‑Let** | `let x = e; body` → `body` with `e` bound to `x` | substitution |
| **R‑Block** | block reduces sequentially; final expression value is the block value | step through statements |

### 4.4 Termination

All programs terminate because:
- Each operation is contractive (as proven by Lean theorems).
- Recursion is not currently supported (future work).

---

## 5. Contractivity Invariants

Every operator atom (`Ap(p)`) and every binary operation **must** satisfy a contractivity bound:

```
λₚ · Lₚ < 1
```

where:
- `λₚ` is the spectral radius of the operator.
- `Lₚ` is the Lipschitz constant of the operation.

The compiler enforces this via:
1. **Lean proofs** attached to every `OperatorAtom` construction (the constructor pattern).
2. **Runtime checks** in the WardMonitor (ρ drift threshold). Telemetry tests enforce `ANOMALY_GOV_THRESHOLD < 0.85` for all transcendental traces.
3. **PWEH** numerical verification (the 108‑cycle trace).

### 5.1 Multiplicity Functor

For an atom `Ap(p)`, the multiplicity is defined as:

```
M(S) = p^m
```

where `m` is the exponent (a rational number). The functor is computed using exact `Rational64` arithmetic to avoid floating‑point drift.

### 5.2 Successor Predicate

The successor predicate `Succ(e)` ensures that any transition from stratum `n` to `n+1` preserves contractivity. This is enforced via the Lean theorem `successor_contractivity_correct`.

### 5.3 Stratum Boundary

`Stratum(e1, e2)` checks that moving from `e1` to `e2` does not cross a boundary that would violate the invariant. The boundary check is defined in `StratumBoundary.lean`.

---

## 6. Standard Library

The `pirtm-stdlib` crate provides:

- **Primitive operators**: `Ap(p)`, `Succ`, `Stratum`.
- **Arithmetic**: `+`, `-`, `*`, `/`, `^`.
- **PWEH helpers**: `trace`, `verify`, `k_bound`.
- **Governance hooks**: `emit_receipt`, `record_event`.

All standard library functions are accompanied by Lean proofs and contractivity certificates.

---

## 7. Implementation Notes

- The compiler is written in Rust and uses MLIR for code generation.
- Lean proofs are extracted via FFI during AST construction.
- The runtime is enforced by the WardMonitor daemon.
- The audit trail is stored in the Archivum ledger.

---

## 8. Future Work

The following are planned for the language surface:

- Support recursive functions (requires a termination proof).
- Full adoption of MLIR tensor operations in the backend (`!pirtm.tensor`).
- Parallel lowering for performance.

---

## 9. References

- [ADR‑012: PIRTM/MOC Language Surface Readiness Classification](docs/adr/ADR_012_PIRTM_MOC_Language_Surface_Readiness.md)
- [MOC.md – Multiplicity Operator Calculus](docs/MOC.md)
- [PWEH Formalization](substrates/lean/MOC/PWEH.lean)
- [Governance‑as‑Compilation ADR‑001](docs/adr/ADR-001-governance-as-compilation.md)

---

*This specification is a work in progress. It is versioned alongside the compiler source. Any changes to the language surface must be accompanied by an update to this document and a corresponding ADR.*
