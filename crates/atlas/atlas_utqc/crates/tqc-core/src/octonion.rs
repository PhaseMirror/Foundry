//! Composition-algebra norm multiplicativity (the octonion eight-square identity).
//!
//! Underpins the `fusion-g2` dictionary row: fusion is norm-multiplicative, `|a|²|b|² = |ab|²`,
//! realized by the Cayley–Dickson composition algebras of dimension 1, 2, 4, 8 (reals, complex,
//! quaternions, octonions — Degen's eight-square identity at dimension 8).

use alloc::vec::Vec;

fn neg(a: &[i128]) -> Vec<i128> {
    a.iter().map(|x| x.saturating_neg()).collect()
}

/// Cayley–Dickson conjugation: negate the imaginary part recursively.
fn conj(a: &[i128]) -> Vec<i128> {
    if a.len() == 1 {
        return a.to_vec();
    }
    let h = a.len() / 2;
    let (re, im) = a.split_at(h);
    let mut out = conj(re);
    out.extend(neg(im));
    out
}

/// Cayley–Dickson product: `(a,b)(c,d) = (a·c − conj(d)·b, d·a + b·conj(c))`.
pub fn cd_mul(a: &[i128], b: &[i128]) -> Vec<i128> {
    let n = a.len();
    if n == 1 {
        return alloc::vec![a[0].saturating_mul(b[0])];
    }
    let h = n / 2;
    let (a1, a2) = a.split_at(h);
    let (b1, b2) = b.split_at(h);
    let zip_sub = |x: &[i128], y: &[i128]| -> Vec<i128> {
        x.iter().zip(y).map(|(p, q)| p.saturating_sub(*q)).collect()
    };
    let zip_add = |x: &[i128], y: &[i128]| -> Vec<i128> {
        x.iter().zip(y).map(|(p, q)| p.saturating_add(*q)).collect()
    };
    let first = zip_sub(&cd_mul(a1, b1), &cd_mul(&conj(b2), a2));
    let second = zip_add(&cd_mul(b2, a1), &cd_mul(a2, &conj(b1)));
    let mut out = first;
    out.extend(second);
    out
}

/// Compute the structure constants $C_{ij}^k$ of the Cayley-Dickson algebra of a given dimension.
#[must_use]
pub fn structure_constants(dim: usize) -> Vec<(usize, usize, usize, i128)> {
    let mut constants = Vec::new();
    if dim == 0 || !dim.is_power_of_two() {
        return constants;
    }
    for i in 0..dim {
        for j in 0..dim {
            let mut ei = alloc::vec![0; dim];
            ei[i] = 1;
            let mut ej = alloc::vec![0; dim];
            ej[j] = 1;
            let ek = cd_mul(&ei, &ej);
            for (k, &val) in ek.iter().enumerate() {
                if val != 0 {
                    constants.push((i, j, k, val));
                }
            }
        }
    }
    constants
}

/// The norm `Σxᵢ²`.
#[must_use]
pub fn norm_sq(a: &[i128]) -> u128 {
    a.iter().fold(0u128, |acc, &x| {
        acc.saturating_add(x.unsigned_abs().saturating_pow(2))
    })
}

/// Whether the composition norm is multiplicative at this dimension: `N(a)·N(b) = N(a·b)`.
///
/// Holds for the normed division algebras (dimensions 1, 2, 4, 8). `a` and `b` must share a
/// power-of-two length.
#[must_use]
pub fn norm_multiplicative(a: &[i128], b: &[i128]) -> bool {
    if a.len() != b.len() || a.is_empty() || !a.len().is_power_of_two() {
        return false;
    }
    norm_sq(a) * norm_sq(b) == norm_sq(&cd_mul(a, b))
}

/// Degen's eight-square identity for octonions: `N(a)·N(b) = N(a·b)`.
#[must_use]
pub fn eight_square_holds(a: &[i128; 8], b: &[i128; 8]) -> bool {
    norm_multiplicative(a, b)
}

/// The structural quotient: taking the absolute value of the structure constants maps the signed
/// Cayley-Dickson algebra to a non-negative fusion ring. This verifies if the resulting ring
/// is strictly associative, bypassing the `SignedFusionConstants` obstruction.
#[must_use]
pub fn absolute_quotient_is_associative(dim: usize) -> bool {
    if dim == 0 || !dim.is_power_of_two() {
        return false;
    }
    for i in 0..dim {
        for j in 0..dim {
            for k in 0..dim {
                let mut ei = alloc::vec![0; dim];
                ei[i] = 1;
                let mut ej = alloc::vec![0; dim];
                ej[j] = 1;
                let mut ek = alloc::vec![0; dim];
                ek[k] = 1;

                let ij = cd_mul(&ei, &ej);
                let mut ij_abs = alloc::vec![0; dim];
                for x in 0..dim {
                    ij_abs[x] = ij[x].abs();
                }

                let ij_k = cd_mul(&ij_abs, &ek);
                let mut ij_k_abs = alloc::vec![0; dim];
                for x in 0..dim {
                    ij_k_abs[x] = ij_k[x].abs();
                }

                let jk = cd_mul(&ej, &ek);
                let mut jk_abs = alloc::vec![0; dim];
                for x in 0..dim {
                    jk_abs[x] = jk[x].abs();
                }

                let i_jk = cd_mul(&ei, &jk_abs);
                let mut i_jk_abs = alloc::vec![0; dim];
                for x in 0..dim {
                    i_jk_abs[x] = i_jk[x].abs();
                }

                if ij_k_abs != i_jk_abs {
                    return false;
                }
            }
        }
    }
    true
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn eight_square_identity_holds() {
        let a = [1, 2, 3, 4, 5, 6, 7, 8];
        let b = [8, -7, 6, -5, 4, -3, 2, -1];
        assert!(eight_square_holds(&a, &b));
        let c = [3, 1, 4, 1, 5, 9, 2, 6];
        let d = [2, 7, 1, 8, 2, 8, 1, 8];
        assert!(eight_square_holds(&c, &d));
    }

    #[test]
    fn multiplicative_at_division_algebra_dims() {
        for dim in [1usize, 2, 4, 8] {
            let a: Vec<i128> = (0..dim as i128).map(|i| i + 1).collect();
            let b: Vec<i128> = (0..dim as i128).map(|i| 2 * i - 3).collect();
            assert!(norm_multiplicative(&a, &b), "dim {dim}");
        }
    }
}
