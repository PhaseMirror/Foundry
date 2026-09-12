# ADR-PIRTM-002: Production Readiness Checklist for pirtm-compiler

## Status
Accepted (Phase 1 Complete)

## Context
pirtm-compiler currently has working lexer/parser/MLIR emission but lacks production-grade infrastructure. This ADR provides a concrete, executable checklist to achieve v1.0.0-ai release readiness.

## Current State Assessment

| Component | Status | Risk Level |
|-----------|--------|------------|
| `src/lib.rs` | ✅ Implemented (139 lines) | Complete |
| `tests/translate_integration.rs` | `#[ignore]` - LLVM backend untested | **Critical** |
| `pirtm-mlir/build.rs` | Hardcoded LLVM 15 path | **High** - Build portability |
| `pirtm-parser/src/pirtm.pest` | Minimal grammar (unused) | **Medium** - Parser completeness |
| No `docs/` directory | Missing | **Medium** |
| No `.github/workflows/pirtm_ci.yml` | Missing | **High** - CI/CD |
| No `CHANGELOG.md` | Missing | **Low** |
| No `CONTRIBUTING.md` | Missing | **Low** |

## Completed (Phase 1)

- Created `src/lib.rs` with `PhaseMirrorCompiler` struct
  - `compile(source: &str) -> Result<MlirModule, CompileError>` ✅
  - `to_mlir(module) -> Result<String, CompileError>` ✅
- Created `src/error.rs` with typed error hierarchy using `thiserror` ✅
- Created `antigrav-audit` stub crate ✅
- Fixed `pirtm-mlir` to work without MLIR libraries (stub mode) ✅

## Decision: Production Readiness Implementation Plan

### Phase 2: Testing & Integration (Days 4-7)

**Goal:** 100% test coverage for core paths, FFI gate validation.

**Tasks:**
1. Update `tests/translate_integration.rs` - remove `#[ignore]`, add skip-on-missing-mlir flag
2. Create `tests/lib_api.rs` - unit tests for public API methods
3. Ensure golden-trace fixture coverage in `tests/test_lean_rc.rs` ✅ (validated)

**Acceptance Criteria:**
- `cargo test -p pirtm-compiler` passes without `[ignore]`
- All FFI entry points preserve witness data (verifiable via test harness)

### Phase 3: Build System & CI/CD (Days 8-10)

**Goal:** Reproducible builds across platforms, automated CI.

**Tasks:**
1. Create `.github/workflows/pirtm_ci.yml`:
   - Build matrix: `x86_64-unknown-linux-gnu`, `aarch64-apple-darwin`, `x86_64-pc-windows-msvc`
   - Lint gate: `cargo clippy -- -D warnings`
   - Test gate: `cargo test --all-features`
2. Update `pirtm-mlir/build.rs` to detect LLVM version dynamically
3. Add version consistency check across workspace crates

**Acceptance Criteria:**
- CI passes on all 3 target platforms
- `cargo clippy` produces zero warnings

### Phase 4: Documentation (Days 11-12)

**Goal:** Complete documentation for contributors and users.

**Tasks:**
1. Create `docs/` directory with:
   - `architecture.md` - MLIR dialect design, FFI boundaries
   - `language-reference.md` - PIRTM language syntax, semantics
   - `api.md` - Library usage examples
2. Create `CONTRIBUTING.md` - build/test/lint/commit conventions
3. Create `CHANGELOG.md` - Keep a Changelog format, v0.1.0 entries
4. Update `README.md` - accurate CLI usage, library examples

**Acceptance Criteria:**
- `cargo doc --no-deps` links to all documentation
- New contributor can build/test in < 15 minutes

### Phase 5: Security Hardening (Days 13-14)

**Goal:** Production security and stability verification.

**Tasks:**
1. Update `SECURITY.md` - threat model, FFI boundary analysis, mitigations
2. Create `STABILITY_OWNERSHIP.md` - per-crate owners
3. Add performance regression check in CI (benchmark comparison)
4. Create `.github/workflows/release.yml` - tag triggers release with binaries

**Acceptance Criteria:**
- `cargo audit` produces zero high-severity findings
- Release checklist dry-run completes in < 30 minutes

## FFI Guard Requirements (L0 Invariant)

The Lean FFI boundary requires special handling for production release:

| Failure Mode | Mitigation | Code Location |
|--------------|------------|---------------|
| Silent witness drop | Validate `zero_spacings` array length on return | `lean_wrapper.rs:verify_proof()` |
| Floating-point corruption | Compare `λ_p × L_p` against precomputed threshold | `lean_wrapper.rs:compute_banach_product()` |
| Failed-proof propagation | Return `Err` on non-zero Lean exit, never stub `LambdaTrace` | `lean_wrapper.rs:verify_proof()` |
| Composite cert bypass | Miller-Rabin primality test on `pirtm.cert` values | `visitor.rs:emit_program()` |

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| MLIR dependency churn | Medium | High | Pin `mlir-sys` to tested version, add compatibility CI matrix |
| Lean 4 FFI instability | Medium | High | Abstract behind `LeanBackend` trait, stub for non-Lean builds |
| Parser grammar incompleteness | High | Medium | Add fuzzing in Phase 5, document known limitations |
| Workspace build fragility | Low | Low | Verify build order in CI before each phase |

## Dependencies

- MLIR 15.x (via `mlir-sys`) - stubbed for non-MLIR environments
- Lean 4 (optional) - required for proof verification
- `antigrav-audit` - stub created

## Consequences

- `pirtm-compiler` becomes callable as library, CLI, and eventually MCP tool
- All workspace crates achieve stable API with version alignment
- Documentation enables community contribution without onboarding friction

## Done (Phase 1)

- ✅ `src/lib.rs` with `PhaseMirrorCompiler` struct
- ✅ `src/error.rs` with typed error hierarchy
- ✅ `antigrav-audit` stub crate created
- ✅ All tests passing: 3/3 in lib, 6/6 in pirtm-mlir