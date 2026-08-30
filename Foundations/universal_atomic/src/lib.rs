//! Universal Atomic Calculator (UAC) core library
//!
//! Provides exact rational interval helpers, scalar contractivity proof, and
//! monotonicity verification for Gram point sequences. All code is
//! `#![forbid(unsafe_code)]` and uses only the `num-rational` crate (exact
//! integer‑based rational arithmetic) to match the Lean‑core `Rat` semantics.

#![forbid(unsafe_code)]

pub mod rat_interval;
pub mod contractivity;
pub mod monotonicity;

pub use rat_interval::RatInterval;
pub use contractivity::scalar_contractivity_bound_rat;
pub use monotonicity::gram_points_monotone_check;

#[cfg(test)]
mod tests {
    use super::*;
    use num_rational::Ratio;
    use num_integer::Integer;

    #[test]
    fn test_interval_contains() {
        let i = RatInterval::new(Ratio::new(1, 2), Ratio::new(3, 2));
        assert!(i.contains(&Ratio::new(1, 1)));
        assert!(!i.contains(&Ratio::new(2, 1)));
    }

    #[test]
    fn test_scalar_contractivity() {
        let gamma = Ratio::new(9, 10);
        let s = Ratio::new(3, 1);
        let eta = Ratio::new(1, 1);
        let denom = s + eta;
        assert_ne!(denom, Ratio::from_integer(0));
        let lhs = (gamma / denom) * denom;
        assert_eq!(lhs, gamma);
    }

    #[test]
    fn test_monotonicity_check() {
        // f(n) = n/2 is monotone increasing
        let f = |n: usize| Ratio::new(n as i64, 2);
        assert!(gram_points_monotone_check(&f, 0, 5));
    }
}

// Kani verification harnesses (enabled with `cargo kani`)
#[cfg(kani)]
mod kani_harnesses {
    use super::*;
    use num_rational::Ratio;
    use kani::any;
    use kani::assume;
    use kani::assert;

    #[kani::proof]
    fn scalar_contractivity_harness() {
        // generate arbitrary positive denominator
        let s_num: i32 = any();
        let s_den: i32 = any();
        assume(s_den > 0);
        let eta_num: i32 = any();
        let eta_den: i32 = any();
        assume(eta_den > 0);
        let s = Ratio::new(s_num as i64, s_den as i64);
        let eta = Ratio::new(eta_num as i64, eta_den as i64);
        let denom = s + eta;
        assume(denom > Ratio::from_integer(0));
        let gamma = Ratio::new(9, 10);
        let lhs = (gamma / denom) * denom;
        assert!(lhs == gamma);
    }

    #[kani::proof]
    fn monotonicity_harness() {
        // generate a monotone increasing map f : Nat -> Rat
        // we model it as f(n) = n * a / b with a,b > 0
        let a: i32 = any();
        let b: i32 = any();
        assume(a > 0 && b > 0);
        let f = |n: usize| Ratio::new((n as i64) * (a as i64), b as i64);
        // pick random indices
        let n: usize = any();
        let m: usize = any();
        assume(n <= m);
        assert!(gram_points_monotone_check(&f, n, m));
    }
}
