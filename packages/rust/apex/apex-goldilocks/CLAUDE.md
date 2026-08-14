# Claude Development Guide: Apex-Goldilocks

## Build and Test Commands
- **Rust (Workspace)**: `cargo build --workspace`
- **Rust (Test)**: `cargo test --workspace`
- **CLI Execution**: `cargo run -p apex-goldilocks-cli -- <COMMAND>`
- **Frontend (Install)**: `npm install`
- **Frontend (Build)**: `npm run build`
- **Frontend (Dev)**: `npm run dev`
- **Stack Validation**: `bash scripts/validate_stack.sh`

## Code Style & Mandates
- **Zero Floats**: Never use `f32` or `f64` in `crates/`. Use `goldilocks::GoldilocksField` or `apex_pikernel::Rational`.
- **Idiomatic Rust**: Prefer `ndarray` views, pattern matching, and trait-based polymorphism.
- **Standalone Readiness**: Ensure all dependencies are Internalized in `crates/` and mapped via `workspace.dependencies`.
- **Certification**: All dynamical updates must generate SlopeUB/GapLB certificates.

## Architecture Mapping
- **Spine**: `crates/apex-goldilocks-core` (Lattice), `crates/pirtm-compiler` (Governance).
- **Kernels**: `packages/apex/apex-pikernel` (Projection/ACE).
- **Runtime**: `crates/multiplicity-runtime` (EchoBraid/Harness).
- **Interface**: `src/` (Stability Dashboard / PIRTM Validator).

## Common Tasks
- **Audit Lattice**: `cargo run -p apex-goldilocks-cli -- audit-lattice`
- **Parameter Sweep**: `cargo run -p apex-goldilocks-cli -- sweep-pikernel`
- **Validate PIRTM**: `cargo run -p apex-goldilocks-cli -- validate-pirtm --source <PATH>`
