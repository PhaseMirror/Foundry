//! The modular identity `E4³ = E6² + 1728·Δ`, verified on `q`-expansion coefficients.
//!
//! Realizes the `modular-identities` dictionary row. Exact integer truncated polynomial
//! arithmetic; the coefficient arrays come from the F1 oracle (cross-checkable against
//! LMFDB / OEIS A004009 / A013973 / A000594).

use alloc::vec::Vec;

/// Truncated polynomial product: the first `n` coefficients of `a · b`.
#[must_use]
pub fn poly_mul_trunc(a: &[i128], b: &[i128], n: usize) -> Vec<i128> {
    let mut out = alloc::vec![0i128; n];
    for (i, &ai) in a.iter().enumerate() {
        if i >= n {
            break;
        }
        for (j, &bj) in b.iter().enumerate() {
            if i + j >= n {
                break;
            }
            out[i + j] += ai * bj;
        }
    }
    out
}

/// Truncated polynomial power: the first `n` coefficients of `a^e` (`e ≥ 1`).
#[must_use]
pub fn poly_pow_trunc(a: &[i128], e: u32, n: usize) -> Vec<i128> {
    let mut acc: Vec<i128> = a.iter().take(n).copied().collect();
    for _ in 1..e {
        acc = poly_mul_trunc(&acc, a, n);
    }
    acc
}

/// Whether `E4³ = E6² + constant·Δ` holds on all overlapping coefficients.
#[must_use]
pub fn identity_holds(e4: &[i128], e6: &[i128], delta: &[i128], constant: i128) -> bool {
    let n = e4.len().min(e6.len()).min(delta.len());
    if n == 0 {
        return false;
    }
    let lhs = poly_pow_trunc(e4, 3, n);
    let e6_sq = poly_pow_trunc(e6, 2, n);
    (0..n).all(|i| lhs[i] == e6_sq[i] + constant * delta[i])
}

#[cfg(test)]
mod tests {
    use super::*;

    // Leading q-expansion coefficients (q^0..q^5), as proved in F1 AtlasModular.
    const E4: [i128; 6] = [1, 240, 2160, 6720, 17520, 30240];
    const E6: [i128; 6] = [1, -504, -16632, -122976, -532728, -1575504];
    const DELTA: [i128; 6] = [0, 1, -24, 252, -1472, 4830];

    #[test]
    fn the_1728_identity_holds() {
        assert!(identity_holds(&E4, &E6, &DELTA, 1728));
    }

    #[test]
    fn a_wrong_constant_is_rejected() {
        assert!(!identity_holds(&E4, &E6, &DELTA, 1729));
    }
}
