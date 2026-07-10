use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use crate::mfl::{
    classify_lambda_band, clamp_mode, derive_allowed_set, parse_blocked_set,
    required_band_brakes,
};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ShadowLogEvent {
    pub requested_action: Option<String>,
    pub mode: String,
    pub lambda_m_band: String,
    pub allowed_action_set: Vec<String>,
    pub action_blocked: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct GovernanceContext {
    pub model_version: String,
    pub mode: String,
    pub lambda_m_band: String,
    pub b_mode: Option<String>,
    pub b_action: HashSet<String>,
    pub b_feature: HashSet<String>,
    pub a_allowed: HashSet<String>,
    pub f_allowed: HashSet<String>,
    pub certificate_id: Option<String>,
    pub signal_id: Option<String>,
    pub shadow_event: Option<ShadowLogEvent>,
}

pub struct LatestCertificate {
    pub certificate_id: String,
    pub lambda_m: f64,
}

pub struct LatestSignal {
    pub signal_id: String,
    pub b_mode: Option<String>,
    pub b_action_json: Option<String>,
    pub b_feature_json: Option<String>,
}

pub trait GovernanceDataSource {
    fn get_model_mode(&self, model_version: &str) -> Result<String, String>;
    fn fetch_latest_certificate(&self, view_ts: &str, model_version: &str) -> Option<LatestCertificate>;
    fn fetch_latest_signal(&self, view_ts: &str, model_version: &str) -> Option<LatestSignal>;
}

pub fn get_governance_context<T: GovernanceDataSource>(
    source: &T,
    view_ts: &str,
    model_version: &str,
    baseline_actions: &[String],
    baseline_features: &[String],
    rights_material: bool,
    domain_matches: bool,
    requested_action: Option<String>,
    amber_blocked_actions: Option<&[String]>,
) -> Result<GovernanceContext, String> {
    let current_mode = source.get_model_mode(model_version)?;

    let cert = source.fetch_latest_certificate(view_ts, model_version);
    let sig = source.fetch_latest_signal(view_ts, model_version);

    let certificate_id = cert.as_ref().map(|c| c.certificate_id.clone());
    let lambda_m = cert.as_ref().map(|c| c.lambda_m).unwrap_or(0.0);
    let lambda_m_band = classify_lambda_band(lambda_m, 0.33, 0.66)?;

    let signal_id = sig.as_ref().map(|s| s.signal_id.clone());
    let signal_b_mode = sig.as_ref().and_then(|s| s.b_mode.clone());
    let signal_b_action = parse_blocked_set(sig.as_ref().and_then(|s| s.b_action_json.as_deref()))?;
    let signal_b_feature = parse_blocked_set(sig.as_ref().and_then(|s| s.b_feature_json.as_deref()))?;

    let (band_b_mode, band_b_actions) = required_band_brakes(
        &lambda_m_band,
        rights_material,
        domain_matches,
        amber_blocked_actions,
    )?;

    let effective_b_mode = band_b_mode.or(signal_b_mode);
    let effective_b_action: HashSet<_> = signal_b_action.union(&band_b_actions).cloned().collect();
    let effective_b_feature = signal_b_feature;

    let effective_mode = clamp_mode(&current_mode, effective_b_mode.as_deref())?;
    let a_allowed = derive_allowed_set(baseline_actions, &effective_b_action);
    let f_allowed = derive_allowed_set(baseline_features, &effective_b_feature);

    let mut shadow_event = None;
    if let Some(ref action) = requested_action {
        let mut allowed_sorted: Vec<_> = a_allowed.iter().cloned().collect();
        allowed_sorted.sort();
        shadow_event = Some(ShadowLogEvent {
            requested_action: Some(action.clone()),
            mode: effective_mode.clone(),
            lambda_m_band: lambda_m_band.clone(),
            allowed_action_set: allowed_sorted,
            action_blocked: !a_allowed.contains(action),
        });
    }

    Ok(GovernanceContext {
        model_version: model_version.to_string(),
        mode: effective_mode,
        lambda_m_band,
        b_mode: effective_b_mode,
        b_action: effective_b_action,
        b_feature: effective_b_feature,
        a_allowed,
        f_allowed,
        certificate_id,
        signal_id,
        shadow_event,
    })
}
