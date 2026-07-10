use num_bigint::BigUint;
use num_traits::{Zero, One};
use serde::{Serialize, Deserialize};

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct PastaField<const N: usize> {
    pub value: BigUint,
    pub modulus: BigUint,
}

impl<const N: usize> PastaField<N> {
    pub fn new(value: BigUint, modulus: BigUint) -> Self {
        Self {
            value: value % &modulus,
            modulus,
        }
    }

    pub fn zero(modulus: BigUint) -> Self {
        Self { value: BigUint::zero(), modulus }
    }

    pub fn one(modulus: BigUint) -> Self {
        Self { value: BigUint::one(), modulus }
    }

    pub fn add(&self, other: &Self) -> Self {
        Self::new(&self.value + &other.value, self.modulus.clone())
    }

    pub fn sub(&self, other: &Self) -> Self {
        if self.value >= other.value {
            Self::new(&self.value - &other.value, self.modulus.clone())
        } else {
            Self::new(&self.modulus + &self.value - &other.value, self.modulus.clone())
        }
    }

    pub fn mul(&self, other: &Self) -> Self {
        Self::new(&self.value * &other.value, self.modulus.clone())
    }

    pub fn pow(&self, exp: &BigUint) -> Self {
        Self::new(self.value.modpow(exp, &self.modulus), self.modulus.clone())
    }

    pub fn inv(&self) -> Option<Self> {
        if self.value.is_zero() {
            return None;
        }
        let exp = &self.modulus - BigUint::from(2u64);
        Some(self.pow(&exp))
    }
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub enum AffinePoint<const N: usize> {
    Identity { modulus: BigUint, a: BigUint, b: BigUint },
    Point {
        x: PastaField<N>,
        y: PastaField<N>,
        a: PastaField<N>,
        b: PastaField<N>,
    },
}

impl<const N: usize> AffinePoint<N> {
    pub fn identity(modulus: BigUint, a: BigUint, b: BigUint) -> Self {
        Self::Identity { modulus, a, b }
    }

    pub fn is_identity(&self) -> bool {
        matches!(self, Self::Identity { .. })
    }

    pub fn add(&self, other: &Self) -> Self {
        match (self, other) {
            (Self::Identity { .. }, _) => other.clone(),
            (_, Self::Identity { .. }) => self.clone(),
            (
                Self::Point { x: x1, y: y1, a, b, .. },
                Self::Point { x: x2, y: y2, .. },
            ) => {
                if x1 == x2 {
                    if y1 == y2 {
                        return self.double();
                    } else {
                        return Self::identity(x1.modulus.clone(), a.value.clone(), b.value.clone());
                    }
                }

                // lambda = (y2 - y1) / (x2 - x1)
                let num = y2.sub(y1);
                let den = x2.sub(x1);
                let lambda = num.mul(&den.inv().unwrap());

                // x3 = lambda^2 - x1 - x2
                let x3 = lambda.mul(&lambda).sub(x1).sub(x2);

                // y3 = lambda(x1 - x3) - y1
                let y3 = lambda.mul(&x1.sub(&x3)).sub(y1);

                Self::Point {
                    x: x3,
                    y: y3,
                    a: a.clone(),
                    b: b.clone(),
                }
            }
        }
    }

    pub fn double(&self) -> Self {
        match self {
            Self::Identity { .. } => self.clone(),
            Self::Point { x, y, a, b } => {
                if y.value.is_zero() {
                    return Self::identity(x.modulus.clone(), a.value.clone(), b.value.clone());
                }

                // lambda = (3x^2 + a) / (2y)
                let three = PastaField::new(BigUint::from(3u64), x.modulus.clone());
                let two = PastaField::new(BigUint::from(2u64), x.modulus.clone());
                
                let num = x.mul(x).mul(&three).add(a);
                let den = y.mul(&two);
                let lambda = num.mul(&den.inv().unwrap());

                // x3 = lambda^2 - 2x
                let x3 = lambda.mul(&lambda).sub(&x.mul(&two));

                // y3 = lambda(x - x3) - y
                let y3 = lambda.mul(&x.sub(&x3)).sub(y);

                Self::Point {
                    x: x3,
                    y: y3,
                    a: a.clone(),
                    b: b.clone(),
                }
            }
        }
    }

    pub fn mul_scalar(&self, scalar: &BigUint) -> Self {
        let mut res = match self {
            Self::Identity { modulus, a, b } => Self::identity(modulus.clone(), a.clone(), b.clone()),
            Self::Point { x, a, b, .. } => Self::identity(x.modulus.clone(), a.value.clone(), b.value.clone()),
        };
        let mut temp = self.clone();
        let mut s = scalar.clone();

        while !s.is_zero() {
            if &s % 2u64 == BigUint::one() {
                res = res.add(&temp);
            }
            temp = temp.double();
            s >>= 1;
        }
        res
    }

    /// Convert point to affine coordinates (x, y).
    pub fn to_affine(&self) -> Option<(BigUint, BigUint)> {
        match self {
            Self::Identity { .. } => None,
            Self::Point { x, y, .. } => Some((x.value.clone(), y.value.clone())),
        }
    }
}

/// Pedersen commitment: C = x*G + r*H
pub struct PedersenCommitment<const N: usize> {
    pub g: AffinePoint<N>,
    pub h: AffinePoint<N>,
}

impl<const N: usize> PedersenCommitment<N> {
    pub fn new(g: AffinePoint<N>, h: AffinePoint<N>) -> Self {
        Self { g, h }
    }

    pub fn commit(&self, value: &BigUint, blinding: &BigUint) -> AffinePoint<N> {
        let vg = self.g.mul_scalar(value);
        let rh = self.h.mul_scalar(blinding);
        vg.add(&rh)
    }

    pub fn verify(&self, commitment: &AffinePoint<N>, value: &BigUint, blinding: &BigUint) -> bool {
        let expected = self.commit(value, blinding);
        commitment == &expected
    }
}

pub fn get_pallas_params() -> (BigUint, BigUint, BigUint, BigUint) {
    let p = BigUint::parse_bytes(b"40000000000000000000000000000000224698fc094cf91b992d30ed00000001", 16).unwrap();
    let q = BigUint::parse_bytes(b"40000000000000000000000000000000224698fc0994a8dd8c46eb2100000001", 16).unwrap();
    let a = BigUint::zero();
    let b = BigUint::from(5u64);
    (p, q, a, b)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_pallas_algebra() {
        let (p, q, a, b) = get_pallas_params();
        
        // Pallas generator: (-1, 2)
        let g = AffinePoint::<32>::Point {
            x: PastaField::<32>::new(p.clone() - BigUint::from(1u64), p.clone()),
            y: PastaField::<32>::new(BigUint::from(2u64), p.clone()),
            a: PastaField::<32>::new(a.clone(), p.clone()),
            b: PastaField::<32>::new(b.clone(), p.clone()),
        };

        // Manual doubling check: 2g = (41/16, -299/64)
        let g2 = g.double();
        if let AffinePoint::Point { ref x, ref y, .. } = g2 {
            let sixteen_inv = PastaField::<32>::new(BigUint::from(16u64), p.clone()).inv().unwrap();
            let sixtyfour_inv = PastaField::<32>::new(BigUint::from(64u64), p.clone()).inv().unwrap();
            let expected_x = PastaField::<32>::new(BigUint::from(41u64), p.clone()).mul(&sixteen_inv);
            let expected_y = PastaField::<32>::new(p.clone() - BigUint::from(299u64), p.clone()).mul(&sixtyfour_inv);
            
            assert_eq!(*x, expected_x, "2g.x mismatch");
            assert_eq!(*y, expected_y, "2g.y mismatch");
        } else {
            panic!("2g is identity");
        }

        // g * 3 = g + 2g
        let g3 = g.mul_scalar(&BigUint::from(3u64));
        let expected_g3 = g.add(&g2);
        assert_eq!(g3, expected_g3, "g*3 mismatch");

        // Scalar multiplication by q (group order) should give identity
        let res = g.mul_scalar(&q);
        assert!(res.is_identity(), "g * q must be identity");
    }
}
