use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use sha2::{Sha256, Digest};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CRMFCertificate {
    pub rho: f64,
    pub lambda: f64,
    pub gamma: f64,
    pub r_t: f64,
    pub status: String,
    pub gain: f64,
    pub reason: String,
    pub proof_hash: String,
    pub semantic_omega: u64,
    pub gates: HashMap<String, bool>,
    pub is_tolerated: bool,
    pub autoimmune_drift: f64,
}

pub fn certify(
    rho: f64,
    lambda: f64,
    gamma: f64,
    r_t: f64,
) -> CRMFCertificate {
    let mut payload = HashMap::new();
    payload.insert("rho".to_string(), serde_json::json!(rho));
    payload.insert("lambda".to_string(), serde_json::json!(lambda));
    payload.insert("gamma".to_string(), serde_json::json!(gamma));
    payload.insert("R_t".to_string(), serde_json::json!(r_t));
    
    let canonical = serde_json::to_string(&payload).unwrap();
    let proof_hash = hex::encode(Sha256::digest(canonical.as_bytes()));

    if gamma > 1.0 {
        return CRMFCertificate {
            rho, lambda, gamma, r_t,
            status: "FAIL".to_string(),
            gain: 0.0,
            reason: "gamma_violation".to_string(),
            proof_hash,
            semantic_omega: 0,
            gates: HashMap::new(),
            is_tolerated: false,
            autoimmune_drift: 0.0,
        };
    }

    CRMFCertificate {
        rho, lambda, gamma, r_t,
        status: "PASS".to_string(),
        gain: 1.0, // Simplified
        reason: "accepted".to_string(),
        proof_hash,
        semantic_omega: 1,
        gates: HashMap::new(),
        is_tolerated: true,
        autoimmune_drift: 0.0,
    }
}
