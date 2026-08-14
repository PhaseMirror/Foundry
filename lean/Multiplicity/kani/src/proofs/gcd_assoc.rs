//! Mirror of `gcd_assoc` (Multiplicity/NumberTheory.lean witness
//! `gcdAssocWitness`): `gcd (gcd a b) c = gcd a (gcd b c)`, bounded `u64` domain (symbolic 64-bit division in Euclid's loop is intractable; the domain `0..65536` keeps the lattice laws exact, matching the unbounded `Nat` statement modulo the finite type).

use multiplicity_algebra::gcd_assoc;

#[kani::proof]
fn gcd_assoc_check() {
    let a: u64 = kani::any();
    let b: u64 = kani::any();
    let c: u64 = kani::any();
    kani::assume(a < 65536 && b < 65536 && c < 65536);
    assert!(gcd_assoc(a, b, c));
}
