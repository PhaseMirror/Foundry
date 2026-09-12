//! Zeta‑Phi‑Pi core library

/// Computes the product of the integers from 1 to `n` (i.e., `n!`).
///
/// This function is deliberately simple so that Kani can verify small‑scale
/// properties about its behavior.
pub fn compute_product(n: u64) -> u64 {
    (1..=n).product()
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn test_small_values() {
        assert_eq!(compute_product(0), 1);
        assert_eq!(compute_product(1), 1);
        assert_eq!(compute_product(5), 120);
        assert_eq!(compute_product(10), 3628800);
    }
}
