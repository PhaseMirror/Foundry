# Architecture Decision Record (ADR) – Production‑Grade Build Plan for pirtm‑mlir
Status: ✅ Proposed → ✅ Accepted
Date: 2026‑06‑22
Authors: Antigravity (AGY) & User

### Context

The pirtm‑mlir workspace depends on the `mlir‑sys` crate, which must compile against LLVM 15 (the project’s supported version). A previous issue caused the crate to pick up LLVM 22 from the system, leading to build failures. The repository also contained a malformed `visitor.rs` that has now been replaced with a clean implementation.

### Decision
Adopt a deterministic, reproducible production build pipeline that:

1. Locks the toolchain (Rust, Cargo, LLVM) to known-good versions.
2. Enforces the LLVM 15 toolchain via a local prefix and wrapper script.
3. Validates the codebase with a full `cargo build --release` run inside a CI‑style environment.
4. Packages the resulting artifacts (binary, Cargo.lock, docs) for deployment.

### Rationale
• Zero‑drift: Guarantees that no downstream component (UI, agent, CI) can silently switch to a newer LLVM version, satisfying the Sedona Spine Mandate (all ESI‑related decisions must flow through the Rust engine).
• Reproducibility: Using a pinned LLVM directory (`llvm15_prefix`) eliminates host‑specific variability.
• Safety: The cleaned `visitor.rs` eliminates syntax errors that previously broke the build.
• Observability: The `antigrav_audit::record_event` calls already instrument the visitor; extending this to the build script provides a full provenance chain (Policy → Event Log → Kernel Computation → Narrative).

### No-Cache Mandate for Proof Extraction
Any form of caching, memoization, or stateful reuse in the proof verification path (specifically dominance and invariant extraction in `ssa_bridge.rs`) is strictly prohibited. 
• **Fresh Computation:** The dominance tree and ContractivityReceipt must be recomputed completely fresh on every single MLIR invocation.
• **Zero-Stale Tolerance:** Caching decouples the proof computation from the exact moment of IR materialization. This introduces an ontological gap that could attach a stale, albeit mathematically valid, proof to a mutated or corrupted IR block, destroying the L0 floor. No matter how robust the cache invalidation algorithm, the risk of a "counterfeit receipt" makes caching unacceptable under Governance-as-Compilation.

### Formal Verification Linkage
The fresh extraction mandate defined above is now formally linked to native Lean 4 theorems. 
• **Failable Constructors:** The implementations of `try_successor` and `try_stratum_boundary` are mechanically bound to Lean proofs asserting that they strictly preserve the L0 invariants under fresh extraction.
• **Dual Gates:** Any near-miss automatically renders the operation ineligible for MLIR emission and instantly emits a structured Phase Mirror lever.
• **L0 Sign-Off:** The Stratum Boundary operator closure via failable constructor has been officially re-audited and structurally proven. **L0 Sign-Off Granted**. This completes the required formal verification gap, authorizing the extraction of the Failable Constructor Pattern as a reusable Rust template.

### Implementation Steps

1. Create a sealed LLVM 15 prefix
2. Export `MLIR_SYS_150_PREFIX` for `mlir‑sys`
3. Verify LLVM version
4. Run a clean build (`cargo build --release`)
5. Run the test suite (`cargo test --release`)
6. Create a reproducible Docker image (optional but recommended)
7. Package artifacts
8. Generate a build manifest
9. Commit and tag release
10. Publish to artifact repository

### Risks & Mitigations
- Accidental LLVM version mismatch: The wrapper script forces the exact binary. Include a CI check for version.
- Future LLVM upgrades break engine: Keep the LLVM 15 prefix immutable; update cautiously.
- Missing audit events: Ensure every public function logs via `record_event`.
- Docker image bloat: Use multi‑stage builds.
- Binary incompatibility on target hosts: Build with the musl target.

### Acceptance Criteria
• `cargo build --release` completes without errors on a fresh checkout.
• `cargo test --release` passes all tests.
• `llvm-config --version` reports 15.x in the build environment.
• Build artifacts are version‑tagged and uploaded.
• All critical steps are logged.

### Next Steps
1. Execute the steps above in a fresh terminal or CI job.
2. Verify the produced binary runs (`./artifacts/release/pirtm-mlir --help`).
3. If successful, create a Git tag (`v1.0.0`) and push to the repository.

This ADR will be stored as `docs/adr/001-production-build.md` for future reference.
