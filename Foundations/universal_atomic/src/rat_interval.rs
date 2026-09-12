//! Exact rational interval helper
use num_rational::Ratio;

/// Immutable rational interval where lower <= upper.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RatInterval {
    pub lower: Ratio<i64>,
    pub upper: Ratio<i64>,
}

impl RatInterval {
    /// Construct a new interval, panicking if lower > upper.
    pub fn new(lower: Ratio<i64>, upper: Ratio<i64>) -> Self {
        assert!(lower <= upper, "Invalid RatInterval: lower > upper");
        Self { lower, upper }
    }

    /// Returns true iff `x` lies within the closed interval.
    pub fn contains(&self, x: &Ratio<i64>) -> bool {
        self.lower <= *x && *x <= self.upper
    }
}
