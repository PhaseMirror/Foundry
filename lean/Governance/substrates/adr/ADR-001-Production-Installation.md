# ADR-001: Production Installation of MOC Lawful Core

## Status
Proposed

## Context
The MOC lawful core (`lean/MOC/Core.lean` and `lean/PIRTM/Transition/`) is now formally verified, axiom-clean, and formally anchored to the `Ξ-Constitution`. To maintain this integrity in a production environment on this machine, we must move from ad-hoc builds to a reproducible, hermetic installation and lifecycle management process.

## Decision
We will establish a hermetic installation pipeline that treats the `axiom-clean` core as an immutable system dependency, preventing any possibility of `Mathlib`-tainted drift.

## Proposed Pipeline
1.  **Hermetic Build Environment:** Use a dedicated Nix/Elan environment strictly pinning the Lean 4 compiler version to ensure bit-reproducible build outputs.
2.  **Axiom-Clean Enforcement:** Implement a pre-build hook that strictly validates the import graph of `lean/`, rejecting any module importing `Mathlib`.
3.  **Deployment:** Install the validated core as a system library, allowing downstream components (the Lisp-bridge and production CRMF agents) to link against the anchored stability certificates.
4.  **Lifecycle Management:** Any update to the production core must be accompanied by a re-verification of all stability certificates within the axiom-clean environment, followed by a ledger-anchored re-certification.

## Consequences
- **Positive:** Guaranteed axiom-cleanliness across all production deployments; elimination of build-time drift.
- **Negative:** Increased complexity in local development workflows; stricter dependency management.
- **Mitigation:** Provide automated "lawful-core" containers for developers to easily replicate the hermetic environment.

---

## MCP FFI Integration Layer (ADR-001 Addendum)

### L0 Classification: FFI RAII Wrappers
The `LeanOwned` and `LeanBorrowed` types in `lean_ffi.rs` are **L0-adjacent artifacts**. Any unsoundness (double-free, use-after-free, leak under adversarial drop) constitutes an immediate Sedona Spine violation because:

1. FFI boundary unsoundness corrupts proof term reference counts
2. Corrupted proofs cause undefined behavior in `lean_verify_successor_invariant`
3. This violates the mathematical object integrity invariant at the core of the Sedona Spine

### Guard Clauses
- All production FFI calls MUST use `LeanOwned::acquire()` or `LeanBorrowed::from_raw()`
- Manual `lean_inc`/`lean_dec` calls are **prohibited** in production code
- Every change to `lean_ffi.rs` requires updated proof reference in `CONTRACT.md`
- CI gate blocks merges without 100% harness coverage of RAII paths

### Classification Matrix
| Artifact | Layer | Failure Mode | Violation Level |
|----------|-------|--------------|-----------------|
| `LeanOwned` / `LeanBorrowed` | L0-adjacent | Double-free | L0 (immediate) |
| `LeanOwned` / `LeanBorrowed` | L0-adjacent | Leak under drop | L0 (immediate) |
| MCP tool logic | L1 | Policy bypass | L1 (advisory/block) |
| Kilo UI display | L3 | Display error | Lever (recoverable) |

---

## ADR-001 Amendment: Multi-Server Spectral L0 Validation Complete

### Completion Status
- **Phase 4 MCP**: Multi-server spectral L0 routing integrated (2026-06-29)
- **SpectralContext** propagated via MCP tool calls
- **validate_spectral** enforces L0 invariant on ρ ≥ 1-ε_tier
- **Archivum witness** records multi-server validation decisions

### Implementation Artifacts
- `crates/commander-core/src/multi_server_validator.rs` - Multi-server validation
- `crates/commander-core/src/hoe_router.rs` - HoE escalation routing
- `crates/alp/src/lib.rs` - SpectralMetrics + validate_spectral + build_spectral_witness

### Verification
- `cargo test --test governance` passes (7 tests)
- `cargo test --package multiplicity-commander-core` passes (6 lib tests)
- Multi-server validator enforces tier ε across nodes
- HoE escalation triggered on spectral radius violation
