//! Mirror of `dvd_trans` (Multiplicity/NumberTheory.lean witness
//! `dvdTransWitness`): `a ∣ b` and `b ∣ c` imply `a ∣ c`.

use multiplicity_core::divides;

#[kani::proof]
fn dvd_trans() {
    let a: u64 = kani::any();
    let b: u64 = kani::any();
    let c: u64 = kani::any();
    if divides(a, b) && divides(b, c) {
        assert!(divides(a, c));
    }
}
