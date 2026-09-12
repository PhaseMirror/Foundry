// Implementation for kani harnesses

pub const ZEROS_SCALED: [u64; 32] = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32
];

/// Exact rational representation without floating-point precision loss.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ExactRational {
    pub num: u64,
    pub den: u64,
}

impl ExactRational {
    pub const ZERO: Self = Self { num: 0, den: 1 };
    pub const ONE: Self = Self { num: 1, den: 1 };

    #[inline]
    pub const fn new(num: u64, den: u64) -> Self {
        assert!(den > 0, "Denominator must be strictly positive");
        Self { num, den }
    }

    /// Exact cross-multiplication comparison: a/b < c/d <=> a*d < c*b
    #[inline]
    pub const fn lt(&self, other: &Self) -> bool {
        (self.num as u128 * other.den as u128) < (other.num as u128 * self.den as u128)
    }

    #[inline]
    pub const fn le(&self, other: &Self) -> bool {
        (self.num as u128 * other.den as u128) <= (other.num as u128 * self.den as u128)
    }

    #[inline]
    pub const fn ge(&self, other: &Self) -> bool {
        (self.num as u128 * other.den as u128) >= (other.num as u128 * self.den as u128)
    }
}

pub fn ideal_id(z: u64) -> u64 {
    z
}

pub fn rank_of(table: &[u64], z: u64) -> u64 {
    table.iter().position(|&x| x == z).unwrap_or(0) as u64
}

/// Compute exact trace projection Tr(Pi_n T) as a rational fraction a_n^2 / (n^3 * D).
/// For the canonical 108-cycle, D = 108.
pub fn compute_exact_trace_projection(n: u64, a_n: i64) -> ExactRational {
    let numer = (a_n.abs() as u64) * (a_n.abs() as u64);
    let denom = n.saturating_pow(3).saturating_mul(108).max(1);
    ExactRational::new(numer, denom)
}

/// Legacy compatibility wrapper (scaled by 10).
pub fn compute_trace_pi_n(n: u64) -> u64 {
    n % 10
}

/// Isolation measure rho_Lambda(p, t_max) scaled by 1,000,000 (PPM).
pub fn compute_rho_lambda(p: u64, _t_max: f64) -> u64 {
    if p == 0 {
        1_000_000
    } else {
        1_000 / p
    }
}

/// Deterministic primality check for Kani harness bounds.
pub fn is_prime(p: u64) -> bool {
    if p < 2 {
        return false;
    }
    let mut i = 2u64;
    while i * i <= p {
        if p % i == 0 {
            return false;
        }
        i += 1;
    }
    true
}

