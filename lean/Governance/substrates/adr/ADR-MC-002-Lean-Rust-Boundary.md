# ADR-MC-002: Lean-to-Rust Boundary

## Status
Proposed

## Context
To achieve "Double-Lock" stability, we must ensure that the high-performance execution in Rust is semantically equivalent to the formal proofs in Lean 4. This is particularly critical for the Goldilocks arithmetic and the contractive update rules.

## Decision
We will implement a rigorous boundary protocol between Lean 4 (The Law) and Rust (The Engine).

### 1. Formal Correspondence
- **Deterministic Reduction**: All Rust-based arithmetic (e.g., Goldilocks field operations) must pass a formal equivalence check against the Lean 4 reference implementation.
- **Invariant Mirroring**: Any invariant defined in `Stability.lean` (e.g., $|k| < 1$) must be enforced at runtime in `lib.rs` with a fail-closed mechanism.

### 2. The Verification Bridge
- **FTSA Hashing**: We will use a shared hashing scheme (PWEH) to ensure that state digests generated in Rust are consistent with those analyzed in Lean.
- **Proof Attestation**: Every MultiplicityCell boot will require a `ProofAttestation` (generated during CI) that links the current Rust binary hash to a successful Lean verification run.

### 3. C-ABI Surface
The Rust core will expose a stable C-ABI to allow Lean (and other languages) to call the high-performance execution paths securely:
```rust
#[no_mangle]
pub extern "C" fn mc_run_kernel(input_ptr: *const f64, len: usize, out_ptr: *mut f64) -> i32;
```

## Consequences
- **Zero Semantic Drift**: Ensures that "The Law" is always what is executed.
- **Tooling Complexity**: Requires a sophisticated CI pipeline to manage cross-language verification.
