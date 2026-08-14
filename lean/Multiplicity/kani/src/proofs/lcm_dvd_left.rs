//! Mirror of `lcm_dvd_left` (Multiplicity/NumberTheory.lean witness
//! `lcmDvdLeftWitness`): `a ∣ lcm a b`, on a bounded domain so the
//! saturating `lcm` cannot overflow (the Lean statement is in unbounded `Nat`).

use multiplicity_algebra::lcm;
use multiplicity_core::divides;

#[kani::proof]
fn lcm_dvd_left() {
    let a: u64 = kani::any();
    let b: u64 = kani::any();
    kani::assume(a < 1024 && b < 1024);
    assert!(divides(a, lcm(a, b)));
}
