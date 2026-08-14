//! Mirror of `dvd_iff_mod_eq_zero` (Multiplicity/NumberTheory.lean witness
//! `dvdIffModWitness`): divisibility agrees with a zero remainder.  Rust `%`
//! panics on a zero divisor, so the `m = 0` case follows the Lean convention
//! `0 ∣ n ↔ n = 0` (`n % 0 = 0` in `Nat`).  Verified on a bounded domain
//! (symbolic 64-bit division is intractable for the solver).

use multiplicity_core::divides;

#[kani::proof]
fn dvd_iff_mod() {
    let m: u64 = kani::any();
    let n: u64 = kani::any();
    kani::assume(m < 65536 && n < 65536);
    if m == 0 {
        assert_eq!(divides(m, n), n == 0);
    } else {
        assert_eq!(divides(m, n), n % m == 0);
    }
}
