//! monodial_ensemble_aggregation – minimal example with a Kani proof.

/// Returns true for any input.
pub fn always_true<T>(_x: T) -> bool { true }

use kani::{any, assert};

#[kani::proof]
fn proof_always_true() {
    // Choose any value of any type (use u8 for simplicity).
    let v: u8 = any();
    assert(always_true(v) == true, "always_true must be true");
}
