//! Exact rational arithmetic over `i128` — the integer-only substrate of the
//! observability calculus.
//!
//! ADR-0021 bans floating point; every matrix entry, pivot, obstruction
//! dimension, and Walsh–Hadamard coefficient below is an exact ratio `n/d`
//! with `d > 0`, gcd-cleaned. No rounding site exists, so stage attribution,
//! kernels, and witness spaces are deterministic across platforms and build
//! configurations.

use serde::{Deserialize, Deserializer, Serialize, Serializer};
use std::cmp::Ordering;
use std::fmt;
use std::ops::{Add, Div, Mul, Neg, Sub};

/// A canonical rational `n/d` with `d > 0`, normalized by `gcd(|n|, d)`.
///
/// The wire bounds (`MAX_ENTRY` in `system`) keep every intermediate product
/// inside `i128`; entries are validated at ingest (`crate::system::validate`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Q {
    pub n: i128,
    pub d: i128,
}

impl Q {
    pub const ZERO: Q = Q { n: 0, d: 1 };
    pub const ONE: Q = Q { n: 1, d: 1 };

    pub fn new(n: i128, d: i128) -> Q {
        debug_assert!(d != 0, "division by zero");
        if d == 0 {
            return Q::ZERO;
        }
        let mut n = n;
        let mut d = d;
        if d < 0 {
            n = -n;
            d = -d;
        }
        let g = gcd(n.abs(), d);
        Q { n: n / g, d: d / g }
    }

    /// From an integer coefficient.
    pub const fn from_i128(n: i128) -> Q {
        Q { n, d: 1 }
    }

    pub const fn is_zero(&self) -> bool {
        self.n == 0
    }

    pub fn recip(self) -> Q {
        Q::new(self.d, self.n)
    }

    /// The i128 value when this is an exact integer; `None` otherwise.
    pub fn as_i128(&self) -> Option<i128> {
        if self.d == 1 {
            Some(self.n)
        } else {
            None
        }
    }
}

impl fmt::Display for Q {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        if self.d == 1 {
            write!(f, "{}", self.n)
        } else {
            write!(f, "{}/{}", self.n, self.d)
        }
    }
}

impl Neg for Q {
    type Output = Q;
    fn neg(self) -> Q {
        Q::new(-self.n, self.d)
    }
}

impl Add for Q {
    type Output = Q;
    fn add(self, o: Q) -> Q {
        Q::new(self.n * o.d + o.n * self.d, self.d * o.d)
    }
}

impl Sub for Q {
    type Output = Q;
    fn sub(self, o: Q) -> Q {
        self + (-o)
    }
}

impl Mul for Q {
    type Output = Q;
    fn mul(self, o: Q) -> Q {
        Q::new(self.n * o.n, self.d * o.d)
    }
}

#[allow(clippy::suspicious_arithmetic_impl)]
impl Div for Q {
    type Output = Q;
    fn div(self, o: Q) -> Q {
        self * o.recip()
    }
}

impl PartialOrd for Q {
    fn partial_cmp(&self, other: &Q) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for Q {
    fn cmp(&self, other: &Q) -> Ordering {
        (self.n * other.d).cmp(&(other.n * self.d))
    }
}

/// Binary gcd over `i128` magnitudes.
pub fn gcd(mut a: i128, mut b: i128) -> i128 {
    while b != 0 {
        let t = b;
        b = a % b;
        a = t;
    }
    a
}

// ---------------------------------------------------------------------------
// Serde: integers render as bare numbers, ratios as `{"n":..,"d":..}`. The
// wire only ever carries coefficients that fit `i64` (system bounds), so the
// codec is i64-based and never touches serde_json's unsupported i128 number
// surface.
// ---------------------------------------------------------------------------

impl Serialize for Q {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        match self.as_i64() {
            Some(i) => serializer.serialize_i64(i),
            None => {
                use serde::ser::SerializeStruct;
                let mut s = serializer.serialize_struct("Q", 2)?;
                s.serialize_field("n", &self.n)?;
                s.serialize_field("d", &self.d)?;
                s.end()
            }
        }
    }
}

impl<'de> Deserialize<'de> for Q {
    fn deserialize<D: Deserializer<'de>>(deserializer: D) -> Result<Q, D::Error> {
        #[derive(Deserialize)]
        #[serde(untagged)]
        enum Rep {
            Int(i64),
            Pair { n: i64, d: i64 },
        }
        match Rep::deserialize(deserializer)? {
            Rep::Int(n) => Ok(Q::from_i128(n as i128)),
            Rep::Pair { n, d } => Ok(Q::new(n as i128, d as i128)),
        }
    }
}

/// Exact scalar checks shared by tests and the Kani harness surface.
pub const fn const_q(n: i128) -> Q {
    Q { n, d: 1 }
}

impl Q {
    /// The `i64` value when this an exact integer fitting `i64`; `None` else.
    pub fn as_i64(&self) -> Option<i64> {
        if self.d == 1 {
            i64::try_from(self.n).ok()
        } else {
            None
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn normalization_makes_3_6_into_1_2() {
        assert_eq!(Q::new(3, 6), Q::new(1, 2));
        assert_eq!(Q::new(-3, 6), Q::new(-1, 2));
        assert_eq!(Q::new(3, -6), Q::new(-1, 2));
    }

    #[test]
    fn arithmetic_is_exact() {
        assert_eq!(Q::new(1, 3) + Q::new(1, 6), Q::new(1, 2));
        assert_eq!(Q::new(1, 3) - Q::new(1, 2), Q::new(-1, 6));
        assert_eq!(Q::new(2, 3) * Q::new(3, 4), Q::new(1, 2));
        assert_eq!(Q::new(1, 2) / Q::new(3, 4), Q::new(2, 3));
    }

    #[test]
    fn ordering_is_cross_multiplied() {
        assert!(Q::new(1, 3) < Q::new(1, 2));
        assert!(Q::new(-1, 2) < Q::new(1, 3));
        assert_eq!(Q::new(2, 4).cmp(&Q::new(1, 2)), Ordering::Equal);
    }

    #[test]
    fn integer_round_trips_bare() {
        let q = Q::from_i128(7);
        let json = serde_json::to_string(&q).unwrap();
        assert_eq!(json, "7");
        let back: Q = serde_json::from_str(&json).unwrap();
        assert_eq!(back, q);
        let ratio = serde_json::from_str::<Q>(r#"{"n":1,"d":2}"#).unwrap();
        assert_eq!(ratio, Q::new(1, 2));
    }
}
