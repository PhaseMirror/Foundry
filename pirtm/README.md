# PIRTM EBNF Decoding Parser
**Prime-Indexed Relational Tensor Model (PIRTM) — Front-end and Core Compiler Parser**

This repository contains the decoding parser pipeline for the PIRTM EBNF grammar, implemented in both Python (front‑end) and Rust (core compiler). The parser transforms human‑readable PIRTM source code into a structured AST that is later checked against formal Lean 4 proofs (`PIRTM.lean`).

---

## 1. Architectural Flow

```text
┌─────────────────────────────┐
│  PIRTM Source Code (.csc)   │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│  Lexical Tokenizer          │  (regex‑based, Python / Rust)
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│  Recursive Descent Parser   │  (PIRTMDecoderParser / lib.rs)
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│  Validated AST              │  (TensorDeclaration,
│                             │   OperatorApplication,
│                             │   ContractivityAssertion)
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│  Formal Proof Gatekeeper    │  (Sedona Spine / PIRTM.lean)
└─────────────────────────────┘
```

The parser itself is responsible only for syntactic decoding; semantic soundness is enforced by the Lean 4 proof‑gate.

---

## 2. EBNF Specification

The grammar accepted by both parsers is given below:

```ebnf
statement       = tensor_decl
                | operator_app
                | contractivity_assert ;

tensor_decl     = "tensor" identifier "[" prime_list "]" ";" ;
prime_list      = prime_atom { "," prime_atom } ;
prime_atom      = "p_" integer ;                (* e.g., p_2, p_3, p_5 *)

operator_app    = identifier "|>" [ "Λ_m" "*" ] prime_chain ";" ;
prime_chain     = prime_atom { "*" prime_atom } ;

contractivity_assert
                = "assert_contractive" "(" identifier ")" "<" float ";" ;

identifier      = letter { letter | digit | "_" } ;
float           = digit+ "." digit+ ;
integer         = digit+ ;
```

### Example program:

```text
tensor T_0 [p_2, p_3, p_5];
T_0 |> Λ_m * p_5 * p_7;
T_0 |> p_2 * p_3;
assert_contractive(T_0) < 0.85;
```

---

## 3. AST Reference

### Python (front‑end, `csc.py`)
```python
@dataclass(frozen=True)
class TensorDeclaration:
    identifier: str
    primes: List[str]

@dataclass(frozen=True)
class OperatorApplication:
    identifier: str
    has_lambda: bool
    prime_chain: List[str]

@dataclass(frozen=True)
class ContractivityAssertion:
    identifier: str
    bound: float
```

### Rust (core parser, `lib.rs`)
```rust
#[derive(Debug, Clone, PartialEq)]
pub enum Statement {
    TensorDeclaration {
        identifier: String,
        primes: Vec<String>,
    },
    OperatorApplication {
        identifier: String,
        has_lambda: bool,
        prime_chain: Vec<String>,
    },
    ContractivityAssertion {
        identifier: String,
        bound: f64,
    },
}
```

Both representations are structurally identical and can be serialised/deserialised for cross‑language verification.

---

## 4. API Usage

### Python
```python
from pirtm.csc import PIRTMDecoderParser

source = """
tensor T_0 [p_2, p_3, p_5];
T_0 |> Λ_m * p_5 * p_7;
assert_contractive(T_0) < 0.85;
"""

parser = PIRTMDecoderParser()
statements = parser.parse(source)
for stmt in statements:
    print(stmt)
```

### Rust
```rust
use pirtm_parser::parse_ebnf_statements;

let input = "tensor T_0 [p_2, p_3]; T_0 |> p_2 * p_3;";
let ast = parse_ebnf_statements(input).unwrap();
println!("{:?}", ast);
```

---

## 5. Project Structure

```text
pirtm/
├── csc.py                 # Python lexer + parser + tests
├── test_csc.py            # Python unit tests (5 cases)
└── README.md              # This file

packages/
└── rust/
    └── pirtm-parser/
        ├── Cargo.toml
        ├── src/
        │   ├── lib.rs     # Rust parser + tests
        │   └── ast.rs     # AST definition
        └── README.md      # Crate-specific documentation
```

---

## 6. Verification

### Python front‑end
```bash
python3 -m unittest pirtm/test_csc.py
```
*Expected output:* `Ran 5 tests ... OK`

### Rust core parser
```bash
cargo test --manifest-path packages/rust/pirtm-parser/Cargo.toml
```
*Expected output:* `21 passed; 0 failed`

### Combined verification
```bash
python3 -m unittest pirtm/test_csc.py && \
cargo test --manifest-path packages/rust/pirtm-parser/Cargo.toml
```

---

## 7. Soundness Anchors

The parser output is designed to be checked against Lean 4 proofs located in `PIRTM.lean`. These proofs establish:
1. **Convergence of PIRTM under repeated $\Lambda$-contraction.**
2. **Prime‑indexed ordering invariants before lever operations.**
3. **Genetic fidelity of transform operators.**

The Rust crate includes tests (`ast::tests::test_pirtm_lean_file_exists`, `test_pir_tm_convergence_proven_in_lean`, etc.) that verify the parser does not accept programs violating the formal gates. This ensures that only axiom‑clean PIRTM programs proceed to compilation.

---

## 8. License

MIT License. See `LICENSE` for details.
