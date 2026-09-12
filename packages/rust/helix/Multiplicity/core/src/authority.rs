use std::collections::HashSet;

#[derive(Debug, PartialEq, Eq)]
pub enum AuthorityLevel {
    Custodian,
    Policy,
    Advisory,
}

pub struct JurisdictionalGuard;

impl JurisdictionalGuard {
    pub fn verify(authority: &str) -> bool {
        let mut mapping = HashSet::new();
        mapping.extend([
            "CUSTODIAN_CA_FED",
            "POLICY_CA_FED",
            "CUSTODIAN_CA_DEFENCE",
            "POLICY_CA_DEFENCE",
            "CUSTODIAN_CA_PRIVACY",
            "POLICY_CA_PRIVACY",
            "CUSTODIAN_QC",
            "POLICY_QC",
            "CUSTODIAN_INDIGENOUS",
            "CUSTODIAN_ITAR",
            "CUSTODIAN",
            "POLICY",
            "ADVISORY",
            "FEDERAL_AUDITOR",
            "SYSADMIN",
        ]);
        mapping.contains(authority)
    }
}

pub fn classify_authority(authority: &str) -> AuthorityLevel {
    if authority.starts_with("CUSTODIAN")
        || authority == "FEDERAL_AUDITOR"
        || authority == "SYSADMIN"
    {
        AuthorityLevel::Custodian
    } else if authority.starts_with("POLICY") {
        AuthorityLevel::Policy
    } else {
        AuthorityLevel::Advisory
    }
}

pub fn ratify_velocity(
    model_recommended_velocity: &str,
    authority: &str,
    jurisdiction: Option<&str>,
) -> String {
    let level = classify_authority(authority);

    if jurisdiction == Some("CA-QC") && authority.starts_with("CUSTODIAN") {
        return model_recommended_velocity.to_string();
    }

    match level {
        AuthorityLevel::Custodian => model_recommended_velocity.to_string(),
        AuthorityLevel::Policy => {
            if model_recommended_velocity == "STOP" {
                "PAUSE".to_string()
            } else {
                model_recommended_velocity.to_string()
            }
        }
        AuthorityLevel::Advisory => "PAUSE".to_string(),
    }
}
