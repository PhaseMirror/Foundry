//! The UTQC inner product: the positive-definite Euclidean composition norm `⟨x,x⟩ = Σxᵢ²`.
//!
//! Realizes the `inner-product` dictionary row. The form is positive-definite outright — a
//! manifest sum of squares. "Generators are unitary" means exactly "permutations preserve
//! this `Σxᵢ²`", i.e. genuine orthogonality, established directly.

use crate::generators::Permutation;

/// `Σxᵢ²`, computed exactly in `i128` to avoid overflow and floating point.
#[must_use]
pub fn euclidean_norm_sq(v: &[i64]) -> u128 {
    v.iter().fold(0u128, |acc, &x| {
        acc.saturating_add((x.unsigned_abs() as u128).saturating_pow(2))
    })
}

/// Whether a permutation preserves `Σxᵢ²` on a given amplitude vector (orthogonality).
#[must_use]
pub fn preserves_norm(perm: &Permutation, v: &[i64]) -> bool {
    euclidean_norm_sq(v) == euclidean_norm_sq(&perm.permute_amplitudes(v))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::generators::Generators;
    use crate::params::UseCaseParams;

    #[test]
    fn permutations_preserve_the_euclidean_norm() {
        let p = UseCaseParams::new(4, 3, 8);
        let g = Generators::new(&p);
        let n = p.class_count() as usize;
        // A non-trivial amplitude vector over the class space.
        let v: alloc::vec::Vec<i64> = (0..n as i64).map(|i| i % 7 - 3).collect();
        for perm in [&g.sigma, &g.tau, &g.mu] {
            assert!(preserves_norm(perm, &v));
        }
    }

    #[test]
    fn norm_is_a_plain_sum_of_squares() {
        assert_eq!(euclidean_norm_sq(&[3, 4]), 25);
        assert_eq!(euclidean_norm_sq(&[-3, 0, 4]), 25);
    }
}
