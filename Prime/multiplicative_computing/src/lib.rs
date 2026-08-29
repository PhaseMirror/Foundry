// Scalar contraction and contraction bound proofs over exact rationals
// and algebraic non‑parallel embedding v(p) = (1, p, 0).

/// Simple rational number type using 64‑bit signed integers.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Rat {
    num: i64, // numerator
    den: i64, // denominator, always > 0
}

impl Rat {
    /// Create a new rational, panicking if denominator is zero or negative.
    pub fn new(num: i64, den: i64) -> Self {
        assert!(den > 0, "denominator must be positive");
        let mut r = Rat { num, den };
        r.normalize();
        r
    }

    /// Normalise by dividing out the gcd and ensuring denominator positive.
    fn normalize(&mut self) {
        fn gcd(mut a: i64, mut b: i64) -> i64 {
            while b != 0 {
                a %= b;
                std::mem::swap(&mut a, &mut b);
            }
            a.abs()
        }
        let g = gcd(self.num, self.den);
        if g != 0 {
            self.num /= g;
            self.den /= g;
        }
        if self.den < 0 {
            self.num = -self.num;
            self.den = -self.den;
        }
    }

    pub fn zero() -> Self { Rat::new(0, 1) }
    pub fn one() -> Self { Rat::new(1, 1) }

    pub fn add(self, other: Self) -> Self {
        Rat::new(self.num * other.den + other.num * self.den, self.den * other.den)
    }

    pub fn mul(self, other: Self) -> Self {
        Rat::new(self.num * other.num, self.den * other.den)
    }

    pub fn inv(self) -> Self {
        assert!(self.num != 0, "cannot invert zero");
        let sign = if self.num < 0 { -1 } else { 1 };
        Rat::new(sign * self.den, sign * self.num.abs())
    }

    pub fn div(self, other: Self) -> Self {
        self.mul(other.inv())
    }

    pub fn le(self, other: Self) -> bool {
        self.num * other.den <= other.num * self.den
    }
}

/// Compute the scalar contraction factor γ / (S + η).
pub fn contraction_factor(gamma: Rat, s: Rat, eta: Rat) -> Rat {
    gamma.div(s.add(eta))
}

/// Theorem A – cancellation identity.
pub fn cancellation_identity(gamma: Rat, s: Rat, eta: Rat) -> bool {
    let factor = contraction_factor(gamma, s, eta);
    factor.mul(s.add(eta)) == gamma
}

/// Theorem B – contraction bound.
/// Requires an implementation‑specific bound S_impl ≤ S + η.
pub fn contraction_bound(gamma: Rat, s_impl: Rat, s: Rat, eta: Rat) -> bool {
    // ensure S_impl ≤ S + η is satisfied by caller
    let factor = contraction_factor(gamma, s, eta);
    factor.mul(s_impl).le(gamma)
}

/// Algebraic embedding for a prime (or any positive integer).
/// v(p) = (1, p, 0). Returns a tuple of integers.
pub fn v(p: i64) -> (i64, i64, i64) {
    (1, p, 0)
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn sanity_v() {
        let (a, b, c) = v(7);
        assert_eq!((a, b, c), (1, 7, 0));
    }
}

// Kani harnesses
#[cfg(kani)]
mod kani_proofs {
    use super::*;
    use kani::any;

    // Helper: construct a rational from two arbitrary i64s satisfying denominator > 0.
    fn any_rat() -> Rat {
        let num: i64 = any();
        let mut den: i64 = any();
        kani::assume(den != 0);
        if den < 0 { den = -den; }
        Rat::new(num, den)
    }

    #[kani::proof]
    fn theorem_a_cancellation() {
        // gamma satisfies 0 < gamma < 1
        let gamma = any_rat();
        kani::assume(gamma.num > 0);
        kani::assume(gamma.num < gamma.den);
        // eta >= 0, S >= 0
        let eta = any_rat();
        kani::assume(eta.num >= 0);
        let s = any_rat();
        kani::assume(s.num >= 0);
        // S + eta > 0
        let sum = s.add(eta);
        kani::assume(sum.num > 0);
        assert!(cancellation_identity(gamma, s, eta));
    }

    #[kani::proof]
    fn theorem_b_contraction() {
        // same constraints as theorem A
        let gamma = any_rat();
        kani::assume(gamma.num > 0);
        kani::assume(gamma.num < gamma.den);
        let eta = any_rat();
        kani::assume(eta.num >= 0);
        let s = any_rat();
        kani::assume(s.num >= 0);
        let sum = s.add(eta);
        kani::assume(sum.num > 0);
        // Choose S_impl such that S_impl ≤ S + η
        let s_impl = any_rat();
        kani::assume(s_impl.le(sum));
        assert!(contraction_bound(gamma, s_impl, s, eta));
    }

    #[kani::proof]
    fn non_parallel_embedding() {
        let p: i64 = any();
        let q: i64 = any();
        kani::assume(p > 0 && q > 0 && p != q);
        let (a1, b1, c1) = v(p);
        let (a2, b2, c2) = v(q);
        // Cross product's z component = a1*b2 - b1*a2 = q - p
        let cross_z = a1 * b2 - b1 * a2;
        assert!(cross_z != 0);
    }
}
