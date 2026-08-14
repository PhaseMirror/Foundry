use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct PwehReceipt {
    pub s_integrity: String,
    pub last_prime_move: u64,
    pub policy_root_hash: String,
    pub crmf_certificate: String,
    pub lambda_m_resonance_score: f64,
}

pub fn validate_receipt(r: &PwehReceipt) -> bool {
    is_valid_hash(&r.s_integrity) &&
    is_valid_hash(&r.policy_root_hash) &&
    is_valid_hash(&r.crmf_certificate) &&
    (0.0..=1.0).contains(&r.lambda_m_resonance_score)
}

fn is_valid_hash(s: &str) -> bool {
    s.len() == 64 && s.chars().all(|c| c.is_ascii_hexdigit() && !c.is_ascii_uppercase())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_valid_receipt_v566() {
        let json_data = r#"{
            "s_integrity": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
            "last_prime_move": 43,
            "policy_root_hash": "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
            "crmf_certificate": "1111111111111111111111111111111111111111111111111111111111111111",
            "lambda_m_resonance_score": 0.992
        }"#;

        let receipt: PwehReceipt = serde_json::from_str(json_data).unwrap();
        assert!(validate_receipt(&receipt));
    }
}
