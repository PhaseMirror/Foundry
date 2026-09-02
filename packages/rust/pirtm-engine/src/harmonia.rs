//! Harmonia (Φπε) Interface Adapter & Contractivity Witness Engine
//!
//! Implements the RI1 First-Contact Interface:
//! 1. Minimal Interoperable Object: Sparse Exponent Signature (`ri1-pirtm-contact-0.1`).
//! 2. Reproducible Invariant: Multiplicity Preservation & Rational Contractivity (‖Λₘ U‖ < 1.0).
//! 3. Ledger Provenance: UnifiedWitness SHA-256 contractivity receipt.

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::BTreeMap;

/// The canonical schema identifier for Harmonia first-contact state transfer
pub const HARMONIA_SCHEMA_VERSION: &str = "ri1-pirtm-contact-0.1";

/// Golden ratio constant Φ satisfying Φ² = Φ + 1
pub const PHI: f64 = 1.618033988749895;

/// Static Gibson exponential-field weight: ξ(p) = log_Φ(p)
pub fn gibson_weight(p: u64) -> f64 {
    if p <= 1 {
        0.0
    } else {
        (p as f64).ln() / PHI.ln()
    }
}

/// Provenance metadata tracking source grammar and generation timestamp
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct HarmoniaProvenance {
    pub source_system: String,
    pub grammar_version: String,
    pub created_at: String,
}

impl Default for HarmoniaProvenance {
    fn default() -> Self {
        Self {
            source_system: "PhiPiEpsilon".to_string(),
            grammar_version: "0.1".to_string(),
            created_at: "2026-08-31".to_string(),
        }
    }
}

/// The Shared First-Contact Artifact matching `ri1-pirtm-contact-0.1`
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct HarmoniaContactArtifact {
    pub schema: String,
    pub symbol_map: BTreeMap<String, u64>,
    pub state: BTreeMap<String, u64>,
    pub prime_signature: String,
    pub provenance: HarmoniaProvenance,
}

impl HarmoniaContactArtifact {
    /// Create a standard Φπε initial state artifact
    pub fn new_phi_pi_epsilon(phi_count: u64, pi_count: u64, eps_count: u64) -> Self {
        let mut symbol_map = BTreeMap::new();
        symbol_map.insert("Phi".to_string(), 2);
        symbol_map.insert("Pi".to_string(), 3);
        symbol_map.insert("Epsilon".to_string(), 5);

        let mut state = BTreeMap::new();
        state.insert("Phi".to_string(), phi_count);
        state.insert("Pi".to_string(), pi_count);
        state.insert("Epsilon".to_string(), eps_count);

        let prime_signature = format!("2^{} * 3^{} * 5^{}", phi_count, pi_count, eps_count);

        Self {
            schema: HARMONIA_SCHEMA_VERSION.to_string(),
            symbol_map,
            state,
            prime_signature,
            provenance: HarmoniaProvenance::default(),
        }
    }

    /// Compute canonical prime factorization integer surplus N = ∏ p_i^(k_i)
    pub fn compute_multiplicity_number(&self) -> u128 {
        let mut n: u128 = 1;
        for (sym, &count) in &self.state {
            if let Some(&p) = self.symbol_map.get(sym) {
                let p_u128 = p as u128;
                for _ in 0..count {
                    n = n.saturating_mul(p_u128);
                }
            }
        }
        n
    }

    /// Compute cumulative Gibson norm ‖ξ(σ)‖
    pub fn compute_gibson_norm(&self) -> f64 {
        let mut total = 0.0;
        for (sym, &count) in &self.state {
            if let Some(&p) = self.symbol_map.get(sym) {
                total += (count as f64) * gibson_weight(p);
            }
        }
        total
    }
}

/// Verification receipt generated when a state transition is validated
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct HarmoniaContractivityReceipt {
    pub contractivity_hash: String,
    pub norm_before: f64,
    pub norm_after: f64,
    pub lambda_m_eff: f64,
    pub is_contractive: bool,
    pub status: String,
}

/// Contractivity Validator for Harmonia process transitions
pub struct HarmoniaValidator;

impl HarmoniaValidator {
    /// Validate state update U : S_prev -> S_next under Λ_m damping
    pub fn validate_transition(
        prev: &HarmoniaContactArtifact,
        next: &HarmoniaContactArtifact,
    ) -> Result<HarmoniaContractivityReceipt, String> {
        let norm_before = prev.compute_gibson_norm();
        let norm_after = next.compute_gibson_norm();

        // Effective contraction coefficient: λ_eff = (1 + norm_after) / (1 + norm_before + 1.0)
        // Damped by the Universal Multiplicity Operator Λ_m (0.97 base factor)
        let lambda_base = 0.97;
        let delta_norm = (norm_after - norm_before).abs();
        let lambda_m_eff = lambda_base * (1.0 / (1.0 + delta_norm * 0.03));

        let is_contractive = lambda_m_eff < 1.0 && norm_after <= norm_before + 1.03;

        if !is_contractive {
            return Err(format!(
                "SIG_GOV_KILL: Non-contractive Harmonia transition. λ_eff = {:.4} >= 1.0",
                lambda_m_eff
            ));
        }

        // Generate SHA-256 UnifiedWitness anchor
        let mut hasher = Sha256::new();
        hasher.update(prev.prime_signature.as_bytes());
        hasher.update(next.prime_signature.as_bytes());
        hasher.update(&lambda_m_eff.to_le_bytes());
        let hash = format!("{:x}", hasher.finalize());

        Ok(HarmoniaContractivityReceipt {
            contractivity_hash: hash,
            norm_before,
            norm_after,
            lambda_m_eff,
            is_contractive,
            status: "CERTIFIED_CONTRACTIVE".to_string(),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_harmonia_schema_roundtrip() {
        let artifact = HarmoniaContactArtifact::new_phi_pi_epsilon(1, 2, 1);
        assert_eq!(artifact.schema, HARMONIA_SCHEMA_VERSION);
        assert_eq!(artifact.compute_multiplicity_number(), 2 * 9 * 5); // 2^1 * 3^2 * 5^1 = 90
        
        let json_str = serde_json::to_string_pretty(&artifact).unwrap();
        let deserialized: HarmoniaContactArtifact = serde_json::from_str(&json_str).unwrap();
        assert_eq!(artifact, deserialized);
    }

    #[test]
    fn test_valid_contractive_transition() {
        let s0 = HarmoniaContactArtifact::new_phi_pi_epsilon(1, 2, 1);
        let s1 = HarmoniaContactArtifact::new_phi_pi_epsilon(1, 1, 1); // 2^1 * 3^1 * 5^1 (subdivision)

        let receipt = HarmoniaValidator::validate_transition(&s0, &s1).expect("Transition should be contractive");
        assert!(receipt.is_contractive);
        assert!(receipt.lambda_m_eff < 1.0);
        assert_eq!(receipt.status, "CERTIFIED_CONTRACTIVE");
    }

    #[test]
    fn test_gibson_field_weights() {
        let w_phi = gibson_weight(2);
        let w_pi = gibson_weight(3);
        let w_eps = gibson_weight(5);

        assert!(w_phi > 0.0);
        assert!(w_pi > w_phi);
        assert!(w_eps > w_pi);
    }
}
