//! Mirror of `int_mod_nonneg` (Multiplicity/NumberTheory.lean witness
//! `intModNonnegWitness`): a non-zero divisor yields a non-negative remainder
//! (Euclidean division).  Verified on a bounded domain — symbolic 64-bit
//! division is intractable; the `i64::MIN / -1` and zero-divisor edges are
//! pinned by `kani/regression/int_div_mod.json`.

use multiplicity_core::int_div_mod;

#[kani::proof]
fn int_mod_nonneg() {
    let a: i64 = kani::any();
    let b: i64 = kani::any();
    kani::assume(b != 0 && a > -65536 && a < 65536 && b > -65536 && b < 65536);
    let (_, r) = int_div_mod(a, b);
    assert!(r >= 0);
}
