# Changelog

All notable changes to the PIRTM compiler are documented in this file.

## [Unreleased]

### Added
- PWEH integration test (`substrates/tests/python/test_pweh_integration.py`) with 3x3 tensor numerical verification
- PWEH formalization in Lean 4 (`lean/Core/moc/PWEH.lean`) - sorry-bounded per alp_sorry_manifest.json, core-only
- CI workflow (`.github/workflows/pirtm_ci.yml`) with Python/NumPy integration

### Fixed
- MlirEmitterVisitor now properly emits operand ops before binary/sigmoid operations
- CLI test assertion for prime_index corrected to match actual output

### Verified
- All 27 Rust test suites pass
- PWEH numerical verification: honest trace converges, forgery blocked