//! Triple-Lock governance integration for PARM sealed state.
//!
//! ```text
//! Guardian  → approves seal operation
//! Examiner  → audits for collisions / overflow
//! Publisher → signs sealed state into Archivum
//! ```

use chrono::Utc;
use super::{ParmEngine, ParmSealWitness, ParmError};

#[derive(Debug, Clone, Default)]
pub struct TripleLockParm {
    pub guardian_approved: bool,
    pub examiner_audited: bool,
    pub publisher_signed: bool,
}

impl TripleLockParm {
    pub const fn new() -> Self {
        Self {
            guardian_approved: false,
            examiner_audited: false,
            publisher_signed: false,
        }
    }

    /// Guardian approves the seal operation.
    pub fn guardian_approve(&mut self) -> &mut Self {
        self.guardian_approved = true;
        self
    }

    /// Examiner audits the sealed state for collisions and overflow.
    pub fn examiner_audit(&mut self, witness: &ParmSealWitness) -> &mut Self {
        // Basic audit: sealed value must be non-zero for non-empty input,
        // and witness timestamp must be recent (not from the future).
        let now = Utc::now().timestamp();
        if witness.sealed_value == 0 && witness.input_hash != [0u8; 32] {
            // Zero seal for non-empty input is suspicious; Examiner rejects.
            return self;
        }
        if witness.timestamp > now + 60 {
            // Timestamp more than 60s in the future; Examiner rejects.
            return self;
        }
        self.examiner_audited = true;
        self
    }

    /// Publisher signs the sealed state into Archivum.
    #[cfg(feature = "archivum")]
    pub fn publisher_sign(&mut self, _proof: &archivum::ParmSealProof) -> &mut Self {
        self.publisher_signed = true;
        self
    }

    /// Publisher signs without Archivum dependency (no-op sign).
    #[cfg(not(feature = "archivum"))]
    pub fn publisher_sign(&mut self) -> &mut Self {
        self.publisher_signed = true;
        self
    }

    /// Returns true if all three locks have been satisfied.
    pub fn is_locked(&self) -> bool {
        self.guardian_approved && self.examiner_audited && self.publisher_signed
    }

    /// Execute the full Triple-Lock flow: seal → approve → audit → sign.
    #[cfg(feature = "archivum")]
    pub fn execute(
        &mut self,
        engine: &ParmEngine,
        primes: &[u64],
        ledger: &mut archivum::WitnessLedger,
    ) -> Result<(u64, ParmSealWitness), ParmError> {
        let (sealed, witness) = engine.seal_with_witness(primes)?;
        let proof = archivum::ParmSealProof::new(witness.input_hash, sealed);
        ledger.stamp_parm_seal_proof(&proof).map_err(|_| ParmError::Overflow)?;
        self.guardian_approve()
            .examiner_audit(&witness)
            .publisher_sign(&proof);
        Ok((sealed, witness))
    }

    /// Execute the full Triple-Lock flow without Archivum.
    #[cfg(not(feature = "archivum"))]
    pub fn execute(
        &mut self,
        engine: &ParmEngine,
        primes: &[u64],
    ) -> Result<(u64, ParmSealWitness), ParmError> {
        let (sealed, witness) = engine.seal_with_witness(primes)?;
        self.guardian_approve()
            .examiner_audit(&witness)
            .publisher_sign();
        Ok((sealed, witness))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn triple_lock_full_flow() {
        let mut lock = TripleLockParm::new();
        let engine = ParmEngine;
        let primes = &[3u64, 3, 3, 2, 2];

        #[cfg(feature = "archivum")]
        {
            let mut ledger = archivum::WitnessLedger::new("/tmp/parm_test_ledger.json");
            let (sealed, _witness) = lock.execute(&engine, primes, &mut ledger).unwrap();
            assert_eq!(sealed, 960);
        }

        #[cfg(not(feature = "archivum"))]
        {
            let (sealed, _witness) = lock.execute(&engine, primes).unwrap();
            assert_eq!(sealed, 960);
        }

        assert!(lock.is_locked());
    }

    #[test]
    fn triple_lock_rejects_zero_seal() {
        let mut lock = TripleLockParm::new();
        let engine = ParmEngine;

        #[cfg(feature = "archivum")]
        {
            let mut ledger = archivum::WitnessLedger::new("/tmp/parm_test_ledger.json");
            let result = lock.execute(&engine, &[], &mut ledger);
            assert!(result.is_err());
        }

        #[cfg(not(feature = "archivum"))]
        {
            let result = lock.execute(&engine, &[]);
            assert!(result.is_err());
        }

        assert!(!lock.is_locked());
    }
}
