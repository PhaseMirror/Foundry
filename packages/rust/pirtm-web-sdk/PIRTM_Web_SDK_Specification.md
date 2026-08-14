# PIRTM Web SDK Specification

## Purpose
The `pirtm-web-sdk` crate operates within the PhaseSpace orchestration engine to provide a Cargo-native wrapper for compiling PIRTM-compliant Lean 4 proofs and logic into WebAssembly (WASM). It allows developers to generate Web Components for integration into browser applications.

## Architecture
- **Wrapper API:** Rust `clap` CLI (`pirtm-web`) exposes standard cargo run targets (`build`, `run`).
- **Internal Execution:** Seamlessly dispatches build commands to `lake` and `emcc`.
- **Target Location:** Outputs to `.lake/build/wasm/main.js`.

## Invariants
- Must adhere to root execution boundaries.
- Must ensure that only canonical Lean 4 logic is used to derive the generated WebAssembly logic, upholding the Sedona Spine Mandate.
