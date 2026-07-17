use serde::{Deserialize, Serialize};

#[cfg(feature = "triple-lock")]
pub mod triple_lock;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MultiplicityOperator {
    pub name: String,
    pub prime_indices: Vec<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CertificationWitness {
    pub operator_hash: [u8; 32],
    pub is_admissible: bool,
    pub timestamp: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZenoWitness {
    pub state_hash: [u8; 32],
    pub is_zeno_contractive: bool,
    pub timestamp: i64,
}

#[derive(Debug, thiserror::Error)]
pub enum AffineCoreViolation {
    #[error("operator {0} is not admissible")]
    NotAdmissible(String),
    #[error("Zeno contractivity violated")]
    ZenoViolation,
}

pub struct AffineCoreEngine;

impl AffineCoreEngine {
    pub fn certify(&self, op: &MultiplicityOperator) -> Result<CertificationWitness, AffineCoreViolation> {
        if op.prime_indices.is_empty() {
            return Err(AffineCoreViolation::NotAdmissible(op.name.clone()));
        }
        
        #[cfg(kani)]
        let operator_hash = [0u8; 32];
        #[cfg(not(kani))]
        let operator_hash = {
            let mut hasher = blake3::Hasher::new();
            hasher.update(op.name.as_bytes());
            for p in &op.prime_indices {
                hasher.update(&p.to_le_bytes());
            }
            hasher.finalize().into()
        };
        
        #[cfg(kani)]
        let timestamp = 0;
        #[cfg(not(kani))]
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs() as i64;
            
        Ok(CertificationWitness {
            operator_hash,
            is_admissible: true,
            timestamp,
        })
    }

    pub fn zeno_check(&self, state: u64, transition: &dyn Fn(u64) -> u64, max_steps: u64) -> Result<ZenoWitness, AffineCoreViolation> {
        let mut curr = state;
        let mut next = transition(curr);
        let mut steps = 0;
        
        while curr != next {
            if steps >= max_steps {
                return Err(AffineCoreViolation::ZenoViolation);
            }
            curr = next;
            next = transition(curr);
            steps += 1;
        }
        
        #[cfg(kani)]
        let state_hash = [0u8; 32];
        #[cfg(not(kani))]
        let state_hash = {
            let mut hasher = blake3::Hasher::new();
            hasher.update(&state.to_le_bytes());
            hasher.finalize().into()
        };
        
        #[cfg(kani)]
        let timestamp = 0;
        #[cfg(not(kani))]
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs() as i64;

        Ok(ZenoWitness {
            state_hash,
            is_zeno_contractive: true,
            timestamp,
        })
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn proof_certification_gate_sound() {
        let engine = AffineCoreEngine;
        let mut op = MultiplicityOperator {
            name: String::new(),
            prime_indices: Vec::new(),
        };
        let is_empty: bool = kani::any();
        if !is_empty {
            op.prime_indices.push(kani::any());
        }
        
        let res = engine.certify(&op);
        if is_empty {
            kani::assert(res.is_err(), "Empty primes must be rejected");
        } else {
            kani::assert(res.is_ok(), "Non-empty primes should be admissible");
        }
    }

    #[kani::proof]
    fn proof_zeno_contractivity() {
        let engine = AffineCoreEngine;
        let state: u64 = kani::any();
        
        // A simple Zeno contractive function: just integer division by 2.
        // It always converges to 0 in finite steps.
        let transition = |x: u64| x / 2;
        
        // max_steps = 64 is enough for u64 to reach 0.
        let res = engine.zeno_check(state, &transition, 64);
        kani::assert(res.is_ok(), "Division by 2 is Zeno contractive within 64 steps");
    }
}
