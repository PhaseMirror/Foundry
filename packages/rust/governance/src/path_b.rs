use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use chrono::Utc;
use thiserror::Error;

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum DeploymentStatus {
    Internal,
    Active,
    Suspended,
    Revoked,
}

#[derive(Error, Debug)]
pub enum PathBError {
    #[error("Invalid status: {0}")]
    InvalidStatus(String),
    #[error("Steward ID is required")]
    StewardRequired,
    #[error("Invalid lifecycle transition: {from:?} -> {to:?}")]
    InvalidTransition { from: DeploymentStatus, to: DeploymentStatus },
    #[error("Domain scope must be explicit and versioned (example: domain@v1)")]
    InvalidScope,
    #[error("Prior CMG gates incomplete: {0:?}")]
    GatesIncomplete(Vec<String>),
    #[error("Expected internal status before Path-B activation, got {0:?}")]
    NotInternal(DeploymentStatus),
    #[error("Enforcement flip requires active deployment, got {0:?}")]
    NotActive(DeploymentStatus),
    #[error("Runtime error: {0}")]
    Runtime(String),
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct EvidenceBundle {
    pub shadow_mode_report_id: Option<String>,
    pub sla_commitment_id: Option<String>,
    pub public_artifact_manifest_version: Option<String>,
    pub label_policy_version: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PathBDecision {
    pub approved: bool,
    pub reason: String,
    pub reversible: bool,
    pub changed: bool,
    pub target_status: Option<DeploymentStatus>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AuditEvent {
    pub event_ts: String,
    pub steward_id: String,
    pub from_status: DeploymentStatus,
    pub to_status: DeploymentStatus,
    pub reason: String,
}

pub trait DeploymentSource {
    fn get_deployment(&self, deployment_id: &str) -> Result<(DeploymentStatus, String), PathBError>;
    fn update_deployment(&mut self, deployment_id: &str, status: DeploymentStatus, updated_ts: &str, commitments_json: &str) -> Result<(), PathBError>;
    fn update_deployment_full(&mut self, deployment_id: &str, status: DeploymentStatus, domain_scope: &str, updated_ts: &str, commitments_json: &str) -> Result<(), PathBError>;
}

pub fn transition_deployment_status<T: DeploymentSource>(
    source: &mut T,
    deployment_id: &str,
    to_status: DeploymentStatus,
    steward_id: &str,
    reason: &str,
    event_ts: Option<String>,
) -> Result<PathBDecision, PathBError> {
    if steward_id.trim().is_empty() {
        return Err(PathBError::StewardRequired);
    }

    let resolved_ts = event_ts.unwrap_or_else(|| Utc::now().to_rfc3339_opts(chrono::SecondsFormat::Millis, true));
    let (from_status, key_commitments_json) = source.get_deployment(deployment_id)?;

    if !is_allowed_transition(&from_status, &to_status) {
        return Err(PathBError::InvalidTransition { from: from_status, to: to_status.clone() });
    }

    let mut commitments: HashMap<String, serde_json::Value> = if key_commitments_json.is_empty() {
        HashMap::new()
    } else {
        serde_json::from_str(&key_commitments_json).map_err(|e| PathBError::Runtime(e.to_string()))?
    };

    record_audit_event(&mut commitments, &resolved_ts, steward_id, &from_status, &to_status, reason)?;

    source.update_deployment(deployment_id, to_status.clone(), &resolved_ts, &serde_json::to_string(&commitments).unwrap())?;

    Ok(PathBDecision {
        approved: true,
        reason: "transition applied".to_string(),
        reversible: to_status != DeploymentStatus::Revoked,
        changed: true,
        target_status: Some(to_status),
    })
}

pub fn transition_to_active_path_b<T: DeploymentSource>(
    source: &mut T,
    deployment_id: &str,
    steward_id: &str,
    prior_gates: &HashMap<String, bool>,
    evidence_bundle: &EvidenceBundle,
    domain_scope_versioned: &str,
    dry_run: bool,
    event_ts: Option<String>,
) -> Result<PathBDecision, PathBError> {
    require_prior_gates(prior_gates)?;
    if !domain_scope_versioned.contains("@v") {
        return Err(PathBError::InvalidScope);
    }

    let missing = missing_evidence(evidence_bundle);
    if !missing.is_empty() {
        return Ok(PathBDecision {
            approved: false,
            reason: format!("missing evidence: {:?}", missing),
            reversible: true,
            changed: false,
            target_status: None,
        });
    }

    let (from_status, key_commitments_json) = source.get_deployment(deployment_id)?;
    if from_status != DeploymentStatus::Internal {
        return Err(PathBError::NotInternal(from_status));
    }

    if dry_run {
        return Ok(PathBDecision {
            approved: true,
            reason: "dry-run passed: activation and rollback path available".to_string(),
            reversible: true,
            changed: false,
            target_status: Some(DeploymentStatus::Active),
        });
    }

    let resolved_ts = event_ts.unwrap_or_else(|| Utc::now().to_rfc3339_opts(chrono::SecondsFormat::Millis, true));
    let mut commitments: HashMap<String, serde_json::Value> = if key_commitments_json.is_empty() {
        HashMap::new()
    } else {
        serde_json::from_str(&key_commitments_json).map_err(|e| PathBError::Runtime(e.to_string()))?
    };

    commitments.insert("path_b_activation".to_string(), serde_json::json!({
        "domain_scope_versioned": domain_scope_versioned,
        "shadow_mode_report_id": evidence_bundle.shadow_mode_report_id,
        "sla_commitment_id": evidence_bundle.sla_commitment_id,
        "public_artifact_manifest_version": evidence_bundle.public_artifact_manifest_version,
        "label_policy_version": evidence_bundle.label_policy_version,
        "event_ts": resolved_ts,
        "steward_id": steward_id,
    }));

    record_audit_event(&mut commitments, &resolved_ts, steward_id, &DeploymentStatus::Internal, &DeploymentStatus::Active, "path-b activation")?;

    source.update_deployment_full(
        deployment_id,
        DeploymentStatus::Active,
        domain_scope_versioned,
        &resolved_ts,
        &serde_json::to_string(&commitments).unwrap()
    )?;

    Ok(PathBDecision {
        approved: true,
        reason: "path-b activation applied".to_string(),
        reversible: true,
        changed: true,
        target_status: Some(DeploymentStatus::Active),
    })
}

pub fn enable_enforcement_flip<T: DeploymentSource>(
    source: &mut T,
    deployment_id: &str,
    steward_id: &str,
    prior_gates: &HashMap<String, bool>,
    evidence_bundle: &EvidenceBundle,
    sla_commitment_signed: bool,
    shadow_report_passed: bool,
    dry_run: bool,
    event_ts: Option<String>,
) -> Result<PathBDecision, PathBError> {
    require_prior_gates(prior_gates)?;
    let missing = missing_evidence(evidence_bundle);
    if !missing.is_empty() {
        return Ok(PathBDecision {
            approved: false,
            reason: format!("missing evidence: {:?}", missing),
            reversible: true,
            changed: false,
            target_status: None,
        });
    }

    if !sla_commitment_signed {
        return Ok(PathBDecision {
            approved: false,
            reason: "SLA commitment not signed".to_string(),
            reversible: true,
            changed: false,
            target_status: None,
        });
    }

    if !shadow_report_passed {
        return Ok(PathBDecision {
            approved: false,
            reason: "shadow-mode report not approved".to_string(),
            reversible: true,
            changed: false,
            target_status: None,
        });
    }

    let (status, key_commitments_json) = source.get_deployment(deployment_id)?;
    if status != DeploymentStatus::Active {
        return Err(PathBError::NotActive(status));
    }

    if dry_run {
        return Ok(PathBDecision {
            approved: true,
            reason: "dry-run passed: enforcement can be enabled and reverted".to_string(),
            reversible: true,
            changed: false,
            target_status: None,
        });
    }

    let resolved_ts = event_ts.unwrap_or_else(|| Utc::now().to_rfc3339_opts(chrono::SecondsFormat::Millis, true));
    let mut commitments: HashMap<String, serde_json::Value> = if key_commitments_json.is_empty() {
        HashMap::new()
    } else {
        serde_json::from_str(&key_commitments_json).map_err(|e| PathBError::Runtime(e.to_string()))?
    };

    commitments.insert("enforcement_flip".to_string(), serde_json::json!({
        "enabled": true,
        "event_ts": resolved_ts,
        "steward_id": steward_id,
        "shadow_mode_report_id": evidence_bundle.shadow_mode_report_id,
        "sla_commitment_id": evidence_bundle.sla_commitment_id,
    }));

    record_audit_event(&mut commitments, &resolved_ts, steward_id, &DeploymentStatus::Active, &DeploymentStatus::Active, "enforcement flip enabled")?;

    source.update_deployment(
        deployment_id,
        DeploymentStatus::Active,
        &resolved_ts,
        &serde_json::to_string(&commitments).unwrap()
    )?;

    Ok(PathBDecision {
        approved: true,
        reason: "enforcement enabled".to_string(),
        reversible: true,
        changed: true,
        target_status: None,
    })
}

fn require_prior_gates(prior_gates: &HashMap<String, bool>) -> Result<(), PathBError> {
    let required = ["C0", "C1", "C2", "C3"];
    let missing: Vec<_> = required.iter()
        .filter(|&&gate| !prior_gates.get(gate).copied().unwrap_or(false))
        .map(|&gate| gate.to_string())
        .collect();

    if !missing.is_empty() {
        return Err(PathBError::GatesIncomplete(missing));
    }
    Ok(())
}

fn missing_evidence(bundle: &EvidenceBundle) -> Vec<String> {
    let mut missing = Vec::new();
    if bundle.shadow_mode_report_id.is_none() { missing.push("shadow_mode_report_id".to_string()); }
    if bundle.sla_commitment_id.is_none() { missing.push("sla_commitment_id".to_string()); }
    if bundle.public_artifact_manifest_version.is_none() { missing.push("public_artifact_manifest_version".to_string()); }
    if bundle.label_policy_version.is_none() { missing.push("label_policy_version".to_string()); }
    missing
}

fn is_allowed_transition(from: &DeploymentStatus, to: &DeploymentStatus) -> bool {
    match from {
        DeploymentStatus::Internal => matches!(to, DeploymentStatus::Active | DeploymentStatus::Suspended | DeploymentStatus::Revoked),
        DeploymentStatus::Active => matches!(to, DeploymentStatus::Suspended | DeploymentStatus::Revoked),
        DeploymentStatus::Suspended => matches!(to, DeploymentStatus::Active | DeploymentStatus::Revoked),
        DeploymentStatus::Revoked => false,
    }
}

fn record_audit_event(
    commitments: &mut HashMap<String, serde_json::Value>,
    event_ts: &str,
    steward_id: &str,
    from_status: &DeploymentStatus,
    to_status: &DeploymentStatus,
    reason: &str,
) -> Result<(), PathBError> {
    let trail = commitments.entry("audit_trail".to_string()).or_insert(serde_json::json!([]));
    let trail_arr = trail.as_array_mut().ok_or_else(|| PathBError::Runtime("audit_trail must be a list".to_string()))?;
    
    trail_arr.push(serde_json::json!({
        "event_ts": event_ts,
        "steward_id": steward_id,
        "from_status": from_status,
        "to_status": to_status,
        "reason": reason,
    }));
    Ok(())
}
