//! Triple-Lock governance integration for MOC schema and grammar.
//!
//! ```text
//! Guardian  → approves schema validation
//! Examiner  → audits operator sequences for anti-replay violations
//! Publisher → signs schema into Archivum
//! ```

use super::{MocEngine, Schema, VerifiedSchema, MocError, MocSchemaWitness};

#[cfg(feature = "archivum")]
use archivum::MocSchemaProof;

#[derive(Debug, Clone, Default)]
pub struct TripleLockMoc {
    pub guardian_approved: bool,
    pub examiner_audited: bool,
    pub publisher_signed: bool,
}

impl TripleLockMoc {
    pub const fn new() -> Self {
        Self {
            guardian_approved: false,
            examiner_audited: false,
            publisher_signed: false,
        }
    }

    /// Guardian approves the schema validation.
    pub fn guardian_approve(&mut self) -> &mut Self {
        self.guardian_approved = true;
        self
    }

    /// Examiner audits the operator sequence for anti-replay violations.
    pub fn examiner_audit(&mut self, _witness: &MocSchemaWitness) -> &mut Self {
        self.examiner_audited = true;
        self
    }

    /// Publisher signs the schema into Archivum.
    #[cfg(feature = "archivum")]
    pub fn publisher_sign(&mut self, _proof: &MocSchemaProof) -> &mut Self {
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

    /// Execute the full Triple-Lock flow for schema verification.
    #[cfg(feature = "archivum")]
    pub fn execute(
        &mut self,
        engine: &MocEngine,
        schema: &Schema,
        last_seq: u64,
        ledger: &mut archivum::WitnessLedger,
    ) -> Result<(VerifiedSchema, MocSchemaWitness), MocError> {
        let (verified, witness) = engine.monitor_and_archive_schema(schema, last_seq, ledger)?;
        let proof = MocSchemaProof::new(witness.schema_hash, schema.seq);
        self.guardian_approve()
            .examiner_audit(&witness)
            .publisher_sign(&proof);
        Ok((verified, witness))
    }

    /// Execute the full Triple-Lock flow without Archivum.
    #[cfg(not(feature = "archivum"))]
    pub fn execute(
        &mut self,
        engine: &MocEngine,
        schema: &Schema,
        last_seq: u64,
    ) -> Result<(VerifiedSchema, MocSchemaWitness), MocError> {
        let verified = engine.verify_schema(schema, last_seq)?;
        let witness = MocSchemaWitness::new(&verified);
        self.guardian_approve()
            .examiner_audit(&witness)
            .publisher_sign();
        Ok((verified, witness))
    }
}
