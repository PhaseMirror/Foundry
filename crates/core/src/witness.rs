use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::time::{SystemTime, UNIX_EPOCH};

fn flatten_f64(params: &[f64]) -> Vec<u8> {
    params.iter().flat_map(|f| f.to_le_bytes()).collect()
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct CRMFWitness {
    pub operator_id: String,
    pub transform_id: String,
    pub input_hash: String,
    pub output_hash: String,
    pub lipschitz_bound: f64,
    pub contraction_bound_after: f64,
    pub resonance_status: String,
    pub drift_value: f64,
    pub timestamp: u64,
    pub previous_witness_hash: Option<String>,

    // New Ṛta fields
    pub arta_defect_before: f64,
    pub arta_defect_after: f64,
    pub rta_dist_to_bindu: f64,
}

impl CRMFWitness {
    pub fn new(
        operator_id: String,
        previous: Option<&CRMFWitness>,
        delta_theta: &[f64],
        input_params: &[f64],
        c_after: f64,
        r_sc_after: f64,
        drift: f64,
        arta_before: f64,
        arta_after: f64,
        rta_dist: f64,
    ) -> Self {
        let input_hash = hex::encode(Sha256::digest(flatten_f64(input_params)));
        let output_params: Vec<f64> = input_params.iter().zip(delta_theta).map(|(a,b)| a+b).collect();
        let output_hash = hex::encode(Sha256::digest(flatten_f64(&output_params)));
        let timestamp = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();
        let transform_id = hex::encode(Sha256::digest(format!("{}{}{}", input_hash, output_hash, timestamp).as_bytes()));
        let previous_witness_hash = previous.map(|w| hex::encode(Sha256::digest(serde_json::to_string(w).unwrap().as_bytes())));
        CRMFWitness {
            operator_id,
            transform_id,
            input_hash,
            output_hash,
            lipschitz_bound: delta_theta.iter().map(|x| x.abs()).fold(0.0_f64, f64::max),
            contraction_bound_after: c_after,
            resonance_status: if r_sc_after >= 1.0 { "safe".into() } else { "clamped".into() },
            drift_value: drift,
            timestamp,
            previous_witness_hash,
            arta_defect_before: arta_before,
            arta_defect_after: arta_after,
            rta_dist_to_bindu: rta_dist,
        }
    }

    pub fn hash(&self) -> String {
        hex::encode(Sha256::digest(serde_json::to_string(self).unwrap().as_bytes()))
    }
}
