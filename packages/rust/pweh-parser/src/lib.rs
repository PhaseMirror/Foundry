//! Rust port of `packages/rust/pweh-parser/pweh_adapter.py`.
//!
//! PWEH checkpoint adapter for DecisionAssure. Validates PWEH checkpoint
//! receipts and produces DecisionAssure verification output.
//!
//! Fidelity contract (see `Adapter_Fidelity_Report.md`):
//! * `validate_hash`      — 64-char lowercase hex, mirrors Lean `isValidHash`
//! * `validate_prime`     — trial-division primality on `last_prime_move`
//! * `validate_resonance_score` — closed interval `[0.0, 1.0]`, mirrors Lean
//!   `isValidResonanceScore`
//!
//! Divergences from the Python (intentional, all stricter/sound):
//! * The Python `lambda_m_resonance_score` check accidentally admits `NaN`
//!   (both comparisons are false); this port rejects non-finite values,
//!   matching the Lean bound rather than the Python quirk.
//! * JSON is deserialized through a statically-typed `PwehReceipt`; non-numeric
//!   resonance scores reject at deserialization instead of at validation time.
//!
//! The `DecisionAssureAdapter` output shape (`receipt_hash`,
//! `continuity_result`, `violation_details`, `timestamp`) matches the Python
//! byte-for-byte for well-formed input.

use chrono::{SecondsFormat, Utc};
use serde::{Deserialize, Serialize};

/// Raw PWEH checkpoint receipt as supplied in the JSON payload.
///
/// All fields default when absent, mirroring the Python
/// `data.get('field', default)` semantics: empty string / `0` / `0.0`.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PwehReceipt {
    #[serde(default)]
    pub s_integrity: String,
    #[serde(default)]
    pub last_prime_move: u64,
    #[serde(default)]
    pub policy_root_hash: String,
    #[serde(default)]
    pub crmf_certificate: String,
    #[serde(default)]
    pub lambda_m_resonance_score: f64,
}

/// Validated PWEH checkpoint, mirroring the Python `PWEHCheckpoint`
/// dataclass: the raw receipt plus the accumulated validation outcome.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PwehCheckpoint {
    pub receipt: PwehReceipt,
    pub is_valid: bool,
    pub validation_errors: Vec<String>,
}

/// DecisionAssure verification output, mirroring the Python dict produced by
/// `DecisionAssureAdapter.verify_checkpoint`.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct VerifyOutput {
    pub receipt_hash: String,
    pub continuity_result: String,
    pub violation_details: Vec<String>,
    pub timestamp: String,
}

impl VerifyOutput {
    /// Convenience predicate mirroring the Python
    /// `sys.exit(0 if result["continuity_result"] == "PASS" else 1)`.
    pub fn is_pass(&self) -> bool {
        self.continuity_result == "PASS"
    }
}

/// Static validation helpers, mirroring `PWEHValidator`.
pub struct PwehValidator;

impl PwehValidator {
    /// Validate a 64-character lowercase hex hash.
    ///
    /// Equivalent to the Python `re.match(r'^[a-f0-9]{64}$', value)` and to
    /// the Lean `isValidHash` predicate: only digits and `a`–`f`, length 64.
    pub fn validate_hash(value: &str, field_name: &str) -> Result<(), String> {
        if value.is_empty() {
            return Err(format!("{field_name} is empty"));
        }
        if value.len() != 64 {
            return Err(format!(
                "{field_name} length is {} (expected 64)",
                value.len()
            ));
        }
        let is_lower_hex = value
            .chars()
            .all(|c| c.is_ascii_hexdigit() && !c.is_ascii_uppercase());
        if !is_lower_hex {
            return Err(format!(
                "{field_name} contains invalid characters (must be lowercase hex)"
            ));
        }
        Ok(())
    }

    /// Validate that a number is prime (trial division, odds only).
    ///
    /// Mirrors the Python `validate_prime`: rejects `< 2` and even numbers,
    /// then trial-divides by odd `i` while `i <= sqrt(value)` (written
    /// overflow-free as `i <= value / i`).
    pub fn validate_prime(value: u64) -> Result<(), String> {
        if value < 2 {
            return Err(format!(
                "last_prime_move must be a prime number >= 2 (got {value})"
            ));
        }
        if value == 2 {
            return Ok(());
        }
        if value.is_multiple_of(2) {
            return Err(format!("{value} is not prime (divisible by 2)"));
        }
        let mut i: u64 = 3;
        while i <= value / i {
            if value.is_multiple_of(i) {
                return Err(format!("{value} is not prime (divisible by {i})"));
            }
            i += 2;
        }
        Ok(())
    }

    /// Validate that a resonance score is within `[0.0, 1.0]`.
    ///
    /// Mirrors the Python bounds check but also rejects non-finite values
    /// (the Python accidentally admits `NaN`); see module docs.
    pub fn validate_resonance_score(value: f64) -> Result<(), String> {
        if !value.is_finite() {
            return Err(format!(
                "lambda_m_resonance_score must be a number (got {value:?})"
            ));
        }
        if !(0.0..=1.0).contains(&value) {
            return Err(format!(
                "lambda_m_resonance_score must be between 0.0 and 1.0 (got {value})"
            ));
        }
        Ok(())
    }

    /// Validate a checkpoint receipt and accumulate every violation.
    ///
    /// Mirrors `PWEHValidator.validate`: runs all five checks regardless of
    /// intermediate failures and reports the full error list.
    pub fn validate(data: &PwehReceipt) -> PwehCheckpoint {
        let mut errors = Vec::new();
        if let Err(msg) = Self::validate_hash(&data.s_integrity, "s_integrity") {
            errors.push(msg);
        }
        if let Err(msg) = Self::validate_hash(&data.policy_root_hash, "policy_root_hash") {
            errors.push(msg);
        }
        if let Err(msg) = Self::validate_hash(&data.crmf_certificate, "crmf_certificate") {
            errors.push(msg);
        }
        if let Err(msg) = Self::validate_prime(data.last_prime_move) {
            errors.push(msg);
        }
        if let Err(msg) = Self::validate_resonance_score(data.lambda_m_resonance_score) {
            errors.push(msg);
        }
        PwehCheckpoint {
            receipt: data.clone(),
            is_valid: errors.is_empty(),
            validation_errors: errors,
        }
    }
}

/// Adapter that consumes PWEH checkpoints and produces DecisionAssure
/// verification output, mirroring `DecisionAssureAdapter`.
pub struct DecisionAssureAdapter;

impl DecisionAssureAdapter {
    /// Verify a PWEH checkpoint and produce DecisionAssure-compatible output.
    ///
    /// `timestamp` mirrors Python `datetime.utcnow().isoformat() + "Z"` —
    /// RFC 3339 in UTC with microsecond precision and a trailing `Z`.
    pub fn verify_checkpoint(&self, receipt: &PwehReceipt) -> VerifyOutput {
        let checkpoint = PwehValidator::validate(receipt);
        VerifyOutput {
            receipt_hash: if checkpoint.receipt.s_integrity.is_empty() {
                String::new()
            } else {
                checkpoint.receipt.s_integrity.clone()
            },
            continuity_result: if checkpoint.is_valid {
                "PASS".to_string()
            } else {
                "FAIL".to_string()
            },
            violation_details: checkpoint.validation_errors,
            timestamp: Utc::now().to_rfc3339_opts(SecondsFormat::Micros, true),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn valid_receipt() -> PwehReceipt {
        PwehReceipt {
            s_integrity: "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
                .to_string(),
            last_prime_move: 43,
            policy_root_hash: "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
                .to_string(),
            crmf_certificate: "1111111111111111111111111111111111111111111111111111111111111111"
                .to_string(),
            lambda_m_resonance_score: 0.992,
        }
    }

    #[test]
    fn validate_hash_accepts_lowercase_hex() {
        assert!(PwehValidator::validate_hash(&"a".repeat(64), "s_integrity").is_ok());
    }

    #[test]
    fn validate_hash_rejects_length() {
        assert_eq!(
            PwehValidator::validate_hash("short", "s_integrity"),
            Err("s_integrity length is 5 (expected 64)".to_string())
        );
    }

    #[test]
    fn validate_hash_rejects_zero_length() {
        assert_eq!(
            PwehValidator::validate_hash("", "policy_root_hash"),
            Err("policy_root_hash is empty".to_string())
        );
    }

    #[test]
    fn validate_hash_rejects_uppercase_and_prefix() {
        assert!(PwehValidator::validate_hash(&"A".repeat(64), "s_integrity").is_err());
        assert!(PwehValidator::validate_hash(
            "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab",
            "s_integrity"
        )
        .is_err());
    }

    #[test]
    fn validate_prime_accepts_known_primes() {
        for p in [2u64, 3, 5, 43] {
            assert!(PwehValidator::validate_prime(p).is_ok(), "prime {p}");
        }
    }

    #[test]
    fn validate_prime_rejects_composites_and_edges() {
        assert!(PwehValidator::validate_prime(0).is_err());
        assert!(PwehValidator::validate_prime(1).is_err());
        assert!(PwehValidator::validate_prime(4).is_err());
        assert!(PwehValidator::validate_prime(9).is_err());
        assert!(PwehValidator::validate_prime(1_000_000_007 * 1_000_000_009).is_err());
    }

    #[test]
    fn validate_prime_error_messages_match_python() {
        let err = PwehValidator::validate_prime(4).unwrap_err();
        assert!(err.contains("prime"));
        assert!(err.contains("divisible by 2"));
        let err = PwehValidator::validate_prime(9).unwrap_err();
        assert!(err.contains("divisible by 3"));
    }

    #[test]
    fn validate_resonance_bounds() {
        assert!(PwehValidator::validate_resonance_score(0.0).is_ok());
        assert!(PwehValidator::validate_resonance_score(0.992).is_ok());
        assert!(PwehValidator::validate_resonance_score(1.0).is_ok());
        assert!(PwehValidator::validate_resonance_score(1.5).is_err());
        assert!(PwehValidator::validate_resonance_score(-0.1).is_err());
        assert!(PwehValidator::validate_resonance_score(f64::NAN).is_err());
        assert!(PwehValidator::validate_resonance_score(f64::INFINITY).is_err());
    }

    #[test]
    fn valid_checkpoint_passes() {
        let checkpoint = PwehValidator::validate(&valid_receipt());
        assert!(checkpoint.is_valid);
        assert!(checkpoint.validation_errors.is_empty());
    }

    #[test]
    fn invalid_hash_length_reports_length_error() {
        let mut r = valid_receipt();
        r.s_integrity = "short".to_string();
        let checkpoint = PwehValidator::validate(&r);
        assert!(!checkpoint.is_valid);
        assert!(checkpoint
            .validation_errors
            .iter()
            .any(|e| e.contains("length is")));
    }

    #[test]
    fn invalid_hash_characters_reject_uppercase_and_prefix() {
        let mut r = valid_receipt();
        r.s_integrity =
            "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab".to_string();
        r.policy_root_hash =
            "ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890".to_string();
        let checkpoint = PwehValidator::validate(&r);
        assert!(!checkpoint.is_valid);
        assert!(checkpoint
            .validation_errors
            .iter()
            .any(|e| e.contains("invalid characters")));
    }

    #[test]
    fn non_prime_is_rejected() {
        let mut r = valid_receipt();
        r.last_prime_move = 4;
        let checkpoint = PwehValidator::validate(&r);
        assert!(!checkpoint.is_valid);
        assert!(checkpoint
            .validation_errors
            .iter()
            .any(|e| e.contains("prime")));
    }

    #[test]
    fn out_of_bounds_resonance_is_rejected() {
        let mut r = valid_receipt();
        r.lambda_m_resonance_score = 1.5;
        let checkpoint = PwehValidator::validate(&r);
        assert!(!checkpoint.is_valid);
        assert!(checkpoint
            .validation_errors
            .iter()
            .any(|e| e.contains("between 0.0 and 1.0")));
    }

    #[test]
    fn missing_fields_default_like_python_get() {
        let r: PwehReceipt = serde_json::from_str("{}").unwrap();
        assert_eq!(r.last_prime_move, 0);
        assert_eq!(r.lambda_m_resonance_score, 0.0);
        let checkpoint = PwehValidator::validate(&r);
        assert!(!checkpoint.is_valid);
        // Empty s_integrity/policy_root_hash/crmf_certificate +
        // non-prime 0 are violations; resonance score 0.0 is in-bounds.
        assert_eq!(checkpoint.validation_errors.len(), 4);
    }

    #[test]
    fn adapter_emits_decisionsassure_shape() {
        let output = DecisionAssureAdapter.verify_checkpoint(&valid_receipt());
        assert_eq!(output.continuity_result, "PASS");
        assert!(output.is_pass());
        assert_eq!(
            output.receipt_hash,
            "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        );
        assert!(output.violation_details.is_empty());
        assert!(output.timestamp.ends_with('Z'));
    }

    #[test]
    fn adapter_reports_failure() {
        let mut r = valid_receipt();
        r.lambda_m_resonance_score = 1.5;
        let output = DecisionAssureAdapter.verify_checkpoint(&r);
        assert_eq!(output.continuity_result, "FAIL");
        assert!(!output.is_pass());
        assert!(!output.violation_details.is_empty());
    }

    #[test]
    fn roundtrip_serialization_matches_sample_report() {
        let mut r = valid_receipt();
        r.lambda_m_resonance_score = 0.992;
        let output = DecisionAssureAdapter.verify_checkpoint(&r);
        let json = serde_json::to_value(&output).unwrap();
        assert_eq!(json["receipt_hash"].as_str().unwrap(), output.receipt_hash);
        assert_eq!(json["continuity_result"], "PASS");
        assert_eq!(json["violation_details"], serde_json::json!([]));
    }
}
