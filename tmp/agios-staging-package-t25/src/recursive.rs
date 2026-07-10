use num_bigint::BigUint;
use num_traits::{Zero, One};
use serde::{Serialize, Deserialize};
use sha3::{Digest, Keccak256};
use thiserror::Error;

/// Pasta prime field representing Pallas/Vesta base field coordinates.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct PastaField {
    pub value: BigUint,
    pub modulus: BigUint,
}

impl PastaField {
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

/// Elliptic curve point representation in Affine coordinates.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub enum AffinePoint {
    Identity { modulus: BigUint, a: BigUint, b: BigUint },
    Point {
        x: PastaField,
        y: PastaField,
        a: PastaField,
        b: PastaField,
    },
}

impl AffinePoint {
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

                let num = y2.sub(y1);
                let den = x2.sub(x1);
                let lambda = num.mul(&den.inv().unwrap());

                let x3 = lambda.mul(&lambda).sub(x1).sub(x2);
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

                let three = PastaField::new(BigUint::from(3u64), x.modulus.clone());
                let two = PastaField::new(BigUint::from(2u64), x.modulus.clone());
                
                let num = x.mul(x).mul(&three).add(a);
                let den = y.mul(&two);
                let lambda = num.mul(&den.inv().unwrap());

                let x3 = lambda.mul(&lambda).sub(&x.mul(&two));
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

    pub fn to_affine(&self) -> Option<(BigUint, BigUint)> {
        match self {
            Self::Identity { .. } => None,
            Self::Point { x, y, .. } => Some((x.value.clone(), y.value.clone())),
        }
    }
}

/// Pedersen commitment scheme: C = v*G + r*H
pub struct PedersenCommitment {
    pub g: AffinePoint,
    pub h: AffinePoint,
}

impl PedersenCommitment {
    pub fn new(g: AffinePoint, h: AffinePoint) -> Self {
        Self { g, h }
    }

    pub fn commit(&self, value: &BigUint, blinding: &BigUint) -> AffinePoint {
        let vg = self.g.mul_scalar(value);
        let rh = self.h.mul_scalar(blinding);
        vg.add(&rh)
    }
}

pub fn get_pallas_params() -> (BigUint, BigUint, BigUint, BigUint) {
    let p = BigUint::parse_bytes(b"40000000000000000000000000000000224698fc094cf91b992d30ed00000001", 16).unwrap();
    let q = BigUint::parse_bytes(b"40000000000000000000000000000000224698fc0994a8dd8c46eb2100000001", 16).unwrap();
    let a = BigUint::zero();
    let b = BigUint::from(5u64);
    (p, q, a, b)
}

/// Recursive Proof Object (RPO) representing a wrapped STARK proof.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecursiveProofObject {
    pub protocol_v: u32,
    pub inner_root: [u8; 32],      // Inner trace commitment root
    pub seal_x: String,            // Hex encoded Pedersen commitment x coordinate
    pub seal_y: String,            // Hex encoded Pedersen commitment y coordinate
}

/// Aggregated Proof Object (APO) combining multiple RPOs into one.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AggregatedProofObject {
    pub protocol_v: u32,
    pub aggregate_root: [u8; 32],  // Keccak256 hash of member roots
    pub member_roots: Vec<[u8; 32]>,
    pub seal_x: String,
    pub seal_y: String,
}

#[derive(Error, Debug)]
pub enum RecursiveProverError {
    #[error("Trace commitment must be 32 bytes.")]
    InvalidTraceCommitment,
    #[error("Pedersen commitment generated an identity point (invalid seal).")]
    InvalidSealPoint,
}

pub struct RecursiveProofBridge {
    pub pedersen: PedersenCommitment,
}

impl RecursiveProofBridge {
    pub fn new() -> Self {
        let (p, _q, a, b) = get_pallas_params();
        
        // Pallas generator: (-1, 2)
        let g = AffinePoint::Point {
            x: PastaField::new(p.clone() - BigUint::from(1u64), p.clone()),
            y: PastaField::new(BigUint::from(2u64), p.clone()),
            a: PastaField::new(a.clone(), p.clone()),
            b: PastaField::new(b.clone(), p.clone()),
        };
        
        let h = g.double();
        
        Self {
            pedersen: PedersenCommitment::new(g, h),
        }
    }

    /// Wraps a single state root trace commitment hash into an RPO v1.
    pub fn wrap_state_root(
        &self,
        trace_commitment: &[u8; 32],
        blinding: &BigUint,
    ) -> Result<RecursiveProofObject, RecursiveProverError> {
        let inner_root_biguint = BigUint::from_bytes_le(trace_commitment);
        let seal = self.pedersen.commit(&inner_root_biguint, blinding);
        
        let (sx, sy) = seal.to_affine().ok_or(RecursiveProverError::InvalidSealPoint)?;

        Ok(RecursiveProofObject {
            protocol_v: 1,
            inner_root: *trace_commitment,
            seal_x: sx.to_str_radix(16),
            seal_y: sy.to_str_radix(16),
        })
    }

    /// Aggregates multiple RPOs into a single APO v1 (Pallas/Vesta recursive proof root).
    pub fn aggregate_rpos(
        &self,
        rpos: &[RecursiveProofObject],
        blinding: &BigUint,
    ) -> Result<AggregatedProofObject, RecursiveProverError> {
        // Compute Keccak256 of all member roots
        let mut hasher = Keccak256::new();
        for rpo in rpos {
            hasher.update(&rpo.inner_root);
        }
        let aggregate_root: [u8; 32] = hasher.finalize().into();

        // Generate Aggregate Seal
        let agg_root_biguint = BigUint::from_bytes_le(&aggregate_root);
        let seal = self.pedersen.commit(&agg_root_biguint, blinding);
        let (sx, sy) = seal.to_affine().ok_or(RecursiveProverError::InvalidSealPoint)?;

        Ok(AggregatedProofObject {
            protocol_v: 1,
            aggregate_root,
            member_roots: rpos.iter().map(|r| r.inner_root).collect(),
            seal_x: sx.to_str_radix(16),
            seal_y: sy.to_str_radix(16),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_recursive_pallas_wrap() {
        let bridge = RecursiveProofBridge::new();
        let trace_root = [42u8; 32];
        let blinding = BigUint::from(98765u64);
        let rpo = bridge.wrap_state_root(&trace_root, &blinding).unwrap();
        
        assert_eq!(rpo.protocol_v, 1);
        assert_eq!(rpo.inner_root, trace_root);
        assert!(!rpo.seal_x.is_empty());
        assert!(!rpo.seal_y.is_empty());
    }

    #[test]
    fn test_aggregation() {
        let bridge = RecursiveProofBridge::new();
        let blinding = BigUint::from(98765u64);

        let rpo1 = bridge.wrap_state_root(&[1u8; 32], &blinding).unwrap();
        let rpo2 = bridge.wrap_state_root(&[2u8; 32], &blinding).unwrap();

        let apo = bridge.aggregate_rpos(&[rpo1, rpo2], &blinding).unwrap();
        assert_eq!(apo.protocol_v, 1);
        assert_eq!(apo.member_roots.len(), 2);
        assert!(!apo.seal_x.is_empty());
    }
}
