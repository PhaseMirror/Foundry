use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum PrimeCategory {
    Exploration,
    Structure,
    Simulation,
    Stabilization,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PrimeDefinition {
    pub id: String,
    pub symbol: String,
    pub label: String,
    pub description: String,
    pub category: PrimeCategory,
}

pub fn default_primes() -> Vec<PrimeDefinition> {
    vec![
        PrimeDefinition {
            id: "reframe".to_string(),
            symbol: "p1".to_string(),
            label: "Reframe".to_string(),
            description: "Shift the problem into a new perspective or representational frame.".to_string(),
            category: PrimeCategory::Exploration,
        },
        PrimeDefinition {
            id: "invert".to_string(),
            symbol: "p2".to_string(),
            label: "Invert".to_string(),
            description: "Consider the opposite, dual, or negation of the current construct.".to_string(),
            category: PrimeCategory::Exploration,
        },
        PrimeDefinition {
            id: "factorize".to_string(),
            symbol: "p3".to_string(),
            label: "Factorize".to_string(),
            description: "Decompose a complex object into simpler, interacting parts.".to_string(),
            category: PrimeCategory::Structure,
        },
        PrimeDefinition {
            id: "mirror".to_string(),
            symbol: "p4".to_string(),
            label: "Mirror".to_string(),
            description: "Create a structural analogue in another domain or representation.".to_string(),
            category: PrimeCategory::Exploration,
        },
        PrimeDefinition {
            id: "simulate".to_string(),
            symbol: "p5".to_string(),
            label: "Simulate".to_string(),
            description: "Run a mental or computational what-if scenario.".to_string(),
            category: PrimeCategory::Simulation,
        },
        PrimeDefinition {
            id: "compress".to_string(),
            symbol: "p6".to_string(),
            label: "Compress".to_string(),
            description: "Remove redundancy and express the pattern more succinctly.".to_string(),
            category: PrimeCategory::Structure,
        },
        PrimeDefinition {
            id: "generalize".to_string(),
            symbol: "p7".to_string(),
            label: "Generalize".to_string(),
            description: "Lift a specific result into a broader rule or transferable pattern.".to_string(),
            category: PrimeCategory::Structure,
        },
        PrimeDefinition {
            id: "perturb".to_string(),
            symbol: "p8".to_string(),
            label: "Perturb".to_string(),
            description: "Introduce controlled variation to test sensitivity or discover new paths.".to_string(),
            category: PrimeCategory::Exploration,
        },
    ]
}

pub fn optional_primes() -> Vec<PrimeDefinition> {
    vec![
        PrimeDefinition {
            id: "localize".to_string(),
            symbol: "p9".to_string(),
            label: "Localize".to_string(),
            description: "Drop to a concrete case, example, or boundary condition.".to_string(),
            category: PrimeCategory::Simulation,
        },
        PrimeDefinition {
            id: "stabilize".to_string(),
            symbol: "p10".to_string(),
            label: "Stabilize".to_string(),
            description: "Increase rigor, structure, or coherence when novelty outruns clarity.".to_string(),
            category: PrimeCategory::Stabilization,
        },
    ]
}

pub fn all_primes() -> Vec<PrimeDefinition> {
    let mut primes = default_primes();
    primes.extend(optional_primes());
    primes
}

pub fn is_prime_id(id: &str) -> bool {
    all_primes().iter().any(|p| p.id == id)
}

pub fn get_prime_definition(id: &str) -> Result<PrimeDefinition, String> {
    all_primes()
        .into_iter()
        .find(|p| p.id == id)
        .ok_or_else(|| format!("Unknown prime id: {}", id))
}

pub fn cohen_kappa(labels_a: &[String], labels_b: &[String]) -> Result<f64, String> {
    if labels_a.is_empty() || labels_b.is_empty() {
        return Err("At least one label is required for each rater.".to_string());
    }
    if labels_a.len() != labels_b.len() {
        return Err("Both raters must label the same number of items.".to_string());
    }

    let total = labels_a.len() as f64;
    let matches = labels_a.iter().zip(labels_b.iter()).filter(|(a, b)| a == b).count() as f64;
    let observed_agreement = matches / total;

    let categories: Vec<String> = all_primes().into_iter().map(|p| p.id).collect();
    let mut expected_agreement = 0.0;

    for category in categories {
        let p_a = labels_a.iter().filter(|&l| *l == category).count() as f64 / total;
        let p_b = labels_b.iter().filter(|&l| *l == category).count() as f64 / total;
        expected_agreement += p_a * p_b;
    }

    if expected_agreement >= 1.0 {
        return Ok(1.0);
    }

    Ok((observed_agreement - expected_agreement) / (1.0 - expected_agreement))
}
