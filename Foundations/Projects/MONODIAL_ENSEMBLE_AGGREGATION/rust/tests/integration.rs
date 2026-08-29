//! Integration tests for MEA framework.
//!
//! These tests verify end-to-end functionality and serve as examples
//! for library consumers.

use monodial_ensemble_aggregation::{
    error::Error,
    ensemble::{Ensemble, WeightedElement},
    aggregate::{AggregateOp, aggregate, AggregationResult},
    verify::{AlgebraicLaw, verify_law, verify_all_laws},
    monodial::{MonoidalCategory, MonoidalObject, MonoidalMorphism},
};

#[test]
fn test_monoidal_object() {
    let obj = MonoidalObject::new(42, "test");
    assert_eq!(obj.id(), 42);
    assert_eq!(obj.label(), "test");
}

#[test]
fn test_monoidal_morphism() {
    let morph = MonoidalMorphism::new(1, 10, 20);
    assert_eq!(morph.source(), 10);
    assert_eq!(morph.target(), 20);
}

#[test]
fn test_monoidal_category_operations() {
    let mut cat = MonoidalCategory::new(0);
    cat.add_object(MonoidalObject::new(0, "I"));
    cat.add_object(MonoidalObject::new(1, "A"));
    cat.add_object(MonoidalObject::new(2, "B"));
    cat.add_tensor_product(1, 2, 3);
    assert!(cat.verify_associativity());
    assert!(cat.verify_left_unital());
    assert!(cat.verify_right_unital());
}

#[test]
fn test_ensemble_weighted_average() {
    let mut ensemble: Ensemble<i32> = Ensemble::new(1);
    ensemble.add(WeightedElement::new(10, 0.3));
    ensemble.add(WeightedElement::new(20, 0.7));
    let avg = ensemble.weighted_average().unwrap();
    assert!((avg - 17.0).abs() < 1e-10);
}

#[test]
fn test_ensemble_tensor_product() {
    let mut e1: Ensemble<i32> = Ensemble::new(1);
    e1.add(WeightedElement::new(1, 0.5));
    let mut e2: Ensemble<i32> = Ensemble::new(2);
    e2.add(WeightedElement::new(2, 0.5));
    let result = e1.tensor_product(&e2).unwrap();
    assert!(!result.is_empty());
    assert_eq!(result.id(), 1002);
}

#[test]
fn test_aggregate_sum() {
    let mut ensemble: Ensemble<i32> = Ensemble::new(1);
    ensemble.add(WeightedElement::new(10, 1.0));
    ensemble.add(WeightedElement::new(20, 1.0));
    let result = aggregate(&ensemble, AggregateOp::Sum).unwrap();
    assert_eq!(result.value(), 30.0);
}

#[test]
fn test_aggregate_max() {
    let mut ensemble: Ensemble<i32> = Ensemble::new(1);
    ensemble.add(WeightedElement::new(10, 1.0));
    ensemble.add(WeightedElement::new(20, 1.0));
    ensemble.add(WeightedElement::new(5, 1.0));
    let result = aggregate(&ensemble, AggregateOp::Max).unwrap();
    assert_eq!(result.value(), 20.0);
}

#[test]
fn test_aggregate_min() {
    let mut ensemble: Ensemble<i32> = Ensemble::new(1);
    ensemble.add(WeightedElement::new(10, 1.0));
    ensemble.add(WeightedElement::new(20, 1.0));
    ensemble.add(WeightedElement::new(5, 1.0));
    let result = aggregate(&ensemble, AggregateOp::Min).unwrap();
    assert_eq!(result.value(), 5.0);
}

#[test]
fn test_aggregate_empty_ensemble_fails() {
    let ensemble: Ensemble<i32> = Ensemble::new(1);
    let result = aggregate(&ensemble, AggregateOp::Sum);
    assert!(result.is_err());
}

#[test]
fn test_verify_associativity_law() {
    let mut a: Ensemble<i32> = Ensemble::new(1);
    a.add(WeightedElement::new(1, 1.0));
    let mut b: Ensemble<i32> = Ensemble::new(2);
    b.add(WeightedElement::new(2, 1.0));
    let mut c: Ensemble<i32> = Ensemble::new(3);
    c.add(WeightedElement::new(3, 1.0));
    let result = verify_law(AlgebraicLaw::Associativity, &a, &b, Some(&c));
    assert!(result.passed());
}

#[test]
fn test_verify_all_laws() {
    let mut a: Ensemble<i32> = Ensemble::new(1);
    a.add(WeightedElement::new(1, 1.0));
    let mut b: Ensemble<i32> = Ensemble::new(2);
    b.add(WeightedElement::new(2, 1.0));
    let results = verify_all_laws(&[a, b]);
    assert!(!results.is_empty());
    assert!(results.iter().all(|r| r.passed()));
}

#[test]
fn test_probability_distribution() {
    let mut ensemble: Ensemble<i32> = Ensemble::new(1);
    ensemble.add(WeightedElement::new(1, 0.5));
    ensemble.add(WeightedElement::new(2, 0.5));
    assert!(ensemble.verify_probability_distribution());
}

#[test]
fn test_error_types() {
    let err = Error::monoidal_invariant("test");
    assert!(err.to_string().contains("test"));

    let err2 = Error::law_verification("associativity");
    assert!(err2.to_string().contains("associativity"));
}

#[test]
fn test_aggregation_result() {
    let result = AggregationResult::new(42.0, AggregateOp::Sum, 0.9);
    assert_eq!(result.value(), 42.0);
    assert_eq!(result.operation(), AggregateOp::Sum);
    assert_eq!(result.confidence(), 0.9);
}
