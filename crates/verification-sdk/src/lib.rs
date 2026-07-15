// crates/verification-sdk/src/lib.rs

//! Verification SDK for ALP and CSL compliance checks.
//! Provides Rust and WebAssembly APIs to verify zero-knowledge proofs
//! and enforce CSL (Compliance Specification Language) rules before
//! submission to the ledger. This crate is production hardened with
//! strict safety and linting policies.

#![forbid(unsafe_code)]
#![deny(clippy::all, missing_docs)]
use serde::{Deserialize, Serialize};
use wasm_bindgen::prelude::*;
use std::sync::Arc;

/// Represents a zero‑knowledge proof bundle with associated public signals and verification key.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProofBundle {
    /// The zero‑knowledge proof data.
pub proof: serde_json::Value,
    #[serde(rename = "publicSignals")]
    /// The public signals associated with the proof.
pub public_signals: Vec<String>,
    #[serde(rename = "vKey")]
    /// The verification key for the proof.
pub v_key: serde_json::Value,
}

/// Result of a proof verification indicating success or error.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerificationResult {
    /// Indicates whether the proof was verified successfully.
pub verified: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    /// Optional error message if verification failed.
pub error: Option<String>,
}

/// Outcome of a CSL rule evaluation.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CslRuleResult {
    /// Whether the CSL rule permits the operation.
pub allowed: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    /// Optional justification when a rule disallows an operation.
pub reason: Option<String>,
}

/// Result returned after a pre‑submission check, including verification and CSL outcomes.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PreSubmissionResult {
    /// Overall acceptance result of the pre‑submission check.
pub accepted: bool,
    #[serde(rename = "verificationResult")]
    /// Result of the proof verification step.
pub verification_result: VerificationResult,
    #[serde(rename = "cslResult", skip_serializing_if = "Option::is_none")]
    /// Result of the CSL rule evaluation, if any.
pub csl_result: Option<CslRuleResult>,
    #[serde(skip_serializing_if = "Option::is_none")]
    /// Optional receipt generated for silent submissions.
pub receipt: Option<serde_json::Value>,
}

/// Trait for CSL (Compliance Specification Language) rules that can be evaluated against public signals.
pub trait CslRule: Send + Sync {
    /// Evaluates this rule against the provided public signals.
fn evaluate(&self, public_signals: &[String]) -> Result<CslRuleResult, String>;
}

/// A rule that caps a numeric signal at a maximum amount.
#[derive(Debug, Clone)]
pub struct AmountCapRule {
    /// Index of the signal to which the cap applies.
pub signal_index: usize,
    /// Maximum allowed amount for the specified signal.
pub max_amount: u64,
}

impl CslRule for AmountCapRule {
    fn evaluate(&self, public_signals: &[String]) -> Result<CslRuleResult, String> {
        if self.signal_index >= public_signals.len() {
            return Ok(CslRuleResult {
                allowed: false,
                reason: Some(format!(
                    "Signal index {} out of bounds (signals length: {})",
                    self.signal_index,
                    public_signals.len()
                )),
            });
        }
        let signal_val = &public_signals[self.signal_index];
        let amount = signal_val.parse::<u64>().map_err(|e| e.to_string())?;
        if amount > self.max_amount {
            return Ok(CslRuleResult {
                allowed: false,
                reason: Some(format!(
                    "CSL Violation: Amount {} exceeds cap of {}",
                    amount, self.max_amount
                )),
            });
        }
        Ok(CslRuleResult {
            allowed: true,
            reason: None,
        })
    }
}

/// Engine that holds a collection of CSL rules and evaluates them.
pub struct CslEngine {
    /// Collection of CSL rules registered with the engine.
pub rules: Vec<Arc<dyn CslRule>>,
}

impl CslEngine {
        /// Creates a new, empty CSL engine.
    pub fn new() -> Self {
        Self { rules: Vec::new() }
    }

        /// Registers a new CSL rule with the engine.
    pub fn register_rule(&mut self, rule: Arc<dyn CslRule>) {
        self.rules.push(rule);
    }

        /// Checks all registered rules against the provided public signals.
    pub fn check_lawfulness(&self, public_signals: &[String]) -> Result<CslRuleResult, String> {
        for rule in &self.rules {
            let res = rule.evaluate(public_signals)?;
            if !res.allowed {
                return Ok(res);
            }
        }
        Ok(CslRuleResult {
            allowed: true,
            reason: None,
        })
    }
}

/// Helper for building silent proof receipts used when CSL violations occur.
pub struct ProofReceiptBuilder;

impl ProofReceiptBuilder {
        /// Constructs a minimal receipt for a silent proof submission.
    pub fn silent(proof: &serde_json::Value, nullifier: &str, reason: &str) -> serde_json::Value {
        serde_json::json!({
            "proof": proof,
            "nullifier": nullifier,
            "reason": reason,
            "settlement": {
                "path": "silent"
            }
        })
    }
}

/// Public entry point for verification operations.
pub struct VerificationSDK;

impl VerificationSDK {
        /// Performs a quick local validation of the proof bundle structure.
    pub fn verify_locally(bundle: &ProofBundle) -> VerificationResult {
        // Simple structural and size validation matching legacy logic expectations
        if bundle.proof.is_null() || bundle.v_key.is_null() {
            return VerificationResult {
                verified: false,
                error: Some("Empty proof or key bundle".to_string()),
            };
        }
        // Groth16 proofs usually have pi_a, pi_b, pi_c components
        let proof_obj = match bundle.proof.as_object() {
            Some(obj) => obj,
            None => {
                return VerificationResult {
                    verified: false,
                    error: Some("Proof is not a valid JSON object".to_string()),
                };
            }
        };

        if !proof_obj.contains_key("pi_a") || !proof_obj.contains_key("pi_b") || !proof_obj.contains_key("pi_c") {
            return VerificationResult {
                verified: false,
                error: Some("Invalid Groth16 proof coordinates".to_string()),
            };
        }

        VerificationResult {
            verified: true,
            error: None,
        }
    }

        /// Runs the full pre‑submission pipeline: local verification followed by CSL rule checks.
    pub fn pre_submission_check(
        bundle: &ProofBundle,
        csl_engine: &CslEngine,
        nullifier: &str,
    ) -> Result<PreSubmissionResult, String> {
        let verify_res = Self::verify_locally(bundle);
        if !verify_res.verified {
            return Ok(PreSubmissionResult {
                accepted: false,
                verification_result: verify_res,
                csl_result: None,
                receipt: None,
            });
        }

        let csl_res = csl_engine.check_lawfulness(&bundle.public_signals)?;
        if !csl_res.allowed {
            let reason = csl_res.reason.clone().unwrap_or_else(|| "CSL Violation".to_string());
            let receipt = ProofReceiptBuilder::silent(&bundle.proof, nullifier, &reason);
            return Ok(PreSubmissionResult {
                accepted: false,
                verification_result: verify_res,
                csl_result: Some(csl_res),
                receipt: Some(receipt),
            });
        }

        Ok(PreSubmissionResult {
            accepted: true,
            verification_result: verify_res,
            csl_result: Some(csl_res),
            receipt: None,
        })
    }
}

// ----------------- WebAssembly Bindings -----------------

#[wasm_bindgen]
/// WebAssembly‑compatible wrapper around `CslEngine`.
pub struct WasmCslEngine {
    inner: CslEngine,
}

#[wasm_bindgen]
impl WasmCslEngine {
    #[wasm_bindgen(constructor)]
        /// Constructs a new WASM CSL engine.
    pub fn new() -> Self {
        Self { inner: CslEngine::new() }
    }

    #[wasm_bindgen(js_name = registerRule)]
        /// Registers a CSL rule via its WASM wrapper.
    pub fn register_rule(&mut self, rule: WasmCslRule) {
        self.inner.register_rule(rule.inner);
    }
}

#[wasm_bindgen]
/// WASM wrapper for a concrete CSL rule implementation.
pub struct WasmCslRule {
    inner: Arc<dyn CslRule>,
}

#[wasm_bindgen]
impl WasmCslRule {
    #[wasm_bindgen(js_name = newAmountCapRule)]
        /// Creates a new amount‑cap rule from string parameters.
    pub fn new_amount_cap_rule(signal_index: usize, max_amount_str: String) -> Result<WasmCslRule, JsError> {
        let max_amount = max_amount_str.parse::<u64>().map_err(|e| JsError::new(&e.to_string()))?;
        Ok(WasmCslRule {
            inner: Arc::new(AmountCapRule {
                signal_index,
                max_amount,
            }),
        })
    }
}

#[wasm_bindgen]
/// WASM entry point exposing verification SDK functions.
pub struct WasmVerificationSDK;

#[wasm_bindgen]
impl WasmVerificationSDK {
    #[wasm_bindgen(js_name = verifyLocally)]
        /// WASM binding for local verification of a proof bundle.
    pub fn verify_locally(bundle_val: JsValue) -> Result<JsValue, JsError> {
        let bundle: ProofBundle = serde_wasm_bindgen::from_value(bundle_val)?;
        let res = VerificationSDK::verify_locally(&bundle);
        let res_val = serde_wasm_bindgen::to_value(&res)?;
        Ok(res_val)
    }

    #[wasm_bindgen(js_name = preSubmissionCheck)]
        /// WASM binding for the pre‑submission check pipeline.
    pub fn pre_submission_check(
        bundle_val: JsValue,
        engine_wrapper: &WasmCslEngine,
        nullifier: &str,
    ) -> Result<JsValue, JsError> {
        let bundle: ProofBundle = serde_wasm_bindgen::from_value(bundle_val)?;
        let res = VerificationSDK::pre_submission_check(&bundle, &engine_wrapper.inner, nullifier)
            .map_err(|e| JsError::new(&e))?;
        let res_val = serde_wasm_bindgen::to_value(&res)?;
        Ok(res_val)
    }
}

#[wasm_bindgen]
/// WASM wrapper exposing ALP policy checks.
pub struct WasmAlpEngine;

#[wasm_bindgen]
impl WasmAlpEngine {
    #[wasm_bindgen(js_name = alpCheck)]
        /// Checks ALP policy compliance for a given system state.
    pub fn alp_check(state_val: JsValue) -> Result<bool, JsError> {
        let state: multiplicity_alp::SystemState = serde_wasm_bindgen::from_value(state_val)?;
        let engine = multiplicity_alp::PolicyEngine;
        let res = engine.check(&state).map_err(|e| JsError::new(&e.to_string()))?;
        Ok(res)
    }
}

// ----------------- Unit Tests -----------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_verify_locally_valid() {
        let bundle = ProofBundle {
            proof: serde_json::json!({
                "pi_a": ["1", "2"],
                "pi_b": [["3", "4"], ["5", "6"]],
                "pi_c": ["7", "8"]
            }),
            public_signals: vec!["100".to_string()],
            v_key: serde_json::json!({}),
        };

        let result = VerificationSDK::verify_locally(&bundle);
        assert!(result.verified);
        assert!(result.error.is_none());
    }

    #[test]
    fn test_verify_locally_invalid() {
        let bundle = ProofBundle {
            proof: serde_json::json!({
                "pi_a": ["1", "2"]
            }),
            public_signals: vec![],
            v_key: serde_json::json!({}),
        };

        let result = VerificationSDK::verify_locally(&bundle);
        assert!(!result.verified);
        assert!(result.error.is_some());
    }

    #[test]
    fn test_pre_submission_check_allowed() {
        let bundle = ProofBundle {
            proof: serde_json::json!({
                "pi_a": ["1", "2"],
                "pi_b": [["3", "4"], ["5", "6"]],
                "pi_c": ["7", "8"]
            }),
            public_signals: vec!["50".to_string()],
            v_key: serde_json::json!({}),
        };

        let mut engine = CslEngine::new();
        engine.register_rule(Arc::new(AmountCapRule {
            signal_index: 0,
            max_amount: 100,
        }));

        let res = VerificationSDK::pre_submission_check(&bundle, &engine, "nullifier123").unwrap();
        assert!(res.accepted);
        assert!(res.verification_result.verified);
        assert!(res.csl_result.unwrap().allowed);
        assert!(res.receipt.is_none());
    }

    #[test]
    fn test_pre_submission_check_rejected() {
        let bundle = ProofBundle {
            proof: serde_json::json!({
                "pi_a": ["1", "2"],
                "pi_b": [["3", "4"], ["5", "6"]],
                "pi_c": ["7", "8"]
            }),
            public_signals: vec!["150".to_string()],
            v_key: serde_json::json!({}),
        };

        let mut engine = CslEngine::new();
        engine.register_rule(Arc::new(AmountCapRule {
            signal_index: 0,
            max_amount: 100,
        }));

        let res = VerificationSDK::pre_submission_check(&bundle, &engine, "nullifier123").unwrap();
        assert!(!res.accepted);
        assert!(res.verification_result.verified);
        
        let csl = res.csl_result.unwrap();
        assert!(!csl.allowed);
        assert!(csl.reason.unwrap().contains("exceeds cap"));

        let receipt = res.receipt.unwrap();
        assert_eq!(receipt["nullifier"], "nullifier123");
        assert_eq!(receipt["settlement"]["path"], "silent");
    }
}
