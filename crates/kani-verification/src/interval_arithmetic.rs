//! Interval arithmetic computable kernels.
//!
//! These implementations back the Lean axioms in:
//! `crates/abd_framework/F1Square/F1Square/Interval.lean`

/// An interval [low, high] with low <= high.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Interval {
    pub low: f64,
    pub high: f64,
}

impl Interval {
    pub fn new(low: f64, high: f64) -> Self {
        if low > high {
            panic!("Interval low must be <= high");
        }
        Self { low, high }
    }

    pub fn from_rat(low: i64, high: i64) -> Self {
        if low > high {
            panic!("Interval low must be <= high");
        }
        Self {
            low: low as f64,
            high: high as f64,
        }
    }

    pub fn add(&self, other: &Self) -> Self {
        Self {
            low: self.low + other.low,
            high: self.high + other.high,
        }
    }

    pub fn sub(&self, other: &Self) -> Self {
        Self {
            low: self.low - other.high,
            high: self.high - other.low,
        }
    }

    pub fn mul_pos(&self, scalar: f64) -> Self {
        if scalar <= 0.0 {
            panic!("Scalar must be positive");
        }
        Self {
            low: self.low * scalar,
            high: self.high * scalar,
        }
    }

    pub fn mul_nonneg(&self, other: &Self) -> Self {
        if self.low < 0.0 || other.low < 0.0 {
            panic!("Intervals must be non-negative");
        }
        Self {
            low: self.low * other.low,
            high: self.high * other.high,
        }
    }

    pub fn div(&self, other: &Self) -> Self {
        if other.low <= 0.0 {
            panic!("Divisor interval must be positive");
        }
        Self {
            low: self.low / other.high,
            high: self.high / other.low,
        }
    }

    pub fn abs(&self) -> Self {
        if self.low >= 0.0 {
            Self {
                low: self.low,
                high: self.high,
            }
        } else if self.high <= 0.0 {
            Self {
                low: -self.high,
                high: -self.low,
            }
        } else {
            Self {
                low: 0.0,
                high: self.high.max(-self.low),
            }
        }
    }

    pub fn contains(&self, x: f64) -> bool {
        self.low <= x && x <= self.high
    }

    pub fn width(&self) -> f64 {
        self.high - self.low
    }
}

// ---------------------------------------------------------------------------
// Kani verification harnesses
// ---------------------------------------------------------------------------

#[cfg(kani)]
mod verification {
    use super::*;
    use kani::proof;

    #[proof]
    fn proof_interval_add_inv() {
        let i1 = Interval {
            low: kani::any(),
            high: kani::any(),
        };
        let i2 = Interval {
            low: kani::any(),
            high: kani::any(),
        };
        kani::assume(i1.low <= i1.high);
        kani::assume(i2.low <= i2.high);
        kani::assume(i1.low.is_finite() && i1.high.is_finite());
        kani::assume(i2.low.is_finite() && i2.high.is_finite());
        
        let result = i1.add(&i2);
        kani::assert(result.low <= result.high, "Interval add: low <= high");
    }

    #[proof]
    fn proof_interval_sub_inv() {
        let i1 = Interval {
            low: kani::any(),
            high: kani::any(),
        };
        let i2 = Interval {
            low: kani::any(),
            high: kani::any(),
        };
        kani::assume(i1.low <= i1.high);
        kani::assume(i2.low <= i2.high);
        kani::assume(i1.low.is_finite() && i1.high.is_finite());
        kani::assume(i2.low.is_finite() && i2.high.is_finite());
        
        let result = i1.sub(&i2);
        kani::assert(result.low <= result.high, "Interval sub: low <= high");
    }

    #[proof]
    fn proof_interval_mul_pos_inv() {
        let i = Interval {
            low: kani::any(),
            high: kani::any(),
        };
        let scalar: f64 = kani::any();
        kani::assume(i.low <= i.high);
        kani::assume(i.low.is_finite() && i.high.is_finite());
        kani::assume(scalar > 0.0 && scalar.is_finite());
        
        let result = i.mul_pos(scalar);
        kani::assert(result.low <= result.high, "Interval mul_pos: low <= high");
    }

    #[proof]
    fn proof_interval_div_inv() {
        let i1 = Interval {
            low: kani::any(),
            high: kani::any(),
        };
        let i2 = Interval {
            low: kani::any(),
            high: kani::any(),
        };
        kani::assume(i1.low <= i1.high);
        kani::assume(i2.low <= i2.high);
        kani::assume(i1.low.is_finite() && i1.high.is_finite());
        kani::assume(i2.low.is_finite() && i2.high.is_finite());
        kani::assume(i2.low > 0.0);
        
        let result = i1.div(&i2);
        kani::assert(result.low <= result.high, "Interval div: low <= high");
    }

    #[proof]
    fn proof_interval_abs_inv() {
        let i = Interval {
            low: kani::any(),
            high: kani::any(),
        };
        kani::assume(i.low <= i.high);
        kani::assume(i.low.is_finite() && i.high.is_finite());
        
        let result = i.abs();
        kani::assert(result.low <= result.high, "Interval abs: low <= high");
    }

    #[proof]
    fn proof_interval_contains_consistent() {
        let i = Interval {
            low: kani::any(),
            high: kani::any(),
        };
        let x: f64 = kani::any();
        kani::assume(i.low <= i.high);
        kani::assume(i.low.is_finite() && i.high.is_finite());
        kani::assume(x.is_finite());
        
        let contained = i.contains(x);
        if contained {
            kani::assert(i.low <= x && x <= i.high, "Contains implies in bounds");
        }
    }

    #[proof]
    fn proof_interval_width_nonnegative() {
        let i = Interval {
            low: kani::any(),
            high: kani::any(),
        };
        kani::assume(i.low <= i.high);
        kani::assume(i.low.is_finite() && i.high.is_finite());
        
        let width = i.width();
        kani::assert(width >= 0.0, "Interval width must be non-negative");
    }
}
