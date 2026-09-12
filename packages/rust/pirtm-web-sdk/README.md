# PIRTM Web SDK (`pirtm-web-sdk`)

The **PIRTM Web SDK** is the governed, certified compilation pipeline for compiling PIRTM-compliant Lean 4 proofs and compute logic into WebAssembly (WASM). It provides the core Web Components needed to integrate the Sedona Spine into browser environments.

## 🏗️ Architecture

This crate acts as a Rust-native wrapper over the underlying Lean 4 WebAssembly compilation toolchain (via `lake` and `emcc`). It seamlessly bridges the standard `cargo` ecosystem with the formal Lean proofs, outputting production-ready WASM artifacts.

## 🚀 Usage

You can use the Rust CLI to build the WASM components.

### Build Web Components
```bash
cargo run --bin pirtm-web -- build --target web
```
This will compile the `Lean2Wasm.lean` environment into WASM, outputting the artifacts in `.lake/build/wasm/`.

### Run via Node (Testing)
```bash
cargo run --bin pirtm-web -- run
```

## ⚖️ Governance & Compliance

As part of the **Sedona Spine Mandate**, this SDK is the *only* authorized path for exporting verifiable ESI retention logic to the web. The compilation process enforces that all exported components maintain full fidelity with the underlying Lean 4 axioms.

- **Prerequisites:** `emcc` (Emscripten) and a working `lake` (Lean 4) toolchain must be in your `PATH`.
