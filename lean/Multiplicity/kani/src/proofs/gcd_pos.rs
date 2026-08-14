//! Mirror of `gcd_pos` (Multiplicity/NumberTheory.lean witness
//! `gcdPosWitness`): a positive input yields a positive gcd.

use multiplicity_algebra::gcd;

#[kani::proof]
fn gcd_pos() {
    let a: u64 = kani::any();
    let b: u64 = kani::any();
    kani::assume(a < 65536 && b < 65536);
    if a != 0 {
        assert!(gcd(a, b) != 0);
    }
}
