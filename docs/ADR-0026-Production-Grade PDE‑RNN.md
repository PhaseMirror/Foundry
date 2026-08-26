# ADR-0026: Production-Grade PDE‑RNN + SMM Implementation with Lean 4 Proofing and Rust/Kani Verification

**Status:** Proposed | **Date:** 2026-08-12 | **Authors:** Phase Mirror Architecture Team


## 1. Context

The PDE‑RNN with Sparse Modular Memory (SMM) specification requires a production-grade implementation with mathematically verifiable correctness. The system comprises:

- **PDE‑RNN cell**: Discretized neural ODE with stability guarantees (contraction factor `L ∈ [0.83, 0.95]`)
- **Sparse Modular Memory**: Content-addressable memory with coherence-bound retrieval
- **Frequency‑domain edge operator**: FFT-based high-pass filtering

The critical correctness properties that demand formal verification:

| Property | Criticality | Verification Target |
|----------|-------------|---------------------|
| Spectral norm bounds (`|B| ≤ b`, `|C| ≤ c`) | **Safety-critical** | Runtime enforcement + Kani |
| Contraction factor `L < 1` | **Safety-critical** | Invariant proof in Lean |
| Memory retrieval threshold correctness | **Functional** | Lean theorem + Kani harness |
| No buffer overflows/UB in FFI boundary | **Safety-critical** | Kani + MIRI |
| Float edge-case handling (NaN, Inf, overflow) | **Functional** | Kani bounded verification |

> Lean 4 and Kani solve **different problems**. Lean proves algorithms over mathematical reals (unbounded, all inputs). Kani verifies the actual Rust code — with all its f32 edge cases — but only for vectors up to size `N` [10†L5-L9][11†L14-L19]. Neither subsumes the other; both are required.


## 2. Decision

**Adopt a three-layer verification architecture:**

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 1: Lean 4 Specification & Theorems                   │
│  - Algorithmic correctness over ℝ (unbounded)              │
│  - Stability invariants (contraction, spectral bounds)      │
│  - Memory coherence/retrieval guarantees                   │
│  - @[export] FFI wrappers                                  │
└─────────────────────────────────────────────────────────────┘
                              │ FFI (lean-rs)
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Layer 2: Rust Implementation (lean-rs + lean-rs-host)     │
│  - Safe FFI bindings to Lean runtime [7†L5-L9]             │
│  - Core PDE-RNN / SMM / FFT logic                          │
│  - Runtime spectral norm enforcement                       │
└─────────────────────────────────────────────────────────────┘
                              │ Kani verification
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Layer 3: Kani Proof Harnesses                             │
│  - Bounded model checking of Rust implementation [1†L4-L6] │
│  - Float edge cases (f32/f64)                             │
│  - Panic-freedom, overflow, unwrap exceptions [1†L22-L23] │
│  - stub_float strategy bridging Lean theorems [10†L21-L30]│
└─────────────────────────────────────────────────────────────┘
```

### 2.1 Lean 4 → Rust FFI Strategy

Use the **`lean-rs`** crate stack [8†L18-L45]:

| Crate | Role |
|-------|------|
| `lean-rs-sys` | Raw Lean 4 C ABI bindings (opt-in unsafe) [0†L21-L24] |
| `lean-rs` | Safe typed FFI: runtime init, module loading, exported functions [7†L5-L9] |
| `lean-rs-host` | Theorem-prover host: `LeanHost`/`LeanCapabilities`/`LeanSession` [6†L5-L10] |
| `lean-toolchain` | Toolchain discovery, Lake module discovery [8†L25-L29] |

**Happy path** [7†L15-L22]:
```rust
let runtime = lean_rs::LeanRuntime::init()?;
let capability = lean_rs::LeanCapability::from_build_manifest(runtime, manifest_path)?;
let verify_stability = capability.exported::<(f32, f32, f32), bool>("verify_contraction")?;
let result = verify_stability.call(alpha, beta, gamma)?;
```

**Lean side** (`@[export]`):
```lean
@[export verify_contraction]
def verifyContraction (α β γ : Float) : Bool :=
  let L := Float.abs (1 - Δt * α) + Δt * β * γ
  L < 1.0
```

### 2.2 Verification Pipeline

Adopt the **compositional verification** pattern from `provable-contracts` [9†L26-L31][10†L21-L30]:

1. **Lean proves the math** — unbounded, over ℝ
2. **Kani `stub_float` bridges** — "If float ops return ANY finite value, structural invariant holds"
3. **Kani exhaustively verifies** — bounded f32 implementations (N=8-32 typical) [10†L18-L20]
4. **proptest provides statistical confidence** — large random vectors
5. **Runtime contracts** — `debug_assert!` enforcement in debug builds [9†L25-L26]

This matches the five-rung verification ladder: L1 lint → L2 types → L3 proptest → L4 Kani → L5 Lean theorems [2†L39-L40].


## 3. Architecture Components

### 3.1 PDE‑RNN Core (Lean Specification + Rust Implementation)

**Lean specification** (`PdeRnn/Spec.lean`):
```lean
structure PdeRnnParams where
  A : Matrix n n  -- typically -α I
  B : Matrix n n
  C : Matrix n n
  U : Matrix n d
  dt : Float
  gamma : Float
  contraction_bound : Float  -- L ∈ [0.83, 0.95]

def contraction_factor (p : PdeRnnParams) : Float :=
  spectral_norm (I + dt * (A - gamma * I)) + dt * spectral_norm B * spectral_norm C

theorem stable_if_contraction (p : PdeRnnParams) (h : contraction_factor p < 1) :
  ∀ h₀ x, ∥step p h₀ x∥ ≤ contraction_factor p * ∥h₀∥ + O(∥x∥)
```

**Rust implementation** with spectral norm enforcement:
```rust
pub struct PdeRnn {
    a: Array2<f32>,  // -α I
    b: Array2<f32>,  // spectral norm ≤ b_target
    c: Array2<f32>,  // spectral norm ≤ c_target
    u: Array2<f32>,
    dt: f32,
    gamma: f32,
}

impl PdeRnn {
    pub fn step(&mut self, h: &Array1<f32>, x: &Array1<f32>) -> Array1<f32> {
        // Kani proof harness verifies:
        // - No panic
        // - No overflow in safe range
        // - h remains bounded if contraction holds
        let nonlinear = self.c.dot(h) + self.u.dot(x);
        let sigma = nonlinear.mapv(|v| v.tanh());
        h + self.dt * (self.a.dot(h) + self.b.dot(&sigma) - self.gamma * h)
    }

    #[kani::proof]
    fn verify_step_bounds() {
        // Exhaustively check boundedness for n ≤ 8
    }
}
```

### 3.2 Sparse Modular Memory

**Lean theorem** for coherence-bound retrieval:
```lean
theorem retrieval_correct {K D : Nat} (M : Matrix D K) (μ : Float)
    (h_coherence : ∀ i ≠ j, |M[i]ᵀ M[j]| ≤ μ)
    (S : Finset K) (r := S.card) (η : Float)
    (h_noise : ∥noise∥ ≤ η)
    (h_range : (2*r - 1)*μ + 2*η < 1)
    (τ : Float, h_tau : r*μ + η < τ < 1 - (r-1)*μ - η) :
    {k | (Mᵀ (∑_{i∈S} M[i] + noise))[k] ≥ τ} = S
```

**Rust with ANN acceleration** (Kani-verifiable):
```rust
pub struct SparseMemory {
    m: Array2<f32>,      // D x K, unit-norm columns
    memory: Array1<f32>, // accumulated D-vector
    lambda: f32,
    tau: f32,
    ann_index: Option<HnswIndex>, // FAISS or custom
}

impl SparseMemory {
    pub fn read(&self) -> Vec<usize> {
        // Kani verifies panic-freedom and threshold logic
        let scores = if let Some(idx) = &self.ann_index {
            // ANN prefilter: top-B candidates
            let candidates = idx.search(&self.memory, 256);
            candidates.iter().filter(|&k| self.score(k) >= self.tau).copied().collect()
        } else {
            self.m.t().dot(&self.memory)
                .iter()
                .enumerate()
                .filter(|(_, &v)| v >= self.tau)
                .map(|(i, _)| i)
                .collect()
        };
        scores
    }
}
```

### 3.3 FFI Boundary Safety

The FFI boundary between Rust and Lean is the **highest-risk area** [0†L22-L24]. Mitigation:

1. **Use `lean-rs` safe bindings** — not raw `lean-rs-sys` [7†L5-L9]
2. **Kani proof harnesses** for every FFI call site
3. **MIRI** for undefined behavior detection in CI
4. **repr(transparent) wrappers** with compile-time safety [5†L11-L12]

```rust
// Safe wrapper pattern
#[repr(transparent)]
pub struct LeanTheoremHandle(LeanObject);

impl LeanTheoremHandle {
    pub fn verify_contraction(&self, alpha: f32, beta: f32, gamma: f32) -> Result<bool, LeanError> {
        // lean-rs handles the unsafe FFI internally
        self.call_export("verify_contraction", (alpha, beta, gamma))
    }
}
```


## 4. Toolchain & CI Integration

### 4.1 Required Tooling

| Tool | Version | Purpose |
|------|---------|---------|
| Lean 4 | 4.26.0–4.31.0-rc1 [6†L25-L26] | Theorem proving |
| `lean-rs` | ≥0.2.0 | Safe FFI bindings |
| Rust | 2024 edition | Implementation |
| Kani | ≥0.67.0 [1†L7-L8] | Bounded model checking |
| `cargo-kani` | Locked version in CI | Kani harness runner |

### 4.2 CI Pipeline

```yaml
# .github/workflows/verify.yml
jobs:
  lean_proofs:
    runs-on: ubuntu-latest
    steps:
      - run: lake build  # Verifies all Lean theorems (0 sorry)

  kani_verification:
    runs-on: ubuntu-latest
    steps:
      - run: cargo install --locked kani-verifier --version 0.67.0
      - run: cargo kani --enable-unstable --harness

  ffi_tests:
    runs-on: ubuntu-latest
    steps:
      - run: cargo test -- --test-threads=1  # Lean FFI is single-threaded [12†L22-L23]
      - run: cargo miri test  # UB detection

  proptest:
    runs-on: ubuntu-latest
    steps:
      - run: cargo test --features proptest  # Statistical confidence
```

### 4.3 Version Pinning

> Kani is deployed in production CI at scale, with over 16,000 harnesses verified per code change in the Rust standard library verification campaign.

Lock all verification tool versions:
- `kani-verifier` version pinned in CI [1†L7-L8]
- Lean toolchain pinned via `lean-toolchain` [8†L25-L29]
- `lean-rs` version locked in `Cargo.lock`


## 5. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Lean theorem doesn't match Rust implementation | **Critical** | Kani `stub_float` strategy bridges mathematical proof to code [10†L21-L30] |
| FFI undefined behavior | **Critical** | Use `lean-rs` safe layer; Kani verifies all FFI call sites |
| Kani timeout on large `N` | **High** | Verify at natural bounds (N=8-32); proptest for larger [10†L18-L20] |
| Spectral norm enforcement overhead | **Medium** | One power iteration per optimizer step; acceptable |
| Lean 4 version compatibility | **Medium** | `lean-rs` handles version transitions [6†L25-L29] |
| Memory retrieval proof too abstract | **Medium** | Generate Kani harnesses from same obligations [11†L39-L42] |

### 5.1 Kill Criteria (Verification Edition)

In addition to spec kill criteria, abort if:
- Any Lean theorem remains `sorry` in production
- Kani verification fails on any `#[kani::proof]` harness
- FFI boundary has any `unsafe` block without a Kani harness
- `cargo miri` detects undefined behavior


## 6. Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
- [ ] Set up Lean 4 project with `lakefile.toml`
- [ ] Set up Rust project with `lean-rs` dependency
- [ ] Implement basic FFI round-trip (call Lean from Rust)
- [ ] Verify with `cargo test -- --test-threads=1`

### Phase 2: PDE-RNN Core (Weeks 3-4)
- [ ] Implement Lean specification + stability theorem
- [ ] Implement Rust `PdeRnn` with spectral norm enforcement
- [ ] Write Kani harnesses for step function (N ≤ 8)
- [ ] Verify contraction invariant with Kani + `stub_float`

### Phase 3: SMM (Weeks 5-6)
- [ ] Implement Lean coherence theorem
- [ ] Implement Rust `SparseMemory` with exact + ANN paths
- [ ] Kani verification of threshold retrieval (bounded K, r)
- [ ] proptest for statistical confidence on large K

### Phase 4: Integration (Weeks 7-8)
- [ ] Full pipeline: Lean proofs → FFI → Rust → Kani
- [ ] CI integration with all verification stages
- [ ] Performance benchmarking vs spec reference


## 7. References

- `lean-rs` FFI stack: [7†L5-L9], [8†L18-L45], [6†L5-L10]
- Kani production deployment: [1†L10-L12]
- Lean + Kani composition: [10†L5-L40], [11†L14-L42]
- Verified FFI example: [12†L4-L18]
- Provable contracts pipeline: [9†L26-L31]
