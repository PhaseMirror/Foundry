use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SessionContext {
    pub domain: String,
    pub problem: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub goal: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub constraints: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tags: Option<Vec<String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ImpactVector {
    pub novelty: f64,
    pub coherence: f64,
    pub transferability: f64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub external_impact: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ExternalSignals {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub citations: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub adoption: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub revenue: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub peer_rating: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prototype_count: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PrimeMove {
    pub prime: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub context: Option<String>,
    pub timestamp: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SessionLogEntry {
    pub id: String,
    pub context: SessionContext,
    pub moves: Vec<PrimeMove>,
    pub metrics: ImpactVector,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub external_signals: Option<ExternalSignals>,
    pub created_at: String,
}

fn normalize_metric(value: f64, label: &str) -> Result<f64, String> {
    if !value.is_finite() || value < 0.0 || value > 1.0 {
        return Err(format!("{} must be a finite number between 0 and 1.", label));
    }
    Ok(value)
}

pub fn normalize_impact_vector(metrics: &ImpactVector) -> Result<ImpactVector, String> {
    Ok(ImpactVector {
        novelty: normalize_metric(metrics.novelty, "novelty")?,
        coherence: normalize_metric(metrics.coherence, "coherence")?,
        transferability: normalize_metric(metrics.transferability, "transferability")?,
        external_impact: match metrics.external_impact {
            Some(v) => Some(normalize_metric(v, "externalImpact")?),
            None => None,
        },
    })
}

pub fn sequence_to_key(moves: &[PrimeMove]) -> String {
    moves.iter().map(|m| m.prime.as_str()).collect::<Vec<&str>>().join(">")
}

pub fn summarize_trajectory(entry: &SessionLogEntry) -> (String, usize, Vec<String>, f64) {
    let sequence = sequence_to_key(&entry.moves);
    let move_count = entry.moves.len();
    
    let mut unique_primes = Vec::new();
    for m in &entry.moves {
        if !unique_primes.contains(&m.prime) {
            unique_primes.push(m.prime.clone());
        }
    }
    
    let balance = if move_count > 0 {
        unique_primes.len() as f64 / move_count as f64
    } else {
        0.0
    };

    (sequence, move_count, unique_primes, balance)
}
