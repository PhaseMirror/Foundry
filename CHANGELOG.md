# Changelog

All notable changes to the Universal Atomic Calculator (UAC) Substrate and PIRTM language surface will be documented in this file.

## [1.1.0-transcendental] - 2026-07-12

### Added
- **Transcendental AST Nodes**: Introduced `Expr::Sin`, `Expr::Cos`, and `Expr::Log` to the core parser syntax (`crates/parser/src/ast.rs`).
- **Formal Contractivity Certificates**: Implemented `TranscendentalContractivity.lean` within the Lean 4 standard library, formally proving strict Lipschitz bounding for trigonometric operations (`sin`, `cos` ≤ 1) and bounded contractivity for `log`.
- **Tensor Boundaries**: Expanded `!pirtm.stratum` type signatures to natively support MLIR tensor definitions.
- **MLIR Intrinsic Lowering**: The backend `visitor.rs` now natively transpiles transcendentals for optimized compilation loops.
- **Telemetry Integration**: 
  - Instrumented `telemetry_transcendental.rs` for live WardMonitor drift validation (`ANOMALY_GOV_THRESHOLD`).
  - Python PWEH tests now execute 108-cycle dense tensor traces against transcendental nodes.
- **Interactive Playground**: Deployed an interactive, glassmorphism-styled WASM/LSP compiler environment in `playground/`.
- **Automated Deployments**: Shipped `.github/workflows/deploy-playground.yml` for automated GitHub Pages hosting.

### Changed
- **PIRTM Specification**: Updated `docs/PIRTM_SPEC.md` and `docs/MOC.md` to reflect the completed transcendental implementation and closed out the research-grade surface tasks defined in ADR-013.
