use std::collections::HashMap;

/// Regime Detection and Transition Invariance

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum BehavioralRegime {
    Stable,
    Artifact,
}

#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub struct Prompt(pub String);

#[derive(Debug, Clone, PartialEq)]
pub struct Output {
    pub text: String,
    pub embedding: Vec<f64>, // The high-dimensional vector from Sedona Spine
}

impl From<String> for Output {
    fn from(text: String) -> Self {
        Output {
            text,
            embedding: vec![],
        }
    }
}

impl<'a> From<&'a str> for Output {
    fn from(text: &'a str) -> Self {
        Output {
            text: text.to_string(),
            embedding: vec![],
        }
    }
}

impl Output {
    pub fn new(text: &str, embedding: Vec<f64>) -> Self {
        Self {
            text: text.to_string(),
            embedding,
        }
    }

    /// Computes True Semantic Vector Divergence (Cosine Distance)
    /// Distance bounds: 0.0 (identical) to 2.0 (opposite)
    pub fn semantic_distance(&self, other: &Output) -> f64 {
        if self.embedding.is_empty() || other.embedding.is_empty() {
            return 1.0; // Fallback distance
        }

        let dot_product: f64 = self
            .embedding
            .iter()
            .zip(other.embedding.iter())
            .map(|(a, b)| a * b)
            .sum();

        let norm_a: f64 = self.embedding.iter().map(|a| a * a).sum::<f64>().sqrt();
        let norm_b: f64 = other.embedding.iter().map(|b| b * b).sum::<f64>().sqrt();

        if norm_a == 0.0 || norm_b == 0.0 {
            return 1.0;
        }

        let similarity = dot_product / (norm_a * norm_b);
        // Cosine distance = 1.0 - Cosine Similarity
        1.0 - similarity
    }
}

pub struct TopologySpace {
    pub mappings: HashMap<Prompt, Output>,
}

impl TopologySpace {
    pub fn new() -> Self {
        Self {
            mappings: HashMap::new(),
        }
    }

    pub fn insert_mapping(&mut self, prompt: Prompt, output: Output) {
        self.mappings.insert(prompt, output);
    }
}

#[derive(Debug, Clone)]
pub struct Perturbation {
    pub structural_change: bool,
    pub isomorphic_change: bool,
    pub original_prompt: Prompt,
    pub perturbed_prompt: Prompt,
}

impl Perturbation {
    pub fn generate_structural_mutation(prompt: &Prompt) -> Self {
        Perturbation {
            structural_change: true,
            isomorphic_change: false,
            original_prompt: prompt.clone(),
            perturbed_prompt: Prompt(format!("{} [struct_mutated]", prompt.0)),
        }
    }

    pub fn generate_isomorphic_mutation(prompt: &Prompt) -> Self {
        Perturbation {
            structural_change: false,
            isomorphic_change: true,
            original_prompt: prompt.clone(),
            perturbed_prompt: Prompt(format!("{} [isomorphic_mutated]", prompt.0)),
        }
    }
}

pub struct CandidatePartition {
    pub name: String,
    pub topology: TopologySpace,
    pub epsilon: f64,
}

impl CandidatePartition {
    pub fn new(name: &str, epsilon: f64) -> Self {
        Self {
            name: name.to_string(),
            topology: TopologySpace::new(),
            epsilon,
        }
    }

    pub fn evaluate_perturbation(
        &self,
        perturbation: &Perturbation,
        perturbed_output: &Output,
    ) -> BehavioralRegime {
        let original_output = self.topology.mappings.get(&perturbation.original_prompt);

        match original_output {
            Some(expected) => {
                let drift_exceeds_threshold =
                    expected.semantic_distance(perturbed_output) > self.epsilon;

                if perturbation.structural_change
                    && !perturbation.isomorphic_change
                    && drift_exceeds_threshold
                {
                    BehavioralRegime::Artifact
                } else {
                    BehavioralRegime::Stable
                }
            }
            None => BehavioralRegime::Stable,
        }
    }
}

#[cfg(kani)]
mod verification {
    use super::*;
    use kani;

    fn any_short_string() -> String {
        let bytes: [u8; 4] = kani::any();
        String::from_utf8(bytes.to_vec()).unwrap_or_else(|_| String::new())
    }

    #[kani::proof]
    #[kani::unwind(5)] // Limit loop unrolling for the vector zip/sum loops
    fn verify_hardened_perturbation_stability() {
        let structural_change: bool = kani::any();
        let isomorphic_change: bool = kani::any();
        let epsilon: f64 = 0.5;

        let mut partition = CandidatePartition::new("hardened_behavior", epsilon);

        let orig_prompt_str = any_short_string();
        let expected_out_str = any_short_string();

        let orig_prompt = Prompt(orig_prompt_str.clone());

        // Mock arbitrary 2D vectors for embedding space verification
        let v1_x: f64 = kani::any();
        let v1_y: f64 = kani::any();
        let expected_out = Output::new(&expected_out_str, vec![v1_x, v1_y]);

        partition
            .topology
            .insert_mapping(orig_prompt.clone(), expected_out.clone());

        let perturbation = Perturbation {
            structural_change,
            isomorphic_change,
            original_prompt: orig_prompt,
            perturbed_prompt: Prompt(any_short_string()),
        };

        let v2_x: f64 = kani::any();
        let v2_y: f64 = kani::any();
        let test_output = Output::new(&any_short_string(), vec![v2_x, v2_y]);

        let regime = partition.evaluate_perturbation(&perturbation, &test_output);
        let distance = expected_out.semantic_distance(&test_output);

        if distance <= epsilon {
            assert_eq!(regime, BehavioralRegime::Stable);
        }

        if structural_change && !isomorphic_change && distance > epsilon {
            assert_eq!(regime, BehavioralRegime::Artifact);
        }
    }

    #[kani::proof]
    #[kani::unwind(5)]
    fn verify_structural_isomorphic_stability() {
        // Fixed case: structural change and isomorphic change both true
        let structural_change: bool = true;
        let isomorphic_change: bool = true;
        let epsilon: f64 = 0.5;

        let mut partition = CandidatePartition::new("stable_behavior", epsilon);

        let orig_prompt = Prompt("origin".to_string());
        let expected_out = Output::new("expected", vec![0.1, 0.2]);
        partition
            .topology
            .insert_mapping(orig_prompt.clone(), expected_out.clone());

        let perturbation = Perturbation {
            structural_change,
            isomorphic_change,
            original_prompt: orig_prompt,
            perturbed_prompt: Prompt("perturbed".to_string()),
        };

        let test_output = Output::new("test", vec![0.3, 0.4]);
        let regime = partition.evaluate_perturbation(&perturbation, &test_output);
        // Regardless of distance, should be Stable because isomorphic_change negates artifact condition
        assert_eq!(regime, BehavioralRegime::Stable);
    }
}
