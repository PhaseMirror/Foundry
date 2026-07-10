use std::collections::HashMap;

/// Enforces Invariant IV: Identity must remain prime-decomposable.
/// The state must be represented as a combination of prime indices.
pub trait PrimeDecomposable {
    /// Returns the components of the state indexed by prime numbers.
    fn prime_components(&self) -> HashMap<u64, f64>;

    /// Validates that all active components are indexed by genuine primes.
    fn verify_prime_basis(&self) -> bool {
        for &p in self.prime_components().keys() {
            if !is_prime(p) {
                return false;
            }
        }
        true
    }
}

fn is_prime(n: u64) -> bool {
    if n < 2 { return false; }
    if n == 2 || n == 3 { return true; }
    if n % 2 == 0 || n % 3 == 0 { return false; }
    let mut i = 5;
    while i * i <= n {
        if n % i == 0 || n % (i + 2) == 0 { return false; }
        i += 6;
    }
    true
}

#[cfg(test)]
mod tests {
    use super::*;

    struct MockState(HashMap<u64, f64>);
    impl PrimeDecomposable for MockState {
        fn prime_components(&self) -> HashMap<u64, f64> {
            self.0.clone()
        }
    }

    #[test]
    fn test_prime_decomposability() {
        let mut good = HashMap::new();
        good.insert(2, 1.0);
        good.insert(17, 0.5);
        let good_state = MockState(good);
        assert!(good_state.verify_prime_basis());

        let mut bad = HashMap::new();
        bad.insert(2, 1.0);
        bad.insert(4, 0.5); // 4 is not prime
        let bad_state = MockState(bad);
        assert!(!bad_state.verify_prime_basis());
    }
}
