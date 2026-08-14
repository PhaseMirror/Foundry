//! Mirror of `int_div_mul_add_mod` (Multiplicity/NumberTheory.lean witness
//! `intDivMulAddModWitness`): `a / b * b + a % b = a`, with wrapping
//! arithmetic (the Lean statement is in unbounded `Int`).  Verified on a
//! bounded domain — symbolic 64-bit division is intractable; the zero-divisor
//! and `i64::MIN / -1` edges are pinned by the deterministic regression vector
//! `kani/regression/int_div_mod.json`.

use multiplicity_core::int_div_mod;

#[kani::proof]
fn int_div_mul_add_mod() {
    let a: i64 = kani::any();
    let b: i64 = kani::any();
    kani::assume(a > -65536 && a < 65536 && b > -65536 && b < 65536);
    let (q, r) = int_div_mod(a, b);
    assert_eq!(q.wrapping_mul(b).wrapping_add(r), a);
}
