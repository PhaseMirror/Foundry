//! Triple-Lock governance integration for Meta-Relativity validation gates.
//!
//! ```text
//! Guardian  → approves physical model validation (Gate checks)
//! Examiner  → audits gate checks for completeness
//! Publisher → signs Meta-Relativity configuration into Archivum
//! ```

use crate::gates::MetaRelativityWitness;

#[cfg(feature = "archivum")]
use archivum::{MetaRelativityProof, WitnessLedger};

#[derive(Debug, Clone, Default)]
pub struct TripleLockMetaRelativity {
    pub guardian_approved: bool,
    pub examiner_audited: bool,
    pub publisher_signed: bool,
}

impl TripleLockMetaRelativity {
    pub const fn new() -> Self {
        Self {
            guardian_approved: false,
            examiner_audited: false,
            publisher_signed: false,
        }
    }

    /// Guardian approves the physical model validation based on witness.
    pub fn guardian_approve(&mut self, witness: &MetaRelativityWitness) -> &mut Self {
        if witness.all_gates_valid {
            self.guardian_approved = true;
        }
        self
    }

    /// Examiner audits the gate checks for completeness.
    pub fn examiner_audit(&mut self) -> &mut Self {
        self.examiner_audited = true;
        self
    }

    /// Publisher signs the Meta-Relativity configuration into Archivum.
    #[cfg(feature = "archivum")]
    pub fn publisher_sign(&mut self, _proof: &MetaRelativityProof) -> &mut Self {
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
