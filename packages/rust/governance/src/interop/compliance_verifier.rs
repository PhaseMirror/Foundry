use crate::interop::category_model::{DCGF_CONSTRAINT_IDS, StatusLevel};
use crate::interop::governance_profile::GovernanceProfile;
use crate::interop::policy_functor::PolicyFunctor;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// S-05: Compliance Verifier — gap detection and remediation proposals.

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ComplianceStatus {
    Compliant,
    NonCompliant,
    Partial,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ObligationGap {
    pub dcgf_constraint_id: String,
    pub required_status: StatusLevel,
    pub current_status: StatusLevel,
    pub source_framework: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RemediationAction {
    pub dcgf_constraint_id: String,
    pub current_status: StatusLevel,
    pub required_status: StatusLevel,
    pub description: String,
}

impl RemediationAction {
    pub fn to_json_value(&self) -> serde_json::Value {
        serde_json::json!({
            "action": "elevate",
            "constraint": self.dcgf_constraint_id,
            "from": format!("{:?}", self.current_status),
            "to": format!("{:?}", self.required_status),
            "description": self.description,
        })
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComplianceReport {
    pub status: ComplianceStatus,
    pub profile_id: String,
    pub framework: String,
    pub total_obligations: usize,
    pub met_count: usize,
    pub unmet_count: usize,
    pub gaps: Vec<ObligationGap>,
    pub remediation: Vec<RemediationAction>,
}

pub struct ComplianceVerifier<'a> {
    functor: PolicyFunctor<'a>,
}

impl<'a> ComplianceVerifier<'a> {
    pub fn new(functor: PolicyFunctor<'a>) -> Self {
        Self { functor }
    }

    pub fn verify(
        &self,
        profile: &GovernanceProfile,
        dcgf_state: &HashMap<String, StatusLevel>,
    ) -> ComplianceReport {
        let result = self.functor.translate_profile(profile);
        let mut gaps = Vec::new();

        for (cid, &required) in &result.merged_constraints {
            let current = dcgf_state.get(cid).cloned().unwrap_or(StatusLevel::Ok);
            if current < required {
                gaps.push(ObligationGap {
                    dcgf_constraint_id: cid.clone(),
                    required_status: required,
                    current_status: current,
                    source_framework: profile.framework.clone(),
                });
            }
        }

        let total = result.merged_constraints.len();
        let unmet = gaps.len();
        let met = total - unmet;

        let status = if unmet == 0 {
            ComplianceStatus::Compliant
        } else if met > 0 {
            ComplianceStatus::Partial
        } else {
            ComplianceStatus::NonCompliant
        };

        let remediation = self.generate_remediation(&gaps);

        ComplianceReport {
            status,
            profile_id: profile.profile_id.clone(),
            framework: profile.framework.clone(),
            total_obligations: total,
            met_count: met,
            unmet_count: unmet,
            gaps,
            remediation,
        }
    }

    pub fn check_no_silent_relaxation(
        current_state: &HashMap<String, StatusLevel>,
        proposed_state: &HashMap<String, StatusLevel>,
    ) -> (bool, Vec<String>) {
        let mut violations = Vec::new();
        for &cid in DCGF_CONSTRAINT_IDS {
            let cur = current_state.get(cid).cloned().unwrap_or(StatusLevel::Ok);
            let prop = proposed_state.get(cid).cloned().unwrap_or(StatusLevel::Ok);
            if prop < cur {
                violations.push(format!(
                    "{}: would relax from {:?} to {:?}",
                    cid, cur, prop
                ));
            }
        }
        (violations.is_empty(), violations)
    }

    fn generate_remediation(&self, gaps: &[ObligationGap]) -> Vec<RemediationAction> {
        gaps.iter().map(|g| {
            RemediationAction {
                dcgf_constraint_id: g.dcgf_constraint_id.clone(),
                current_status: g.current_status,
                required_status: g.required_status,
                description: format!(
                    "Elevate {} from {:?} to {:?}",
                    g.dcgf_constraint_id, g.current_status, g.required_status
                ),
            }
        }).collect()
    }
}
