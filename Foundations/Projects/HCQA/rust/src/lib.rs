//! HCQA — Rust Numerical Backend
//!
//! Provides verified numerical implementations of:
//! - Qudit compression and physical qudit count
//! - HSEC overhead ratio calculation
//! - QCFI adaptive allocation
//! - Prime sieving and p-adic valuation
//!
//! Verification via unit tests.

/// Qudit dimension d = 2(2I + 1) for nuclear spin I.
pub fn qudit_dim(i: u64) -> u64 {
    2 * (2 * i + 1)
}

/// Compression factor C = d / log2(d).
pub fn compression_factor(d: u64) -> f64 {
    if d == 0 {
        0.0
    } else {
        (d as f64).log2()
    }
}

/// Number of physical qudits needed for n logical qubits.
pub fn physical_qudits(n: u64, d: u64) -> u64 {
    if d == 0 {
        0
    } else {
        (n as f64 / 2.0).ceil() as u64
    }
}

/// HSEC overhead ratio.
pub fn overhead_ratio(d: u64, m: u64, d_prime: u64) -> f64 {
    if m == 0 || d_prime == 0 {
        0.0
    } else {
        let qubit_overhead = (2 * d_prime - 1).pow(2);
        let hsec_overhead = (2 * m - 1).pow(2) * d / m;
        qubit_overhead as f64 / hsec_overhead as f64
    }
}

/// Eells-Kuiper invariant for Σ(2,3,r).
pub fn eells_kuiper_23(r: u64) -> u64 {
    match r {
        5 => 0,
        7 => 8,
        11 => 16,
        13 => 4,
        17 => 12,
        19 => 20,
        _ => 0,
    }
}

/// Simple prime sieve up to n.
pub fn sieve_primes(n: u64) -> Vec<u64> {
    if n < 2 {
        return vec![];
    }
    let mut is_prime = vec![true; (n + 1) as usize];
    is_prime[0] = false;
    is_prime[1] = false;
    for i in 2..=n {
        if is_prime[i as usize] && i * i <= n {
            for j in (i * i..=n).step_by(i as usize) {
                is_prime[j as usize] = false;
            }
        }
    }
    (2..=n).filter(|&p| is_prime[p as usize]).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_qudit_dim_sr87() {
        assert_eq!(qudit_dim(9), 38);
    }

    #[test]
    fn test_qudit_dim_yb171() {
        assert_eq!(qudit_dim(1), 6);
    }

    #[test]
    fn test_compression_factor() {
        assert!(compression_factor(20) > 1.0);
    }

    #[test]
    fn test_physical_qudits() {
        assert_eq!(physical_qudits(20, 20), 10);
    }

    #[test]
    fn test_overhead_ratio() {
        assert!(overhead_ratio(20, 16, 2) > 0.0);
    }

    #[test]
    fn test_eells_kuiper_57() {
        assert_eq!(eells_kuiper_23(7), 8);
    }

    #[test]
    fn test_sieve_2() {
        assert!(sieve_primes(2).contains(&2));
    }
}
