//! Mirror of `gcd_dvd_left` (Multiplicity/NumberTheory.lean witness
//! `gcdDvdLeftWitness`): `gcd a b ∣ a`, bounded `u64` domain (symbolic 64-bit division in Euclid's loop is intractable; the domain `0..65536` keeps the lattice laws exact, matching the unbounded `Nat` statement modulo the finite type).

use multiplicity_algebra::gcd;
use multiplicity_core::divides;

#[kani::proof]
fn gcd_dvd_left() {
    let a: u64 = kani::any();
    let b: u64 = kani::any();
    kani::assume(a < 65536 && b < 65536);
    assert!(divides(gcd(a, b), a));
}
