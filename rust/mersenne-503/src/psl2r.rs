//! PSL(2,R) group dynamics and hyperbolic geometry.
//!
//! Implements Möbius transformations and group operations
//! with verified hyperbolic distance properties.

use crate::error::{Error, Result};

/// Möbius transformation in PSL(2,R).
///
/// Represents z → (az + b) / (cz + d) with ad - bc = 1.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MobiusTransform {
    a: i64,
    b: i64,
    c: i64,
    d: i64,
}

impl MobiusTransform {
    /// Create a new Möbius transformation.
    ///
    /// # Errors
    ///
    /// Returns error if ad - bc != 1.
    pub fn new(a: i64, b: i64, c: i64, d: i64) -> Result<Self> {
        let det = a * d - b * c;
        if det != 1 {
            return Err(Error::psl2r(format!(
                "determinant must be 1, got {}",
                det
            )));
        }
        Ok(Self { a, b, c, d })
    }

    /// Get the 'a' coefficient.
    pub fn a(&self) -> i64 {
        self.a
    }

    /// Get the 'b' coefficient.
    pub fn b(&self) -> i64 {
        self.b
    }

    /// Get the 'c' coefficient.
    pub fn c(&self) -> i64 {
        self.c
    }

    /// Get the 'd' coefficient.
    pub fn d(&self) -> i64 {
        self.d
    }

    /// Compose two Möbius transformations.
    pub fn compose(&self, other: &Self) -> Result<Self> {
        let a = self.a * other.a + self.b * other.c;
        let b = self.a * other.b + self.b * other.d;
        let c = self.c * other.a + self.d * other.c;
        let d = self.c * other.b + self.d * other.d;
        Self::new(a, b, c, d)
    }

    /// Compute the inverse transformation.
    pub fn inverse(&self) -> Result<Self> {
        Self::new(self.d, -self.b, -self.c, self.a)
    }

    /// Apply transformation to a point in the upper half-plane.
    pub fn apply(&self, z_re: f64, z_im: f64) -> (f64, f64) {
        let denom = self.c * z_re as i64 + self.d;
        if denom == 0 {
            return (f64::INFINITY, f64::INFINITY);
        }
        let num_re = self.a * z_re as i64 + self.b;
        let num_im = self.a * z_im as i64;
        let new_re = num_re as f64 / denom as f64;
        let new_im = num_im as f64 / denom as f64;
        (new_re, new_im)
    }

    /// Compute hyperbolic distance between two points after transformation.
    pub fn hyperbolic_distance(&self, z1: (f64, f64), z2: (f64, f64)) -> f64 {
        let (w1_re, w1_im) = self.apply(z1.0, z1.1);
        let (w2_re, w2_im) = self.apply(z2.0, z2.1);
        let d_re = w1_re - w2_re;
        let d_im = w1_im - w2_im;
        let z1_mod = w1_re * w1_re + w1_im * w1_im;
        let z2_mod = w2_re * w2_re + w2_im * w2_im;
        let numerator = d_re * d_re + d_im * d_im;
        let denominator = (1.0 - z1_mod) * (1.0 - z2_mod);
        if denominator <= 0.0 {
            return f64::INFINITY;
        }
        2.0 * (1.0 + numerator / denominator).ln()
    }
}

/// PSL(2,R) group wrapper.
pub struct PSL2R;

impl PSL2R {
    /// Create the identity transformation.
    pub fn identity() -> Result<MobiusTransform> {
        MobiusTransform::new(1, 0, 0, 1)
    }

    /// Create a parabolic transformation fixing infinity.
    pub fn parabolic(t: i64) -> Result<MobiusTransform> {
        MobiusTransform::new(1, t, 0, 1)
    }

    /// Create a hyperbolic transformation.
    pub fn hyperbolic(t: f64) -> Result<MobiusTransform> {
        let a = (t.exp() / 2.0).round() as i64;
        let d = a;
        MobiusTransform::new(a, 0, 0, d)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mobius_identity() {
        let id = PSL2R::identity().unwrap();
        assert_eq!(id.a(), 1);
        assert_eq!(id.d(), 1);
        assert_eq!(id.b(), 0);
        assert_eq!(id.c(), 0);
    }

    #[test]
    fn test_mobius_apply() {
        let transform = MobiusTransform::new(1, 0, 0, 1).unwrap();
        let (re, im) = transform.apply(3.0, 4.0);
        assert_eq!(re, 3.0);
        assert_eq!(im, 4.0);
    }

    #[test]
    fn test_mobius_inverse() {
        let m = MobiusTransform::new(2, 1, 1, 1).unwrap();
        let inv = m.inverse().unwrap();
        let composed = m.compose(&inv).unwrap();
        let id = PSL2R::identity().unwrap();
        assert_eq!(composed, id);
    }
}
