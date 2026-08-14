//! Mirror of `polyEval_quad` (Multiplicity/PolynomialProofs.lean witness
//! `polyEvalQuadWitness`): `polyEval [a, b, c] x = (a * x + b) * x + c`,
//! over the full `i64` domain with wrapping arithmetic.

use multiplicity_algebra::poly_eval;

#[kani::proof]
fn poly_eval_quad() {
    let a: i64 = kani::any();
    let b: i64 = kani::any();
    let c: i64 = kani::any();
    let x: i64 = kani::any();
    let direct = a
        .wrapping_mul(x)
        .wrapping_add(b)
        .wrapping_mul(x)
        .wrapping_add(c);
    assert_eq!(poly_eval(&[a, b, c], x), direct);
}
