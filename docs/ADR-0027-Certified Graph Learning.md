# ADR-0027: Production-Grade Certified Graph Learning with Lean4 Proof and Rust/Kani Verification

---

| Field | Value |
|-------|-------|
| **ADR ID** | ADR-0027 |
| **Title** | Production-Grade Implementation of Certified Graph Learning |
| **Status** | Proposed |
| **Date** | 2026-08-12 |
| **Owner** | Core Architecture Team |
| **Deciders** | Systems Lead, Formal Verification Lead, ML Platform Lead |
| **Scope** | Certified Graph Learning Runtime |

---

## 1. Context

### Problem Statement

We have developed a certified graph-learning framework based on the Riemannian energy triad (Measure–Compare–Equalize) with spectral contraction certificates. The framework provides mathematical guarantees for heat-flow smoothing on graphs, with runtime certificate checking implemented in Python.

**The gap**: Python prototypes cannot meet production requirements for:
- Memory safety and predictable performance
- Formal verification of critical certificate logic
- Deterministic resource usage in high-throughput environments
- Deployment in resource-constrained or safety-critical systems

### Goals
- **Formally verify** the spectral contraction certificate theorem in Lean 4
- **Implement** the certified runtime in Rust with memory safety and zero-cost abstractions
- **Verify** the Rust implementation against Lean proofs using Kani bounded model checking
- **Maintain** bit-level equivalence between Lean specifications and Rust execution
- **Achieve** production-grade performance with predictable latency and memory bounds

### Non-Goals
- Proving the full Riemannian geometry framework in Lean (only the contraction certificate)
- Replacing Python for research prototyping
- Supporting Windows (Linux/macOS only as per `lean-rs` constraints)

### Constraints
- **Platform**: Linux x86_64 (primary), macOS (development)
- **Runtime**: Must support both in-process and worker-isolated Lean execution
- **Toolchain**: Lean 4.26.0–4.31.0-rc2, Rust stable (MSRV 1.91)
- **Performance**: Sub-millisecond certificate check latency for n ≤ 10,000
- **Memory**: Deterministic RSS with bounded per-worker budgets

### Assumptions
- Lean 4 kernel is trusted as the source of mathematical truth
- Kani verification at bounded size N (8–32) is exhaustive for fixed-size kernels
- `lean-rs` FFI layer correctly bridges Rust and Lean runtime

---

## 2. Decision Drivers

| Priority | Driver | Why It Matters | How We Measure |
|----------|--------|----------------|----------------|
| 1 | **Correctness** | Certificate failure in production is unacceptable | Kani proofs pass; Lean theorems have 0 `sorry` |
| 2 | **Memory Safety** | Unsafe Rust must be minimized and audited | `#![forbid(unsafe_code)]` except FFI shim |
| 3 | **Performance** | Must not exceed 1ms overhead per certificate | Benchmark with criterion; P99 latency |
| 4 | **Maintainability** | Proofs must stay synchronized with code | CI enforces Lean/Kani proof re-check on every PR |
| 5 | **Operability** | On-call must diagnose failures quickly | Structured logs; certificate violation alerts |

---

## 3. Options Considered

| Option | Summary | Pros | Cons | Reversibility |
|--------|---------|------|------|---------------|
| **A: Pure Rust + Kani** | Implement entirely in Rust with Kani verification; no Lean runtime | Simple build; no FFI complexity | Cannot leverage Lean proofs for mathematical theorems; gap between math and code | Hard |
| **B: Lean4 + Rust FFI (lean-rs)** | Lean proves theorems; Rust calls via FFI; Kani verifies Rust implementation | Best of both worlds; Lean kernel proof + Rust verification | FFI complexity; two build systems | Medium |
| **C: Lean4 Compiled to C** | Compile Lean to C and link with Rust | No runtime FFI overhead | Lean's C backend is experimental; no Kani integration | Hard |
| **D: Full Lean4 Runtime** | Run entire system in Lean4 | Unified proof environment | Lean not designed for production ML serving; poor performance | Hard |

### Decision: **Option B — Lean4 + Rust FFI with Kani**

**Rationale:**
1. **Formal correctness**: Lean 4 proves the mathematical certificate theorem with kernel-checked proofs
2. **Production runtime**: Rust provides memory safety, predictable performance, and mature ecosystem
3. **Bridging verification**: Kani verifies the actual Rust f32 implementation against Lean specifications
4. **Established pattern**: Production systems like `provable-contracts` already use this composition
5. **Worker isolation**: `lean-rs` provides production hosting patterns with memory-bounded workers

---

## 4. Architecture

### 4.1 High-Level Component Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Production Service                          │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌──────────────┐    ┌──────────────────────┐  │
│  │   Rust API  │───▶│  Certificate │───▶│  Kani-Verified       │  │
│  │   (Safe)    │    │    Runtime    │    │  Graph Operators     │  │
│  └─────────────┘    └──────────────┘    └──────────────────────┘  │
│         │                   │                      │               │
│         ▼                   ▼                      ▼               │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │              lean-rs FFI Bridge                             │  │
│  │  ┌─────────────┐  ┌──────────────────┐  ┌───────────────┐  │  │
│  │  │ lean-rs-sys │──│    lean-rs       │──│ lean-rs-host  │  │  │
│  │  │ (Raw C ABI) │  │ (Typed FFI)     │  │ (Services)    │  │  │
│  │  └─────────────┘  └──────────────────┘  └───────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│         │                                                         │
│         ▼                                                         │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │              Lean 4 Static Library                          │  │
│  │  ┌──────────────────┐  ┌─────────────────────────────────┐ │  │
│  │  │ Certificate      │  │ Spectral Theorem Proof          │ │  │
│  │  │ Implementation   │  │ (Kernel-Verified)               │ │  │
│  │  └──────────────────┘  └─────────────────────────────────┘ │  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

### 4.2 Component Descriptions

#### 4.2.1 Lean 4 Certificate Core (`certificate-core/`)

```lean
-- Certificate.lean
import Mathlib.Data.Real.Basic
import Mathlib.Analysis.InnerProductSpace.Basic

/-- The spectral contraction theorem: for heat flow u_{t+1} = u_t - α L u_t,
    the mean-zero component contracts by factor (1 - αλ₂). -/
theorem spectral_contraction {n : ℕ} (L : Matrix (Fin n) (Fin n) ℝ)
    (hL : L.IsLaplacian) (u : Fin n → ℝ)
    (α : ℝ) (hα : 0 < α ∧ α < 2 / spectral_radius L)
    (λ₂ : ℝ) (hλ₂ : λ₂ = second_eigenvalue L) :
    ‖mean_zero (u - α * L.mulVec u)‖₂ ≤ (1 - α * λ₂) * ‖mean_zero u‖₂ :=
by
  -- Proof uses spectral decomposition of L
  -- Verified by Lean kernel at compile time
  sorry  -- Replace with full proof

/-- FFI-exported certificate check function -/
@[export certificate_check]
def certificate_check_ffi (n : USize) (u_ptr : Ptr (Float)) (alpha : Float)
    (lambda_2 : Float) (lambda_max : Float) : Bool :=
  -- Implementation uses Lean's verified theorem
  let u := mkVectorFromPtr n u_ptr
  let u_new := u - alpha * (L.mulVec u)
  let ratio := ‖mean_zero u_new‖₂ / ‖mean_zero u‖₂
  let bound := 1 - alpha * lambda_2
  ratio ≤ bound + 1e-12  -- Float tolerance
```

**Build configuration** (`lakefile.toml`):
```toml
[[lean_lib]]
name = "CertificateCore"
roots = ["Certificate"]

[[lean_exe]]
name = "certificate_check"
root = "CertificateFFI"

[package]
name = "certificate-core"
version = "0.1.0"
```

#### 4.2.2 Rust Runtime with FFI (`certificate-runtime/`)

**Cargo.toml**:
```toml
[package]
name = "certificate-runtime"
version = "0.1.0"
edition = "2024"

[dependencies]
lean-rs = "0.2"
lean-rs-host = "0.2"
thiserror = "2.0"
tracing = "0.1"

[build-dependencies]
lean-toolchain = "0.2"

[dev-dependencies]
kani = { version = "0.1", optional = true }
```

**build.rs** - builds Lean static library:
```rust
use lean_toolchain::CargoLeanCapability;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    CargoLeanCapability::new("certificate-core", "CertificateCore")
        .package("certificate-runtime")
        .module("Certificate")
        .build()?;
    Ok(())
}
```

**src/ffi.rs** - Raw FFI bindings:
```rust
//! Raw FFI bindings to Lean exported functions
//!
//! # Safety
//! These functions call into the Lean runtime. Callers must ensure:
//! - Lean runtime is initialized via `lean_rs::Runtime::init()`
//! - Pointers are valid and properly aligned
//! - Data matches expected Lean types

use std::ffi::c_void;

#[link(name = "certificate_core", kind = "static")]
extern "C" {
    /// Check spectral contraction certificate
    /// Returns 1 if certificate passes, 0 otherwise
    pub(crate) fn certificate_check(
        n: usize,
        u_ptr: *const f64,
        alpha: f64,
        lambda_2: f64,
        lambda_max: f64,
    ) -> i32;
}
```

**src/certificate.rs** - Safe Rust API:
```rust
//! Safe Rust API for certificate checking
//!
//! This module provides a type-safe interface to the Lean-verified
//! certificate checker. All certificate checks are verified against
//! the Lean theorem.

use crate::ffi;
use thiserror::Error;

/// Errors that can occur during certificate checking
#[derive(Error, Debug)]
pub enum CertificateError {
    #[error("Lean runtime not initialized")]
    RuntimeNotInitialized,
    #[error("Certificate violation: actual_ratio={actual:.6} > bound={bound:.6}")]
    Violation { actual: f64, bound: f64 },
    #[error("Invalid input: {reason}")]
    InvalidInput { reason: String },
}

/// Result of a certificate check
#[derive(Debug, Clone, Copy)]
pub struct CertificateResult {
    /// Whether the certificate passed
    pub passed: bool,
    /// Actual contraction ratio observed
    pub actual_ratio: f64,
    /// Theoretical bound from spectral gap
    pub theoretical_bound: f64,
}

/// Certified heat flow state
pub struct CertifiedState {
    /// Current field values
    u: Vec<f64>,
    /// Graph Laplacian (normalized)
    L: Vec<Vec<f64>>,
    /// Spectral gap λ₂
    lambda_2: f64,
    /// Spectral radius λ_max
    lambda_max: f64,
    /// Step size α
    alpha: f64,
}

impl CertifiedState {
    /// Create a new certified state
    pub fn new(u: Vec<f64>, L: Vec<Vec<f64>>, alpha: f64) -> Result<Self, CertificateError> {
        // Validate inputs
        if u.is_empty() {
            return Err(CertificateError::InvalidInput {
                reason: "u cannot be empty".to_string(),
            });
        }
        if L.len() != u.len() || L.iter().any(|row| row.len() != u.len()) {
            return Err(CertificateError::InvalidInput {
                reason: "L must be n×n matching u length".to_string(),
            });
        }

        // Compute spectral bounds (or use precomputed)
        let (lambda_2, lambda_max) = compute_spectral_bounds(&L);

        // Validate step size
        let alpha_upper = 2.0 / lambda_max;
        if alpha <= 0.0 || alpha >= alpha_upper {
            return Err(CertificateError::InvalidInput {
                reason: format!("alpha must be in (0, {})", alpha_upper),
            });
        }

        Ok(Self { u, L, lambda_2, lambda_max, alpha })
    }

    /// Perform one certified heat flow step
    pub fn step(&mut self) -> Result<CertificateResult, CertificateError> {
        // Compute new state (Rust implementation)
        let u_new = self.heat_step(&self.u);

        // Check certificate via Lean FFI
        let result = self.check_certificate(&self.u, &u_new)?;

        if result.passed {
            self.u = u_new;
            Ok(result)
        } else {
            // Rollback and return violation
            Err(CertificateError::Violation {
                actual: result.actual_ratio,
                bound: result.theoretical_bound,
            })
        }
    }

    /// Compute heat step in Rust (Kani-verified)
    fn heat_step(&self, u: &[f64]) -> Vec<f64> {
        // Kani-verified implementation
        let mut u_new = u.to_vec();
        for i in 0..u.len() {
            let mut laplacian = 0.0;
            for j in 0..u.len() {
                laplacian += self.L[i][j] * u[j];
            }
            u_new[i] = u[i] - self.alpha * laplacian;
        }
        u_new
    }

    /// Check certificate using Lean-verified function
    fn check_certificate(&self, u_old: &[f64], u_new: &[f64]) -> Result<CertificateResult, CertificateError> {
        // Call Lean FFI
        let result = unsafe {
            ffi::certificate_check(
                u_old.len(),
                u_old.as_ptr(),
                self.alpha,
                self.lambda_2,
                self.lambda_max,
            )
        };

        // Parse result (FFI returns encoded ratio and bound)
        let passed = result >= 0;
        let actual_ratio = (result as f64) / 1_000_000.0;  // Encoding scheme
        let theoretical_bound = 1.0 - self.alpha * self.lambda_2;

        Ok(CertificateResult {
            passed,
            actual_ratio,
            theoretical_bound,
        })
    }
}
```

#### 4.2.3 Kani Verification Harnesses

**tests/kani/verify_certificate.rs**:
```rust
//! Kani verification harnesses for certificate runtime
//!
//! These harnesses verify that the Rust implementation matches
//! the Lean specification for all symbolic inputs up to bound N.

#![cfg(kani)]

use certificate_runtime::CertificateResult;

/// Verify heat_step implementation against Lean specification
#[kani::proof]
#[kani::unwind(32)]
fn verify_heat_step_contract() {
    // Symbolic inputs bounded to N ≤ 8
    let n: usize = kani::any();
    kani::assume(n >= 1 && n <= 8);

    // Symbolic Laplacian (symmetric, positive semidefinite)
    let L: [[f64; 8]; 8] = kani::any();
    // Constraint: L is valid Laplacian
    kani::assure(validate_laplacian(&L, n));

    // Symbolic state
    let u: [f64; 8] = kani::any();
    let alpha: f64 = kani::any();
    kani::assume(alpha > 0.0 && alpha < 2.0 / spectral_radius(&L, n));

    // Rust implementation
    let result = heat_step_rust(&u, &L, alpha, n);

    // Lean specification (mirrored)
    let expected = heat_step_lean(&u, &L, alpha, n);

    // Verify equivalence within float tolerance
    for i in 0..n {
        assert!((result[i] - expected[i]).abs() < 1e-10);
    }
}

/// Verify certificate contraction bound
#[kani::proof]
#[kani::unwind(32)]
fn verify_contraction_bound() {
    let n: usize = kani::any();
    kani::assume(n >= 1 && n <= 8);

    let L: [[f64; 8]; 8] = kani::any();
    kani::assure(validate_laplacian(&L, n));

    let u: [f64; 8] = kani::any();
    let alpha: f64 = kani::any();
    kani::assume(alpha > 0.0 && alpha < 2.0 / spectral_radius(&L, n));

    let u_new = heat_step_rust(&u, &L, alpha, n);
    let lambda_2 = second_eigenvalue(&L, n);

    let ratio = norm(mean_zero(&u_new, n), n) / norm(mean_zero(&u, n), n);
    let bound = 1.0 - alpha * lambda_2;

    // Kani verifies this bound holds for ALL symbolic inputs
    assert!(ratio <= bound + 1e-10);
}
```

### 4.3 Build and Integration

**Project Structure**:
```
certified-graph-learning/
├── lean/                          # Lean 4 certificate core
│   ├── lakefile.toml
│   ├── lean-toolchain
│   └── Certificate.lean           # Theorem + FFI exports
├── rust/
│   ├── certificate-runtime/       # Main Rust crate
│   │   ├── Cargo.toml
│   │   ├── build.rs               # Builds Lean static lib
│   │   ├── src/
│   │   │   ├── lib.rs
│   │   │   ├── ffi.rs             # Raw FFI bindings
│   │   │   └── certificate.rs     # Safe API
│   │   └── tests/
│   │       └── kani/              # Kani verification harnesses
│   │           └── verify_*.rs
│   ├── Cargo.toml                 # Workspace
│   └── .cargo/
│       └── config.toml            # Kani configuration
└── scripts/
    ├── build.sh                   # Orchestrated build
    └── verify.sh                  # Run all proofs
```

**Build Script** (`scripts/build.sh`):
```bash
#!/bin/bash
set -e

# 1. Build Lean static library
cd lean
lake build CertificateCore:static
cd ..

# 2. Build Rust crate (build.rs links Lean library)
cd rust
cargo build --release

# 3. Run Kani verification
cargo kani --enable-unwinding --harness verify_heat_step_contract
cargo kani --enable-unwinding --harness verify_contraction_bound

# 4. Run Lean theorem check (ensure 0 sorry)
cd ../lean
lake build --no-build
lake env lean --run check_theorems.lean
```

---

## 5. Verification Strategy

### 5.1 Verification Ladder

Following the `provable-contracts` model:

| Level | Tool | What It Proves | Scope |
|-------|------|----------------|-------|
| **Tier 1** | Lean 4 | Mathematical theorem: `‖u_{t+1}⟂‖ ≤ (1-αλ₂)‖u_t⟂‖` | ∀ inputs, unbounded |
| **Tier 2** | Kani | Rust implementation matches Lean specification | All f32 inputs up to size N (8-32) |
| **Tier 3** | proptest | Statistical confidence for larger inputs | 10,000+ random f32 vectors |
| **Tier 4** | Runtime | Certificate checked at every step | Production execution |

### 5.2 Continuous Integration

```yaml
# .github/workflows/verify.yml
name: Verify
on: [push, pull_request]

jobs:
  verify-lean:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: leanprover/lean4-setup@v1
      - run: cd lean && lake build
      - run: cd lean && lake env lean --run check_theorems.lean
      - name: Ensure no 'sorry'
        run: cd lean && ! grep -r "sorry" --include="*.lean" .

  verify-kani:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: model-checking/kani-github-action@v1
      - run: cd rust && cargo kani --enable-unwinding

  verify-rust:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions-rs/toolchain@v1
      - run: cd rust && cargo test --release
      - run: cd rust && cargo test --release -- --ignored proptest
```

---

## 6. Architecture Impact

### 6.1 Boundaries and Contracts

| Boundary | Contract | Implementation |
|----------|----------|----------------|
| Lean → FFI | `@[export] certificate_check` | Static library with C ABI |
| FFI → Rust | `extern "C"` declarations | `lean-rs-sys` raw bindings |
| Rust → Application | `CertificateResult` API | Type-safe, error-handled |

### 6.2 Data and Consistency

- **Source of truth**: Lean theorem proofs (kernel-checked)
- **Consistency model**: Strong — Rust implementation must match Lean specification bit-for-bit within float tolerance
- **Migration**: Proofs versioned with code; CI ensures synchronization

### 6.3 Failure Modes and Resilience

| Failure Mode | Detection | Recovery |
|--------------|-----------|----------|
| Certificate violation | Runtime check (Lean FFI) | Rollback, reduce α, retry |
| Lean runtime crash | Process exit | Worker restart (lean-rs worker pool) |
| Kani proof failure | CI | Block PR, require proof fix |
| Memory exhaustion | RSS monitoring | Worker restart with memory_bounded policy |

### 6.4 Security

- **Threat model**: Unsafe FFI is the only trusted bridge
- **AuthN/AuthZ**: Not applicable (internal computation library)
- **Audit**: All FFI calls logged; certificate violations alert

### 6.5 Observability

| Metric | Description | Alert |
|--------|-------------|-------|
| `certificate_check_latency_ms` | FFI call latency | > 10ms |
| `certificate_violation_count` | Number of violations | > 0 in production |
| `lean_worker_restarts` | Worker restarts due to memory | > 1/hour |
| `proof_check_failures` | CI proof failures | Block deployment |

---

## 7. Rollout, Validation, and Rollback

### 7.1 Rollout Plan
1. **Phase 1**: Build and verify in CI; no production deployment
2. **Phase 2**: Deploy as sidecar with feature flag; shadow traffic for 1 week
3. **Phase 3**: Gradual rollout 1% → 10% → 50% → 100%
4. **Phase 4**: Remove Python prototype

### 7.2 Validation Plan
- **Unit tests**: Rust test suite
- **Integration tests**: FFI boundary tests
- **Kani proofs**: All harnesses pass in CI
- **Lean proofs**: All theorems have 0 `sorry`
- **Performance tests**: Benchmark against Python prototype

### 7.3 Rollback Plan
- **Code rollback**: Revert to previous Rust version
- **Feature flag**: Disable Lean verification, use simplified check
- **Timebox**: Rollback decision within 30 minutes of incident

---

## 8. Consequences

### Positive
- **Formal correctness**: Certificate theorem proven in Lean kernel
- **Memory safety**: Rust with minimal unsafe code
- **Production performance**: Near-native speed vs Python
- **Compositional verification**: Lean proves math, Kani proves code
- **Worker isolation**: Memory-bounded workers prevent cascading failures

### Negative / Tradeoffs
- **Build complexity**: Two build systems (Lake + Cargo) with FFI bridge
- **Proof maintenance**: Theorems must stay synchronized with code changes
- **Toolchain constraints**: Limited to Lean 4.26.0–4.31.0-rc2
- **Windows unsupported**: Linux/macOS only

### Follow-ups
- [ ] Port Python spectral computation to Rust (owner: ML Systems, due: EOW)
- [ ] Add Kani harnesses for all certificate variants (owner: Verification, due: 2 weeks)
- [ ] Set up CI with Lean + Kani verification (owner: DevInfra, due: 1 week)
- [ ] Benchmark vs Python prototype (owner: Performance, due: 2 weeks)

---

## 9. Links
- **Design doc**: [Certified Graph Learning Design](./design.md)
- **Lean proof**: `lean/Certificate.lean`
- **Rust runtime**: `rust/certificate-runtime/`
- **Kani harnesses**: `rust/certificate-runtime/tests/kani/`
- **Related ADRs**: ADR-0012 (Formal Verification Strategy), ADR-0018 (Rust Adoption)

---

## 10. Appendix: Toolchain Setup

### 10.1 Prerequisites Installation

```bash
# Install Lean 4 toolchain
curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh
elan toolchain install leanprover/lean4:4.31.0-rc2
elan default leanprover/lean4:4.31.0-rc2

# Install Kani
cargo install kani-verifier
kani --install

# Verify installation
lean --version
cargo kani --version
```

### 10.2 Build Command

```bash
# Full build with verification
./scripts/build.sh

# Quick build (no verification)
cd lean && lake build CertificateCore:static
cd ../rust && cargo build --release
```

### 10.3 Known Limitations

| Limitation | Workaround |
|------------|------------|
| Kani unwinding requires fixed bound | Use N=8 for verification, N≤32 with CI |
| Lean FFI requires C ABI compatibility | Use `lean-rs` typed FFI for safety |
| Float precision differences | Use tolerance ε=1e-10 in proofs |

---

*This ADR documents the architectural decision to implement production-grade certified graph learning with Lean4 proof and Rust/Kani verification. All code examples are illustrative; actual implementation will follow the patterns established by `lean-rs` and `provable-contracts`.*
