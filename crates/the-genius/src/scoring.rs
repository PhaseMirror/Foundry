use serde::{Deserialize, Serialize};
use crate::logging::{ExternalSignals, ImpactVector, SessionLogEntry, sequence_to_key};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GeniusWeights {
    pub novelty: f64,
    pub coherence: f64,
    pub transferability: f64,
    pub external_impact: f64,
    pub atypicality: f64,
    pub randomness_penalty: f64,
}

impl Default for GeniusWeights {
    fn default() -> Self {
        Self {
            novelty: 0.35,
            coherence: 0.35,
            transferability: 0.2,
            external_impact: 0.1,
            atypicality: 0.15,
            randomness_penalty: 0.2,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GeniusIndexBreakdown {
    pub sequence: String,
    pub impact: f64,
    pub internal_impact: f64,
    pub external_impact: f64,
    pub atypicality: f64,
    pub exploration_penalty: f64,
    pub score: f64,
    pub recommended_actions: Vec<String>,
}

fn clamp01(value: f64) -> f64 {
    value.clamp(0.0, 1.0)
}

fn saturating_score(value: f64, scale: f64) -> f64 {
    1.0 - (-value.max(0.0) / scale).exp()
}

pub fn score_external_signals(signals: Option<&ExternalSignals>) -> f64 {
    if let Some(s) = signals {
        let mut scores = Vec::new();
        if let Some(v) = s.citations { scores.push(saturating_score(v, 5.0)); }
        if let Some(v) = s.adoption { scores.push(saturating_score(v, 20.0)); }
        if let Some(v) = s.revenue { scores.push(saturating_score(v, 10_000.0)); }
        if let Some(v) = s.peer_rating { scores.push(clamp01(v / 5.0)); }
        if let Some(v) = s.prototype_count { scores.push(saturating_score(v, 3.0)); }

        if scores.is_empty() {
            0.0
        } else {
            let sum: f64 = scores.iter().sum();
            sum / scores.len() as f64
        }
    } else {
        0.0
    }
}

pub fn compute_impact_score(
    metrics: &ImpactVector,
    external_signals: Option<&ExternalSignals>,
    weights: &GeniusWeights,
) -> (f64, f64, f64) {
    let internal = clamp01(
        (metrics.novelty * weights.novelty)
            + (metrics.coherence * weights.coherence)
            + (metrics.transferability * weights.transferability),
    );

    let external = clamp01(
        metrics.external_impact.unwrap_or_else(|| score_external_signals(external_signals))
    );

    let impact = clamp01(internal + (external * weights.external_impact));

    (internal, external, impact)
}

pub fn derive_meta_rules(metrics: &ImpactVector) -> Vec<String> {
    let mut rules = Vec::new();

    if metrics.novelty >= 0.75 && metrics.coherence < 0.55 {
        rules.push("Increase `stabilize` and `factorize`; reduce `perturb` until coherence recovers.".to_string());
    }

    if metrics.coherence >= 0.8 && metrics.novelty < 0.5 {
        rules.push("Increase `perturb` or `reframe` to escape local minima and search more broadly.".to_string());
    }

    if metrics.transferability < 0.45 {
        rules.push("Use `mirror` and `generalize` to force a cross-domain explanation or analogy.".to_string());
    }

    if rules.is_empty() {
        rules.push("Maintain the current balance and keep a small exploration rate for rare primes.".to_string());
    }

    rules
}

pub fn compute_genius_index(
    entry: &SessionLogEntry,
    baseline_probability: f64,
    weights: &GeniusWeights,
) -> GeniusIndexBreakdown {
    let (internal, external, impact) = compute_impact_score(
        &entry.metrics,
        entry.external_signals.as_ref(),
        weights,
    );

    let bounded_baseline = baseline_probability.clamp(1e-9, 1.0);
    let atypicality = -bounded_baseline.ln();
    
    let exploration_penalty = (entry.metrics.novelty - entry.metrics.coherence - 0.25).max(0.0) * weights.randomness_penalty;
    
    let score = (impact * (1.0 + (weights.atypicality * atypicality)) - exploration_penalty).max(0.0);

    GeniusIndexBreakdown {
        sequence: sequence_to_key(&entry.moves),
        impact,
        internal_impact: internal,
        external_impact: external,
        atypicality,
        exploration_penalty,
        score,
        recommended_actions: derive_meta_rules(&entry.metrics),
    }
}
