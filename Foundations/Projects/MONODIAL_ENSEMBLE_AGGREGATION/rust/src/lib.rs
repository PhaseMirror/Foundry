//! Monodial Ensemble Aggregation core library
//!
//! Provides utilities to aggregate multiple ensembles (vectors of numeric data)
//! into a single consolidated ensemble via element‑wise summation.
//!
//! The implementation is deliberately straightforward so that Kani can verify
//! fundamental algebraic properties (e.g., commutativity, associativity) on
//! bounded inputs.

use std::ops::Add;

/// Aggregates a slice of ensembles (each a slice of `T`) into a single vector.
///
/// All ensembles must have the same length; otherwise the function panics.
/// The aggregation is performed element‑wise using the `Add` trait.
///
/// # Examples
/// ```
/// let ensembles = vec![
///     vec![1u64, 2, 3],
///     vec![4u64, 5, 6],
/// ];
/// let agg = aggregate(&ensembles);
/// assert_eq!(agg, vec![5, 7, 9]);
/// ```
pub fn aggregate<T>(ensembles: &[&[T]]) -> Vec<T>
where
    T: Copy + Add<Output = T> + Default,
{
    if ensembles.is_empty() {
        return Vec::new();
    }
    let len = ensembles[0].len();
    // Verify all ensembles share the same length
    for e in ensembles.iter() {
        assert_eq!(e.len(), len, "All ensembles must have equal length");
    }
    // Initialize result with defaults
    let mut result: Vec<T> = vec![T::default(); len];
    for e in ensembles.iter() {
        for (i, &val) in e.iter().enumerate() {
            result[i] = result[i] + val;
        }
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn test_aggregate_simple() {
        let a = vec![1u64, 2, 3];
        let b = vec![4u64, 5, 6];
        let result = aggregate(&[&a, &b]);
        assert_eq!(result, vec![5, 7, 9]);
    }
    #[test]
    #[should_panic]
    fn test_aggregate_mismatched_lengths() {
        let a = vec![1u64, 2];
        let b = vec![3u64, 4, 5];
        let _ = aggregate(&[&a, &b]);
    }
}
