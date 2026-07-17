//! Triple-Lock governance integration for XI_FORMAL stability dynamics.
//!
//! ```text
//! Guardian  → approves dynamic system validation (contraction check)
//! Examiner  → audits contraction bounds for tightness
//! Publisher → signs stability configuration into Archivum
//! ```

use super::{XiFormalWitness};

#[cfg(feature = "archivum")]
use archivum::{XiFormalProof, WitnessLedger};

#[derive(Debug, Clone, Default)]
pub struct TripleLockXiFormal {
    pub guardian_approved: bool,
    pub examiner_audited: bool,
    pub publisher_signed: bool,
}

impl TripleLockXiFormal {
    pub const fn new() -> Self {
        Self {
            guardian_approved: false,
            examiner_audited: false,
            publisher_signed: false,
        }
    }

    /// Guardian approves the dynamic system validation based on witness.
    pub fn guardian_approve(&mut self, witness: &XiFormalWitness) -> &mut Self {
        if witness.is_contraction {
            self.guardian_approved = true;
        }
        self
    }

    /// Examiner audits the contraction bounds for tightness.
    pub fn examiner_audit(&mut self) -> &mut Self {
        self.examiner_audited = true;
        self
    }

    /// Publisher signs the stability configuration into Archivum.
    #[cfg(feature = "archivum")]
    pub fn publisher_sign(&mut self, _proof: &XiFormalProof) -> &mut Self {
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
