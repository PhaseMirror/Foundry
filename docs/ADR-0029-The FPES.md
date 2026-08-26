# Architecture Decision Record: FPES Production Implementation

**Status**: Proposed
**Date**: 2026-08-15
**Decision ID**: ADR-FPES-001
**Domain**: Formal Verification Infrastructure

---

## Context

The Falsification-Preserving Experiment Selection (FPES) method requires a production-grade implementation that guarantees:

1. **Lean 4 proofs** of unbounded mathematical correctness (the `∀ x ∈ ℝⁿ` property)
2. **Kani verification** that the Rust implementation matches the Lean specification for bounded inputs
3. **Zero runtime escape**—the compiler must refuse to produce a binary if any proof obligation is unfulfilled

The gap between Lean's mathematical reals and Rust's `f32`/`f64` is the primary failure mode this ADR addresses. Lean proves properties over ℝ; Rust implements them with IEEE floats that overflow, underflow, and accumulate ULP errors .

---

## Decision Drivers

1. **No `sorry` in production**—every Lean theorem must be machine-checked
2. **Kani harnesses must pass** for all natural bounds (e.g., vector length ≤ 8 for SIMD kernels)
3. **FFI safety**—Lean↔Rust cross-call boundaries must preserve the proof contract
4. **Local runtime**—`make kani-full` must complete in developer time
5. **Escape-proof enforcement**—violating a contract must make compilation impossible, not merely difficult

---

## Decision

We will implement FPES using the **provable-contracts seven-phase pipeline** :

```text
Extract → Specify → Scaffold → Implement → Falsify → Verify → Prove
```

### 1. Specification Layer (YAML Contract)

Each proof obligation is encoded in YAML with **both** a Lean theorem obligation and a Kani harness definition :

```yaml
proof_obligations:
  - id: FPES-MULTIPLICITY-001
    type: invariant
    property: "Path multiplicity m(path) > 0 for all equivalence classes"
    formal: "∀ c ∈ Classes, |{p ∈ Paths : p ↝ c}| ≥ 1"
    lean:
      theorem: FPES.multiplicity_nonzero
      status: unproved
    kani_harnesses:
      - id: KANI-FPES-001
        obligation: FPES-MULTIPLICITY-001
        property: "multiplicity_count() returns > 0 for |Paths| ≤ N"
        bound: 8
        strategy: stub_float_on_transcendentals
```

### 2. Lean 4 Proof Layer (Unbounded Correctness)

The Lean theorem proves the mathematical property **for all inputs**, assuming infinite precision :

```lean
-- From leonardoalt/circuit-lean-rust-ffi pattern
theorem multiplicity_preserved_under_contraction
  (H : HypothesisSpace)
  (c : ContractionOperator)
  (h_bound : operator_norm c < 1)
  (h_survival : survival_invariant H)
  : ∀ p : Path, p ∈ H.paths →
      ∃ p' : Path, p' ∈ c(H).paths ∧ equivalent_mechanism p p' :=
begin
  -- Lean kernel checks this at compile time
  sorry -- Must be replaced with actual proof
end

@[export]
def lean_multiplicity_check (h_ptr : LeanPtr HypothesisSpace) : LeanPtr Bool :=
  -- Exported C ABI symbol, callable from Rust via FFI
  ...
```

**Key requirement**: The Lean theorem must have **no `sorry`** . The kernel rejects incomplete proofs.

### 3. Kani Verification Layer (Bounded Real-Code Correctness)

Kani verifies the **actual Rust implementation**—with all float edge cases—for bounded inputs :

```rust
// From xpile/contracts/kani/xlate_lean_to_rust.rs pattern
#[kani::proof]
fn multiplicity_count_preserved_under_contraction() {
    // Symbolic arbitrary HypothesisSpace up to size N
    let h: HypothesisSpace = kani::any();

    // Bound the space size for Kani tractability
    kani::assume(h.paths.len() <= 8);
    kani::assume(h.classes.len() <= 8);

    // Run the actual production code
    let pruned = contraction_operator(&h);

    // Verify the invariant
    let survival = multiplicity_survives(&h, &pruned);
    kani::assert(survival,
        "Every equivalence class must retain at least one path");
}
```

### 4. FFI Bridge (Lean ↔ Rust)

String/opaque data crossing the FFI boundary requires careful handling . Use the established pattern:

```rust
// Mimic Lean's memory layout with #[repr(C)]
#[repr(C)]
struct LeanStringObject {
    header: lean_object,
    m_size: usize,
    m_capacity: usize,
    m_length: usize,
    m_data: [c_char; 0], // flexible array member
}

// Or use the C shim approach for stability
extern "C" {
    fn lean_string_cstr(obj: *mut lean_object) -> *const c_char;
}

#[no_mangle]
pub extern "C" fn fpes_check_paths(
    h_ptr: *mut lean_object,  // Lean HypothesisSpace
) -> u8 {
    // Cast via C shim or direct layout
    let paths = unsafe { lean_string_cstr(h_ptr) };
    // ... verification logic ...
}
```

For opaque types, register with `lean_register_external_class` .

### 5. Build System Enforcement

The `build.rs` script **must** gate binary production :

```rust
// build.rs
fn main() {
    // Phase 1: Validate YAML contracts
    let status = std::process::Command::new("pv")
        .args(["lint", "contracts/fpes.yaml"])
        .status()
        .unwrap();
    assert!(status.success(), "YAML contract validation failed");

    // Phase 2: Check Lean proofs have no sorry
    let lean_status = std::process::Command::new("pv")
        .args(["lean-status", "contracts/"])
        .status()
        .unwrap();
    assert!(lean_status.success(), "Lean proofs incomplete");

    // Phase 3: Generate Rust trait stubs and Kani harnesses
    let scaffold = std::process::Command::new("pv")
        .args(["scaffold", "contracts/fpes.yaml"])
        .status()
        .unwrap();
    assert!(scaffold.success());

    // Phase 4: Enable CONTRACT_* environment for debug_assert! injection
    println!("cargo:rustc-env=CONTRACT_FPES=1");
}
```

### 6. Runtime Debug Assertions

The `#[contract]` macro injects `debug_assert!` at call sites :

```rust
#[contract]
fn prune_hypotheses<T: ContractBound>(
    space: &mut HypothesisSpace<T>,
    policy: &SelectionPolicy,
) -> Result<(), PruneError> {
    // Injected by macro: checks CONTRACT_FPES env
    // debug_assert!(space.paths.len() > 0);
    // debug_assert!(multiplicity_survives(space, policy));
    // ... actual implementation ...
}
```

---

## Alternatives Considered

| Option | Rejected Because |
|--------|------------------|
| Lean only, no Kani | Misses float/overflow edge cases; ℝ ≠ f32  |
| Kani only, no Lean | Cannot verify unbounded mathematical properties |
| Proptest instead of Kani | Probabilistic; cannot provide proof certificates |
| FFI via JSON serialization | Slower; loses type safety at boundary |

---

## Consequences

### Positive
- **Complete verification ladder**: unbounded (Lean) + bounded real-code (Kani) + runtime checks
- **Escape-proof**: compiler refuses binary on proof failure
- **Production-viable**: Kani bounds kept small (≤8 nodes) for local runtime

### Negative
- Build time increases significantly (Lean kernel check + Kani model checking)
- FFI boundary remains unsafe; requires careful `#[repr(C)]` layout or C shims
- Kani cannot reason about `f32::exp()` natively—requires `stub_float` strategy

### Mitigations
- Use `cfg(kani)` compatibility layers to replace HashMap with fixed arrays
- Delegate >N graph coverage to Proptest for statistical confidence
- Use `lean4export` for independent re-checking of proofs

---

## Implementation Roadmap

| Phase | Deliverable | Verification |
|-------|-------------|--------------|
| 1 | YAML contract for FPES invariants | `pv lint` passes |
| 2 | Lean 4 theorem stubs | Lean kernel accepts (no `sorry`) |
| 3 | Kani harnesses for N≤8 | `cargo kani` passes |
| 4 | FFI bridge (Lean↔Rust) | Roundtrip property tests pass |
| 5 | build.rs gating | Binary fails to link if proof incomplete |
| 6 | Runtime assertions | `cargo test` enforces invariants |

---

## References

- [Provable Contracts Methodology](https://github.com/paiml/provable-contracts)
- [Lean + Kani Composition Specification](https://github.com/paiml/provable-contracts/blob/main/docs/specifications/sub/lean-kani-composition.md)
- [Verified Arithmetic Circuit Simplifier (Lean + Rust FFI)](https://github.com/leonardoalt/circuit-lean-rust-ffi)
- [Xpile Lean-to-Rust Lowering Kani Proofs](https://github.com/paiml/xpile/blob/main/contracts/kani/xlate_lean_to_rust.rs)
- [Lean String FFI Memory Layout](https://leanprover-community.github.io/archive/stream/270676-lean4/topic/Issue.20with.20String.20marshalling.20between.20Lean.20and.20Rust.20FFI.html)
- [Bounded Kani Harnesses ADR](https://github.com/leynos/netsuke/blob/main/docs/adr-004-bound-kani-ir-harnesses-to-small-n.md)
