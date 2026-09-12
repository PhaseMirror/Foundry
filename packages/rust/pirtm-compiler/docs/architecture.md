# pirtm-compiler Architecture

## Overview

The `pirtm-compiler` is a Rust-based compiler front-end for the PIRTM/moc language targeting MLIR. It provides lexer, parser, AST → MLIR conversion, Lean 4 proof verification, and back-ends for LLVM and WebAssembly.

## Architecture Layers

```
┌─────────────────────────────────────┐
│           CLI (main.rs)              │
├─────────────────────────────────────┤
│        PhaseMirrorCompiler (lib.rs)   │
│     - compile(source) → MlirModule    │
│     - to_mlir(module) → String      │
├─────────────────────────────────────┤
│         Visitor Pattern               │
│   pirtm-mlir/transpiler/visitor.rs  │
│   - MlirEmitterVisitor               │
│   - visit_expression() → PirtmOp      │
├─────────────────────────────────────┤
│           MLIR Dialect                │
│    pirtm-mlir/dialect/ops.rs         │
│    - PirtmOp.emit_mlir()             │
└─────────────────────────────────────┘
```

## FFI Boundary

The Lean 4 FFI boundary (`src/lean_ffi.rs`) requires special care:

1. **Witness Preservation**: All Lean proof verifications must preserve `zero_spacings` array and witness data
2. **Banach Contraction**: `λ_p × L_p < 1.0` must hold for valid proofs
3. **Fail-Closed**: Failed proofs must return `Err`, never stub data

## Invariants

- **L0**: Every compilation produces an audit record
- **L1**: Parser accepts only valid PIRTM syntax
- **L2**: MLIR emission produces well-formed operations