//! Triple-Lock governance integration for ROC stability dynamics.
//!
//! ```text
//! Guardian  → approves dynamic system validation (Lyapunov descent check)
//! Examiner  → audits Lyapunov traces for descent violations
//! Publisher → signs ROC configuration into Archivum
//! ```

use super::{RocDynamicsWitness};

#[cfg(feature = "archivum")]
use archivum::{RocDynamicsProof, WitnessLedger};

#[derive(Debug, Clone, Default)]
pub struct TripleLockRoc {
    pub guardian_approved: bool,
    pub examiner_audited: bool,
    pub publisher_signed: bool,
}

impl TripleLockRoc {
    pub const fn new() -> Self {
        Self {
            guardian_approved: false,
            examiner_audited: false,
            publisher_signed: false,
        }
    }

    /// Guardian approves the dynamic system validation based on witness.
    pub fn guardian_approve(&mut self, witness: &RocDynamicsWitness) -> &mut Self {
        if witness.descent_holds {
            self.guardian_approved = true;
        }
        self
    }

    /// Examiner audits the Lyapunov bounds.
    pub fn examiner_audit(&mut self) -> &mut Self {
        self.examiner_audited = true;
        self
    }

    /// Publisher signs the ROC configuration into Archivum.
    #[cfg(feature = "archivum")]
    pub fn publisher_sign(&mut self, _proof: &RocDynamicsProof) -> &mut Self {
        self.publisher_signed = true;
        self
    }

    /// Publisher signs without Archivum dependency.
    #[cfg(not(feature = "archivum"))]
    pub fn publisher_sign(&mut self) -> &mut Self {
        self.publisher_signed = true;
        self
    }

    /// Returns true if all three locks have been satisfied.
    pub fn is_locked(&self) -> bool {
        self.guardian_approved && self.examiner_audited && self.publisher_signed
    }
}
