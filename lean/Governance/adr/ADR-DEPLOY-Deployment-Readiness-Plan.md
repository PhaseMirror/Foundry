# ADR-DEPLOY: PIRTM Compute Language Deployment Readiness Plan

**Status:** Proposed
**Date:** 2026-06-29
**Author:** PhaseSpace Commander Coding Agent
**Horizon:** 30 days to first production binary, 90 days to zero-drift rollout

---

## 1. Context & Tension

The PIRTM compute language has a mathematically sealed substrate (F1Square Lean 4 proofs, Sedona Spine governance, L0 invariants) and a rich ADR corpus (60+ accepted/proposed decisions). However, the path from verified source to production-deployable artifact contains critical gaps:

- **No reproducible build environment exists**: ADR-001 mandates LLVM 15 hermetic prefix, but CI does not enforce it. The Docker images ship LLVM 11.
- **No release artifacts**: The workspace produces no binary targets. There is no `v1.0.0` tag, no published container, no artifact registry linkage.
- **CI provenance is aspirational**: ADR-011 describes checksum enforcement and `/compliance/manifest.json`, but neither file nor workflow exists.
- **Governance gaps in CI**: The `sedona_spine_ci.yml` only performs grep-level checks (file existence, sorry-free, Mathlib imports) rather than running the actual proofs.
- **Workspace fragmentation**: The `commander-core`, `commander-cli`, `alp`, `sigma`, and `mcp` crates described in AGENTS.md and ADR-ALP-001 are not unified in the root `Cargo.toml`.
- **Phase 3 MCP ecosystem is at 25%**: Only Steps 1-2 are DONE; Steps 3-8 (tool registry, multi-server routing, Python ALP proxy, HTTP/SSE transport, GitHub adapter, sandboxed scripts) are OPEN.
- **Mock cryptographic primitives**: `nl_to_pirtm.py` uses SHA256 with a `POSEIDON:` prefix instead of a real Poseidon hash.
- **Zero-drift rollout at 0%**: Phase 7 (the actual production go-live) has no progress recorded. Mock paths remain active.
- **NEXT_STEPS.md is absent**: The Phase 3 sequencing document referenced in AGENTS.md does not exist.

The tension is between **mathematical completeness** (the proofs are solid) and **operational incompleteness** (no one can deploy this system in production today).

---

## 2. Decision

We will execute a structured, gate-ordered deployment readiness program with four workstreams:

1. **Build Pipeline Closure** — Seal the LLVM 15 prefix, integrate into CI, produce reproducible release artifacts
2. **CI Provenance Activation** — Implement ADR-011's manifest-anchored pipeline with checksum enforcement
3. **Workspace Unification** — Integrate the `commander-*` and `alp`/`sigma`/`mcp` crates into the root workspace
4. **Zero-Drift Activation** — Complete Phase 3 Steps 3-8, replace mock crypto, activate Phase 7

Each workstream has explicit acceptance criteria, owners, and blocking conditions.

---

## 3. Current State Assessment

### 3.1 Existing Strengths

| Component | State | Evidence |
|-----------|-------|----------|
| F1Square formal substrate | Complete (v0.20.0) | `substrates/lean/MOC/PIRTM.lean` — Theorem 2, 3 proved |
| Sedona Spine CI gate | Functional | `.github/workflows/sedona_spine_ci.yml` runs axiom-clean checks |
| Governance ADRs | Comprehensive | 60+ ADRs covering ALP, Sigma, MCP, CI provenance, fail-closed |
| Deployment audit | Locked | `Governance/audit/DEPLOYMENT_AUDIT_v1.0.0.md` — PASSED/LOCKED 2026-06-14 |
| Rust test suite | 27+ tests | `pirtm-rs`, `pirtm-parser`, `pirtm-candle`, `pirtm-mlir` |
| Python numerical harness | Functional | `test_pirtm_convergence.py`, `test_pweh_integration.py` |

### 3.2 Blocking Gaps

| Gap | Severity | Constraint |
|-----|----------|------------|
| No LLVM 15 prefix in CI | **Critical** | Blocks all MLIR compilation |
| No artifact registry linkage | **Critical** | No deployable output |
| CI provenance workflow missing | **High** | ADR-011 unimplemented |
| Workspace fragmentation | **High** | Multi-crate build is manual |
| Docker LLVM 11 vs 15 | **High** | Container runtime mismatch |
| Mock Poseidon hash | **Medium** | Cryptographic audit gap |
| Phase 7 zero-drift at 0% | **Medium** | Production go-live blocked |
| NEXT_STEPS.md absent | **Medium** | Phase 3 sequencing undefined |
| Root user in containers | **Medium** | Security posture |
| Empty ADR files (10 files) | **Low** | Documentation debt |

---

## 4. Workstream 1: Build Pipeline Closure

**Owner:** Substrates / DevOps Lead
**Blocking condition:** No release binary can be produced until this workstream passes its acceptance criteria.

### 4.1 LLVM 15 Prefix Seal

**Action:** Create the hermetic LLVM 15 prefix as defined in ADR-001.

```bash
# Create canonical prefix path
mkdir -p /opt/llvm-15-prefix
# Build or download LLVM 15 with MLIR enabled
# Verify: llvm-config --version reports 15.x
```

**Acceptance criteria:**
- `llvm-config --version` returns a `15.x.y` string
- `mlir-opt --version` reports MLIR built from LLVM 15
- The prefix path is committed to `.ci/llvm15_prefix` in the repository
- A wrapper script `scripts/llvm15-config` exports `MLIR_SYS_150_PREFIX` and `LLVM_CONFIG_PATH`

### 4.2 Rust Toolchain Pinning

**Action:** Add `rust-toolchain.toml` to the workspace root.

```toml
[toolchain]
channel = "1.85.0"
components = ["rustfmt", "clippy"]
profile = "minimal"
```

**Acceptance criteria:**
- `rustup show` reports toolchain 1.85.0 on fresh checkout
- `cargo --version` and `rustc --version` are deterministically pinned

### 4.3 CI Integration

**Action:** Update `.github/workflows/pirtm_ci.yml` to:
1. Use `dtolnay/rust-toolchain@stable` with `toolchain: 1.85.0`
2. Install LLVM 15 via the sealed prefix
3. Set `MLIR_SYS_150_PREFIX` before `cargo build`
4. Verify `llvm-config --version` == 15.x in CI

**Action:** Update `.github/workflows/sedona_spine_ci.yml` to actually run Lean proofs via `lake build` rather than grep-only checks.

**Acceptance criteria:**
- CI passes on a fresh `ubuntu-latest` runner with no pre-installed LLVM
- `lake build F1Square` runs and produces `.olean` files
- No `sorry` or `native_decide` in CI output
- Build logs include LLVM version stamp

### 4.4 Binary Crate Definitions

**Action:** Add `[[bin]]` targets to workspace crates that need executables.

```toml
# In crates/compiler/Cargo.toml
[[bin]]
name = "pirtm"
path = "src/main.rs"
```

**Acceptance criteria:**
- `cargo build --release --bin pirtm` produces a working binary
- `./target/release/pirtm --help` outputs usage information
- Binary is statically linked (musl target) for portability

### 4.5 Release Profile Optimization

**Action:** Add release profile tuning to root `Cargo.toml`.

```toml
[profile.release]
lto = true
codegen-units = 1
strip = true
panic = "abort"
```

---

## 5. Workstream 2: CI Provenance Activation

**Owner:** Examiner / Substrates
**Blocking condition:** ADR-011 requires this before any production merge.

### 5.1 Compliance Manifest

**Action:** Create `/compliance/manifest.json` with SHA-256 hashes for all release artifacts.

```json
{
  "version": "1.0.0",
  "build_timestamp": "<ISO-8601>",
  "artifacts": {
    "pirtm": "<sha256-hex>",
    "libpirtm_core.rlib": "<sha256-hex>",
    "libpirtm_parser.rlib": "<sha256-hex>"
  },
  "toolchain": {
    "rust": "1.85.0",
    "llvm": "15.x.y"
  },
  "lean_proofs": {
    "PIRTM.olean": "<sha256-hex>",
    "PWEH.olean": "<sha256-hex>"
  }
}
```

**Action:** Create `.github/workflows/verify.yml` (per ADR-011):
1. Build target codebase
2. Calculate artifact SHA-256 hashes
3. Compare against `/compliance/manifest.json`
4. Fail build on hash mismatch
5. Run Dual-Prover SNARK harness (when arkworks integration is ready)

**Acceptance criteria:**
- `verify.yml` passes on tagged releases
- Any artifact modification causes CI failure
- Manifest is committed atomically with the matching tag

### 5.2 Dependency Scanning

**Action:** Add `cargo-deny` and `cargo-audit` to CI.

```yaml
- name: cargo-deny check
  run: cargo deny check
- name: cargo-audit
  run: cargo audit
```

**Acceptance criteria:**
- CI fails on any advisory with severity >= medium
- CI fails on unapproved licenses
- `cargo-deny` configuration committed to `deny.toml`

### 5.3 Container Image Provenance

**Action:** Update Dockerfiles to LLVM 15, non-root user, and add image signing.

**Action:** Update `.github/workflows/publish-images.yml`:
1. Build multi-arch images (amd64, arm64)
2. Run Trivy vulnerability scan
3. Sign with sigstore/cosign
4. Push to registry with provenance attestation

**Acceptance criteria:**
- Docker images report LLVM 15 at runtime
- Containers run as non-root `appuser`
- Images pass Trivy with 0 critical/high vulnerabilities
- cosign signature verifiable

---

## 6. Workstream 3: Workspace Unification

**Owner:** Compiler Engineering
**Blocking condition:** Multi-crate builds must be reproducible before CI provenance can be trusted.

### 6.1 Identify Missing Crates

The following crates are described in AGENTS.md but not present in the root `Cargo.toml` workspace:

| Crate | Expected Path | Current Location |
|-------|--------------|------------------|
| `commander-core` | `crates/commander-core/` | Unknown / not in workspace |
| `commander-cli` | `crates/commander-cli/` | Unknown / not in workspace |
| `alp` | `crates/alp/` | Unknown / not in workspace |
| `sigma` | `crates/sigma/` | Unknown / not in workspace |
| `mcp` | `crates/mcp/` | Unknown / not in workspace |

**Action:** Audit the repository for these crates. If they exist in subdirectories (`ensembles/`, `projects/`), document the build strategy. If they do not exist, implement minimal scaffold crates that satisfy ADR-ALP-001 and ADR-MCP-001 interfaces.

**Acceptance criteria:**
- All governance-layer crates are discoverable via `cargo metadata`
- `cargo build --workspace` produces no errors
- ADR-ALP-001 and ADR-MCP-001 verification tests compile and pass

### 6.2 Root Cargo.toml Update

**Action:** Add missing crates to root workspace `members` array.

```toml
[workspace]
members = [
    "crates/core",
    "crates/mlir",
    "crates/parser",
    "crates/compiler",
    "crates/monitor",
    "crates/lexer",
    "crates/telemetry-recorder",
    "crates/benchmarks",
    "crates/commander-core",
    "crates/commander-cli",
    "crates/alp",
    "crates/sigma",
    "crates/mcp",
]
```

---

## 7. Workstream 4: Zero-Drift Activation

**Owner:** Operations / Core Math
**Blocking condition:** Phase 7 production go-live is gated on completion of Phase 3 Steps 3-8.

### 7.1 Complete Phase 3 MCP Ecosystem (Steps 3-8)

Per AGENTS.md Phase 3 Roadmap:

| Step | Task | ADR Reference | Status Target |
|------|------|---------------|---------------|
| 3 | MCP tool descriptor registry | ADR-MCP-002 | DONE within 7 days |
| 4 | Multi-server MCP routing | ADR-MCP-002 Amendment | DONE within 14 days |
| 5 | Python MCP ALP proxy | ADR-MCP-003 | DONE within 14 days |
| 6 | HTTP/SSE transport layer | ADR-MCP-004 | DONE within 21 days |
| 7 | GitHub MCP adapter | ADR-MCP-005 | DONE within 21 days |
| 8 | Sandboxed external scripts | New: ADR-MCP-006 | DONE within 30 days |

**Acceptance criteria per step:**
- Step 3: `pscmd mcp list` shows servers as `VERIFIED` or `INSECURE`; `pscmd mcp attest <id>` works
- Step 4: Workflow YAML with `server_binding` passes ALP; missing `server_binding` is rejected
- Step 5: All Python MCP tool calls return a Rust-issued SAT token; ALP-unreachable calls are rejected
- Step 6: `pscmd mcp serve --transport http` accepts JSON-RPC over HTTP with SSE log channel
- Step 7: GitHub tool calls route through ALP gate with GitHub identity mapping
- Step 8: External scripts run in seccomp-bpf sandbox with no access to governed state

### 7.2 Replace Mock Cryptographic Primitives

**Action:** Replace the mock Poseidon hash in `scripts/nl_to_pirtm.py` (`substrates/tests/python/`) with a real Poseidon implementation or remove the mock entirely until a Rust-native implementation is available.

**Action:** Ensure all `verify.yml` and CI checks use real cryptographic hashes, not truncated/mocked values.

**Acceptance criteria:**
- No file in the repository contains the string `"POSEIDON:"` prefixing a SHA-256 hash
- Poseidon implementation passes test vectors against known values
- If implementation is deferred, the mock is gated behind a `MOCK_POSEIDON` feature flag with documentation

### 7.3 NEXT_STEPS.md

**Action:** Create `NEXT_STEPS.md` at the repository root with Phase 3 step owners, metrics, and blocking conditions. Reference the ADR-AGI-001 through ADR-AGI-005 gate sequence from AGENTS.md.

**Acceptance criteria:**
- File exists and is non-empty
- Each Phase 3 step has an owner, metric, and horizon date
- ADR-AGI gate sequence is documented with pass conditions

### 7.4 Zero-Drift Policy Activation (Phase 7)

**Action:** Disable all mock paths in the codebase.

**Action:** Activate hard veto: any transition without a `UnifiedWitness` is strictly rejected.

**Action:** Remove deprecated branch references (ECP, etc.) from production binaries and logs.

**Acceptance criteria:**
- No `MOCK_POSEIDON` or equivalent feature flags enabled in release profile
- `kill_switch.py` trigger test passes in CI (per L0 invariant 9)
- `governance/ledger.json` contains all four required fields (`quorum_threshold`, `rollback_ref`, `review_cadence_days`, `audit_trigger`)

---

## 8. Acceptance Criteria Summary

The deployment readiness program is complete when ALL of the following are true:

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | `cargo build --release` passes on fresh checkout with LLVM 15 | CI green on PR |
| 2 | `lake build F1Square` produces axiom-clean `.olean` files | CI green on PR |
| 3 | `/compliance/manifest.json` exists with correct hashes | CI verify.yml passes |
| 4 | Binary targets defined and buildable | `cargo build --release --bin pirtm` |
| 5 | All Phase 3 Steps 3-8 have passing tests | Test suite green |
| 6 | No mock Poseidon hashes in committed code | `rg "POSEIDON:"` returns empty |
| 7 | `NEXT_STEPS.md` exists with Phase 3 gate sequence | File non-empty |
| 8 | Docker images use LLVM 15, non-root user | `docker run --rm <image> llvm-config --version` |
| 9 | `cargo-deny` and `cargo-audit` pass in CI | CI green |
| 10 | Zero-drift policy activated (no mock paths) | `rg "MOCK_" src/` returns empty |

---

## 9. Implementation Order

```
Day 1-3:   Workstream 1 (LLVM 15 prefix, Rust toolchain pinning, CI update)
Day 3-5:   Workstream 2 (compliance manifest, verify.yml)
Day 5-10:  Workstream 3 (workspace audit, crate integration)
Day 10-21: Workstream 4 Phase 3 Steps 3-6 (tool registry, routing, ALP proxy, transport)
Day 21-25: Workstream 4 Phase 3 Steps 7-8 (GitHub adapter, sandboxed scripts)
Day 25-28: Workstream 4 Mock crypto replacement + NEXT_STEPS.md
Day 28-30: Integration testing, Phase 7 zero-drift activation, final sign-off
```

---

## 10. Escalation Protocol

If any workstream cannot meet its acceptance criteria:
1. Document the blocker in `state/archivum/witnesses.jsonl` via `UnifiedWitness`
2. State which constitutional invariant (L0-1 through L0-9) is at risk
3. Escalate to the Multiplicity Foundation council per Ξ-Constitution Article IX

<!-- LawfulRecursionVersion:1.0 -->
