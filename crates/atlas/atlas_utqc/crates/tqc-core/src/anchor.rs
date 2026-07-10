//! The definite anchor: positive-definiteness of a use-case's Gram matrix.
//!
//! Realizes the generic side of the `definite-anchor-e8` dictionary row. The check is generic
//! over any symmetric integer Gram matrix (Sylvester's criterion via a fraction-free
//! determinant); the Atlas instance supplies the E8 Gram, an arbitrary use-case supplies its
//! Euclidean companion.

use alloc::vec::Vec;

/// Integer determinant via the Bareiss (fraction-free) algorithm, in natural pivot order.
///
/// Returns `None` on a zero pivot — in the only context this is used (positive-definiteness),
/// a zero leading-minor already means "not positive-definite", so no row swapping is needed.
fn det_bareiss(mut m: Vec<Vec<i128>>) -> Option<i128> {
    let n = m.len();
    if n == 0 {
        return Some(1);
    }
    let mut prev = 1i128;
    for k in 0..n {
        if m[k][k] == 0 {
            return None;
        }
        if k + 1 == n {
            break;
        }
        for i in (k + 1)..n {
            for j in (k + 1)..n {
                m[i][j] = (m[i][j] * m[k][k] - m[i][k] * m[k][j]) / prev;
            }
        }
        prev = m[k][k];
    }
    Some(m[n - 1][n - 1])
}

/// Whether a symmetric integer matrix is positive-definite (Sylvester's criterion: every
/// leading principal minor is strictly positive).
#[must_use]
pub fn is_positive_definite(gram: &[Vec<i64>]) -> bool {
    let n = gram.len();
    if n == 0 || gram.iter().any(|row| row.len() != n) {
        return false;
    }
    for (i, row) in gram.iter().enumerate() {
        for (j, &val) in row.iter().enumerate() {
            if val != gram[j][i] {
                return false; // not symmetric
            }
        }
    }
    (1..=n).all(|k| {
        let sub: Vec<Vec<i128>> = gram[..k]
            .iter()
            .map(|row| row[..k].iter().map(|&x| i128::from(x)).collect())
            .collect();
        matches!(det_bareiss(sub), Some(d) if d > 0)
    })
}

/// The Euclidean companion Gram of a use-case: the identity of size `dim` (the manifest sum of
/// squares `Σxᵢ²`).
#[must_use]
pub fn euclidean_companion(dim: usize) -> Vec<Vec<i64>> {
    (0..dim)
        .map(|i| (0..dim).map(|j| i64::from(i == j)).collect())
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn identity_is_positive_definite() {
        assert!(is_positive_definite(&euclidean_companion(24)));
        assert!(is_positive_definite(&euclidean_companion(8)));
    }

    #[test]
    fn indefinite_and_asymmetric_are_rejected() {
        // diag(1, -1) is indefinite.
        assert!(!is_positive_definite(&[std::vec![1, 0], std::vec![0, -1]]));
        // asymmetric.
        assert!(!is_positive_definite(&[std::vec![2, 1], std::vec![0, 2]]));
        assert!(!is_positive_definite(&[]));
    }
}
