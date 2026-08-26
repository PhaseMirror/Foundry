# Architecture Decision Record: Production-Grade Alpha Function Implementation

**Status:** Proposed
**Date:** 2026-08-12
**Decision Makers:** Architecture Team
**Context:** IFMD (ACE + PETC + Langlands Prism + PIRTM) integration requiring mathematically verified numerical kernel


## 1. Context & Problem Statement

The Alpha Function—a unifying Laplace–Mellin kernel capable of reproducing Gamma, Beta, Zeta, Bessel, and generalized hypergeometric functions via parameter slices—must be deployed in a production safety-critical control system. The implementation must be:

1. **Mathematically correct** for all valid parameter domains
2. **Numerically robust** across floating-point edge cases (NaN, Inf, overflow, underflow)
3. **Verifiably safe** within the ACE projection safety set
4. **Performance-competitive** for real-time PETC actuation

The core tension: Lean 4 proves mathematical truth over ℝ (unbounded, infinite precision), while Rust executes on f32/f64 with finite bounds and IEEE edge cases.

## 2. Decision

**Adopt a three-layer verification architecture:**

| Layer | Tool | Scope | What It Proves |
|-------|------|-------|----------------|
| **L5 (Math)** | Lean 4 + Mathlib | ∀ x ∈ ℝⁿ, unbounded | Algorithm correctness, convergence, identities |
| **L4 (Code)** | Kani (CBMC) | ∀ f32 vectors up to bound N (8-32) | Rust code matches algorithm, no overflow/panic |
| **L3 (Runtime)** | proptest + debug_assert! | Statistical (10k+ random inputs) | Confidence across production-relevant ranges |

This follows established patterns from provable-contracts, rs-verified-der, and the verified zkEVM pipeline.

## 3. Technical Architecture

### 3.1 Lean 4 Specification Layer

**Location:** `alpha/lean/AlphaFunction.lean`

**Core Theorems to Prove:**

```lean
-- Convergence: integral absolutely converges for valid θ
theorem alpha_convergent (θ : Θ) (hθ : θ ∈ valid_domain) :
    ∃ M : ℝ, ∀ x ≥ 1, |∫₀^∞ t^(θ₀-1) e^(-xt) 𝒢(t;θ) dt| ≤ M

-- Recovery: Gamma slice reproduces Γ(s)
theorem alpha_gamma_slice (s : ℝ) (hs : s > 0) :
    alpha 1 ⟨s, 0, ..., 0⟩ = Gamma s

-- Recovery: Zeta via discrete part
theorem alpha_zeta_slice (s : ℝ) (hs : s > 1) :
    alpha x ⟨s, ..., 0⟩ = ∑_{n=1}^∞ n^(-s)  -- discrete term only

-- Stability: small θ perturbations → bounded output change (Lipschitz)
theorem alpha_lipschitz (θ₁ θ₂ : Θ) (h : ‖θ₁ - θ₂‖ < δ) :
    |alpha(x; θ₁) - alpha(x; θ₂)| ≤ L(θ) * ‖θ₁ - θ₂‖
```

**Implementation Strategy:** Use Mathlib's `measure_theory` for integrals, `analysis.special_functions` for Gamma/Bessel, and custom definitions for the kernel family. Target: **0 `sorry` theorems** across all obligations.

**Build:** `lake build AlphaFunction:static` produces C-compatible static library.

### 3.2 Rust Implementation Layer

**Location:** `alpha-rs/`

**Core Module Structure:**

```rust
// src/lib.rs - Public API
pub struct AlphaEvaluator {
    config: AlphaConfig,
    cache: LruCache<Params, f64>,  // memoization for repeated calls
}

impl AlphaEvaluator {
    /// Evaluate α(x; θ) with full diagnostics
    pub fn evaluate(&self, x: f64, theta: &[f64]) -> AlphaResult {
        // 1. Domain guard (runtime check)
        guard_domain(x, theta)?;
        
        // 2. Dispatch: integral or series path
        let (value, diag) = if theta.is_series_mode() {
            self.evaluate_series(x, theta)
        } else {
            self.evaluate_integral(x, theta)
        };
        
        Ok(AlphaResult { value, diagnostics: diag })
    }
}

// src/integral.rs - Gauss-Laguerre quadrature
fn gauss_laguerre<F>(f: F, nodes: &[f64], weights: &[f64]) -> f64
where F: Fn(f64) -> f64 { ... }

// src/series.rs - Adaptive truncation
fn adaptive_series<F>(terms: F, tolerance: f64, max_terms: usize) -> SeriesResult
where F: Fn(usize) -> f64 { ... }
```

**Safety Attributes:**
- `#![forbid(unsafe_code)]` — no unsafe Rust in the core
- `#![deny(clippy::pedantic)]` — rigorous linting
- No panics in the hot path (all `unwrap()` replaced with `?`)

### 3.3 Kani Verification Layer

**Location:** `alpha-rs/tests/kani/`

Kani verifies the **actual Rust code** with all f32/f64 edge cases, bounded to N (typically 8-32 elements).

**Harness Pattern** (from provable-contracts):

```rust
// tests/kani/integral.rs
#[kani::proof]
fn verify_integral_evaluation() {
    let x: f64 = kani::any();  // symbolic f64
    let theta: [f64; 4] = kani::any();
    
    // Constrain to valid domain
    kani::assume(x > 0.0 && x < 100.0);
    kani::assume(theta[0] > 0.0 && theta[0] < 10.0);
    
    let result = AlphaEvaluator::default()
        .evaluate(x, &theta)
        .unwrap();
    
    // Invariant: result is finite and within expected bounds
    assert!(result.value.is_finite());
    assert!(result.value >= 0.0);
}

#[kani::proof]
fn verify_series_convergence() {
    let s: f64 = kani::any();
    kani::assume(s > 1.0 && s < 10.0);
    
    let zeta = evaluate_zeta(s);
    // Tail bound: remainder ≤ N^(1-s)/(s-1)
    assert!(zeta.tail_estimate <= zeta.tail_bound());
}

// Symbolic exploration: 256^4 ≈ 4.3B configurations
#[kani::proof]
fn verify_gamma_recovery_symbolic() {
    let s: f64 = kani::any();
    kani::assume(s > 0.5 && s < 1.5);
    
    let alpha_val = AlphaEvaluator::default()
        .evaluate(1.0, &[s, 0.0, 0.0, 0.0])
        .unwrap();
    let gamma_val = gamma_approx(s);  // stubbed reference
    
    // ε = 1e-6 tolerance for float approximation
    assert!((alpha_val.value - gamma_val).abs() < 1e-6);
}
```

**Key Insight:** Lean proves `Σᵢ exp(xᵢ)/Z = 1` over ℝ; Kani's `stub_float` strategy proves surrounding code produces `1.0 ± ε` for ALL f32 vectors up to N.

### 3.4 Lean ↔ Rust FFI Integration

**Approach:** Export Lean-compiled static library, call from Rust via `lean-sys` (or `leo3` for higher-level bindings).

**FFI Wrapper:**

```rust
// src/lean_ffi.rs
use std::ffi::CString;
use std::os::raw::c_char;

extern "C" {
    // Exported from Lean via @[export] attribute
    fn lean_alpha_evaluate(
        x: f64,
        theta_ptr: *const f64,
        theta_len: usize,
        result_ptr: *mut f64,
        diag_ptr: *mut AlphaDiagnostics,
    ) -> i32;  // 0 = success, non-zero = error
}

pub fn evaluate_with_lean(x: f64, theta: &[f64]) -> Result<AlphaResult, LeanError> {
    let mut value = 0.0;
    let mut diag = AlphaDiagnostics::default();
    
    let status = unsafe {
        lean_alpha_evaluate(
            x,
            theta.as_ptr(),
            theta.len(),
            &mut value,
            &mut diag,
        )
    };
    
    if status == 0 {
        Ok(AlphaResult { value, diagnostics: diag.into() })
    } else {
        Err(LeanError::from_code(status))
    }
}
```

**Build Integration:**
```makefile
# Build Lean static lib
lean-build:
	cd alpha/lean && lake build AlphaFunction:static

# Link into Rust
alpha-rs/build.rs:
	fn main() {
	    println!("cargo:rustc-link-search=../alpha/lean/build/lib");
	    println!("cargo:rustc-link-lib=static=AlphaFunction");
	}
```

### 3.5 ACE/PETC Integration

**Location:** `ifmd-alpha/`

```rust
// src/features.rs - PETC-compatible feature extraction
pub fn extract_alpha_features(theta: &[f64], x_points: &[f64]) -> Vec<f64> {
    let evaluator = AlphaEvaluator::with_cache(1024);
    x_points.iter()
        .map(|&x| evaluator.evaluate(x, theta).unwrap().value)
        .collect()
}

// src/safety.rs - ACE projection with certificates
pub fn project_to_safety(
    weights: &[f64],
    safety_budget: f64,
    alpha_features: &[f64],
) -> (Vec<f64>, SafetyCertificate) {
    // Weighted-ℓ₁ projection via soft-thresholding
    let (safe_weights, gap_lb, slope_ub) = 
        weighted_l1_projection(weights, safety_budget, alpha_features);
    
    // Log certificates as in Prism/PIRTM
    log_certificates(gap_lb, slope_ub);
    
    (safe_weights, SafetyCertificate { gap_lb, slope_ub })
}
```

## 4. Verification Ladder & Tradeoffs

Following the provable-contracts model:

| Rung | Method | Cost | Confidence | When to Use |
|------|--------|------|------------|-------------|
| L1 | Lint + types | Very Low | Low | All code, CI gate |
| L2 | proptest (10k runs) | Low | Medium | PRs, nightly builds |
| L3 | Kani (bounded) | Medium | High (within N) | Release candidates |
| L4 | Lean theorems | High | Maximum (unbounded) | Critical paths only |

**Selection for Alpha Function:**
- **Integral kernel**: L4 (Lean) — convergence and recovery proofs
- **Quadrature implementation**: L3 (Kani) — no overflow/panic for N ≤ 64 nodes
- **Series truncation**: L3 (Kani) + L2 (proptest) — tail bounds verified
- **ACE projection**: L3 (Kani) — safety set membership for bounded weights

## 5. CI/CD Pipeline

```yaml
# .github/workflows/verify.yml
name: Verification Pipeline

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - run: cargo clippy -- -D warnings
      - run: cargo fmt --check

  proptest:
    runs-on: ubuntu-latest
    steps:
      - run: cargo test --test proptest --release  # 10k iterations

  kani:
    runs-on: ubuntu-latest
    steps:
      - name: Install Kani
        run: cargo install --locked kani-verifier && cargo kani setup
      - name: Run Kani proofs
        run: cargo kani --harness verify_integral_evaluation --enable-unstable
        timeout-minutes: 30  # BMC can be expensive

  lean:
    runs-on: ubuntu-latest
    steps:
      - name: Install Lean 4
        uses: leanprover/lean4@v4.0.0
      - name: Build Lean
        run: cd alpha/lean && lake build
      - name: Verify theorems
        run: cd alpha/lean && lake test  # 0 sorry required
```

## 6. Performance Considerations

| Concern | Mitigation |
|---------|------------|
| Lean static library size | Optimize with `lake build -O`; strip debug symbols |
| FFI overhead | Batch evaluations; cache parameterized results |
| Kani proof time | CI timeout 30min; split harnesses across runners |
| Runtime quadrature | Precompute nodes/weights; memoize per (x, θ) |

**Target Performance:**
- Single evaluation: < 10µs (cached), < 100µs (cold)
- Batch (64 points): < 500µs
- Memory: < 50MB (including Lean runtime)

## 7. Risks & Mitigations

| Risk | Probability | Mitigation |
|------|-------------|------------|
| Lean 4 toolchain drift | Medium | Pin Lean version in `lean-toolchain`; CI verifies compatibility |
| Kani cannot verify all f32 edge cases | Low | Supplement with proptest; document bounds in `PROOF_MANIFEST.md` |
| FFI marshalling bugs | Medium | Validate with `#[repr(C)]`; use `leo3-ffi-check` |
| Performance regression | Low | Benchmark suite; gate on < 2x baseline |
| Proof obligations too many | Medium | Prioritize: convergence → recovery → stability → Lipschitz |

## 8. Decision Criteria

This approach is preferred because:

1. **Lean proves mathematical truth** (unbounded, infinite precision)
2. **Kani verifies actual Rust execution** (f32 edge cases, bounded)
3. **Separation is compositional** — Lean says "algorithm is correct"; Kani says "code matches algorithm"
4. **Proven in production** — rs-verified-der, provable-contracts, verified zkEVM
5. **No unsafe code in Rust core**

## 9. Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| Lean-only (Rust via extraction) | Extraction tools (Aeneas/Hax) have known limits; cannot verify f32 semantics |
| Kani-only (no Lean) | Cannot prove unbounded mathematical properties; misses asymptotic convergence |
| C++ with CBMC | Lacks Lean's Mathlib; more difficult to maintain proofs |
| Python with hypothesis | No static guarantees; runtime-only verification |

## 10. References

1. **Provable Contracts** — YAML contracts → Kani harnesses + Lean theorems
2. **Lean + Kani Composition** — Why both are needed; `stub_float` strategy
3. **rs-verified-der** — Production DER codec with Kani (L3) + Aeneas→Lean (L4)
4. **Rust-to-Lean Verification Pipeline** — Production crypto code → Lean proofs
5. **Verified Arithmetic Circuit** — Lean proof + Rust FFI via `lean-sys`
6. **Leo3** — Safe Rust bindings to Lean 4
