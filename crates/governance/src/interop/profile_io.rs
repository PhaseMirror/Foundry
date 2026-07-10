use crate::interop::category_model::{DCGF_CONSTRAINT_IDS, StatusLevel, status_join};
use crate::interop::governance_profile::{GovernanceProfile, ProfileObligation};
use crate::interop::obligation_mapping::MappingRegistry;
use crate::interop::policy_functor::{PolicyFunctor, TranslationResult};
use serde_json;
use std::collections::HashMap;

/// S-06: Profile Import/Export — round-trip pipeline with overlay management.

pub fn import_profile(
    data: &str,
    functor: &PolicyFunctor,
) -> Result<(GovernanceProfile, TranslationResult), String> {
    let profile: GovernanceProfile = serde_json::from_str(data)
        .map_err(|e| format!("Invalid profile JSON: {}", e))?;
    
    let (ok, errors) = profile.validate();
    if !ok {
        return Err(format!("Invalid profile: {}", errors.join("; ")));
    }
    
    let result = functor.translate_profile(&profile);
    Ok((profile, result))
}

pub fn export_profile(
    dcgf_state: &HashMap<String, StatusLevel>,
    framework: &str,
    registry: &MappingRegistry,
) -> GovernanceProfile {
    let mut obligations = Vec::new();
    for &cid in DCGF_CONSTRAINT_IDS {
        let status = dcgf_state.get(cid).cloned().unwrap_or(StatusLevel::Ok);
        let fw_mappings = registry.lookup_by_dcgf(cid);
        let fw_mapping = fw_mappings.iter().find(|m| m.framework == framework);
        
        if let Some(m) = fw_mapping {
            obligations.push(ProfileObligation::new(
                &m.external_id,
                if m.label.is_empty() { &m.external_id } else { &m.label },
                status,
                framework,
                Some(cid),
            ));
        }
    }
    
    GovernanceProfile::new(
        &format!("{}-export", framework),
        framework,
        "exported",
        &format!("{} exported profile", framework),
        obligations,
    )
}

pub struct ProfileOverlayManager {
    overlays: HashMap<String, GovernanceProfile>,
    translated: HashMap<String, TranslationResult>,
}

impl ProfileOverlayManager {
    pub fn new() -> Self {
        Self {
            overlays: HashMap::new(),
            translated: HashMap::new(),
        }
    }

    pub fn add_overlay(
        &mut self,
        profile: GovernanceProfile,
        functor: &PolicyFunctor,
    ) -> HashMap<String, StatusLevel> {
        let result = functor.translate_profile(&profile);
        self.overlays.insert(profile.profile_id.clone(), profile.clone());
        self.translated.insert(profile.profile_id, result);
        self.merged_state()
    }

    pub fn remove_overlay(&mut self, profile_id: &str) {
        self.overlays.remove(profile_id);
        self.translated.remove(profile_id);
    }

    pub fn active_overlays(&self) -> Vec<String> {
        self.overlays.keys().cloned().collect()
    }

    pub fn merged_state(&self) -> HashMap<String, StatusLevel> {
        let mut merged = HashMap::new();
        for &cid in DCGF_CONSTRAINT_IDS {
            merged.insert(cid.to_string(), StatusLevel::Ok);
        }
        for result in self.translated.values() {
            for (cid, &status) in &result.merged_constraints {
                let current = merged.get(cid).cloned().unwrap_or(StatusLevel::Ok);
                merged.insert(cid.clone(), status_join(current, status));
            }
        }
        merged
    }

    pub fn merged_status(&self, dcgf_id: &str) -> StatusLevel {
        self.merged_state().get(dcgf_id).cloned().unwrap_or(StatusLevel::Ok)
    }

    pub fn verify_non_relaxation(
        &self,
        baseline: &HashMap<String, StatusLevel>,
    ) -> (bool, Vec<String>) {
        let mut violations = Vec::new();
        let merged = self.merged_state();
        for &cid in DCGF_CONSTRAINT_IDS {
            let base = baseline.get(cid).cloned().unwrap_or(StatusLevel::Ok);
            let cur = merged.get(cid).cloned().unwrap_or(StatusLevel::Ok);
            if cur < base {
                violations.push(format!(
                    "{}: overlay relaxes from {:?} to {:?}",
                    cid, base, cur
                ));
            }
        }
        (violations.is_empty(), violations)
    }
}

pub fn verify_round_trip(
    profile: &GovernanceProfile,
    functor: &PolicyFunctor,
    registry: &MappingRegistry,
) -> (bool, Vec<String>) {
    let mut errors = Vec::new();
    // import
    let r1 = functor.translate_profile(profile);
    // export (reverse-map)
    let exported = export_profile(&r1.merged_constraints, &profile.framework, registry);
    // re-import
    let r2 = functor.translate_profile(&exported);

    for &cid in DCGF_CONSTRAINT_IDS {
        let s1 = r1.merged_constraints.get(cid).cloned().unwrap_or(StatusLevel::Ok);
        let s2 = r2.merged_constraints.get(cid).cloned().unwrap_or(StatusLevel::Ok);
        if s1 != s2 {
            errors.push(format!("{}: original={:?} re-imported={:?}", cid, s1, s2));
        }
    }

    (errors.is_empty(), errors)
}
