use crate::ofa::{RatInterval, Term};
use num_bigint::BigInt;
use num_traits::{One, Zero};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::HashMap;

fn timestamp_now() -> String {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
        .to_string()
}

/// Deterministic witness binding for CRMF telemetry.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct CrmfWitness {
    pub witness_id: String,
    pub term: Term,
    pub interval: RatInterval,
    pub dimension: usize,
    pub contraction_coefficient: RatInterval,
    pub verified: bool,
}

impl CrmfWitness {
    pub fn new(
        term: Term,
        interval: RatInterval,
        dimension: usize,
        contraction_coefficient: RatInterval,
    ) -> Self {
        let witness_id = Self::compute_id(&term);
        Self {
            witness_id,
            term,
            interval,
            dimension,
            contraction_coefficient,
            verified: false,
        }
    }

    fn compute_id(term: &Term) -> String {
        let mut hasher = Sha256::new();
        hasher.update(serde_json::to_string(term).unwrap_or_default().as_bytes());
        format!("{:x}", hasher.finalize())
    }

    fn serialize(&self) -> String {
        serde_json::to_string(self).unwrap_or_default()
    }

    pub fn verify(&mut self, kani_result: &KaniResult) -> bool {
        self.verified = kani_result.passed && kani_result.dimension <= self.dimension;
        self.verified
    }
}

/// Kani bounded model checking result.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct KaniResult {
    pub harness_name: String,
    pub passed: bool,
    pub dimension: usize,
    pub bound: RatInterval,
    pub counterexample: Option<String>,
}

impl KaniResult {
    pub fn pass(harness_name: String, dimension: usize, bound: RatInterval) -> Self {
        Self {
            harness_name,
            passed: true,
            dimension,
            bound,
            counterexample: None,
        }
    }

    pub fn fail(harness_name: String, dimension: usize, counterexample: String) -> Self {
        Self {
            harness_name,
            passed: false,
            dimension,
            bound: RatInterval::singleton(BigInt::from(0), BigInt::from(1)),
            counterexample: Some(counterexample),
        }
    }
}

/// CRMF binding: maps Lean proof artifacts to Rust runtime telemetry.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CrmfBinding {
    pub contract_id: String,
    pub witnesses: Vec<CrmfWitness>,
    pub kani_results: Vec<KaniResult>,
    pub audit_log: Vec<AuditEntry>,
}

/// Single audit log entry.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct AuditEntry {
    pub timestamp: String,
    pub event: String,
    pub witness_id: String,
    pub governor: String,
    pub hash: String,
}

impl CrmfBinding {
    pub fn new(contract_id: String) -> Self {
        Self {
            contract_id,
            witnesses: Vec::new(),
            kani_results: Vec::new(),
            audit_log: Vec::new(),
        }
    }

    pub fn add_witness(&mut self, witness: CrmfWitness) {
        let entry = AuditEntry {
            timestamp: timestamp_now(),
            event: "witness_added".to_string(),
            witness_id: witness.witness_id.clone(),
            governor: "system".to_string(),
            hash: witness.term.hash(),
        };
        self.audit_log.push(entry);
        self.witnesses.push(witness);
    }

    pub fn add_kani_result(&mut self, result: KaniResult) {
        let entry = AuditEntry {
            timestamp: timestamp_now(),
            event: "kani_result".to_string(),
            witness_id: result.harness_name.clone(),
            governor: "kani".to_string(),
            hash: format!(
                "{:x}",
                Sha256::new()
                    .chain_update(
                        serde_json::to_string(&result)
                            .unwrap_or_default()
                            .as_bytes()
                    )
                    .finalize()
            ),
        };
        self.audit_log.push(entry);
        self.kani_results.push(result);
    }

    pub fn verify_all(&mut self) -> bool {
        for witness in &mut self.witnesses {
            let kani_result = self
                .kani_results
                .iter()
                .find(|r| r.harness_name == witness.witness_id && r.passed);
            if let Some(result) = kani_result {
                witness.verify(result);
            }
        }
        self.witnesses.iter().all(|w| w.verified)
    }

    pub fn is_drift_free(&self) -> bool {
        self.witnesses.iter().all(|w| w.verified) && self.kani_results.iter().all(|r| r.passed)
    }

    pub fn trigger_gov_kill(&self) -> Option<String> {
        if !self.is_drift_free() {
            Some(format!(
                "SIG_GOV_KILL: drift detected in contract {}",
                self.contract_id
            ))
        } else {
            None
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_crmf_witness_creation() {
        let term = Term::Var {
            name: "x".to_string(),
        };
        let interval = RatInterval::singleton(BigInt::from(1), BigInt::from(2));
        let cc = RatInterval::singleton(BigInt::from(1), BigInt::from(10));
        let witness = CrmfWitness::new(term, interval, 12, cc);
        assert_eq!(witness.dimension, 12);
        assert!(!witness.verified);
    }

    #[test]
    fn test_kani_result_pass() {
        let result = KaniResult::pass(
            "verify_coherence_finite_primes".to_string(),
            12,
            RatInterval::singleton(BigInt::from(1), BigInt::from(1000)),
        );
        assert!(result.passed);
        assert_eq!(result.dimension, 12);
    }

    #[test]
    fn test_binding_drift_free() {
        let mut binding = CrmfBinding::new("zeta_comb".to_string());
        let term = Term::Var {
            name: "x".to_string(),
        };
        let interval = RatInterval::singleton(BigInt::from(1), BigInt::from(2));
        let cc = RatInterval::singleton(BigInt::from(1), BigInt::from(10));
        let mut witness = CrmfWitness::new(term, interval, 12, cc);
        witness.witness_id = "verify_coherence_finite_primes".to_string();
        binding.add_witness(witness);

        let result = KaniResult::pass(
            "verify_coherence_finite_primes".to_string(),
            12,
            RatInterval::singleton(BigInt::from(1), BigInt::from(1000)),
        );
        binding.add_kani_result(result);

        assert!(binding.verify_all());
        assert!(binding.is_drift_free());
        assert!(binding.trigger_gov_kill().is_none());
    }

    #[test]
    fn test_binding_drift_detected() {
        let mut binding = CrmfBinding::new("zeta_comb".to_string());
        let term = Term::Var {
            name: "x".to_string(),
        };
        let interval = RatInterval::singleton(BigInt::from(1), BigInt::from(2));
        let cc = RatInterval::singleton(BigInt::from(1), BigInt::from(10));
        let witness = CrmfWitness::new(term, interval, 12, cc);
        binding.add_witness(witness);

        assert!(!binding.is_drift_free());
        assert!(binding.trigger_gov_kill().is_some());
    }
}
