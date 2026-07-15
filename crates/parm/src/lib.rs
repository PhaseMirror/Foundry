use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParmSealWitness {
    pub input_hash: [u8; 32],
    pub sealed_value: u64,
    pub timestamp: i64,
}

#[derive(Debug, thiserror::Error)]
pub enum ParmError {
    #[error("sealed state overflow")]
    Overflow,
}

pub struct ParmEngine;

impl ParmEngine {
    pub fn sealed_state(&self, primes: &[u64]) -> Result<u64, ParmError> {
        let mut v = match primes {
            [] => return Ok(0),
            [p] => return Ok(p.checked_mul(*p).ok_or(ParmError::Overflow)?),
            [p, ..] => p.checked_mul(*p).ok_or(ParmError::Overflow)?,
        };
        for &p in primes.iter().skip(1) {
            let p_mul_v = p.checked_mul(v).ok_or(ParmError::Overflow)?;
            let p_mul_p = p.checked_mul(p).ok_or(ParmError::Overflow)?;
            v = p_mul_v.checked_add(p_mul_p).ok_or(ParmError::Overflow)?;
        }
        Ok(v)
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn proof_deterministic() {
        let engine = ParmEngine;
        let p1: u64 = kani::any();
        let p2: u64 = kani::any();
        
        let res1 = engine.sealed_state(&[p1, p2]);
        let res2 = engine.sealed_state(&[p1, p2]);
        
        match (res1, res2) {
            (Ok(v1), Ok(v2)) => kani::assert(v1 == v2, "Deterministic"),
            (Err(_), Err(_)) => kani::assert(true, "Deterministic error"),
            _ => kani::assert(false, "Non-deterministic"),
        }
    }

    #[kani::proof]
    fn proof_no_overflow() {
        let engine = ParmEngine;
        let p1: u64 = kani::any();
        let p2: u64 = kani::any();
        kani::assume(p1 < 1000 && p2 < 1000);
        let res = engine.sealed_state(&[p1, p2]);
        kani::assert(res.is_ok(), "No overflow for small inputs");
    }
}
