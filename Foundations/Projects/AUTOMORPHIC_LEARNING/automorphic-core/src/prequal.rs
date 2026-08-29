//! Preregistration schema, linter, and pass/fail gates.
//!
//! The preregistration YAML defines the experiment configuration.
//! The linter validates it against the specification.
//! The gates enforce pass/fail criteria.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum PrequalError {
    #[error("missing required field: {field}")]
    MissingField { field: String },
    #[error("invalid value for {field}: {reason}")]
    InvalidValue { field: String, reason: String },
    #[error("gate failed: {gate} = {value} > {threshold}")]
    GateFailed {
        gate: String,
        value: f64,
        threshold: f64,
    },
}

/// Preregistration schema (v0.2.1).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Preregistration {
    pub splits: Splits,
    pub embedding: Embedding,
    pub group: GroupConfig,
    pub masking: MaskingConfig,
    pub unitarization: UnitarizationConfig,
    pub st_proxy: STProxyConfig,
    pub entropy: EntropyConfig,
    pub ace: ACEConfig,
    pub determinism: DeterminismConfig,
    pub gates: GatesConfig,
    pub ablations: AblationsConfig,
    pub numerics: NumericsConfig,
    pub sampling: SamplingConfig,
    pub data: DataConfig,
    pub optimization: OptimizationConfig,
    pub hashing: HashingConfig,
    pub version: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Splits {
    pub prime_train: Vec<u32>,
    pub prime_val: Vec<u32>,
    pub prime_test: Vec<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Embedding {
    pub method: String,
    pub primes: Vec<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GroupConfig {
    pub agl_include_transpose: bool,
    pub agl_generator_policy: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MaskingConfig {
    pub alpha: f64,
    pub beta: f64,
    pub diagonal_policy: String,
    pub normalize_logits: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UnitarizationConfig {
    pub epsilon_rule: String,
    pub paths: Vec<String>,
    pub sinkhorn: SinkhornConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SinkhornConfig {
    pub iters: usize,
    pub tol: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct STProxyConfig {
    pub pass_band: PassBand,
    pub bootstrap_resamples: usize,
    pub law_seed: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PassBand {
    pub w2_median_max: f64,
    pub bca_width_max: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EntropyConfig {
    pub band: [f64; 2],
    pub violation_handler: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ACEConfig {
    pub projection_variant: String,
    pub violation_policy: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeterminismConfig {
    pub cuda_deterministic: bool,
    pub cudnn_deterministic: bool,
    pub tf32_policy: String,
    pub amp_policy: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GatesConfig {
    pub slopeub_max: f64,
    pub non_inferiority_margin: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AblationsConfig {
    pub required: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NumericsConfig {
    pub tolerances: Tolerances,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Tolerances {
    pub projection_feasibility: f64,
    pub permutation_ks: f64,
    pub sinkhorn_positivity: f64,
    pub matrix_exp_rel_error: f64,
    pub cayley_safety_margin: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SamplingConfig {
    pub st_law_seed: u64,
    pub power_target_ci_width: f64,
    pub min_batches_ci: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DataConfig {
    pub tokenization: String,
    pub seeds: HashMap<String, u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OptimizationConfig {
    pub optimizer: String,
    pub lr: f64,
    pub batch_size: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HashingConfig {
    pub enabled: bool,
}

/// Linter result.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LintResult {
    pub passed: bool,
    pub errors: Vec<String>,
    pub warnings: Vec<String>,
}

/// Lint the preregistration schema.
pub fn lint_prereg(prereg: &Preregistration) -> LintResult {
    let mut errors = Vec::new();
    let mut warnings = Vec::new();

    // Check version
    if prereg.version != "v0.2.1" {
        warnings.push(format!("version is {}, expected v0.2.1", prereg.version));
    }

    // Check splits are non-overlapping
    let all_primes: Vec<u32> = prereg
        .splits
        .prime_train
        .iter()
        .chain(prereg.splits.prime_val.iter())
        .chain(prereg.splits.prime_test.iter())
        .copied()
        .collect();
    let mut seen = std::collections::HashSet::new();
    for &p in &all_primes {
        if !seen.insert(p) {
            errors.push(format!("prime {} appears in multiple splits", p));
        }
    }

    // Check embedding primes are valid
    for &p in &prereg.embedding.primes {
        if p < 2 || p % 2 == 0 {
            errors.push(format!("embedding prime {} must be odd and >= 2", p));
        }
    }

    // Check masking parameters
    if prereg.masking.beta <= 0.0 {
        errors.push("masking.beta must be > 0".to_string());
    }
    if prereg.masking.alpha < 0.0 {
        errors.push("masking.alpha must be >= 0".to_string());
    }

    // Check gate thresholds
    if prereg.gates.slopeub_max <= 0.0 {
        errors.push("gates.slopeub_max must be > 0".to_string());
    }

    // Check required ablations
    let required = &[
        "no_mask",
        "cyclic_mask",
        "residue_permute",
        "break_csl",
        "drop_T1",
        "drop_Ug",
        "unitary_swap",
        "no_projection",
    ];
    for abl in required {
        if !prereg.ablations.required.contains(&abl.to_string()) {
            errors.push(format!("missing required ablation: {}", abl));
        }
    }

    // Check tolerances
    if prereg.numerics.tolerances.projection_feasibility <= 0.0 {
        errors.push("projection_feasibility tolerance must be > 0".to_string());
    }

    LintResult {
        passed: errors.is_empty(),
        errors,
        warnings,
    }
}

/// Pass/fail gates configuration.
#[derive(Debug, Clone)]
pub struct PassFailGates {
    pub slopeub_max: f64,
    pub non_inferiority_margin: f64,
    pub w2_median_max: f64,
    pub bca_width_max: f64,
    pub permutation_ks_max: f64,
}

impl Default for PassFailGates {
    fn default() -> Self {
        Self {
            slopeub_max: 50.0,
            non_inferiority_margin: 0.003,
            w2_median_max: 0.03,
            bca_width_max: 0.05,
            permutation_ks_max: 5e-6,
        }
    }
}

/// Evaluate all gates.
pub fn evaluate_gates(gates: &PassFailGates, metrics: &GateMetrics) -> GateResult {
    let mut results = Vec::new();

    results.push(GateEvaluation {
        name: "ST_w2_median".to_string(),
        value: metrics.w2_median,
        threshold: gates.w2_median_max,
        passes: metrics.w2_median <= gates.w2_median_max,
    });

    results.push(GateEvaluation {
        name: "ST_bca_width".to_string(),
        value: metrics.bca_width,
        threshold: gates.bca_width_max,
        passes: metrics.bca_width <= gates.bca_width_max,
    });

    results.push(GateEvaluation {
        name: "SlopeUB".to_string(),
        value: metrics.slopeub,
        threshold: gates.slopeub_max,
        passes: metrics.slopeub <= gates.slopeub_max,
    });

    results.push(GateEvaluation {
        name: "non_inferiority".to_string(),
        value: metrics.accuracy_drop,
        threshold: gates.non_inferiority_margin,
        passes: metrics.accuracy_drop <= gates.non_inferiority_margin,
    });

    results.push(GateEvaluation {
        name: "permutation_ks".to_string(),
        value: metrics.permutation_ks,
        threshold: gates.permutation_ks_max,
        passes: metrics.permutation_ks <= gates.permutation_ks_max,
    });

    let all_pass = results.iter().all(|r| r.passes);

    GateResult {
        all_pass,
        evaluations: results,
    }
}

/// Metrics for gate evaluation.
#[derive(Debug, Clone)]
pub struct GateMetrics {
    pub w2_median: f64,
    pub bca_width: f64,
    pub slopeub: f64,
    pub accuracy_drop: f64,
    pub permutation_ks: f64,
}

/// Result of gate evaluation.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GateResult {
    pub all_pass: bool,
    pub evaluations: Vec<GateEvaluation>,
}

/// Single gate evaluation.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GateEvaluation {
    pub name: String,
    pub value: f64,
    pub threshold: f64,
    pub passes: bool,
}

#[cfg(test)]
mod tests {
    use super::*;

    fn golden_prereg() -> Preregistration {
        Preregistration {
            splits: Splits {
                prime_train: vec![3, 5, 7, 11, 13, 41],
                prime_val: vec![17, 19, 23],
                prime_test: vec![29, 31, 37],
            },
            embedding: Embedding {
                method: "crt".to_string(),
                primes: vec![43, 47],
            },
            group: GroupConfig {
                agl_include_transpose: false,
                agl_generator_policy: "auto".to_string(),
            },
            masking: MaskingConfig {
                alpha: 0.0,
                beta: 20.0,
                diagonal_policy: "allow_self".to_string(),
                normalize_logits: false,
            },
            unitarization: UnitarizationConfig {
                epsilon_rule: "1e-6_row_mean".to_string(),
                paths: vec!["exp".to_string(), "cayley".to_string()],
                sinkhorn: SinkhornConfig {
                    iters: 5,
                    tol: 1e-3,
                },
            },
            st_proxy: STProxyConfig {
                pass_band: PassBand {
                    w2_median_max: 0.03,
                    bca_width_max: 0.05,
                },
                bootstrap_resamples: 1000,
                law_seed: 42,
            },
            entropy: EntropyConfig {
                band: [1.2, 2.6],
                violation_handler: "log_and_penalize".to_string(),
            },
            ace: ACEConfig {
                projection_variant: "A".to_string(),
                violation_policy: "abort".to_string(),
            },
            determinism: DeterminismConfig {
                cuda_deterministic: true,
                cudnn_deterministic: true,
                tf32_policy: "disabled".to_string(),
                amp_policy: "fp32".to_string(),
            },
            gates: GatesConfig {
                slopeub_max: 50.0,
                non_inferiority_margin: 0.003,
            },
            ablations: AblationsConfig {
                required: vec![
                    "no_mask".to_string(),
                    "cyclic_mask".to_string(),
                    "residue_permute".to_string(),
                    "break_csl".to_string(),
                    "drop_T1".to_string(),
                    "drop_Ug".to_string(),
                    "unitary_swap".to_string(),
                    "no_projection".to_string(),
                ],
            },
            numerics: NumericsConfig {
                tolerances: Tolerances {
                    projection_feasibility: 1e-8,
                    permutation_ks: 5e-6,
                    sinkhorn_positivity: 1e-12,
                    matrix_exp_rel_error: 1e-8,
                    cayley_safety_margin: 1e-6,
                },
            },
            sampling: SamplingConfig {
                st_law_seed: 42,
                power_target_ci_width: 0.05,
                min_batches_ci: 1000,
            },
            data: DataConfig {
                tokenization: "default".to_string(),
                seeds: vec![
                    ("train".to_string(), 1),
                    ("val".to_string(), 2),
                    ("test".to_string(), 3),
                ]
                .into_iter()
                .collect(),
            },
            optimization: OptimizationConfig {
                optimizer: "adamw".to_string(),
                lr: 3.0e-4,
                batch_size: 64,
            },
            hashing: HashingConfig { enabled: false },
            version: "v0.2.1".to_string(),
        }
    }

    #[test]
    fn test_golden_prereg_lints() {
        let prereg = golden_prereg();
        let result = lint_prereg(&prereg);
        assert!(result.passed, "errors: {:?}", result.errors);
    }

    #[test]
    fn test_gate_pass() {
        let gates = PassFailGates::default();
        let metrics = GateMetrics {
            w2_median: 0.02,
            bca_width: 0.04,
            slopeub: 10.0,
            accuracy_drop: 0.001,
            permutation_ks: 1e-6,
        };
        let result = evaluate_gates(&gates, &metrics);
        assert!(result.all_pass);
    }

    #[test]
    fn test_gate_fail() {
        let gates = PassFailGates::default();
        let metrics = GateMetrics {
            w2_median: 0.1, // too high
            bca_width: 0.04,
            slopeub: 10.0,
            accuracy_drop: 0.001,
            permutation_ks: 1e-6,
        };
        let result = evaluate_gates(&gates, &metrics);
        assert!(!result.all_pass);
    }
}
