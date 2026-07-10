# Position-Aware Recursive Multiplicity (PARM)

The PARM Engine is a framework for analyzing linguistic patterns—specifically Hebrew textual data—using principles of prime-number recurrence and resonance.

## Project Structure

This project has evolved into a multi-layered architecture:

### 1. Prototype Layer (Python)
- **Purpose**: Rapid prototyping, initial algorithm exploration, and visualization.
- **Location**: Root directory (`parm.py`, `analyze_*.py`, etc.)
- **Status**: Legacy/Prototyping. Contains the initial research code.

### 2. Core Library & Analysis Layer (Rust)
- **Purpose**: High-performance analysis, corpus processing, and robust production-ready tools.
- **Location**: `parm-rs/`
- **Features**:
  - Parity-verified implementation of the core `sealed_state` and RQ algorithms.
  - Efficient XML lexicon parsing (`BDB`, `Strong`).
  - Corpus-scale frequency analysis with Zipfian simulation.
- **Status**: Production/Active.

### 3. Formal Verification Layer (Lean 4)
- **Purpose**: Formal mathematical verification of the core recurrence algorithms to ensure correctness.
- **Location**: `lean4-parm/`
- **Status**: Verified/Core logic formalized.

## Getting Started

### Rust Analysis Tool
```bash
cd parm-rs
cargo test
# The library provides analysis modules for corpus processing.
```

### Lean 4 Formalization
```bash
cd lean4-parm
lake build
lake env lean Parm/Core.lean
```

## Documentation
- `docs/RUST_PORT_PLAN.md`: Migration strategy.
- `docs/adr/`: Architectural Decision Records regarding the core mathematics and integration.
- `METHODS.md`: Foundational methodology.
