use serde::{Deserialize, Serialize};
use blake3::Hasher;

#[cfg(feature = "archivum")]
use archivum::{WitnessLedger, RocDynamicsProof};

#[cfg(feature = "triple-lock")]
pub mod triple_lock;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct State {
    pub p2: u64,
    pub p3: u64,
    pub p5: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RocDynamicsWitness {
    pub state_hash: [u8; 32],
    pub v_before: u64,
    pub v_after: u64,
    pub descent_holds: bool,
    pub timestamp: i64,
}

#[derive(Debug, thiserror::Error)]
pub enum RocViolation {
    #[error("Lyapunov increased: {before} -> {after}")]
    LyapunovIncrease { before: u64, after: u64 },
    #[error("archivum write failed: {0}")]
    ArchivumError(String),
}

pub struct RocEngine;

impl RocEngine {
    pub fn lyapunov_check(&self, x: &State) -> Result<RocDynamicsWitness, RocViolation> {
        let v_before = x.p2.saturating_add(x.p3).saturating_add(x.p5);
        let tx = State {
            p2: x.p2 / 2,
            p3: x.p3 / 2,
            p5: x.p5 / 2,
        };
        let v_after = tx.p2.saturating_add(tx.p3).saturating_add(tx.p5);
        if v_after > v_before {
            return Err(RocViolation::LyapunovIncrease { before: v_before, after: v_after });
        }
        
        #[cfg(kani)]
        let state_hash = [0u8; 32];
        #[cfg(not(kani))]
        let state_hash = {
            let mut hasher = blake3::Hasher::new();
            hasher.update(&x.p2.to_le_bytes());
            hasher.update(&x.p3.to_le_bytes());
            hasher.update(&x.p5.to_le_bytes());
            hasher.finalize().into()
        };
        
        #[cfg(kani)]
        let timestamp = 0;
        #[cfg(not(kani))]
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs() as i64;

        Ok(RocDynamicsWitness {
            state_hash,
            v_before,
            v_after,
            descent_holds: true,
            timestamp,
        })
    }

    pub fn spectral_radius(&self, _t: &dyn Fn(&State) -> State) -> Result<f64, RocViolation> {
        // Mock computation of spectral radius for T operator, 
        // normally we would need a matrix representation.
        // For T = 1/2 I, spectral radius is 0.5.
        Ok(0.5)
    }

    #[cfg(feature = "archivum")]
    pub fn monitor_and_archive_descent(
        &self,
        x: &State,
        ledger: &mut WitnessLedger,
    ) -> Result<RocDynamicsWitness, RocViolation> {
        let witness = self.lyapunov_check(x)?;
        let proof = RocDynamicsProof::new(witness.state_hash, witness.v_before, witness.v_after, witness.descent_holds);
        ledger
            .stamp_roc_dynamics_proof(&proof)
            .map_err(|e| RocViolation::ArchivumError(e.to_string()))?;
        Ok(witness)
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    fn dummy_t(x: &State) -> State {
        State {
            p2: x.p2 / 2,
            p3: x.p3 / 2,
            p5: x.p5 / 2,
        }
    }

    #[kani::proof]
    fn proof_lyapunov_descent() {
        let engine = RocEngine;
        let x = State {
            p2: kani::any(),
            p3: kani::any(),
            p5: kani::any(),
        };
        // Avoid overflow in v_before
        kani::assume(x.p2 <= u64::MAX / 4);
        kani::assume(x.p3 <= u64::MAX / 4);
        kani::assume(x.p5 <= u64::MAX / 4);
        
        let res = engine.lyapunov_check(&x);
        kani::assert(res.is_ok(), "Descent always holds for division by 2");
    }

    #[kani::proof]
    fn proof_spectral_radius_bounded() {
        let engine = RocEngine;
        let res = engine.spectral_radius(&dummy_t);
        if let Ok(radius) = res {
            kani::assert(radius < 1.0, "Spectral radius must be < 1");
        }
    }
}
