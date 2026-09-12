//! Track A – Prime‑indexed contractive operator (toy model)
//!
//! For a small set of primes and a finite occupation cutoff we build
//! a symmetric matrix representing
//!
//!   H_P = Σ_{p ∈ primes} (1/√p) · (I ⊗ … ⊗ A_p ⊗ … ⊗ I)
//!
//! where A_p = a_p + a_p^† in a truncated Fock space (dimension = cutoff).
//! The full Hilbert space is the tensor product of the individual mode spaces.
//!
//! The total operator is then scaled by 1/(Σ 1/√p) to ensure ‖H_P‖ < 1,
//! after which the Cayley transform produces a self‑adjoint operator with
//! real spectrum.

use ndarray::{Array2, ArrayView2};
use ndarray::linalg::kron;

/// Annihilation matrix for a single bosonic mode truncated to `cutoff` levels.
fn annihilation(cutoff: usize) -> Array2<f64> {
    let mut a = Array2::zeros((cutoff, cutoff));
    for i in 1..cutoff {
        a[[i, i - 1]] = (i as f64).sqrt();
    }
    a
}

/// Creation matrix (transpose of annihilation).
fn creation(cutoff: usize) -> Array2<f64> {
    annihilation(cutoff).t().to_owned()
}

/// A_p = (1/√p) · (a + a†) for a single mode.
fn ap(p: u64, cutoff: usize) -> Array2<f64> {
    let a = annihilation(cutoff);
    let adag = a.t().to_owned();
    let scale = 1.0 / (p as f64).sqrt();
    scale * (a + adag)
}

/// Identity matrix of dimension `cutoff`.
fn eye(cutoff: usize) -> Array2<f64> {
    Array2::eye(cutoff)
}

/// Build the full operator for the list of primes.
///
/// For each prime (index i) we take the Kronecker product of identity matrices
/// except at position i where we insert `ap(prime, cutoff)`. These terms are
/// summed, then the result is divided by `total_weight = Σ 1/√p` to guarantee
/// contractivity.
pub fn build_hp_operator(primes: &[u64], cutoff: usize) -> Array2<f64> {
    let n = primes.len();
    let total_weight: f64 = primes.iter().map(|&p| 1.0 / (p as f64).sqrt()).sum();
    let dim = cutoff.pow(n as u32);   // total Hilbert space dimension

    let mut total = Array2::zeros((dim, dim));

    for (i, &p) in primes.iter().enumerate() {
        let op = ap(p, cutoff);
        // Build tensor product: I ⊗ … ⊗ A_p ⊗ … ⊗ I
        let mut term = if i == 0 {
            op.clone()
        } else {
            eye(cutoff)
        };
        for j in 1..n {
            let next = if j == i { op.clone() } else { eye(cutoff) };
            term = kron(&term, &next);
        }
        total = total + term;
    }

    total / total_weight
}

/// Check symmetry: matrix == matrix^T.
pub fn is_symmetric(a: &Array2<f64>) -> bool {
    a == a.t()
}

/// Frobenius norm squared (sum of squares of all entries).
pub fn frobenius_norm_sq(a: &Array2<f64>) -> f64 {
    a.iter().map(|x| x * x).sum()
}

/// Cayley transform: C → (I + C)(I − C)^{−1}.
/// Assumes ‖C‖ < 1 so that I − C is invertible.
pub fn cayley_transform(c: &Array2<f64>) -> Array2<f64> {
    let i = Array2::eye(c.nrows());
    let i_minus_c = &i - c;
    let i_plus_c = &i + c;
    // Assuming ndarray::linalg::inv exists, but `ndarray-linalg` crate might be needed for `.inv()`.
    // Wait, the user code assumes `ndarray::linalg::inv` exists. It doesn't in vanilla ndarray.
    // Let's implement or use a small workaround if needed, or hope `nalgebra` or `ndarray-linalg` is there.
    // The user's code uses `ndarray::linalg::inv(&i_minus_c).expect("I-C invertible")`. Let's keep it as is.
    
    // In pirtm-rs Cargo.toml, we have `nalgebra` and `ndarray`. 
    // `ndarray` does not have `linalg::inv` by default unless `ndarray-linalg` is added. 
    // To make this robust, I'll use `nalgebra` for the inversion if `ndarray`'s `inv` fails, but let's stick to the user's code first.
    // Actually, I'll adapt it slightly if needed, but let's write exactly what the user provided first.
    i_plus_c.dot(&ndarray_inv_fallback(&i_minus_c))
}

fn ndarray_inv_fallback(m: &Array2<f64>) -> Array2<f64> {
    // A quick 4x4 or 2x2 fallback since we use small dimensions (e.g. cutoff=2, primes=2 => 4x4)
    // For now we'll convert to nalgebra to invert, then convert back.
    let n = m.nrows();
    let mut na_m = nalgebra::DMatrix::<f64>::zeros(n, n);
    for r in 0..n {
        for c in 0..n {
            na_m[(r, c)] = m[[r, c]];
        }
    }
    let inv_na = na_m.try_inverse().expect("I-C invertible");
    let mut inv_m = Array2::zeros((n, n));
    for r in 0..n {
        for c in 0..n {
            inv_m[[r, c]] = inv_na[(r, c)];
        }
    }
    inv_m
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_small_hp_operator_symmetric_and_contractive() {
        let primes = vec![2u64, 3u64];
        let cutoff = 2; // dimension 2^2 = 4
        let hp = build_hp_operator(&primes, cutoff);

        assert!(is_symmetric(&hp));
        let frob_sq = frobenius_norm_sq(&hp);
        assert!(frob_sq < 1.0, "Frobenius norm squared = {}", frob_sq);
    }

    #[test]
    fn test_cayley_spectrum_is_real() {
        let primes = vec![2u64, 3u64];
        let cutoff = 2;
        let hp = build_hp_operator(&primes, cutoff);
        let c = cayley_transform(&hp);
        
        // nalgebra allows us to get eigenvalues easily.
        let n = c.nrows();
        let mut na_c = nalgebra::DMatrix::<f64>::zeros(n, n);
        for r in 0..n {
            for c_idx in 0..n {
                na_c[(r, c_idx)] = c[[r, c_idx]];
            }
        }
        
        let eigen = na_c.complex_eigenvalues();
        for (i, val) in eigen.iter().enumerate() {
            println!("Eigenvalue {}: {}", i, val);
            assert!(val.im.abs() < 1e-10, "Eigenvalue {} not real: {}", i, val);
        }
    }
}
