use std::collections::HashSet;
use uuid::Uuid;
use chrono::Utc;
use async_trait::async_trait;
use crate::types::{
    CapabilityToken, LTrace, FailureCode, ComplianceChecks, ComplianceReport, Verdict,
    CslCommutationResult, SubjectValue
};
use crate::prime_gate::PrimeGate;
use crate::drift_monitor::{DriftMonitor, Mode};
use crate::token_verifier::{TokenVerifier, TokenVerificationInput};

#[derive(Debug, Clone)]
pub struct CertifyInput {
    pub token: serde_json::Value,
    pub ltrace: serde_json::Value,
    pub epoch_index: u64,
    pub drift_value: f64,
    pub subject_secret: SubjectValue,
    pub subject_salt: SubjectValue,
    pub intent_object: serde_json::Value,
    pub policy_rules: serde_json::Value,
    pub policy_version: String,
    pub policy_issued_at: u64,
    pub rights_material: bool,
    pub domain_matches: bool,
    pub amber_blocked_actions: Option<HashSet<String>>,
}

#[async_trait]
pub trait MTPICertifierDependencies: Send + Sync {
    async fn verify_signature(&self, _token: &CapabilityToken) -> bool { true }
    async fn is_trust_anchor_valid(&self, _token: &CapabilityToken, _epoch_index: u64) -> bool { true }
    async fn evaluate_csl(&self, _input: &CertifyInput) -> CslCommutationResult { CslCommutationResult::Allow }
    async fn check_nullifier_fresh(&self, _token: &CapabilityToken) -> bool { true }
    async fn is_certificate_revoked(&self, _system_id: &str) -> bool { false }
    async fn verify_archivum(&self, _input: &CertifyInput) -> bool { true }
    async fn sign_report(&self, _report: &ComplianceReport) -> Option<String> { None }
}

pub struct DefaultDependencies;
#[async_trait]
impl MTPICertifierDependencies for DefaultDependencies {}

pub struct CertifierConfig {
    pub drift_max: f64,
    pub clock_skew_seconds: u64,
}

impl Default for CertifierConfig {
    fn default() -> Self {
        Self {
            drift_max: 0.5,
            clock_skew_seconds: 30,
        }
    }
}

pub struct MTPICertifier {
    config: CertifierConfig,
    prime_gate: PrimeGate,
    drift_monitor: DriftMonitor,
    token_verifier: TokenVerifier,
    deps: Box<dyn MTPICertifierDependencies>,
}

impl MTPICertifier {
    pub fn new(config: CertifierConfig, deps: Box<dyn MTPICertifierDependencies>) -> Self {
        let drift_monitor = DriftMonitor::new(config.drift_max);
        Self {
            config,
            prime_gate: PrimeGate::new(),
            drift_monitor,
            token_verifier: TokenVerifier::new(),
            deps,
        }
    }

    pub async fn certify(&self, input: CertifyInput) -> ComplianceReport {
        let now = Utc::now().timestamp() as u64;
        let report_id = Uuid::new_v4().to_string();

        let mut checks = self.empty_checks(input.drift_value);
        let mut failure_codes = Vec::new();

        // Schema validation
        let token: CapabilityToken = match serde_json::from_value(input.token.clone()) {
            Ok(t) => t,
            Err(_) => {
                failure_codes.push(FailureCode::SchemaInvalid);
                checks.schema_valid = false;
                return self.finalize_report(report_id, None, input.epoch_index, checks, failure_codes, None, HashSet::new()).await;
            }
        };

        let ltrace: LTrace = match serde_json::from_value(input.ltrace.clone()) {
            Ok(lt) => lt,
            Err(_) => {
                failure_codes.push(FailureCode::SchemaInvalid);
                checks.schema_valid = false;
                return self.finalize_report(report_id, Some(token), input.epoch_index, checks, failure_codes, None, HashSet::new()).await;
            }
        };

        checks.schema_valid = true;

        // Signature check
        checks.signature_valid = self.deps.verify_signature(&token).await;
        if !checks.signature_valid {
            failure_codes.push(FailureCode::SignatureInvalid);
        }

        // Trust Anchor check
        checks.trust_anchor_valid = self.deps.is_trust_anchor_valid(&token, input.epoch_index).await;
        if !checks.trust_anchor_valid {
            failure_codes.push(FailureCode::TrustAnchorInvalid);
        }

        // Prime Gate check
        let prime_result = self.prime_gate.evaluate(input.epoch_index);
        checks.prime_gate_open = prime_result.is_prime;
        if !checks.prime_gate_open {
            failure_codes.push(FailureCode::PrimeGateClosed);
            return self.finalize_report(report_id, Some(token), prime_result.epoch_index, checks, failure_codes, None, HashSet::new()).await;
        }

        // Temporal check
        let skew = self.config.clock_skew_seconds;
        let temporal_not_yet = now + skew < token.nbf;
        let temporal_expired = now > token.exp + skew;
        checks.temporal_valid = !(temporal_not_yet || temporal_expired);
        if temporal_not_yet {
            failure_codes.push(FailureCode::TemporalNotYet);
        }
        if temporal_expired {
            failure_codes.push(FailureCode::TemporalExpired);
        }

        // Nullifier check
        checks.nullifier_fresh = self.deps.check_nullifier_fresh(&token).await;
        if !checks.nullifier_fresh {
            failure_codes.push(FailureCode::NullifierReplay);
        }

        // Revocation check
        checks.certificate_not_revoked = !self.deps.is_certificate_revoked(&token.system_id).await;
        if !checks.certificate_not_revoked {
            failure_codes.push(FailureCode::CertificateRevoked);
        }

        // Token bindings check
        let verification = self.token_verifier.verify(TokenVerificationInput {
            token: token.clone(),
            subject_secret: input.subject_secret.clone(),
            subject_salt: input.subject_salt.clone(),
            intent_object: input.intent_object.clone(),
            policy_rules: input.policy_rules.clone(),
            policy_version: input.policy_version.clone(),
            policy_issued_at: input.policy_issued_at,
            ltrace: ltrace.clone(),
        }).await;

        checks.identity_binding = verification.identity_binding;
        checks.intent_binding = verification.intent_binding;
        checks.policy_binding = verification.policy_binding;
        checks.audit_binding = verification.audit_binding;
        failure_codes.extend(verification.failure_codes);

        // Drift check (incorporating Brakes specs)
        let drift_result = self.drift_monitor.evaluate(
            input.drift_value, 
            input.rights_material, 
            input.domain_matches, 
            input.amber_blocked_actions.clone()
        );
        checks.drift_value = drift_result.drift_value;
        checks.drift_within_bounds = drift_result.within_bounds;
        if !checks.drift_within_bounds {
            failure_codes.push(FailureCode::DriftExceeded);
        }

        // CSL check
        checks.csl_commutation = self.deps.evaluate_csl(&input).await;
        if checks.csl_commutation != CslCommutationResult::Allow {
            failure_codes.push(FailureCode::CslSilence);
        }

        // Archivum check
        checks.archivum_verified = self.deps.verify_archivum(&input).await;
        if !checks.archivum_verified {
            failure_codes.push(FailureCode::ArchivumInclusionFail);
        }

        self.finalize_report(
            report_id, 
            Some(token), 
            prime_result.epoch_index, 
            checks, 
            failure_codes,
            drift_result.required_mode,
            drift_result.blocked_actions
        ).await
    }

    fn empty_checks(&self, drift_value: f64) -> ComplianceChecks {
        ComplianceChecks {
            schema_valid: false,
            signature_valid: false,
            trust_anchor_valid: false,
            temporal_valid: false,
            prime_gate_open: false,
            identity_binding: false,
            intent_binding: false,
            policy_binding: false,
            audit_binding: false,
            csl_commutation: CslCommutationResult::Silent,
            drift_within_bounds: false,
            drift_value,
            nullifier_fresh: false,
            certificate_not_revoked: false,
            archivum_verified: false,
        }
    }

    async fn finalize_report(
        &self,
        report_id: String,
        token: Option<CapabilityToken>,
        epoch_index: u64,
        checks: ComplianceChecks,
        mut failure_codes: Vec<FailureCode>,
        required_mode: Option<Mode>,
        blocked_actions: HashSet<String>,
    ) -> ComplianceReport {
        // Deduplicate failure codes
        let mut seen = HashSet::new();
        failure_codes.retain(|code| seen.insert(format!("{:?}", code)));

        let verdict = if failure_codes.is_empty() {
            Verdict::Compliant
        } else if failure_codes.iter().any(|c| matches!(c, FailureCode::PrimeGateClosed | FailureCode::CslSilence)) {
            Verdict::Silent
        } else {
            Verdict::NonCompliant
        };

        let mut report = ComplianceReport {
            report_id,
            system_id: token.map(|t| t.system_id).unwrap_or_else(|| "unknown-system".to_string()),
            timestamp: Utc::now().timestamp() as u64,
            epoch_index,
            prime_gate_open: checks.prime_gate_open,
            verdict,
            checks,
            failure_codes: failure_codes.clone(),
            signature: None,
            attestation_uid: None,
        };

        // Add additional metadata for Red band brakes if applicable
        if let Some(mode) = required_mode {
             println!("Mandatory Brake Triggered: Mode -> {:?}", mode);
        }
        if !blocked_actions.is_empty() {
             println!("Blocked Actions: {:?}", blocked_actions);
        }

        if let Some(sig) = self.deps.sign_report(&report).await {
            report.signature = Some(sig);
        }

        report
    }
}
