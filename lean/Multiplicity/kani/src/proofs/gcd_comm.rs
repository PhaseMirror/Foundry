//! Mirror of `gcd_comm` (Multiplicity/NumberTheory.lean witness
//! `gcdCommWitness`): `gcd a b = gcd b a`, bounded `u64` domain (symbolic 64-bit division in Euclid's loop is intractable; the domain `0..65536` keeps the lattice laws exact, matching the unbounded `Nat` statement modulo the finite type).

use multiplicity_algebra::gcd_comm;

#[kani::proof]
fn gcd_comm_check() {
    let a: u64 = kani::any();
    let b: u64 = kani::any();
    kani::assume(a < 65536 && b < 65536);
    assert!(gcd_comm(a, b));
}
