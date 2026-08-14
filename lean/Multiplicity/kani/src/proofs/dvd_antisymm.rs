//! Mirror of `dvd_antisymm` (Multiplicity/NumberTheory.lean witness
//! `dvdAntisymmWitness`): mutual divisibility forces equality.

use multiplicity_core::divides;

#[kani::proof]
fn dvd_antisymm() {
    let m: u64 = kani::any();
    let n: u64 = kani::any();
    if divides(m, n) && divides(n, m) {
        assert_eq!(m, n);
    }
}
