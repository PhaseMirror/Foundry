# ADR-MIG-001: Migration of Multiplicity Packages to Native Rust

- Status: accepted
- Date: 2026-05-22
- Owners: Multiplicity Core Architecture Team
- Tags: runtime, migration, architecture, rust
- Depends On: ADR-WIT-001, ADR-ALP-001, ADR-SIG-001
- Supersedes: None
- Phase: phase-3
- See-Also: https://github.com/MultiplicityFoundation/.github/tree/main/library/migration
- Published-At: https://github.com/MultiplicityFoundation/the-commander/blob/main/docs/adr/accepted/ADR-MIG-001-rust-package-migration.md

## 1. Context
The Multiplicity ecosystem contains multiple legacy, prototype, and active components written in Python and TypeScript under the `packages/` directory.
While these external environments (particularly Python for science/math and TypeScript for web runtimes) were useful during initial prototyping, they present significant challenges:
1. **Security Vulnerabilities**: External runtimes introduce a larger attack surface, dependency vulnerabilities (e.g., in NPM and PyPI packages), and bypass vectors for policy enforcement.
2. **Operational Overhead**: Multiple runtimes require distinct toolchains (Node/NPM, Python/pip/uv, Rust/Cargo), increasing container size, deployment complexity, and cold-start latency.
3. **Semantic & Mathematical Drift**: Core invariants (e.g., L0-1 to L0-9) must be enforced identically across all layers. Maintaining redundant validation logic in Python, TypeScript, and Rust leads to implementation drift and verification gaps.
4. **Performance Bottlenecks**: High-throughput components like the Sigma kernel and the proof engine suffer from the performance overhead of dynamic interpretation and cross-process IPC.

To satisfy the Ξ-Constitution and achieve the Phase 3 roadmap goals, we require a unified, secure, and performant runtime.

## 2. Decision
We will systematically migrate the contents of the `packages/` directory into native Rust crates under `crates/`, where applicable, according to a three-tier priority classification.

### 2.1. Crate Mapping & Migration Classification

#### Tier A: Core Invariant & Policy Engine (High Priority - Immediate Rust Migration)
These packages execute system-level policy, maintain local ledgers, enforce mathematical invariants, or direct the execution loop. They must be ported to pure Rust to ensure zero-bypass safety.

| Legacy Package | Target Rust Crate | Migration & Implementation Strategy |
| :--- | :--- | :--- |
| `packages/sigma_kernel` | `crates/sigma-kernel` | Complete port of `kernel.py`, Wetterich solver (`wetterich_solver.py`), and ledgers to Rust. Replace SQLite storage with a memory-mapped database or pure Rust SQLite interface (`rusqlite`). |
| `packages/atomic-language` | `crates/alp` | Port grapheme decomposition (`l1_grapheme.py` / UAX #29 segmentation) and prime-indexed symbolic feature mappings (`l2_morpheme.py`, `layers.py`) into pure Rust. |
| `packages/daemon` | `crates/commander-daemon` (New) | Port the system scheduler, observability watchdog, and rollback triggers. Build as a native Rust background worker managed via `systemd`. |
| `packages/digital_twin` | `crates/digital-twin` (New) | Rewrite the state simulation, helix simulation, and snapshot validation engines to leverage Rust's safety and parallel iterator features (`rayon`). |
| `packages/meta-ensembles` | `crates/multiplicity-ensembles` | Rewrite the spectral aggregation algorithms. Replace NumPy/SciPy operations with Rust equivalents (`ndarray` or `nalgebra`) to compute the coupling matrix and verify contractivity ($\rho < 0.95$). |
| `packages/mvf` | `crates/multiplicity-math` | Port Multiplicity Viability Flow simulation math and phase diagram calculations to pure Rust. |

#### Tier B: Cryptographic & Proof Services (Medium Priority - Rust Port with Legacy Fallback)
These packages generate formal proofs or manage MEV/privacy properties. They benefit heavily from Rust's performance and memory safety.

| Legacy Package | Target Rust Crate | Migration & Implementation Strategy |
| :--- | :--- | :--- |
| `packages/prover` | `crates/prover` (New) | Migrate from Python proof wrappers to Rust-based SAT/SMT bindings (e.g., `z3`) or native zero-knowledge proof libraries (`arkworks`). |
| `packages/policy` | `crates/alp` or `crates/zk-policy` | Port Circom ZK-SNARK verification and c14n formatting into native Rust, leveraging crates like `ark-groth16` or `bellman`. |
| `packages/privacy-mev` | `crates/privacy-mev` (New) | Rewrite MEV mitigation and transaction privacy algorithms to run within Rust's low-latency pipeline. |
| `packages/onboarding-identity`| `crates/common` / `crates/identity` | Port key generation, Ed25519 signing, and onboarding flows to Rust. |

#### Tier C: Web, UI, and Client SDKs (Low Priority - WASM Target / TS Wrapper)
These packages interface with web browsers, operators, or frontend applications. They will remain in TypeScript to preserve native web ecosystem compatibility but will link to the Rust core via WebAssembly (WASM).

| Legacy Package | Target Rust Crate / Packaging | Migration & Implementation Strategy |
| :--- | :--- | :--- |
| `packages/verification-sdk`| `crates/verification-sdk` + WASM | Compile verification core logic to WASM using `wasm-bindgen` and publish as a npm package with TypeScript definitions. |
| `packages/health-sdk` | `crates/health-sdk` + WASM | Compile diagnostic checks to WASM to share health models between CLI and dashboard. |
| `packages/the-genius` | `packages/the-genius` (TS Wrapper) | Retain the TypeScript framework for agent reasoning but delegate all mathematical and cryptographic checks to the Rust core. |
| `packages/profile-web4` | `packages/profile-web4` (TS Wrapper) | Retain for browser interactions, loading profiles verified by Rust's `crates/alp`. |

### 2.2. Interoperability & Transition Protocol

To prevent breaking existing workflows during the migration, we will adopt a phased integration protocol:
1. **PyO3 Bridging (Python to Rust)**: For Tier A and Tier B Python packages, we will expose the Rust implementation via PyO3 as a Python native module. This allows existing Python code to call the new Rust implementation, enabling differential testing.
2. **WebAssembly / Node-API (TS/JS to Rust)**: For TypeScript components, we will use `wasm-bindgen` or Node-API (`neon`) to call the compiled Rust core, ensuring that the same policy engine (`crates/alp`) validates transactions in both browser/Node contexts and the native CLI.
3. **Differential Verification (Parallel Run)**: Prior to deprecating any legacy package, we will run the Python/TS code and the Rust code in parallel in staging, asserting that state mutations, signature hashes, and outputs match exactly.

### 2.3. Architectural Invariants (Unchanged)
1. **Unified Witness**: Every execution path must still write a valid `UnifiedWitness` record to `state/archivum/witnesses.jsonl` and anchor it via the `GitLedger`.
2. **ALP Gate Validation**: No state mutation can bypass the ALP validation check (`PolicyEngine::validate_action`).

## 3. Alternatives Considered

### Alternative A: Retaining Python and TypeScript in Production
- *Why Rejected*: This alternative would require maintaining multiple interpreters in production, keeping container sizes above 1GB, and risking semantic drift between the verification logic in TS/Python and the enforcement logic in the Rust CLI.

### Alternative B: Direct Process Spawning / IPC (Rust CLI calls Python processes)
- *Why Rejected*: Spawning Python scripts per-transaction introduces significant latency (100ms+ startup overhead) and requires managing Python pathing and environment isolation at runtime, which violates the "offline-first, zero-external-dependencies" constraint of the secure operator shell.

## 4. Dependencies
- **Cargo Workspaces**: The workspace `Cargo.toml` must be updated as new crates are introduced.
- **Math & SciPy Alternatives**: Migration of `meta-ensembles` and `mvf` depends on the completeness of Rust's numerical math ecosystem (e.g., `nalgebra`, `ndarray`, `sprs`).
- **ZK Proof Ecosystem**: Porting `policy` ZK validators depends on compatibility with Circom constraints and `arkworks` bindings.

## 5. Risks
- **Numerical Precision Mismatch**: Floating-point operations in Python (NumPy) may slightly differ from Rust (`ndarray`) due to differences in BLAS/LAPACK backends or default IEEE 754 rounding. *Mitigation*: Implement strict rounding tolerance ($\epsilon = 10^{-12}$) and run extensive differential testing.
- **Development Interruption**: Rewriting complex solvers (like the Wetterich solver or Circom verification) requires dedicated engineering time. *Mitigation*: Follow a step-by-step phased approach, moving one package at a time and preserving legacy code as verification benchmarks.

## 6. Consequences
- **Positive**:
  - Unifies the entire system under a single toolchain (Rust/Cargo).
  - Shrinks container and distribution footprint from >1.5GB to <100MB.
  - Eliminates interpreter cold-start overhead, reducing policy verification times to sub-millisecond ranges.
  - Guarantees zero-drift: a single implementation of the ALP and Sigma kernel is shared across all platforms.
- **Negative**:
  - Requires initial developer effort to rewrite mathematically complex Python/TypeScript scripts.
  - Increased compile times for the workspace as complex crates are added.
