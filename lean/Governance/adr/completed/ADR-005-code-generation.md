# ADR-005: Code Generation (LLVM/WASM)

**Status:** Accepted (2026-06-22)

## Context
The PIRTM compiler now produces pristine MLIR modules that encode cryptographic provenance. To close the final loop and produce runnable artifacts, we need to lower MLIR to LLVM IR and WebAssembly.

## Decision
We will use the existing `mlir-translate` tool to translate our MLIR modules to LLVM IR and WebAssembly.

## Consequences
The toolchain is now fully usable to produce runnable binaries. Cryptographic provenance remains attached as attributes in the MLIR.
