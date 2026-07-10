use serde::{Deserialize, Serialize};
use num_bigint::BigUint;

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum Verdict {
    Compliant,
    NonCompliant,
    Silent,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum CslCommutationResult {
    Allow,
    Silent,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CapabilityToken {
    pub token_id: String,
    pub system_id: String,
    pub issuer_public_key: String,
    pub signature: String,
    pub nbf: u64,
    pub exp: u64,
    pub subject_id_hash: String,
    pub intent_hash: String,
    pub policy_bundle_hash: String,
    pub ltrace_ref: String,
    pub nullifier: String,
    pub epoch_index: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LTrace {
    pub trace_id: String,
    pub event_count: u64,
    pub root_hash: String,
    pub events_digest: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum FailureCode {
    SchemaInvalid,
    SignatureInvalid,
    TrustAnchorInvalid,
    TemporalExpired,
    TemporalNotYet,
    IdentityMismatch,
    IntentMismatch,
    PolicyDeprecated,
    TraceNotFound,
    TraceCorrupted,
    CslSilence,
    CslCommutationFail,
    PrimeGateClosed,
    DriftExceeded,
    NullifierReplay,
    CertificateRevoked,
    ArchivumInclusionFail,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ComplianceChecks {
    pub schema_valid: bool,
    pub signature_valid: bool,
    pub trust_anchor_valid: bool,
    pub temporal_valid: bool,
    pub prime_gate_open: bool,
    pub identity_binding: bool,
    pub intent_binding: bool,
    pub policy_binding: bool,
    pub audit_binding: bool,
    pub csl_commutation: CslCommutationResult,
    pub drift_within_bounds: bool,
    pub drift_value: f64,
    pub nullifier_fresh: bool,
    pub certificate_not_revoked: bool,
    pub archivum_verified: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ComplianceReport {
    pub report_id: String,
    pub system_id: String,
    pub timestamp: u64,
    pub epoch_index: u64,
    pub prime_gate_open: bool,
    pub verdict: Verdict,
    pub checks: ComplianceChecks,
    pub failure_codes: Vec<FailureCode>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub signature: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub attestation_uid: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum SubjectValue {
    BigUint(BigUint),
    U64(u64),
    String(String),
}
