//! Hcqa – a tiny example module with a simple parity check and Kani verification.
//!
//! The purpose of this crate is to provide a concrete, verifiable implementation
//! for the placeholder Lean file `Hcqa.lean`.  We model a very simple function
//! that determines whether a 64‑bit integer is even.

/// Returns true iff `n` is even.
pub fn is_even(n: u64) -> bool {
    n % 2 == 0
}

// Bring Kani utilities into scope for the proof harness.
use kani::{any, assert};

/// Kani proof that `is_even` correctly reflects the parity of `n`.
/// For any nondeterministic input `n`, the function must return the exact
/// result of the `% 2` test.
#[kani::proof]
fn proof_is_even_correct() {
    let n: u64 = any();
    let result = is_even(n);
    // The expression `n % 2 == 0` is the specification.
    assert(result == (n % 2 == 0), "is_even must match parity test");
}

