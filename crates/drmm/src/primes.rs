/// Prime generation utilities for DRMM.
use num_prime::nt_funcs::nth_prime;

pub fn generate_first_n_primes(count: usize) -> Vec<u64> {
    if count == 0 {
        return Vec::new();
    }

    (1..=count as u64)
        .map(|n| nth_prime(n))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_primes() {
        let p = generate_first_n_primes(10);
        assert_eq!(p, vec![2, 3, 5, 7, 11, 13, 17, 19, 23, 29]);
    }
}
