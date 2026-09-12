use num_bigint::BigInt;
use num_traits::{One, Zero};

pub struct RnsLane {
    pub modulus: BigInt,
}

impl RnsLane {
    pub fn new(modulus: BigInt) -> Self {
        Self { modulus }
    }

    pub fn encode(&self, x: &BigInt) -> BigInt {
        x % &self.modulus
    }

    pub fn add(&self, a: &BigInt, b: &BigInt) -> BigInt {
        (a + b) % &self.modulus
    }

    pub fn mul(&self, a: &BigInt, b: &BigInt) -> BigInt {
        (a * b) % &self.modulus
    }

    pub fn sub(&self, a: &BigInt, b: &BigInt) -> BigInt {
        let res = (a - b) % &self.modulus;
        if res < BigInt::zero() {
            res + &self.modulus
        } else {
            res
        }
    }
}

pub fn rns_encode(x: &BigInt, moduli: &[BigInt]) -> Vec<BigInt> {
    moduli.iter().map(|m| x % m).collect()
}

pub fn rns_decode(residues: &[BigInt], moduli: &[BigInt]) -> BigInt {
    assert_eq!(residues.len(), moduli.len());

    let mut m_total = BigInt::one();
    for m in moduli {
        m_total *= m;
    }

    let mut x = BigInt::zero();
    for (r_i, m_i) in residues.iter().zip(moduli.iter()) {
        let m_i_inv = &m_total / m_i;
        let y_i = mod_inverse(&m_i_inv, m_i).expect("Moduli must be coprime");
        x += r_i * &m_i_inv * y_i;
    }

    x % m_total
}

fn mod_inverse(a: &BigInt, m: &BigInt) -> Option<BigInt> {
    let (g, x, _) = extended_gcd(a, m);
    if g != BigInt::one() {
        None
    } else {
        Some((x % m + m) % m)
    }
}

fn extended_gcd(a: &BigInt, b: &BigInt) -> (BigInt, BigInt, BigInt) {
    if *a == BigInt::zero() {
        (b.clone(), BigInt::zero(), BigInt::one())
    } else {
        let (g, x, y) = extended_gcd(&(b % a), a);
        (g, y - (b / a) * &x, x)
    }
}
