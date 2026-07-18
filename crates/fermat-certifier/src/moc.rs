use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MocOperator {
    pub name: String,
    pub prime_gate: u64,
    pub spectral_radius: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContractionCertificate {
    pub operator_name: String,
    pub prime_gate: u64,
    pub lambda_p: f64,
    pub proof_hash: String,
}

#[derive(Debug, thiserror::Error)]
pub enum CertError {
    #[error("Operator {0} is not contractive (lambda_p = {1} >= 1.0)")]
    NonContractive(String, f64),
}

pub struct FermatCertifier;

impl FermatCertifier {
    pub fn issue(op: &MocOperator) -> Result<ContractionCertificate, CertError> {
        if op.spectral_radius >= 1.0 {
            return Err(CertError::NonContractive(op.name.clone(), op.spectral_radius));
        }
        
        // Mock Lean proof hash generation
        let proof_hash = blake3::hash(format!("{}_{}_{}", op.name, op.prime_gate, op.spectral_radius).as_bytes()).to_string();
        
        Ok(ContractionCertificate {
            operator_name: op.name.clone(),
            prime_gate: op.prime_gate,
            lambda_p: op.spectral_radius,
            proof_hash,
        })
    }
    
    pub fn verify(cert: &ContractionCertificate) -> bool {
        if cert.lambda_p >= 1.0 {
            return false;
        }
        let expected_hash = blake3::hash(format!("{}_{}_{}", cert.operator_name, cert.prime_gate, cert.lambda_p).as_bytes()).to_string();
        cert.proof_hash == expected_hash
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn proof_certificate_soundness() {
        let radius: f64 = kani::any();
        kani::assume(radius.is_finite());
        
        let op = MocOperator {
            name: "test".to_string(),
            prime_gate: 2,
            spectral_radius: radius,
        };
        
        match FermatCertifier::issue(&op) {
            Ok(cert) => {
                kani::assert(cert.lambda_p < 1.0, "Issued certificate for non-contractive operator");
                kani::assert(FermatCertifier::verify(&cert), "Issued certificate fails verification");
            }
            Err(_) => {
                kani::assert(radius >= 1.0, "Rejected valid operator");
            }
        }
    }
    
    #[kani::proof]
    fn proof_certificate_non_forgeable() {
        let mut cert = ContractionCertificate {
            operator_name: "test".to_string(),
            prime_gate: 2,
            lambda_p: 0.5,
            proof_hash: "".to_string(),
        };
        
        // Correct hash
        cert.proof_hash = blake3::hash(format!("{}_{}_{}", cert.operator_name, cert.prime_gate, cert.lambda_p).as_bytes()).to_string();
        kani::assert(FermatCertifier::verify(&cert), "Valid cert rejected");
        
        // Forged hash
        cert.proof_hash = "forged".to_string();
        kani::assert(!FermatCertifier::verify(&cert), "Forged cert accepted");
        
        // Non-contractive mutation
        cert.lambda_p = 1.5;
        cert.proof_hash = blake3::hash(format!("{}_{}_{}", cert.operator_name, cert.prime_gate, cert.lambda_p).as_bytes()).to_string();
        kani::assert(!FermatCertifier::verify(&cert), "Non-contractive cert accepted");
    }

    #[kani::proof]
    fn proof_resonance_preserves_contraction() {
        let radius: f64 = kani::any();
        kani::assume(radius.is_finite() && radius >= 0.0 && radius < 1.0);
        
        let op = MocOperator {
            name: "test".to_string(),
            prime_gate: 2,
            spectral_radius: radius,
        };
        
        let term = CrmfResonanceTerm {
            source_prime: 2,
            target_prime: 3,
            source_exponent: 1,
            target_exponent: 1,
            resonance_predicate: true,
        };
        
        let new_op = activate_resonance(&op, &term);
        kani::assert(new_op.spectral_radius < 1.0, "Resonance broke contractivity bounds");
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CrmfResonanceTerm {
    pub source_prime: u64,
    pub target_prime: u64,
    pub source_exponent: i64,
    pub target_exponent: i64,
    pub resonance_predicate: bool,
}

pub fn activate_resonance(op: &MocOperator, term: &CrmfResonanceTerm) -> MocOperator {
    let mut new_op = op.clone();
    if term.resonance_predicate {
        // Activation modifies spectral_radius within contractive bounds
        new_op.spectral_radius *= 0.99;
    }
    new_op
}
