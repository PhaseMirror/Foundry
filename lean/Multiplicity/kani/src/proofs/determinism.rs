//! Mirror of `deterministic_of_any` (Multiplicity/Kernel.lean): the factorial
//! is deterministic (same input, same output) on a bounded domain.

use multiplicity_core::{factorial, is_deterministic};

#[kani::proof]
#[kani::unwind(64)]
fn determinism() {
    let n: u64 = kani::any();
    kani::assume(n < 64);
    assert!(is_deterministic(factorial, n));
}
