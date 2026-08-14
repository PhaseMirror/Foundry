//! # AL-GFT Derivation Engine
//!
//! Schwinger-Keldysh derivation of the Gaussian AL-GFT power spectrum,
//! with cryptographically hashed W1_AXIOM witnesses at each step.
//!
//! This crate provides:
//! - `DerivationStep` trait for witnessable derivation stages
//! - Five built-in steps implementing the full SK derivation
//! - Python bridge for SymPy symbolic manipulation (hybrid JSON pipeline)
//! - `DerivationPipeline` for sequential step execution and ledger emission
//!
//! Zero `sorry`, zero `unsafe`, all hashes are SHA-256.

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

// ============================================================================
// Core Types
// ============================================================================

/// A cryptographically hashed witness for a single derivation step.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DerivationWitness {
    /// Unique step identifier (e.g. "step1_action")
    pub step_id: String,
    /// Human-readable step name
    pub step_name: String,
    /// Symbolic expression tree (JSON from SymPy or Rust symbolic engine)
    pub expression_tree: serde_json::Value,
    /// Assumptions under which the step is valid
    pub assumptions: Vec<String>,
    /// Transformation rules applied to reach this expression
    pub transformation_rules: Vec<String>,
    /// SHA-256 of the canonical expression representation
    pub symbolic_hash: String,
    /// W1_AXIOM signature: hash of step_id + symbolic_hash + assumptions + rules
    pub w1_axiom: String,
    /// Unix timestamp of witness emission
    pub timestamp: u64,
}

/// A multi-level ledger bundling W0 (execution), W1 (derivation), and W2 (physics).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExtendedWitness {
    pub w0_exec_hash: String,
    pub w1_axioms: Vec<String>,
    pub w2_phys_hash: String,
    pub c_total: String,
    pub derivation_steps: Vec<DerivationWitness>,
}

// ============================================================================
// DerivationStep Trait
// ============================================================================

/// A witnessable derivation step. Each implementation represents one stage
/// of the Schwinger-Keldysh derivation and can emit a `DerivationWitness`.
pub trait DerivationStep {
    /// Unique step identifier (e.g. "step1_action")
    fn step_id(&self) -> &'static str;
    /// Human-readable step name
    fn step_name(&self) -> &'static str;
    /// Symbolic expression tree as JSON (cloned for ownership)
    fn expression_tree(&self) -> serde_json::Value;
    /// Assumptions (e.g. "gaussian_field", "slow_roll")
    fn assumptions(&self) -> Vec<String>;
    /// Transformation rules applied (e.g. "complete_square", "fourier_transform")
    fn transformation_rules(&self) -> Vec<String>;
    /// SHA-256 of the canonical symbolic representation
    fn symbolic_hash(&self) -> &str;

    /// Compute the W1_AXIOM signature for this step.
    fn compute_w1_axiom(&self) -> String {
        let mut hasher = Sha256::new();
        hasher.update(self.step_id().as_bytes());
        hasher.update(self.symbolic_hash().as_bytes());
        hasher.update(self.assumptions().join(",").as_bytes());
        hasher.update(self.transformation_rules().join(",").as_bytes());
        format!("W1_AXIOM_{}", hex::encode(hasher.finalize()))
    }

    /// Emit the full `DerivationWitness` for this step.
    fn to_witness(&self) -> DerivationWitness {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();

        DerivationWitness {
            step_id: self.step_id().to_string(),
            step_name: self.step_name().to_string(),
            expression_tree: self.expression_tree(),
            assumptions: self.assumptions(),
            transformation_rules: self.transformation_rules(),
            symbolic_hash: self.symbolic_hash().to_string(),
            w1_axiom: self.compute_w1_axiom(),
            timestamp,
        }
    }
}

// ============================================================================
// Pipeline
// ============================================================================

/// Ordered collection of derivation steps with ledger emission.
pub struct DerivationPipeline {
    pub steps: Vec<Box<dyn DerivationStep>>,
}

impl std::fmt::Debug for DerivationPipeline {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("DerivationPipeline")
            .field("steps", &self.steps.len())
            .finish()
    }
}

impl Default for DerivationPipeline {
    fn default() -> Self {
        Self { steps: Vec::new() }
    }
}

impl DerivationPipeline {
    /// Create an empty pipeline.
    pub fn new() -> Self {
        Self::default()
    }

    /// Add a step to the pipeline.
    pub fn push(mut self, step: Box<dyn DerivationStep>) -> Self {
        self.steps.push(step);
        self
    }

    /// Run all steps and collect witnesses.
    pub fn run(&self) -> Vec<DerivationWitness> {
        self.steps.iter().map(|step| step.to_witness()).collect()
    }

    /// Compute the composite C_TOTAL hash over all W1_AXIOM signatures.
    pub fn composite_hash(&self, witnesses: &[DerivationWitness]) -> String {
        let mut hasher = Sha256::new();
        for w in witnesses {
            hasher.update(w.w1_axiom.as_bytes());
        }
        format!("C_TOTAL_{}", hex::encode(hasher.finalize()))
    }

    /// Emit a full `ExtendedWitness` ledger.
    pub fn emit_extended_witness(
        &self,
        witnesses: &[DerivationWitness],
        w0_exec_hash: String,
        w2_phys_hash: String,
    ) -> ExtendedWitness {
        let c_total = self.composite_hash(witnesses);
        let w1_axioms = witnesses.iter().map(|w| w.w1_axiom.clone()).collect();

        ExtendedWitness {
            w0_exec_hash,
            w1_axioms,
            w2_phys_hash,
            c_total,
            derivation_steps: witnesses.to_vec(),
        }
    }
}

// ============================================================================
// Helper: canonical JSON hash
// ============================================================================

/// Compute a deterministic SHA-256 hash of a JSON value by sorting keys.
pub fn canonical_json_hash(value: &serde_json::Value) -> String {
    let canonical = serde_json::to_string(value).unwrap_or_default();
    hex::encode(Sha256::digest(canonical.as_bytes()))
}

// ============================================================================
// Re-export modules
// ============================================================================

pub mod steps;
pub mod python_bridge;

// ============================================================================
// Tests
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_action_specification_witness() {
        let step = steps::ActionSpecification::new();
        let witness = step.to_witness();
        assert_eq!(witness.step_id, "step1_action");
        assert!(witness.w1_axiom.starts_with("W1_AXIOM_"));
        assert_eq!(witness.assumptions.len(), 3);
        assert_eq!(witness.transformation_rules.len(), 2);
        assert!(witness.symbolic_hash.len() == 64);
    }

    #[test]
    fn test_pipeline_composite_hash() {
        let pipeline = DerivationPipeline::new()
            .push(Box::new(steps::ActionSpecification::new()))
            .push(Box::new(steps::InfluenceFunctional::new()))
            .push(Box::new(steps::LangevinEquation::new()))
            .push(Box::new(steps::PowerSpectrum::new()))
            .push(Box::new(steps::NullTest::new()));

        let witnesses = pipeline.run();
        assert_eq!(witnesses.len(), 5);

        let c_total = pipeline.composite_hash(&witnesses);
        assert!(c_total.starts_with("C_TOTAL_"));
        assert_eq!(c_total.len(), 8 + 64);
    }

    #[test]
    fn test_canonical_json_hash_deterministic() {
        let value = serde_json::json!({"b": 2, "a": 1});
        let h1 = canonical_json_hash(&value);
        let h2 = canonical_json_hash(&value);
        assert_eq!(h1, h2);
        assert_eq!(h1.len(), 64);
    }

    #[test]
    fn test_each_step_has_unique_w1_axiom() {
        let steps: Vec<Box<dyn DerivationStep>> = vec![
            Box::new(steps::ActionSpecification::new()),
            Box::new(steps::InfluenceFunctional::new()),
            Box::new(steps::LangevinEquation::new()),
            Box::new(steps::PowerSpectrum::new()),
            Box::new(steps::NullTest::new()),
        ];

        let axioms: Vec<String> = steps.iter().map(|s| s.compute_w1_axiom()).collect();
        let unique: std::collections::HashSet<_> = axioms.iter().collect();
        assert_eq!(unique.len(), 5, "each step must emit a distinct W1_AXIOM");
    }
}
