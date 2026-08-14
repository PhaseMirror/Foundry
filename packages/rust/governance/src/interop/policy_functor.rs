use crate::interop::category_model::{DCGF_CONSTRAINT_IDS, StatusLevel, status_join};
use crate::interop::governance_profile::{GovernanceProfile, ProfileObligation};
use crate::interop::obligation_mapping::MappingRegistry;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// S-04: Lax Functor — policy translation with lax preservation.

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct TranslatedObligation {
    pub dcgf_constraint_id: Option<String>,
    pub source_framework: String,
    pub source_id: String,
    pub source_status: StatusLevel,
    pub translated_status: StatusLevel,
    pub confidence: f64,
    pub is_gap: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TranslationResult {
    pub translated_obligations: Vec<TranslatedObligation>,
    pub merged_constraints: HashMap<String, StatusLevel>,
    pub gaps: Vec<TranslatedObligation>,
    pub source_profile_id: String,
}

pub struct PolicyFunctor<'a> {
    registry: &'a MappingRegistry,
}

impl<'a> PolicyFunctor<'a> {
    pub fn new(registry: &'a MappingRegistry) -> Self {
        Self { registry }
    }

    pub fn translate_obligation(&self, ob: &ProfileObligation) -> TranslatedObligation {
        let mapping = self.registry.lookup(&ob.framework, &ob.obligation_id);
        match mapping {
            None => TranslatedObligation {
                dcgf_constraint_id: None,
                source_framework: ob.framework.clone(),
                source_id: ob.obligation_id.clone(),
                source_status: ob.status,
                translated_status: StatusLevel::Violation,
                confidence: 0.0,
                is_gap: true,
            },
            Some(m) => TranslatedObligation {
                dcgf_constraint_id: Some(m.dcgf_constraint_id.clone()),
                source_framework: ob.framework.clone(),
                source_id: ob.obligation_id.clone(),
                source_status: ob.status,
                translated_status: ob.status,
                confidence: m.confidence,
                is_gap: false,
            },
        }
    }

    pub fn translate_profile(&self, profile: &GovernanceProfile) -> TranslationResult {
        let translated: Vec<TranslatedObligation> = profile.obligations.iter()
            .map(|ob| self.translate_obligation(ob))
            .collect();
        
        let gaps: Vec<TranslatedObligation> = translated.iter()
            .filter(|t| t.is_gap)
            .cloned()
            .collect();

        let mut merged = HashMap::new();
        for t in &translated {
            if let Some(cid) = &t.dcgf_constraint_id {
                let current = merged.get(cid).cloned().unwrap_or(StatusLevel::Ok);
                merged.insert(cid.clone(), status_join(current, t.translated_status));
            }
        }

        TranslationResult {
            translated_obligations: translated,
            merged_constraints: merged,
            gaps,
            source_profile_id: profile.profile_id.clone(),
        }
    }

    pub fn compose_translations(&self, results: &[TranslationResult]) -> HashMap<String, StatusLevel> {
        let mut merged = HashMap::new();
        for r in results {
            for (cid, &status) in &r.merged_constraints {
                let current = merged.get(cid).cloned().unwrap_or(StatusLevel::Ok);
                merged.insert(cid.clone(), status_join(current, status));
            }
        }
        merged
    }

    pub fn verify_lax_condition(&self, profiles: &[GovernanceProfile]) -> (bool, Vec<String>) {
        let mut violations = Vec::new();
        let results: Vec<TranslationResult> = profiles.iter()
            .map(|p| self.translate_profile(p))
            .collect();

        for i in 0..results.len() {
            for j in (i + 1)..results.len() {
                let r_i = &results[i];
                let r_j = &results[j];
                let composed_target = self.compose_translations(&[r_i.clone(), r_j.clone()]);

                let mut combined_obs: Vec<ProfileObligation> = Vec::new();
                let mut seen: HashMap<String, StatusLevel> = HashMap::new();
                
                for p in &[&profiles[i], &profiles[j]] {
                    for ob in &p.obligations {
                        let key = &ob.obligation_id;
                        if let Some(&existing_status) = seen.get(key) {
                            seen.insert(key.clone(), status_join(existing_status, ob.status));
                        } else {
                            seen.insert(key.clone(), ob.status);
                            combined_obs.push(ob.clone());
                        }
                    }
                }

                for ob in &mut combined_obs {
                    let joined_status = *seen.get(&ob.obligation_id).unwrap();
                    ob.status = joined_status;
                }

                let source_composed = GovernanceProfile::new(
                    "__lax_check__",
                    "composite",
                    "check",
                    "lax check composite",
                    combined_obs,
                );
                let f_composed = self.translate_profile(&source_composed);

                for &cid in DCGF_CONSTRAINT_IDS {
                    let f_ab = f_composed.merged_constraints.get(cid).cloned().unwrap_or(StatusLevel::Ok);
                    let fa_fb = composed_target.get(cid).cloned().unwrap_or(StatusLevel::Ok);
                    if f_ab > fa_fb {
                        violations.push(format!(
                            "{}: F(a∘b)={:?} > F(a)∘F(b)={:?} for {}×{}",
                            cid, f_ab, fa_fb, profiles[i].profile_id, profiles[j].profile_id
                        ));
                    }
                }
            }
        }

        (violations.is_empty(), violations)
    }
}
