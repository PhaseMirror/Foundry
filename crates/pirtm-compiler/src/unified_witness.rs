use serde::{Deserialize, Serialize};

/// The UnifiedWitness represents a frozen state of compilation failure,
/// typically caused by an ACE budget deficit or topological constraint violation.
/// It acts as the cryptographic payload that must be co-signed to permit recovery.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UnifiedWitness {
    pub tensor_hash: String,
    pub compilation_timestamp: u64,
    pub ace_deficit: f64,
}

impl UnifiedWitness {
    pub fn new(tensor_hash: String, compilation_timestamp: u64, ace_deficit: f64) -> Self {
        Self {
            tensor_hash,
            compilation_timestamp,
            ace_deficit,
        }
    }

    /// Derives the canonical payload string to be hashed and signed.
    pub fn derive_canonical_payload(&self) -> String {
        format!("{}:{}:{}", self.tensor_hash, self.compilation_timestamp, self.ace_deficit)
    }
}

/// A structure to hold the recovery approval protocol.
/// It strictly mandates two independent valid signatures.
#[derive(Debug, Clone)]
pub struct DualSignatureRecovery {
    pub witness: UnifiedWitness,
    pub primary_signature: Option<String>,
    pub secondary_signature: Option<String>,
}

impl DualSignatureRecovery {
    pub fn new(witness: UnifiedWitness) -> Self {
        Self {
            witness,
            primary_signature: None,
            secondary_signature: None,
        }
    }

    pub fn attach_primary_signature(&mut self, sig: String) {
        self.primary_signature = Some(sig);
    }

    pub fn attach_secondary_signature(&mut self, sig: String) {
        self.secondary_signature = Some(sig);
    }

    /// Verifies the Dual-Signature protocol. Both signatures must be present.
    /// In a fully integrated system, this would also cryptographic check the ECDSA/ED25519 bounds.
    pub fn verify_recovery(&self) -> Result<(), &'static str> {
        if self.primary_signature.is_none() {
            return Err("Primary signature missing. Recovery aborted.");
        }
        if self.secondary_signature.is_none() {
            return Err("Secondary signature missing. Recovery aborted.");
        }
        if self.primary_signature == self.secondary_signature {
            return Err("Signatures must be cryptographically distinct (no self-dealing).");
        }
        
        Ok(())
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    #[kani::unwind(3)]
    fn verify_dual_signature_mandate() {
        let hash_val = String::from("mock_hash");
        let ts: u64 = kani::any();
        let deficit: f64 = kani::any();
        
        kani::assume(deficit > 0.0);
        
        let witness = UnifiedWitness::new(hash_val, ts, deficit);
        let mut recovery = DualSignatureRecovery::new(witness);
        
        // At creation, recovery MUST fail.
        kani::assert(recovery.verify_recovery().is_err(), "Recovery must fail with zero signatures");
        
        // Single signature MUST fail.
        recovery.attach_primary_signature(String::from("SIG_1"));
        kani::assert(recovery.verify_recovery().is_err(), "Recovery must fail with one signature");
        
        // Identical signatures MUST fail (anti-Sybil / self-dealing).
        recovery.attach_secondary_signature(String::from("SIG_1"));
        kani::assert(recovery.verify_recovery().is_err(), "Recovery must fail with identical signatures");
        
        // Distinct dual signatures MUST succeed.
        recovery.attach_secondary_signature(String::from("SIG_2"));
        kani::assert(recovery.verify_recovery().is_ok(), "Recovery must succeed with valid distinct dual signatures");
    }
}
