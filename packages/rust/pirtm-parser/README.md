# `pirtm-parser` — PIRTM Language Parser & AST Engine

The `pirtm-parser` crate provides the lexing, tokenization, AST generation, and EBNF decoding parsing infrastructure for **PIRTM-lang**.

---

## 1. Features

- **PIRTM EBNF Decoder Parser:** Full recursive descent implementation of the ratified PIRTM EBNF specification matching [`pirtm/csc.py`](../../../pirtm/csc.py).
- **Dual Statement Support:**
  - `Statement::TensorDeclaration`: Prime-indexed tensor sheaf basis definitions.
  - `Statement::OperatorApplication`: Multiplicity operator chains with optional $\Lambda_m$ scaling.
  - `Statement::ContractivityAssertion`: Fixed-point contractivity bounds enforcement.
- **Sedona Spine Integration:** Hard proof-gate checks enforcing fail-closed rejection on invalid prime shifts, stratum boundaries, or successor operations before lever emission.
- **Formal Verification Alignment:** Automated regression checks against [`lean/Multiplicity/PIRTM.lean`](../../../lean/Multiplicity/PIRTM.lean) verifying scale factor stabilization (`k_equals_kappa`).

---

## 2. Quick Start

### Add as Dependency
```toml
[dependencies]
pirtm-parser = { path = "packages/rust/pirtm-parser" }
```

### Parsing EBNF Statements

```rust
use pirtm_parser::{parse_ebnf_statements, Statement};

fn main() -> Result<(), String> {
    let code = r#"
        tensor T_0 [p_2, p_3, p_5];
        T_0 |> \Lambda_m * p_7 * p_11;
        assert_contractive(T_0) < 0.85;
    "#;

    let statements = parse_ebnf_statements(code)?;
    for stmt in statements {
        match stmt {
            Statement::TensorDeclaration { identifier, primes } => {
                println!("Tensor {}: primes {:?}", identifier, primes);
            }
            Statement::OperatorApplication { identifier, has_lambda, prime_chain } => {
                println!("Operator {}: Lambda={}, Chain={:?}", identifier, has_lambda, prime_chain);
            }
            Statement::ContractivityAssertion { identifier, bound } => {
                println!("Assert Contractivity {}: < {}", identifier, bound);
            }
        }
    }
    Ok(())
}
```

---

## 3. Running Test Suite

```bash
cargo test --manifest-path packages/rust/pirtm-parser/Cargo.toml
```

All 21 unit tests (including EBNF parser verification, AST proof gate enforcement, and Lean correspondence checks) execute and validate cleanly.
