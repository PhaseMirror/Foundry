//! Kani formal verification proofs for MEA.
//!
//! These proofs verify the algebraic laws of monoidal ensemble aggregation
//! using bit-precise model checking.

#[cfg(kani)]
use crate::ensemble::{Ensemble, WeightedElement};
#[cfg(kani)]
use crate::aggregate::{AggregateOp, verify_sum_associative, verify_sum_identity};
#[cfg(kani)]
use crate::verify::{AlgebraicLaw, verify_law};
#[cfg(kani)]
use crate::monodial::MonoidalCategory;

/// Kani proof: Ensemble weighted average is within bounds.
#[cfg(kani)]
#[kani::proof]
fn kani_ensemble_weighted_average_bounds() {
    let w1: f64 = kani::assume(w1 > 0.0 && w1 <= 1.0);
    let w2: f64 = kani::assume(w2 > 0.0 && w2 <= 1.0);
    let v1: i32 = kani::assume(v1 >= -1000 && v1 <= 1000);
    let v2: i32 = kani::assume(v2 >= -1000 && v2 <= 1000);

    let mut ensemble: Ensemble<i32> = Ensemble::new(1);
    ensemble.add(WeightedElement::new(v1, w1));
    ensemble.add(WeightedElement::new(v2, w2));

    if let Ok(avg) = ensemble.weighted_average() {
        assert!(avg.is_finite());
        assert!(avg >= v1.min(v2) as f64);
        assert!(avg <= v1.max(v2) as f64);
    }
}

/// Kani proof: Sum aggregation is commutative.
#[cfg(kani)]
#[kani::proof]
fn kani_sum_commutative() {
    let v1: i32 = kani::assume(v1 >= -100 && v1 <= 100);
    let v2: i32 = kani::assume(v2 >= -100 && v2 <= 100);

    let mut e1: Ensemble<i32> = Ensemble::new(1);
    e1.add(WeightedElement::new(v1, 1.0));
    e1.add(WeightedElement::new(v2, 1.0));

    let mut e2: Ensemble<i32> = Ensemble::new(2);
    e2.add(WeightedElement::new(v2, 1.0));
    e2.add(WeightedElement::new(v1, 1.0));

    let sum1 = aggregate(&e1, AggregateOp::Sum).unwrap().value();
    let sum2 = aggregate(&e2, AggregateOp::Sum).unwrap().value();

    assert!((sum1 - sum2).abs() < 1e-10);
}

/// Kani proof: Sum aggregation is associative.
#[cfg(kani)]
#[kani::proof]
fn kani_sum_associative() {
    let v1: i32 = kani::assume(v1 >= -100 && v1 <= 100);
    let v2: i32 = kani::assume(v2 >= -100 && v2 <= 100);
    let v3: i32 = kani::assume(v3 >= -100 && v3 <= 100);

    let mut a: Ensemble<i32> = Ensemble::new(1);
    a.add(WeightedElement::new(v1, 1.0));
    let mut b: Ensemble<i32> = Ensemble::new(2);
    b.add(WeightedElement::new(v2, 1.0));
    let mut c: Ensemble<i32> = Ensemble::new(3);
    c.add(WeightedElement::new(v3, 1.0));

    assert!(verify_sum_associative(&a, &b, &c));
}

/// Kani proof: Sum identity element.
#[cfg(kani)]
#[kani::proof]
fn kani_sum_identity() {
    let v: i32 = kani::assume(v >= -100 && v <= 100);

    let mut ensemble: Ensemble<i32> = Ensemble::new(1);
    ensemble.add(WeightedElement::new(v, 1.0));

    assert!(verify_sum_identity(&ensemble));
}

/// Kani proof: Monoidal category associativity.
#[cfg(kani)]
#[kani::proof]
fn kani_monoidal_associativity() {
    let mut cat = MonoidalCategory::new(0);
    cat.add_tensor_product(1, 2, 3);
    cat.add_tensor_product(3, 4, 5);
    cat.add_tensor_product(1, 6, 7);
    assert!(cat.verify_associativity());
}

/// Kani proof: Monoidal left unital law.
#[cfg(kani)]
#[kani::proof]
fn kani_monoidal_left_unital() {
    let mut cat = MonoidalCategory::new(0);
    cat.add_tensor_product(0, 1, 1);
    assert!(cat.verify_left_unital());
}

/// Kani proof: Monoidal right unital law.
#[cfg(kani)]
#[kani::proof]
fn kani_monoidal_right_unital() {
    let mut cat = MonoidalCategory::new(0);
    cat.add_tensor_product(1, 0, 1);
    assert!(cat.verify_right_unital());
}

/// Kani proof: Tensor product preserves ensemble structure.
#[cfg(kani)]
#[kani::proof]
fn kani_tensor_product_preserves_structure() {
    let mut e1: Ensemble<i32> = Ensemble::new(1);
    e1.add(WeightedElement::new(1, 0.5));
    let mut e2: Ensemble<i32> = Ensemble::new(2);
    e2.add(WeightedElement::new(2, 0.5));

    let result = e1.tensor_product(&e2).unwrap();
    assert!(!result.is_empty());
    assert_eq!(result.id(), 1001);
}

/// Kani proof: Probability distribution weights sum to 1.
#[cfg(kani)]
#[kani::proof]
fn kani_probability_distribution_weights() {
    let w1: f64 = kani::assume(w1 > 0.0 && w1 < 1.0);
    let w2: f64 = kani::assume(w2 > 0.0 && w2 < 1.0);

    let mut ensemble: Ensemble<i32> = Ensemble::new(1);
    ensemble.add(WeightedElement::new(1, w1));
    ensemble.add(WeightedElement::new(2, w2));

    // For this to be a probability distribution, weights must sum to 1
    // We verify the property holds when weights sum to 1
    if (w1 + w2 - 1.0).abs() < 1e-10 {
        assert!(ensemble.verify_probability_distribution());
    }
}

/// Kani proof: Aggregation result has valid confidence.
#[cfg(kani)]
#[kani::proof]
fn kani_aggregation_confidence() {
    let mut ensemble: Ensemble<i32> = Ensemble::new(1);
    ensemble.add(WeightedElement::new(1, 1.0));
    ensemble.add(WeightedElement::new(2, 1.0));

    let result = aggregate(&ensemble, AggregateOp::WeightedAverage).unwrap();
    assert!(result.confidence() > 0.0);
    assert!(result.confidence() <= 1.0);
}
