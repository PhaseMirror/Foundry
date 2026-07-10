// Removed unused imports

use num_prime::nt_funcs::is_prime;
use num_prime::Primality;

pub fn isprime(n: i64) -> bool {
    if n < 0 { return false; }
    match is_prime(&(n as u64), None) {
        Primality::Yes | Primality::Probable(_) => true,
        Primality::No => false,
    }
}

/// Represents an element in the Galois Field GF(p).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct GFElement {
    pub value: i64,
    pub p: i64,
}

impl GFElement {
    /// Create a new element in GF(p). The value is automatically reduced modulo p.
    pub fn new(value: i64, p: i64) -> Self {
        assert!(p > 1, "Modulus must be > 1");
        Self {
            value: value.rem_euclid(p),
            p,
        }
    }

    pub fn add(&self, other: &Self) -> Self {
        assert_eq!(self.p, other.p, "Field mismatch");
        Self::new(self.value + other.value, self.p)
    }

    pub fn mul(&self, other: &Self) -> Self {
        assert_eq!(self.p, other.p, "Field mismatch");
        Self::new(self.value * other.value, self.p)
    }

    /// Multiplicative inverse in GF(p) using Extended Euclidean Algorithm.
    /// Returns None if the element is 0.
    pub fn inv(&self) -> Option<Self> {
        if self.value == 0 {
            return None;
        }
        let eea = Self::extended_gcd(self.value, self.p);
        // eea.1 is the coefficient of self.value
        Some(Self::new(eea.1, self.p))
    }

    /// Extended Euclidean Algorithm.
    /// Returns (gcd, x, y) such that ax + by = gcd(a, b).
    fn extended_gcd(a: i64, b: i64) -> (i64, i64, i64) {
        if a == 0 {
            return (b, 0, 1);
        }
        let (g, x1, y1) = Self::extended_gcd(b.rem_euclid(a), a);
        let x = y1 - (b / a) * x1;
        let y = x1;
        (g, x, y)
    }
}

/// A state sector inhabiting the prime-dimensional space H_p.
#[derive(Debug, Clone)]
pub struct PrimeSector {
    pub p: i64,
    pub state: Vec<GFElement>, // Dimension p
}

impl PrimeSector {
    pub fn new(p: i64, initial_values: Vec<i64>) -> Self {
        let state = initial_values.into_iter().map(|v| GFElement::new(v, p)).collect();
        Self { p, state }
    }
}

/// The Binary-to-Prime Lifting Function (Level 2)
/// Takes a normalized float in [0, 1) and maps it into GF(p).
pub fn lift_float_to_gfp(value: f64, p: i64) -> GFElement {
    let clamped = value.max(0.0).min(0.999999);
    // Simple binning encoder: [0, 1) -> {0, 1, ..., p-1}
    let mapped = (clamped * p as f64).floor() as i64;
    GFElement::new(mapped, p)
}

/// Level 4: Cross-Sector Interaction via Chinese Remainder Theorem (CRT)
/// Given an element a in GF(p) and b in GF(q) (with gcd(p,q)=1),
/// find the unique x in Z/(pq)Z such that x = a mod p and x = b mod q.
pub fn crt_reconstruct(a: &GFElement, b: &GFElement) -> GFElement {
    let p = a.p;
    let q = b.p;
    
    // N = pq
    let n = p * q;
    
    // We need inv_q = q^-1 mod p and inv_p = p^-1 mod q
    // Equivalently, we use Extended Euclidean Algorithm on (p, q):
    // p * m1 + q * m2 = 1 (since p, q are prime and distinct, gcd is 1)
    let (_, m1, m2) = GFElement::extended_gcd(p, q);
    
    // The CRT formula:
    // x = (a * q * m2 + b * p * m1) mod (pq)
    let x = a.value * q * m2 + b.value * p * m1;
    
    GFElement::new(x, n)
}

/// Solves the system: x = a_i mod p_i for all i.
pub fn crt_reconstruct_multi(elements: &[GFElement]) -> GFElement {
    if elements.is_empty() {
        panic!("Empty elements list for CRT");
    }
    
    let mut result = elements[0];
    for next in &elements[1..] {
        result = crt_reconstruct(&result, next);
    }
    result
}

/// A state vector in the semantic layer, partitioned into prime sectors.
#[derive(Debug, Clone)]
pub struct PartitionedState {
    pub sectors: Vec<PrimeSector>,
}

impl PartitionedState {
    pub fn new(primes: &[i64], dimensions: &[usize]) -> Self {
        let sectors = primes.iter().zip(dimensions.iter())
            .map(|(&p, &d)| {
                PrimeSector::new(p, vec![0; d])
            })
            .collect();
        Self { sectors }
    }

    /// Reconstruct a single scalar value from the first element of each sector using CRT.
    pub fn reconstruct_scalar(&self) -> GFElement {
        let residues: Vec<GFElement> = self.sectors.iter()
            .map(|s| s.state[0])
            .collect();
        crt_reconstruct_multi(&residues)
    }

    /// Apply a cyclic shift operator (Hadamard-like basis shift) to each sector.
    pub fn apply_shift(&mut self) {
        for sector in &mut self.sectors {
            let mut new_state = sector.state.clone();
            let p = sector.p as usize;
            for i in 0..p {
                // S|n> = |n+1 mod p>
                new_state[(i + 1) % p] = sector.state[i];
            }
            sector.state = new_state;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_gf_arithmetic() {
        let a = GFElement::new(4, 7);
        let b = GFElement::new(5, 7);
        assert_eq!(a.add(&b).value, 2); // 9 mod 7 = 2
        assert_eq!(a.mul(&b).value, 6); // 20 mod 7 = 6
        assert_eq!(a.inv().unwrap().value, 2); // 4 * 2 = 8 = 1 mod 7
    }

    #[test]
    fn test_crt() {
        // x = 2 mod 3, x = 3 mod 5 => x = 8 mod 15
        let a = GFElement::new(2, 3);
        let b = GFElement::new(3, 5);
        let x = crt_reconstruct(&a, &b);
        assert_eq!(x.value, 8);
        assert_eq!(x.p, 15);
    }
}
