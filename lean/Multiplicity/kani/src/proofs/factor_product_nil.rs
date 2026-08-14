//! Mirror of `factorProduct_nil` (Multiplicity/NumberTheory.lean witness
//! `factorProductNilWitness`): the product of the empty factor list is one.

use multiplicity_primes::factor_product;

#[kani::proof]
fn factor_product_nil() {
    assert_eq!(factor_product(&[]), 1);
}
