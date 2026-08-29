//! Ensemble types and combination operations.
//!
//! Defines weighted ensembles, combination strategies, and
//! verified ensemble algebra.

use crate::error::{Error, Result};

/// A weighted element in an ensemble.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct WeightedElement<T> {
    value: T,
    weight: f64,
}

impl<T> WeightedElement<T> {
    /// Create a new weighted element.
    pub fn new(value: T, weight: f64) -> Self {
        Self { value, weight }
    }

    /// Get the value.
    pub fn value(&self) -> &T {
        &self.value
    }

    /// Get the weight.
    pub fn weight(&self) -> f64 {
        self.weight
    }
}

/// An ensemble of weighted elements.
#[derive(Debug, Clone, PartialEq)]
pub struct Ensemble<T> {
    elements: Vec<WeightedElement<T>>,
    id: u64,
}

impl<T> Ensemble<T> {
    /// Create a new empty ensemble.
    pub fn new(id: u64) -> Self {
        Self {
            elements: Vec::new(),
            id,
        }
    }

    /// Add an element to the ensemble.
    pub fn add(&mut self, element: WeightedElement<T>) {
        self.elements.push(element);
    }

    /// Get the ensemble ID.
    pub fn id(&self) -> u64 {
        self.id
    }

    /// Get all elements.
    pub fn elements(&self) -> &[WeightedElement<T>] {
        &self.elements
    }

    /// Get the number of elements.
    pub fn len(&self) -> usize {
        self.elements.len()
    }

    /// Check if empty.
    pub fn is_empty(&self) -> bool {
        self.elements.is_empty()
    }

    /// Compute the total weight.
    pub fn total_weight(&self) -> f64 {
        self.elements.iter().map(|e| e.weight()).sum()
    }

    /// Compute the weighted average (for numeric types).
    pub fn weighted_average(&self) -> Result<f64>
    where
        T: Into<f64> + Copy,
    {
        if self.is_empty() {
            return Err(Error::ensemble("cannot average empty ensemble"));
        }
        let total_weight = self.total_weight();
        if total_weight == 0.0 {
            return Err(Error::ensemble("total weight is zero"));
        }
        let sum: f64 = self.elements.iter().map(|e| e.value().clone().into() * e.weight()).sum();
        Ok(sum / total_weight)
    }

    /// Combine two ensembles via tensor product.
    pub fn tensor_product(&self, other: &Self) -> Result<Ensemble<(T, T)>>
    where
        T: Clone,
    {
        let mut result = Ensemble::new(self.id * 1000 + other.id);
        for a in &self.elements {
            for b in &other.elements {
                let combined_weight = a.weight() * b.weight();
                if combined_weight > 0.0 {
                    result.add(WeightedElement::new((a.value().clone(), b.value().clone()), combined_weight));
                }
            }
        }
        Ok(result)
    }

    /// Verify that weights sum to 1 (probability distribution).
    pub fn verify_probability_distribution(&self) -> bool {
        let total = self.total_weight();
        (total - 1.0).abs() < 1e-10
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_weighted_element() {
        let elem = WeightedElement::new(42, 0.5);
        assert_eq!(elem.value(), &42);
        assert_eq!(elem.weight(), 0.5);
    }

    #[test]
    fn test_ensemble_creation() {
        let ensemble: Ensemble<i32> = Ensemble::new(1);
        assert!(ensemble.is_empty());
    }

    #[test]
    fn test_ensemble_add() {
        let mut ensemble: Ensemble<i32> = Ensemble::new(1);
        ensemble.add(WeightedElement::new(10, 0.3));
        ensemble.add(WeightedElement::new(20, 0.7));
        assert_eq!(ensemble.len(), 2);
        assert!((ensemble.total_weight() - 1.0).abs() < 1e-10);
    }

    #[test]
    fn test_weighted_average() {
        let mut ensemble: Ensemble<i32> = Ensemble::new(1);
        ensemble.add(WeightedElement::new(10, 0.3));
        ensemble.add(WeightedElement::new(20, 0.7));
        let avg = ensemble.weighted_average().unwrap();
        assert!((avg - 17.0).abs() < 1e-10);
    }

    #[test]
    fn test_tensor_product() {
        let mut e1: Ensemble<i32> = Ensemble::new(1);
        e1.add(WeightedElement::new(1, 0.5));
        let mut e2: Ensemble<i32> = Ensemble::new(2);
        e2.add(WeightedElement::new(2, 0.5));
        let result = e1.tensor_product(&e2).unwrap();
        assert_eq!(result.len(), 1);
    }

    #[test]
    fn test_probability_distribution() {
        let mut ensemble: Ensemble<i32> = Ensemble::new(1);
        ensemble.add(WeightedElement::new(1, 0.5));
        ensemble.add(WeightedElement::new(2, 0.5));
        assert!(ensemble.verify_probability_distribution());
    }
}
