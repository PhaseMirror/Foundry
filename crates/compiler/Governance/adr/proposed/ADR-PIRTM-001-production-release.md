# ADR-PIRTM-001: Production Release Plan for pirtm-compiler

## Status
Proposed

## Context

`pirtm-compiler` is the primary front-end for the PIRTM (Phase Invariant Runtime Type Machine) language, targeting MLIR emission with optional Lean 4 proof verification and WardMonitor drift detection. The project exists as a workspace with six sub-crates (`pirtm-parser`, `pirtm-lexer`, `pirtm-mlir`, `pirtm-monitor`, `pirtm-bench`, `ward-monitor`) and a functional CLI (`compile`, `prove`, `monitor`, `translate`).

However, the project is not in a releasable state:

- `src/lib.rs` is a 14-line placeholder (`pub fn add() -> i32 { 42 }`) — no public library API
- `tests/translate_integration.rs` is marked `@[ignore]` — the LLVM/WASM backend path is untested
- The `docs/` directory referenced in the README does not exist
- CI workflows reference `pirtm-compiler` test targets that may not exist or be incomplete
- No `CHANGELOG.md`, `CONTRIBUTING.md`, or release checklist exists
- The workspace member `pirtm-bench` and `ward-monitor` are unverified in CI
- No ADR governance artifacts exist for the compiler itself

This ADR defines the phased plan to bring `pirtm-compiler` to a production-ready `v1.0.0-ai` release, consistent with the governance and CI standards established by the Phase Mirror MCP integration.

## Decision

We will complete `pirtm-compiler` through a five-phase engineering plan, with each phase having executable acceptance criteria and CI gates. The plan prioritizes the core library API, then testing, documentation, CI/CD, and finally production hardening.

### Invariant 0: FFI Witness Preservation (L0 — Non-Negotiable)

The Lean 4 FFI boundary (`src/lean_ffi.rs` + `src/lean_wrapper.rs`) is the sole compute surface where untrusted external code can silently corrupt witness data. Any corruption propagates unchecked to every downstream consumer (`phase-mirror-mcp`, WORM storage, TripleLock).

**Four forbidden failure modes:**

| Failure Mode | Mechanism | Consequence |
|:-------------|:----------|:------------|
| Silent witness drop | `zero_spacings` array truncated or zeroed during C ABI marshalling | Emitted MLIR carries incomplete Lambda-Trace; downstream Banach check passes with stale data |
| Floating-point corruption | `λ_p` or `L_p` bit-flipped across FFI boundary | `λ_p × L_p` may silently cross `1.0` threshold without detection |
| Failed-proof propagation failure | Lean proof returns non-zero exit; wrapper returns stub `LambdaTrace` instead of `Err` | Invalid proof accepted as authoritative |
| Composite cert bypass | Lean term with composite `mod=` value passes verification | Violates `!pirtm.cert` prime-only invariant |

**Golden Trace (canonical `prime_108_core` proof round-trip):**

```
proof_name:    prime_108_core
lambda_p:      0.999999
l_p:           0.95
zero_spacings: [0.9549652277648129, 1.5563111057990717, 1.2289235832739145]
signature:     "SIGNED_HASH"
signer_pubkey: "ed25519:twin-prime-042"
proof_hash:    "LEAN_PROOF_HASH_108_CORE"
Banach product: 0.999999 × 0.95 = 0.94999905 < 1.0 ✓
```

Any deviation from these values on a successful `prime_108_core` proof is an L0 violation.

**Classification Matrix for FFI Violations:**

| Severity | Failure Mode | Response | Example |
|:---------|:-------------|:---------|:--------|
| **Critical (L0)** | Double-free, refcount underflow, witness truncation, composite cert | Immediate fail-closed; hard abort (exit 1); no partial `LambdaTrace` emitted | `LeanOwned` drop after refcount reaches 0 |
| **Benign (L3)** | Memory leak, drop-order anomaly, non-zero Lean exit with fallback hash | Compilation unit completes; structured dissonance report emitted; Agent-on-Exception + counterfeit detection | `ward-monitor` reports drift but compilation succeeds |

**Artefact Gates:**

| Artefact | Location | Gate |
|:---------|:---------|:-----|
| Source | `src/lean_ffi.rs`, `src/lean_wrapper.rs`, `pirtm-mlir/src/visitor.rs` | All FFI entry points must route through `validate_witness_preservation()` before MLIR emission |
| Test | `tests/test_lean_rc.rs` | Golden-trace fixture + error-injection paths + dissonance-report schema validation |
| CI | `.github/workflows/sedona_spine_ci.yml` | `pirtm_ffi_gate` job: builds with `--features lean-ffi`, runs expanded harness, blocks merge on bypass |
| ADR | This document | "FFI Witness Preservation" accepted by Governance before Phase 2 begins |
| CONTRACT | `CONTRACT.md` | Lean FFI boundary defined as L3 surface with explicit witness-handling requirements |

**Levers:**

| Lever | Owner | Metric | Horizon | Acceptance Test |
|:------|:------|:-------|:--------|:----------------|
| FFI witness preservation | PIRTM compiler maintainer | 100% of Lean proof round-trips preserve `zero_spacings` array length and `λ_p × L_p < 1.0` | 7 days | `tests/test_lean_rc.rs` golden-trace comparison: FFI output matches canonical values within machine epsilon |
| Proof failure propagation | Governance | 100% of failed/invalid proofs return `Err`, never a stub `LambdaTrace` | 14 days | CI matrix: valid proof → `Ok` with witness; invalid proof → `Err` with diagnostic code; missing Lean binary → `Err` with `LEAN_NOT_FOUND` |
| Prime-only cert invariant | PIRTM compiler maintainer | Zero composite certs emitted | 7 days | Property test: every `pirtm.cert` value in emitted MLIR passes Miller-Rabin primality test |
| Supply-chain integrity | DevOps | All vendored crates pinned; Flatpak signature valid | 21 days | `cargo metadata --locked` produces deterministic graph; Flatpak bundle signature verified |

### Phase 1: Core Library Completion (Week 1-2)

**Goal:** Replace the placeholder `lib.rs` with a production-grade public API that wires the workspace crates together.

| Task | Deliverable | Acceptance Criteria |
|------|-------------|---------------------|
| Rewrite `src/lib.rs` | Public `PhaseMirrorCompiler` struct with `compile()`, `prove()`, `translate()` methods | `cargo doc --no-deps` generates clean API docs; `pritm-compiler` usable as a library |
| Wire `pirtm-parser` → `pirtm-mlir` pipeline | `compile()` returns `Result<MlirModule, CompileError>` | Round-trip: source → AST → MLIR → LLVM IR produces valid output |
| Implement `CompileError` enum | Typed error hierarchy with `thiserror` | All error paths produce machine-readable diagnostics |
| Un-ignore `tests/translate_integration.rs` | Full LLVM/WASM backend integration test | Test passes on CI with no `#[ignore]` |

**Blocking:** No further phases begin until `cargo test -p pirtm-compiler` passes 100%.

### Phase 2: Testing & Verification (Week 3-4)

**Goal:** Achieve comprehensive test coverage and formal verification hooks.

| Task | Deliverable | Acceptance Criteria |
|------|-------------|---------------------|
| Unit tests for `lib.rs` public API | `tests/lib_api.rs` | Every public method has positive, boundary, and failure tests |
| Property-based tests for parser | `tests/property_tests.rs` using `proptest` | Round-trip property: parse → emit → re-parse yields equivalent AST |
| Lean proof verification test matrix | `tests/lean_proof.rs` expanded | Tests cover valid proof, invalid proof, missing Lean binary, timeout |
| WardMonitor integration test | `tests/monitor_integration.rs` | Daemon starts, detects injected drift, emits structured report |
| CI test gate | `sedona_spine_ci.yml` includes `pirtm-compiler` job | CI fails on any test regression |
| Benchmark suite | `pirtm-bench/` with `criterion` | Baseline numbers captured for compile, prove, translate |

**Blocking:** 80% line coverage minimum; all benchmarks green.

### Phase 3: Documentation (Week 5)

**Goal:** Create the missing documentation infrastructure.

| Task | Deliverable | Acceptance Criteria |
|------|-------------|---------------------|
| Create `docs/` directory | `docs/architecture.md`, `docs/language-reference.md`, `docs/mlir-dialect.md` | Each doc has at least 3 concrete code examples |
| Update `README.md` | Accurate project overview, build instructions, usage examples | READOME matches actual CLI output and library API |
| Create `CONTRIBUTING.md` | Build, test, lint, commit conventions | New contributors can build and test in < 15 minutes |
| Create `CHANGELOG.md` | Keep a Changelog format, seeded with v0.1.0 entries | All workspace crates have documented versions |
| ADR governance | `Governance/adr/proposed/ADR-PIRTM-001.md` (this document) | Accepted by Governance before Phase 4 |

### Phase 4: CI/CD & Release Pipeline (Week 6)

**Goal:** Automated build, test, and release pipeline.

| Task | Deliverable | Acceptance Criteria |
|------|-------------|---------------------|
| Workspace-wide CI | `.github/workflows/pirtm_ci.yml` | Builds all 8 workspace crates, runs all tests |
| Lint gate | `clippy` + `rustfmt` check in CI | CI fails on warnings or format deviations |
| Cross-compilation | Build for `x86_64-unknown-linux-gnu`, `aarch64-apple-darwin`, `x86_64-pc-windows-msvc` | All three targets produce working binaries |
| Release automation | `.github/workflows/release.yml` | Tag push creates GitHub Release with binaries |
| Flatpak manifest | `com.multiplicity.pirtm-compiler.yml` | Builds in Flatpak sandbox with all dependencies |
| Semantic versioning | `Cargo.toml` version fields aligned across workspace | `cargo metadata` shows consistent versions |

### Phase 5: Production Hardening (Week 7-8)

**Goal:** Security, performance, and operational readiness.

| Task | Deliverable | Acceptance Criteria |
|------|-------------|---------------------|
| Security audit | `SECURITY.md` updated, `SECURITY_ADVISORIES.md` seeded | No high-severity findings; medium findings have mitigations |
| Error message quality | All user-facing errors have codes and suggestions | Error codes documented in `docs/errors.md` |
| Performance regression suite | `pirtm-bench/` with CI comparison | PRs that regress performance > 5% are blocked |
| Fuzzing harness | `fuzz/` directory with `cargo-fuzz` | 24-hour fuzz run with no crashes |
| Stability ownership | `STABILITY_OWNERSHIP.md` per crate | Each workspace member has a named owner |
| Release rehearsal | Full dry-run of release checklist | All steps complete in < 30 minutes on clean checkout |

## Dependencies

- **ADR-MCP-001**: MCP Native Boundaries (protocol shell, not policy authority)
- **ADR-MCP-002**: Governed MCP Tool Registry (dynamic server discovery)
- **ADR-WIT-001**: Unified Witness Requirement (complete witness for every externally visible action)
- **Phase Mirror MCP integration**: The CLI `compile` command must be callable as an MCP tool via `phase-mirror-mcp`
- **WardMonitor**: The `monitor` subcommand depends on the `ward-monitor` crate being production-ready

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Lean 4 FFI instability | Medium | High | Abstract Lean calls behind `LeanBackend` trait; provide stub implementation for non-Lean builds |
| MLIR C++ API churn | Medium | Medium | Pin `mlir-sys` to tested version; add compatibility CI matrix |
| Parser grammar incompleteness | High | Medium | Add fuzzing in Phase 5; document known limitations |
| Workspace build order fragility | Low | Low | Verify `cargo workspace` build order in CI before each phase |
| Performance regressions during hardening | Medium | Low | Benchmark suite in Phase 2 catches regressions early |

## Consequences

- `pritm-compiler` becomes the canonical compiler for the PIRTM language, callable as a CLI, library, MCP tool, and Flatpak app.
- The workspace structure (`pirtm-parser`, `pirtm-mlir`, etc.) becomes stable and versioned independently.
- Documentation coverage enables community contribution without burst onboarding cost.
- CI/CD pipeline enforces the same Sedona Spine governance contract as `phase-mirror-mcp`.
