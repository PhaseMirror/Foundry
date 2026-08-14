use pirtm_stdlib::prelude::*;
use sha2::{Sha256, Digest};
use std::fs::OpenOptions;
use std::io::Write;
use chrono::Utc;
use serde::Serialize;

#[derive(Serialize, Debug)]
pub struct RegistryReceipt {
    pub package_name: String,
    pub timestamp: String,
    pub pweh: String,
    pub nf_hash: String,
    pub c: f64,
    pub rsc: f64,
    pub status: String,
}

pub struct Registry;

impl Registry {
    /// Governed publish of a PIRTM ensemble.
    /// Rejects publication if contraction bounds or resonance tension fails.
    pub fn publish(name: &str, word: &MOCWord) -> Result<RegistryReceipt, String> {
        // 1. EvalNF Core
        let (c, r1, r2, r3) = EvalNF::evaluate(word);
        let rsc = Resonance::calculate(r1, r2, r3);

        // 2. Hashes
        let mut pweh_hasher = Sha256::new();
        pweh_hasher.update(word.to_string().as_bytes());
        let pweh = format!("{:x}", pweh_hasher.finalize());

        let mut nf_hasher = Sha256::new();
        nf_hasher.update(format!("{:.4}{:.4}{:.4}{:.4}", c, r1, r2, r3).as_bytes());
        let nf_hash = format!("{:x}", nf_hasher.finalize());

        // 3. Phase Mirror Checks
        if c >= 1.0 - 1e-6 {
            let msg = format!("Publish Rejected: Contraction bound violated (c = {:.4})", c);
            Self::append_ledger(name, false, &pweh, &nf_hash, c, rsc, &msg);
            return Err(msg);
        }

        if rsc < 1.0 {
            let msg = format!("Publish Rejected: Resonance tension too low (Rsc = {:.4})", rsc);
            Self::append_ledger(name, false, &pweh, &nf_hash, c, rsc, &msg);
            return Err(msg);
        }

        let receipt = RegistryReceipt {
            package_name: name.to_string(),
            timestamp: Utc::now().to_rfc3339(),
            pweh: pweh.clone(),
            nf_hash: nf_hash.clone(),
            c,
            rsc,
            status: "PUBLISHED".to_string(),
        };

        // 4. Ledger Anchor
        Self::append_ledger(name, true, &pweh, &nf_hash, c, rsc, "PUBLISHED");

        Ok(receipt)
    }

    fn append_ledger(name: &str, valid: bool, pweh: &str, nf_hash: &str, c: f64, rsc: f64, status: &str) {
        if let Ok(mut file) = OpenOptions::new().create(true).append(true).open("registry_ledger.jsonl") {
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
    fn test_publish_valid_ensemble() {
        // Third-party crate constructs Ap(2) + Ap(3)
        let ensemble = Ap(2) + Ap(3);
        
        // Attempt governed publish
        let result = Registry::publish("my_ensemble", &ensemble);
        
        assert!(result.is_ok());
        let receipt = result.unwrap();
        assert_eq!(receipt.package_name, "my_ensemble");
        assert!(receipt.c < 1.0 - 1e-6);
        assert!(receipt.rsc >= 1.0);
    }
    
    #[test]
    fn test_publish_invalid_ensemble() {
        // Third-party crate constructs unlawful Ap(1)
        let ensemble = Ap(1);
        
        // Attempt governed publish
        let result = Registry::publish("unlawful_ensemble", &ensemble);
        
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("Contraction bound violated"));
    }
}
