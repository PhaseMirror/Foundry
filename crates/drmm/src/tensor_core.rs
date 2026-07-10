use ndarray::Array2;
use num_prime::nt_funcs::nth_prime;

/// Generate a tensor of shape (dim, dim) where each entry is weighted by prime-indexed coefficients.
/// 
/// Parity with: drmm/src/tensor_core.py -> prime_indexed_tensor
pub fn prime_indexed_tensor(max_prime: usize, dim: usize) -> Array2<f64> {
    use num_prime::nt_funcs::is_prime;
    use num_prime::Primality;
    let primes: Vec<u64> = (1..=max_prime as u64)
        .filter(|&n| match is_prime(&n, None) {
            Primality::No => false,
            _ => true,
        })
        .collect();
    
    let mut tensor = Array2::zeros((dim, dim));
    
    if primes.is_empty() {
        return tensor;
    }

    for i in 0..dim {
        for j in 0..dim {
            let idx = (i * dim + j) % primes.len();
            tensor[[i, j]] = primes[idx] as f64;
        }
    }
    
    tensor
}

/// Normalize a tensor using Frobenius norm.
/// 
/// Parity with: drmm/src/tensor_core.py -> normalize_tensor
pub fn normalize_tensor(t: &Array2<f64>) -> Array2<f64> {
    let mut square_sum = 0.0;
    for val in t.iter() {
        square_sum += val * val;
    }
    let norm = square_sum.sqrt();

    if norm > 1e-12 {
        t / norm
    } else {
        t.clone()
    }
}

/// Compute eigenvalues of a tensor.
/// 
/// Parity with: drmm/src/tensor_core.py -> tensor_spectrum
/// NOTE: Stubbed until a Lapack backend is available in the environment.
pub fn tensor_spectrum(_t: &Array2<f64>) -> Vec<num_complex::Complex<f64>> {
    println!("Warning: tensor_spectrum is currently a stub due to missing Lapack backend.");
    vec![]
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_prime_indexed_tensor_parity() {
        // With n=10, primes <= 10 are [2, 3, 5, 7]
        let t = prime_indexed_tensor(10, 3);
        assert_eq!(t[[0, 0]], 2.0); // Index 0 -> 2
        assert_eq!(t[[0, 1]], 3.0); // Index 1 -> 3
        assert_eq!(t[[0, 2]], 5.0); // Index 2 -> 5
        assert_eq!(t[[1, 0]], 7.0); // Index 3 -> 7
        assert_eq!(t[[1, 1]], 2.0); // Index 4 -> 2 (Wrap)
        assert_eq!(t[[2, 2]], 2.0); // Index 8 -> 8 % 4 = 0 -> 2 (Wrap)
    }

    #[test]
    fn test_normalization() {
        let t = Array2::from_elem((2, 2), 1.0);
        let tn = normalize_tensor(&t);
        let mut square_sum = 0.0;
        for val in tn.iter() {
            square_sum += val * val;
        }
        let norm = square_sum.sqrt();
        assert!((norm - 1.0).abs() < 1e-10);
    }
}
