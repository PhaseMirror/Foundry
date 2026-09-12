//! Coxeter / Weyl data: the rank as `φ(h)` of the Coxeter number.
//!
//! Realizes the `coxeter-weyl` dictionary row. For the Atlas, `rank = φ(30) = 8 = O`
//! (`context`). Euler's totient is generic; the Coxeter number and exponents are sourced
//! from F1.

/// Euler's totient `φ(n)`.
#[must_use]
pub fn euler_phi(mut n: u32) -> u32 {
    if n == 0 {
        return 0;
    }
    let mut result = n;
    let mut p = 2;
    while p * p <= n {
        if n % p == 0 {
            while n % p == 0 {
                n /= p;
            }
            result -= result / p;
        }
        p += 1;
    }
    if n > 1 {
        result -= result / n;
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn phi_30_is_8() {
        // The E8 Coxeter number is 30; its totient is the rank, which equals O = 8.
        assert_eq!(euler_phi(30), 8);
    }

    #[test]
    fn totient_spot_checks() {
        assert_eq!(euler_phi(1), 1);
        assert_eq!(euler_phi(7), 6);
        assert_eq!(euler_phi(12), 4);
    }
}
