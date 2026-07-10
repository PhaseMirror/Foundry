use std::collections::HashMap;
use serde::{Deserialize, Serialize};

use crate::primes::all_primes;
use crate::logging::{SessionLogEntry, ImpactVector, sequence_to_key};
use crate::scoring::{compute_genius_index, derive_meta_rules, GeniusIndexBreakdown};

pub type SequencePrior = HashMap<String, f64>;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PriorObservation {
    pub entry: SessionLogEntry,
    pub baseline_probability: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateOptions {
    pub learning_rate: Option<f64>,
    pub exploration_rate: Option<f64>,
}

impl Default for UpdateOptions {
    fn default() -> Self {
        UpdateOptions {
            learning_rate: Some(0.5),
            exploration_rate: Some(0.05),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrimeRecommendation {
    pub prime: String,
    pub score: f64,
    pub rationale: String,
}

fn normalize_prior(prior: &SequencePrior) -> SequencePrior {
    let mut total = 0.0;
    for &weight in prior.values() {
        if weight.is_finite() && weight > 0.0 {
            total += weight;
        }
    }

    if total == 0.0 {
        return HashMap::new();
    }

    let mut normalized = HashMap::new();
    for (key, &weight) in prior {
        if weight.is_finite() && weight > 0.0 {
            normalized.insert(key.clone(), weight / total);
        }
    }
    normalized
}

fn boost(scores: &mut HashMap<String, f64>, prime: &str, amount: f64) {
    let entry = scores.entry(prime.to_string()).or_insert(0.0);
    *entry += amount;
}

fn apply_metric_heuristics(scores: &mut HashMap<String, f64>, metrics: Option<&ImpactVector>) -> Vec<String> {
    if let Some(m) = metrics {
        let rules = derive_meta_rules(m);

        if m.novelty >= 0.75 && m.coherence < 0.55 {
            boost(scores, "stabilize", 0.35);
            boost(scores, "factorize", 0.2);
            boost(scores, "perturb", -0.1);
        }

        if m.coherence >= 0.8 && m.novelty < 0.5 {
            boost(scores, "perturb", 0.2);
            boost(scores, "reframe", 0.15);
        }

        if m.transferability < 0.45 {
            boost(scores, "mirror", 0.2);
            boost(scores, "generalize", 0.2);
        }

        rules
    } else {
        Vec::new()
    }
}

pub fn seed_sequence_prior(primes: Option<&[String]>) -> SequencePrior {
    let mut prior = HashMap::new();
    if let Some(p_list) = primes {
        for p in p_list {
            prior.insert(p.clone(), 1.0);
        }
    } else {
        for p in all_primes() {
            prior.insert(p.id, 1.0);
        }
    }
    normalize_prior(&prior)
}

pub fn update_sequence_prior(
    prior: &SequencePrior,
    observations: &[PriorObservation],
    options: Option<&UpdateOptions>,
) -> SequencePrior {
    let opts = options.cloned().unwrap_or_default();
    let learning_rate = opts.learning_rate.unwrap_or(0.5);
    let exploration_rate = opts.exploration_rate.unwrap_or(0.05);

    let mut next: HashMap<String, f64> = prior
        .iter()
        .map(|(k, &v)| (k.clone(), if v > 0.0 { v } else { f64::EPSILON }))
        .collect();

    for obs in observations {
        let key = sequence_to_key(&obs.entry.moves);
        let current = *next.get(&key).unwrap_or(&(exploration_rate / (next.len() as f64 + 1.0).max(1.0)));
        let baseline = obs.baseline_probability.unwrap_or(current);
        let breakdown = compute_genius_index(&obs.entry, baseline, &Default::default());
        next.insert(key, current * (learning_rate * breakdown.score).exp());
    }

    let normalized = normalize_prior(&next);
    let count = normalized.len() as f64;

    if count == 0.0 {
        return HashMap::new();
    }

    let mut final_prior = HashMap::new();
    for (key, value) in normalized {
        final_prior.insert(key, (value * (1.0 - exploration_rate)) + (exploration_rate / count));
    }
    final_prior
}

pub fn recommend_next_primes(
    history: &[String],
    prior: &SequencePrior,
    top_n: usize,
    metrics: Option<&ImpactVector>,
) -> Vec<PrimeRecommendation> {
    let mut scores = HashMap::new();
    for p in all_primes() {
        scores.insert(p.id, 0.0);
    }

    let prefix_length = history.len();

    for (sequence_key, &weight) in prior {
        let sequence: Vec<&str> = sequence_key.split('>').filter(|s| !s.is_empty()).collect();
        
        for prime in &sequence {
            boost(&mut scores, prime, weight / (sequence.len() as f64).max(1.0));
        }

        let matches_prefix = prefix_length == 0 || history.iter().enumerate().all(|(i, p)| {
            i < sequence.len() && sequence[i] == p
        });

        if !matches_prefix {
            continue;
        }

        if sequence.len() > prefix_length {
            let candidate = sequence[prefix_length];
            boost(&mut scores, candidate, weight * 2.0);
        }
    }

    let rules = apply_metric_heuristics(&mut scores, metrics);

    let mut sorted_scores: Vec<(String, f64)> = scores.into_iter().collect();
    sorted_scores.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));

    sorted_scores
        .into_iter()
        .take(top_n)
        .map(|(prime, score)| PrimeRecommendation {
            prime,
            score,
            rationale: rules.first().cloned().unwrap_or_else(|| "Recommended from the current posterior over prime sequences.".to_string()),
        })
        .collect()
}

pub struct PhaseMirrorModel {
    pub sessions: Vec<SessionLogEntry>,
    pub prior: SequencePrior,
}

impl PhaseMirrorModel {
    pub fn new(initial_prior: Option<SequencePrior>) -> Self {
        PhaseMirrorModel {
            sessions: Vec::new(),
            prior: normalize_prior(&initial_prior.unwrap_or_else(|| seed_sequence_prior(None))),
        }
    }

    pub fn ingest(&mut self, entry: SessionLogEntry) -> GeniusIndexBreakdown {
        let key = sequence_to_key(&entry.moves);
        let baseline = *self.prior.get(&key).unwrap_or(&(1.0 / (self.prior.len() as f64).max(1.0)));
        let breakdown = compute_genius_index(&entry, baseline, &Default::default());
        
        let obs = PriorObservation {
            entry: entry.clone(),
            baseline_probability: Some(baseline),
        };
        
        self.sessions.push(entry);
        self.prior = update_sequence_prior(&self.prior, &[obs], None);
        breakdown
    }

    pub fn recommend(
        &self,
        history: Option<&[String]>,
        metrics: Option<&ImpactVector>,
        top_n: usize,
    ) -> Vec<PrimeRecommendation> {
        let hist = history.unwrap_or(&[]);
        recommend_next_primes(hist, &self.prior, top_n, metrics)
    }
}
