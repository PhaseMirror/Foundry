use serde::{Deserialize, Serialize};

pub const DRIFT_THRESHOLD_DEFAULT: f64 = 0.3;

/// Checks if the drift is within the lawful threshold.
pub fn is_lawful_drift(d: f64, threshold: Option<f64>) -> bool {
    let t = threshold.unwrap_or(DRIFT_THRESHOLD_DEFAULT);
    d <= t
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SilentState {
    pub commit_count: usize,
    pub primed: bool,
}

/// Determines if the engine should remain silent based on commit count and primed state.
/// Silent unless primed AND commit_count is non-zero.
pub fn should_stay_silent(state: &SilentState) -> bool {
    !state.primed || state.commit_count == 0
}

/// Toy drift metric (L1 over vectors).
/// Ported from TypeScript: sum(abs(a - b)) / n
pub fn drift(current: &[f64], lawful_basis: &[f64]) -> f64 {
    let n = current.len().max(lawful_basis.len());
    if n == 0 {
        return 0.0;
    }
    
    let mut s = 0.0;
    for i in 0..n {
        let a = current.get(i).cloned().unwrap_or(0.0);
        let b = lawful_basis.get(i).cloned().unwrap_or(0.0);
        s += (a - b).abs();
    }
    s / (n as f64)
}

/// Checks if a number is prime.
pub fn is_prime(n: usize) -> bool {
    if n < 2 {
        return false;
    }
    let mut i = 2;
    while i * i <= n {
        if n % i == 0 {
            return false;
        }
        i += 1;
    }
    true
}

/// Checks if the commit count passes through the prime gates.
/// Open if commit_count equals any prime gate and is itself prime.
pub fn prime_gate(commit_count: usize, gates: &[usize]) -> bool {
    gates.contains(&commit_count) && is_prime(commit_count)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_is_lawful_drift() {
        assert!(is_lawful_drift(0.2, None));
        assert!(!is_lawful_drift(0.4, None));
        assert!(is_lawful_drift(0.4, Some(0.5)));
    }

    #[test]
    fn test_should_stay_silent() {
        assert!(should_stay_silent(&SilentState { commit_count: 5, primed: false }));
        assert!(should_stay_silent(&SilentState { commit_count: 0, primed: true }));
        assert!(!should_stay_silent(&SilentState { commit_count: 5, primed: true }));
    }

    #[test]
    fn test_drift_calculation() {
        let current = vec![1.0, 0.0];
        let basis = vec![0.5, 0.5];
        // (abs(1.0-0.5) + abs(0.0-0.5)) / 2 = (0.5 + 0.5) / 2 = 0.5
        assert!((drift(&current, &basis) - 0.5).abs() < 1e-10);
    }

    #[test]
    fn test_is_prime() {
        assert!(is_prime(2));
        assert!(is_prime(3));
        assert!(!is_prime(4));
        assert!(is_prime(17));
        assert!(!is_prime(1));
    }

    #[test]
    fn test_prime_gate() {
        let gates = vec![2, 3, 5, 7];
        assert!(prime_gate(5, &gates));
        assert!(!prime_gate(4, &gates));
        assert!(!prime_gate(11, &gates));
    }
}
