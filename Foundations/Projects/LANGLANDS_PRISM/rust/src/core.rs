/// Universal Multiplicity Constant Lambda_m = (sqrt(5) - 1) / 2 ~ 0.6180339887...
pub const LAMBDA_M: f64 = 0.6180339887498949;

/// Golden ratio phi = (1 + sqrt(5)) / 2 ~ 1.6180339887...
pub const PHI: f64 = 1.6180339887498949;

/// Prime basis standard sets
pub const DEFAULT_PRIMES_5: [u64; 5] = [2, 3, 5, 7, 11];
pub const DEFAULT_PRIMES_8: [u64; 8] = [2, 3, 5, 7, 11, 13, 17, 19];

/// Primality test via trial division.
pub fn is_prime(n: u64) -> bool {
    if n < 2 {
        return false;
    }
    if n == 2 || n == 3 {
        return true;
    }
    if n % 2 == 0 || n % 3 == 0 {
        return false;
    }
    let mut d = 5;
    while d * d <= n {
        if n % d == 0 || n % (d + 2) == 0 {
            return false;
        }
        d += 6;
    }
    true
}

/// Sieve of Eratosthenes up to limit.
pub fn sieve_primes(limit: usize) -> Vec<u64> {
    if limit < 2 {
        return Vec::new();
    }
    let mut is_p = vec![true; limit + 1];
    is_p[0] = false;
    is_p[1] = false;
    let mut p = 2;
    while p * p <= limit {
        if is_p[p] {
            let mut m = p * p;
            while m <= limit {
                is_p[m] = false;
                m += p;
            }
        }
        p += 1;
    }
    is_p.iter().enumerate()
        .filter_map(|(idx, &p_flag)| if p_flag { Some(idx as u64) } else { None })
        .collect()
}

/// Return the first N prime numbers.
pub fn first_n_primes(n: usize) -> Vec<u64> {
    let mut primes = Vec::with_capacity(n);
    let mut candidate = 2;
    while primes.len() < n {
        if is_prime(candidate) {
            primes.push(candidate);
        }
        candidate += 1;
    }
    primes
}

/// Dirichlet character modulo 4:
/// chi_4(n) = 1 if n = 1 (mod 4), -1 if n = 3 (mod 4), 0 if even.
pub fn dirichlet_char_4(n: u64) -> i32 {
    if n % 2 == 0 {
        0
    } else if n % 4 == 1 {
        1
    } else {
        -1
    }
}

/// Dirichlet L-function Euler factor at prime p:
/// L_p(s, chi) = (1 - chi(p) * p^{-s})^{-1}
pub fn dirichlet_euler_factor(p: u64, s: f64, chi: i32) -> f64 {
    if chi == 0 {
        1.0
    } else {
        let p_pow = (p as f64).powf(-s);
        let denom = 1.0 - (chi as f64) * p_pow;
        if denom.abs() < 1e-12 {
            1e12
        } else {
            1.0 / denom
        }
    }
}

/// Dirichlet L-function series evaluation L(s, chi) = sum_{n=1}^N chi(n) / n^s
pub fn dirichlet_l_series(s: f64, num_terms: usize) -> f64 {
    let mut sum = 0.0;
    for n in 1..=num_terms {
        let chi = dirichlet_char_4(n as u64);
        if chi != 0 {
            sum += (chi as f64) / (n as f64).powf(s);
        }
    }
    sum
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_prime_generation() {
        let p5 = first_n_primes(5);
        assert_eq!(p5, vec![2, 3, 5, 7, 11]);
        assert!(is_prime(13));
        assert!(!is_prime(15));
    }

    #[test]
    fn test_dirichlet_character_and_euler_factors() {
        assert_eq!(dirichlet_char_4(1), 1);
        assert_eq!(dirichlet_char_4(2), 0);
        assert_eq!(dirichlet_char_4(3), -1);
        assert_eq!(dirichlet_char_4(5), 1);

        let ef_5 = dirichlet_euler_factor(5, 1.0, dirichlet_char_4(5));
        // L_5(1) = (1 - 1/5)^-1 = 5/4 = 1.25
        assert!((ef_5 - 1.25).abs() < 1e-6);

        let ef_3 = dirichlet_euler_factor(3, 1.0, dirichlet_char_4(3));
        // L_3(1) = (1 - (-1)/3)^-1 = (4/3)^-1 = 0.75
        assert!((ef_3 - 0.75).abs() < 1e-6);
    }
}
