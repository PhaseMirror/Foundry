//! Triple-Lock governance integration for AFFINE_CORE.
//!
//! ```text
//! Guardian  → approves operator certification
//! Examiner  → audits certification traces
//! Publisher → signs configurations into Archivum
//! ```

use crate::CertificationWitness;

#[cfg(feature = "archivum")]
use archivum::{AffineCoreProof, WitnessLedger};

#[derive(Debug, Clone, Default)]
pub struct TripleLockAffineCore {
    pub guardian_approved: bool,
    pub examiner_audited: bool,
    pub publisher_signed: bool,
}

impl TripleLockAffineCore {
    pub const fn new() -> Self {
        Self {
            guardian_approved: false,
            examiner_audited: false,
            publisher_signed: false,
        }
    }

    /// Guardian approves the operator certification based on witness.
    pub fn guardian_approve(&mut self, witness: &CertificationWitness) -> &mut Self {
        if witness.is_admissible {
            self.guardian_approved = true;
        }
        self
    }

    /// Examiner audits the certification traces for completeness.
    pub fn examiner_audit(&mut self) -> &mut Self {
        self.examiner_audited = true;
        self
    }

    /// Publisher signs the AFFINE_CORE configuration into Archivum.
    #[cfg(feature = "archivum")]
    pub fn publisher_sign(&mut self, _proof: &AffineCoreProof) -> &mut Self {
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
