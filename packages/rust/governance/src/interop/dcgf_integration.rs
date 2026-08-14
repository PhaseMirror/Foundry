use crate::interop::category_model::{DCGF_CONSTRAINT_IDS, StatusLevel};
use crate::interop::compliance_verifier::{ComplianceReport, ComplianceVerifier};
use crate::interop::governance_profile::GovernanceProfile;
use crate::interop::policy_functor::PolicyFunctor;
use std::collections::HashMap;
use std::time::{SystemTime, UNIX_EPOCH};

/// S-07: DCGF Integration — live state binding and continuous monitoring.

pub type ChangeListener = Box<dyn Fn(&str, StatusLevel, StatusLevel) + Send + Sync>;

pub struct DCGFConstraintState {
    state: HashMap<String, StatusLevel>,
    listeners: Vec<ChangeListener>,
}

impl DCGFConstraintState {
    pub fn new() -> Self {
        let mut state = HashMap::new();
        for &cid in DCGF_CONSTRAINT_IDS {
            state.insert(cid.to_string(), StatusLevel::Ok);
        }
        Self {
            state,
            listeners: Vec::new(),
        }
    }

    pub fn get(&self, cid: &str) -> StatusLevel {
        self.state.get(cid).cloned().unwrap_or(StatusLevel::Ok)
    }

    pub fn set(&mut self, cid: &str, level: StatusLevel) {
        let old = self.get(cid);
        if old != level {
            self.state.insert(cid.to_string(), level);
            for listener in &self.listeners {
                listener(cid, old, level);
            }
        }
    }

    pub fn snapshot(&self) -> HashMap<String, StatusLevel> {
        self.state.clone()
    }

    pub fn add_listener(&mut self, listener: ChangeListener) {
        self.listeners.push(listener);
    }

    pub fn bulk_set(&mut self, updates: HashMap<String, StatusLevel>) {
        for (cid, level) in updates {
            self.set(&cid, level);
        }
    }
}

#[derive(Debug, Clone)]
pub struct ComplianceAlert {
    pub profile_id: String,
    pub framework: String,
    pub constraint_id: String,
    pub required_status: StatusLevel,
    pub actual_status: StatusLevel,
    pub timestamp: u64,
}

pub struct ComplianceMonitor<'a> {
    verifier: ComplianceVerifier<'a>,
    profiles: HashMap<String, GovernanceProfile>,
    last_reports: HashMap<String, ComplianceReport>,
    alerts: Vec<ComplianceAlert>,
}

impl<'a> ComplianceMonitor<'a> {
    pub fn new(verifier: ComplianceVerifier<'a>) -> Self {
        Self {
            verifier,
            profiles: HashMap::new(),
            last_reports: HashMap::new(),
            alerts: Vec::new(),
        }
    }

    pub fn register_profile(&mut self, profile: GovernanceProfile, state: &DCGFConstraintState) -> ComplianceReport {
        let report = self.verifier.verify(&profile, &state.snapshot());
        self.last_reports.insert(profile.profile_id.clone(), report.clone());
        self.profiles.insert(profile.profile_id.clone(), profile);
        report
    }

    pub fn unregister_profile(&mut self, profile_id: &str) {
        self.profiles.remove(profile_id);
        self.last_reports.remove(profile_id);
    }

    pub fn check_all(&mut self, state: &DCGFConstraintState) -> HashMap<String, ComplianceReport> {
        let snap = state.snapshot();
        let mut reports = HashMap::new();
        
        // Fix borrow checker: clone profiles to iterate or collect alerts after loop
        let p_list: Vec<_> = self.profiles.values().cloned().collect();
        
        for profile in p_list {
            let report = self.verifier.verify(&profile, &snap);
            self.emit_alerts(&profile, &report);
            self.last_reports.insert(profile.profile_id.clone(), report.clone());
            reports.insert(profile.profile_id, report);
        }
        reports
    }

    fn emit_alerts(&mut self, profile: &GovernanceProfile, report: &ComplianceReport) {
        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();
        for gap in &report.gaps {
            self.alerts.push(ComplianceAlert {
                profile_id: profile.profile_id.clone(),
                framework: profile.framework.clone(),
                constraint_id: gap.dcgf_constraint_id.clone(),
                required_status: gap.required_status,
                actual_status: gap.current_status,
                timestamp: now,
            });
        }
    }

    pub fn get_alerts(&self) -> Vec<ComplianceAlert> {
        self.alerts.clone()
    }

    pub fn clear_alerts(&mut self) {
        self.alerts.clear();
    }
}

pub struct FederationNode {
    pub node_id: String,
    pub profiles: HashMap<String, GovernanceProfile>,
}

impl FederationNode {
    pub fn new(node_id: &str) -> Self {
        Self {
            node_id: node_id.to_string(),
            profiles: HashMap::new(),
        }
    }

    pub fn publish(&mut self, profile: GovernanceProfile) -> serde_json::Value {
        self.profiles.insert(profile.profile_id.clone(), profile.clone());
        serde_json::json!({
            "node_id": self.node_id,
            "profile": profile,
        })
    }

    pub fn receive(&mut self, payload: serde_json::Value) -> Result<GovernanceProfile, String> {
        let profile: GovernanceProfile = serde_json::from_value(payload["profile"].clone())
            .map_err(|e| format!("Invalid profile in payload: {}", e))?;
        self.profiles.insert(profile.profile_id.clone(), profile.clone());
        Ok(profile)
    }
}

pub fn check_profile_compatibility(
    local: &GovernanceProfile,
    remote: &GovernanceProfile,
    functor: &PolicyFunctor,
) -> (bool, Vec<String>) {
    let r_local = functor.translate_profile(local);
    let r_remote = functor.translate_profile(remote);
    let mut issues = Vec::new();
    for &cid in DCGF_CONSTRAINT_IDS {
        let local_s = r_local.merged_constraints.get(cid).cloned().unwrap_or(StatusLevel::Ok);
        let remote_s = r_remote.merged_constraints.get(cid).cloned().unwrap_or(StatusLevel::Ok);
        if remote_s < local_s {
            issues.push(format!("{}: remote ({:?}) < local ({:?})", cid, remote_s, local_s));
        }
    }
    (issues.is_empty(), issues)
}
