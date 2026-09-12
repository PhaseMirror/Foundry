//! BN254 Elliptic Curve Arithmetic over Base Field F_p
//! Curve Equation: y^2 = x^3 + 3 (mod p)

use num_bigint::{BigInt, BigUint, ToBigInt};
use num_traits::{One, Zero};
use serde::{Deserialize, Serialize};

/// Affine point on BN254 G1 curve (or Point at Infinity).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum G1Point {
    Infinity,
    Affine { x: BigUint, y: BigUint },
}

pub struct Bn254;

impl Bn254 {
    /// Base field prime p: 21888242871839275222246405745257275088696311157297823662689037894645226208583
    pub fn p() -> BigUint {
        "21888242871839275222246405745257275088696311157297823662689037894645226208583"
            .parse::<BigUint>()
            .unwrap()
    }

    /// Scalar field group order q: 21888242871839275222246405745257275088548364400416034343698204186575808495617
    pub fn q() -> BigUint {
        "21888242871839275222246405745257275088548364400416034343698204186575808495617"
            .parse::<BigUint>()
            .unwrap()
    }

    /// Canonical generator G = (1, 2) on BN254 G1.
    pub fn generator_g() -> G1Point {
        G1Point::Affine {
            x: BigUint::one(),
            y: 2u32.into(),
        }
    }

    /// Check if point satisfies curve equation: y^2 ≡ x^3 + 3 (mod p).
    pub fn is_on_curve(point: &G1Point) -> bool {
        match point {
            G1Point::Infinity => true,
            G1Point::Affine { x, y } => {
                let p = Self::p();
                let y2 = (y * y) % &p;
                let x3 = (x * x % &p * x) % &p;
                let rhs = (x3 + 3u32) % &p;
                y2 == rhs
            }
        }
    }

    /// Modular inverse in F_p using Extended Euclidean Algorithm.
    pub fn mod_inv(a: &BigUint, m: &BigUint) -> Option<BigUint> {
        let a_bi = a.to_bigint().unwrap();
        let m_bi = m.to_bigint().unwrap();
        let (g, x, _) = Self::extended_gcd(&a_bi, &m_bi);
        if g.is_one() {
            let res = (x % &m_bi + &m_bi) % &m_bi;
            res.to_biguint()
        } else {
            None
        }
    }

    fn extended_gcd(a: &BigInt, b: &BigInt) -> (BigInt, BigInt, BigInt) {
        if b.is_zero() {
            (a.clone(), BigInt::one(), BigInt::zero())
        } else {
            let (g, x1, y1) = Self::extended_gcd(b, &(a % b));
            let x = y1.clone();
            let y = x1 - (a / b) * y1;
            (g, x, y)
        }
    }

    /// Affine point addition on BN254 G1.
    pub fn add(p1: &G1Point, p2: &G1Point) -> G1Point {
        match (p1, p2) {
            (G1Point::Infinity, other) | (other, G1Point::Infinity) => other.clone(),
            (G1Point::Affine { x: x1, y: y1 }, G1Point::Affine { x: x2, y: y2 }) => {
                let p = Self::p();
                if x1 == x2 {
                    if (y1 + y2) % &p == BigUint::zero() {
                        return G1Point::Infinity;
                    }
                    // Point doubling: lambda = (3 * x1^2) / (2 * y1) mod p
                    let num = (3u32 * x1 * x1) % &p;
                    let den = (2u32 * y1) % &p;
                    let lambda = (num * Self::mod_inv(&den, &p).unwrap()) % &p;

                    let x3 = ((&lambda * &lambda) % &p + &p + &p - (2u32 * x1) % &p) % &p;
                    let y3 = ((&lambda * (&p + x1 - &x3)) % &p + &p - y1) % &p;
                    G1Point::Affine { x: x3, y: y3 }
                } else {
                    // Distinct points: lambda = (y2 - y1) / (x2 - x1) mod p
                    let num = (&p + y2 - y1 % &p) % &p;
                    let den = (&p + x2 - x1 % &p) % &p;
                    let lambda = (num * Self::mod_inv(&den, &p).unwrap()) % &p;

                    let x3 = ((&lambda * &lambda) % &p + &p + &p - x1 - x2) % &p;
                    let y3 = ((&lambda * (&p + x1 - &x3)) % &p + &p - y1) % &p;
                    G1Point::Affine { x: x3, y: y3 }
                }
            }
        }
    }

    /// Scalar multiplication: [scalar]P using double-and-add.
    pub fn scalar_mul(p: &G1Point, scalar: &BigUint) -> G1Point {
        let mut result = G1Point::Infinity;
        let mut addend = p.clone();
        let mut s = scalar.clone();

        while !s.is_zero() {
            if &s % 2u32 == BigUint::one() {
                result = Self::add(&result, &addend);
            }
            addend = Self::add(&addend, &addend);
            s /= 2u32;
        }

        result
    }

    /// Subgroup check: [q]P == O.
    pub fn is_in_subgroup(point: &G1Point) -> bool {
        let q = Self::q();
        let scaled = Self::scalar_mul(point, &q);
        scaled == G1Point::Infinity
    }
}
