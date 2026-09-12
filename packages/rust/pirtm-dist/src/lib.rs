use pirtm_stdlib::prelude::*;
use sha2::{Sha256, Digest};
use std::fs::OpenOptions;
use std::io::Write;
use chrono::Utc;
use serde::Serialize;
use pirtm_registry::{RegistryReceipt, Registry};

#[derive(Serialize, Debug)]
pub struct InstallReceipt {
    pub package_name: String,
    pub timestamp: String,
    pub pweh: String,
    pub nf_hash: String,
    pub c: f64,
    pub rsc: f64,
    pub status: String,
}

pub struct Distributor;

impl Distributor {
    /// Simulates downloading the package registry and verifying it before local install.
    /// In a real system, this fetches the registry receipt via network.
    pub fn install(name: &str, word_to_download: &MOCWord) -> Result<InstallReceipt, String> {
        // 0. Enforce All 10 Core Phase Mirror Invariants First
        if let Err(e) = pirtm_invariants::PhaseMirrorInvariants::enforce_all(word_to_download) {
            let msg = format!("Install Rejected: Full Phase Mirror Invariant Violation - {}", e);
            // Hashes for rejection record
            let mut pweh_hasher = Sha256::new();
            pweh_hasher.update(word_to_download.to_string().as_bytes());
            let pweh = format!("{:x}", pweh_hasher.finalize());
            let (c, r1, r2, r3) = EvalNF::evaluate(word_to_download);
            let rsc = Resonance::calculate(r1, r2, r3);
            let mut nf_hasher = Sha256::new();
            nf_hasher.update(format!("{:.4}{:.4}{:.4}{:.4}", c, r1, r2, r3).as_bytes());
            let nf_hash = format!("{:x}", nf_hasher.finalize());
            
            Self::append_ledger(name, false, &pweh, &nf_hash, c, rsc, &msg);
            return Err(msg);
        }

        // 1. Pre-download Verification (Local Phase Mirror Gate - already partially handled above)
        let (c, r1, r2, r3) = EvalNF::evaluate(word_to_download);
        let rsc = Resonance::calculate(r1, r2, r3);

        let mut pweh_hasher = Sha256::new();
        pweh_hasher.update(word_to_download.to_string().as_bytes());
        let pweh = format!("{:x}", pweh_hasher.finalize());

        let mut nf_hasher = Sha256::new();
        nf_hasher.update(format!("{:.4}{:.4}{:.4}{:.4}", c, r1, r2, r3).as_bytes());
        let nf_hash = format!("{:x}", nf_hasher.finalize());

        // 2. Fetch from Registry (Simulated local call)
        // If we got here, pre-download checks passed. Let's make sure the registry actually has it published validly.
        match Registry::publish(name, word_to_download) {
            Ok(receipt) => {
                // Verified.
                let install_receipt = InstallReceipt {
                    package_name: name.to_string(),
                    timestamp: Utc::now().to_rfc3339(),
                    pweh: receipt.pweh,
                    nf_hash: receipt.nf_hash,
                    c: receipt.c,
                    rsc: receipt.rsc,
                    status: "INSTALLED".to_string(),
                };
                Self::append_ledger(name, true, &pweh, &nf_hash, c, rsc, "INSTALLED");
                Ok(install_receipt)
            },
            Err(e) => {
                let msg = format!("Install Rejected: Registry verification failed - {}", e);
                Self::append_ledger(name, false, &pweh, &nf_hash, c, rsc, &msg);
                Err(msg)
            }
        }
    }

    fn append_ledger(name: &str, valid: bool, pweh: &str, nf_hash: &str, c: f64, rsc: f64, status: &str) {
        if let Ok(mut file) = OpenOptions::new().create(true).append(true).open("dist_ledger.jsonl") {
            let entry = serde_json::json!({
                "package_name": name,
                "timestamp": Utc::now().to_rfc3339(),
                "valid": valid,
                "pweh": pweh,
                "nf_hash": nf_hash,
                "c": c,
                "rsc": rsc,
                "status": status
            });
            let _ = writeln!(file, "{}", entry.to_string());
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_install_valid_ensemble() {
        let ensemble = Ap(2) + Ap(3);
        let result = Distributor::install("my_ensemble", &ensemble);
        assert!(result.is_ok());
        let receipt = result.unwrap();
        assert_eq!(receipt.package_name, "my_ensemble");
        assert_eq!(receipt.status, "INSTALLED");
    }
    
    #[test]
    fn test_install_invalid_ensemble() {
        let ensemble = Ap(1);
        let result = Distributor::install("unlawful_ensemble", &ensemble);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("Invariant Violation"));
    }
}
