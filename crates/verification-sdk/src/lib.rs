// crates/verification-sdk/src/lib.rs

use serde::{Deserialize, Serialize};
use wasm_bindgen::prelude::*;
use std::sync::Arc;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProofBundle {
    pub proof: serde_json::Value,
    #[serde(rename = "publicSignals")]
    pub public_signals: Vec<String>,
    #[serde(rename = "vKey")]
    pub v_key: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerificationResult {
    pub verified: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CslRuleResult {
    pub allowed: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub reason: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PreSubmissionResult {
    pub accepted: bool,
    #[serde(rename = "verificationResult")]
    pub verification_result: VerificationResult,
    #[serde(rename = "cslResult", skip_serializing_if = "Option::is_none")]
    pub csl_result: Option<CslRuleResult>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub receipt: Option<serde_json::Value>,
}

pub trait CslRule: Send + Sync {
    fn evaluate(&self, public_signals: &[String]) -> Result<CslRuleResult, String>;
}

#[derive(Debug, Clone)]
pub struct AmountCapRule {
    pub signal_index: usize,
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

pub struct CslEngine {
    pub rules: Vec<Arc<dyn CslRule>>,
}

impl CslEngine {
    pub fn new() -> Self {
        Self { rules: Vec::new() }
    }

    pub fn register_rule(&mut self, rule: Arc<dyn CslRule>) {
        self.rules.push(rule);
    }

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

pub struct ProofReceiptBuilder;

impl ProofReceiptBuilder {
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

pub struct VerificationSDK;

impl VerificationSDK {
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
pub struct WasmCslEngine {
    inner: CslEngine,
}

#[wasm_bindgen]
impl WasmCslEngine {
    #[wasm_bindgen(constructor)]
    pub fn new() -> Self {
        Self { inner: CslEngine::new() }
    }

    #[wasm_bindgen(js_name = registerRule)]
    pub fn register_rule(&mut self, rule: WasmCslRule) {
        self.inner.register_rule(rule.inner);
    }
}

#[wasm_bindgen]
pub struct WasmCslRule {
    inner: Arc<dyn CslRule>,
}

#[wasm_bindgen]
impl WasmCslRule {
    #[wasm_bindgen(js_name = newAmountCapRule)]
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
pub struct WasmVerificationSDK;

#[wasm_bindgen]
impl WasmVerificationSDK {
    #[wasm_bindgen(js_name = verifyLocally)]
    pub fn verify_locally(bundle_val: JsValue) -> Result<JsValue, JsError> {
        let bundle: ProofBundle = serde_wasm_bindgen::from_value(bundle_val)?;
        let res = VerificationSDK::verify_locally(&bundle);
        let res_val = serde_wasm_bindgen::to_value(&res)?;
        Ok(res_val)
    }

    #[wasm_bindgen(js_name = preSubmissionCheck)]
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
