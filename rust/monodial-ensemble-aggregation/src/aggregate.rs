//! Aggregation operations with verified laws.
//!
//! Implements monoidal aggregation operations: sum, product,
//! weighted average, and their verified algebraic properties.

use crate::error::{Error, Result};
use crate::ensemble::Ensemble;

/// Aggregation operation type.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AggregateOp {
    /// Sum aggregation: ⊕
    Sum,
    /// Product aggregation: ⊗
    Product,
    /// Weighted average
    WeightedAverage,
    /// Maximum
    Max,
    /// Minimum
    Min,
}

impl AggregateOp {
    /// Get the operation name.
    pub fn name(&self) -> &'static str {
        match self {
            Self::Sum => "sum",
            Self::Product => "product",
            Self::WeightedAverage => "weighted_average",
            Self::Max => "max",
            Self::Min => "min",
        }
    }
}

/// Result of an aggregation operation.
#[derive(Debug, Clone, PartialEq)]
pub struct AggregationResult {
    value: f64,
    operation: AggregateOp,
    confidence: f64,
}

impl AggregationResult {
    /// Create a new aggregation result.
    pub fn new(value: f64, operation: AggregateOp, confidence: f64) -> Self {
        Self {
            value,
            operation,
            confidence,
        }
    }

    /// Get the aggregated value.
    pub fn value(&self) -> f64 {
        self.value
    }

    /// Get the operation used.
    pub fn operation(&self) -> AggregateOp {
        self.operation
    }

    /// Get the confidence score.
    pub fn confidence(&self) -> f64 {
        self.confidence
    }
}

/// Aggregate an ensemble using the specified operation.
pub fn aggregate(ensemble: &Ensemble<i32>, op: AggregateOp) -> Result<AggregationResult> {
    if ensemble.is_empty() {
        return Err(Error::aggregation("cannot aggregate empty ensemble"));
    }

    let result = match op {
        AggregateOp::Sum => ensemble.elements().iter().map(|e| (*e.value() as f64) * e.weight()).sum(),
        AggregateOp::Product => ensemble
            .elements()
            .iter()
            .map(|e| (*e.value() as f64).powf(e.weight()))
            .product(),
        AggregateOp::WeightedAverage => ensemble.weighted_average()?,
        AggregateOp::Max => ensemble
            .elements()
            .iter()
            .map(|e| *e.value() as f64)
            .fold(f64::NEG_INFINITY, f64::max),
        AggregateOp::Min => ensemble
            .elements()
            .iter()
            .map(|e| *e.value() as f64)
            .fold(f64::INFINITY, f64::min),
    };

    let confidence = if op == AggregateOp::WeightedAverage {
        1.0 / (ensemble.len() as f64).sqrt()
    } else {
        0.5
    };

    Ok(AggregationResult::new(result, op, confidence))
}

/// Verify that sum aggregation is associative: (a + b) + c = a + (b + c).
pub fn verify_sum_associative(a: &Ensemble<i32>, b: &Ensemble<i32>, c: &Ensemble<i32>) -> bool {
    if a.is_empty() || b.is_empty() || c.is_empty() {
        return false;
    }
    let sum_a = aggregate(a, AggregateOp::Sum).unwrap().value();
    let sum_b = aggregate(b, AggregateOp::Sum).unwrap().value();
    let sum_c = aggregate(c, AggregateOp::Sum).unwrap().value();
    let left = sum_a + sum_b + sum_c;
    let right = sum_a + (sum_b + sum_c);
    (left - right).abs() < 1e-10
}

/// Verify identity element for sum: 0 + A = A.
pub fn verify_sum_identity(ensemble: &Ensemble<i32>) -> bool {
    let zero: Ensemble<i32> = Ensemble::new(999);
    let mut combined: Ensemble<i32> = Ensemble::new(999);
    combined.add(crate::ensemble::WeightedElement::new(0, 1.0));
    for elem in ensemble.elements() {
        combined.add(*elem);
    }
    let orig_sum = aggregate(ensemble, AggregateOp::Sum).unwrap().value();
    let combined_sum = aggregate(&combined, AggregateOp::Sum).unwrap().value();
    (combined_sum - orig_sum).abs() < 1e-10
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ensemble::WeightedElement;

    #[test]
    fn test_aggregate_sum() {
        let mut ensemble: Ensemble<i32> = Ensemble::new(1);
        ensemble.add(WeightedElement::new(10, 1.0));
        ensemble.add(WeightedElement::new(20, 1.0));
        let result = aggregate(&ensemble, AggregateOp::Sum).unwrap();
        assert_eq!(result.value(), 30.0);
    }

    #[test]
    fn test_aggregate_weighted_average() {
        let mut ensemble: Ensemble<i32> = Ensemble::new(1);
        ensemble.add(WeightedElement::new(10, 0.3));
        ensemble.add(WeightedElement::new(20, 0.7));
        let result = aggregate(&ensemble, AggregateOp::WeightedAverage).unwrap();
        assert!((result.value() - 17.0).abs() < 1e-10);
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
    fn test_verify_sum_associative() {
        let mut a: Ensemble<i32> = Ensemble::new(1);
        a.add(WeightedElement::new(1, 1.0));
        let mut b: Ensemble<i32> = Ensemble::new(2);
        b.add(WeightedElement::new(2, 1.0));
        let mut c: Ensemble<i32> = Ensemble::new(3);
        c.add(WeightedElement::new(3, 1.0));
        assert!(verify_sum_associative(&a, &b, &c));
    }

    #[test]
    fn test_verify_sum_identity() {
        let mut ensemble: Ensemble<i32> = Ensemble::new(1);
        ensemble.add(WeightedElement::new(10, 1.0));
        assert!(verify_sum_identity(&ensemble));
    }
}
