//! Mirror of `dvd_refl` (Multiplicity/NumberTheory.lean witness
//! `dvdReflWitness`): `a ∣ a` for every `a`.

use multiplicity_core::divides;

#[kani::proof]
fn dvd_refl() {
    let a: u64 = kani::any();
    assert!(divides(a, a));
}
