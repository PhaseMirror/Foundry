# Ξ∞/CSL Automorphic Learning

A formal specification with certificates, preregistration, and reference code for automorphic learning with prime-structured inductive bias.

## Overview

This framework provides:

1. **Finite group actions** (AGL(1,p)) on token indices
2. **Additive masking** with Legendre/CRT embeddings
3. **Permutation-equivariant unitarization** (exp/Cayley paths)
4. **Sato-Tate spectral proxy** with BCa bootstrap CIs
5. **ACE weighted-ℓ₁ projection** with KKT certificates
6. **Preregistration schema** with linter and pass/fail gates

## Project Structure

```
AUTOMORPHIC_LEARNING/
├── automorphic-core/        # Rust core library
│   ├── src/
│   │   ├── group.rs         # AGL(1,p) actions, CRT embeddings, Legendre symbol
│   │   ├── mask.rs          # Residue masks, additive logits, ε-Sinkhorn
│   │   ├── unitary.rs       # exp/Cayley unitarization
│   │   ├── spectral.rs      # Eigen-phase extraction, Sato-Tate comparison
│   │   ├── projection.rs    # Weighted-ℓ₁ projection, KKT certificates
│   │   ├── cert.rs          # SoftmaxUB, SlopeUB, unitarity residual
│   │   └── prequal.rs       # Preregistration schema, linter, gates
│   └── tests/
├── automorphic-lean/        # Lean 4 formalization
├── automorphic-py/          # Python package
│   └── automorphic/
│       ├── group.py
│       ├── mask.py
│       ├── unitary.py
│       ├── spectral.py
│       └── projection.py
├── automorphic-ci/          # CI scripts
├── docs/
│   └── templateArxiv.tex    # Mathematical specification
├── references.bib           # Bibliography
├── formalization.lean       # Lean placeholder
└── lakefile.lean
```

## Quick Start

### Rust

```bash
cd automorphic-core
cargo build --release
cargo test
```

### Python

```bash
cd automorphic-py
pip install -e ".[dev]"
pytest tests/
```

### CI

```bash
cd automorphic-ci/scripts
bash validate.sh
```

## Mathematical Specification

See `docs/templateArxiv.tex` for the full mathematical specification including:

- AGL(1,p) group actions and CRT embeddings
- Additive masking semantics
- Permutation-equivariant unitarization
- Sato-Tate spectral proxy
- ACE projection with KKT certificates
- Preregistration schema and pass/fail gates

## Key Results

- **Projection**: Weighted-ℓ₁ projection with KKT certificates and dual gap
- **Unitarity**: Permutation-equivariant unitarization with spectral diagnostics
- **Safety**: ACE projection enforces Lipschitz bounds via SlopeUB
- **Reproducibility**: Preregistration schema with automated linting

## License

MIT
