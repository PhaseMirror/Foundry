//! CRMF WORM ledger integration.
//!
//! Extends the Λ^p-Archivum WORM ledger with CRMF-specific operations.

use std::fs::{File, OpenOptions};
use std::io::{BufRead, BufReader, Write};
use std::path::{Path, PathBuf};
use hex;

use crate::{CrmfEnvelope, CrmfError};
use archivum::{ArchivumLedger, ArchivumError};

/// CRMF-specific WORM ledger that extends ArchivumLedger.
#[derive(Debug, Clone)]
pub struct CrmfLedger {
    pub archivum: ArchivumLedger,
    path: PathBuf,
}

impl CrmfLedger {
    pub fn new<P: AsRef<Path>>(path: P) -> Self {
        Self {
            archivum: ArchivumLedger::new(),
            path: path.as_ref().to_path_buf(),
        }
    }

    /// Append a sealed CRMF envelope to the WORM ledger.
    pub fn append_envelope(&mut self, envelope: &CrmfEnvelope) -> Result<(), CrmfError> {
        let state_hash = envelope.seal.dual_anchor.sha256_hex.clone();
        let _bcs_bytes = envelope.to_bcs()?;

        if self.archivum.witnesses.iter().any(|w| w.state_hash == state_hash) {
            return Err(ArchivumError::DuplicateWitness { state_hash }.into());
        }

        self.archivum.root_hash = self.archivum.compute_root_hash();

        self.ensure_dir()?;
        let mut file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.path)?;

        let entry = serde_json::json!({
            "state_hash": state_hash,
            "timestamp": envelope.timestamp,
            "event_type": envelope.payload.event_type,
            "bcs_hash": envelope.seal.bcs_hash,
            "poseidon2": envelope.seal.poseidon2,
            "ed25519_pk": hex::encode(&envelope.seal.dual_anchor.ed25519_pk),
            "previous_root": hex::encode(self.archivum.root_hash),
        });

        writeln!(file, "{}", entry)?;
        Ok(())
    }

    /// Verify the CRMF ledger chain integrity.
    pub fn verify_chain(&self) -> bool {
        self.archivum.verify_chain()
    }

    /// Scan for any seal violations (tamper evidence).
    pub fn scan_for_violations<P: AsRef<Path>>(&self, _storage_path: P) -> Vec<String> {
        let mut violations = Vec::new();
        if let Ok(file) = File::open(&self.path) {
            let reader = BufReader::new(file);
            for line in reader.lines() {
                if let Ok(l) = line {
                    if let Ok(obj) = serde_json::from_str::<serde_json::Value>(&l) {
                        if obj.get("state_hash").is_none() {
                            violations.push("Missing state_hash in ledger entry".to_string());
                        }
                    }
                }
            }
        }
        violations
    }

    fn ensure_dir(&self) -> Result<(), CrmfError> {
        if let Some(parent) = self.path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        Ok(())
    }
}
