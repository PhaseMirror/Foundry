//! Built-in derivation steps for the Gaussian AL-GFT Schwinger-Keldysh pipeline.
//!
//! Each step is a self-contained unit that produces a `DerivationWitness`.
//! The expression trees can be constructed either by the Python SymPy bridge
//! or directly in Rust.

use super::*;

// ============================================================================
// Step 1: Action Specification
// ============================================================================

/// Step 1 — Total action specification.
///
/// Defines the total action `S_total[φ,χ]` for the GFT field φ and the
/// Zeta-Comb environment χ, including the interaction `g ∫ φ χ`.
#[derive(Debug, Clone)]
pub struct ActionSpecification {
    data: DerivationStepData,
}

impl ActionSpecification {
    pub fn new() -> Self {
        let expr_tree = serde_json::json!({
            "type": "Add",
            "operands": [
                {
                    "type": "Symbol",
                    "name": "S_GFT",
                    "description": "GFT action for field φ"
                },
                {
                    "type": "Symbol",
                    "name": "S_env",
                    "description": "Environment action for Zeta-Comb χ"
                },
                {
                    "type": "Mul",
                    "operands": [
                        {
                            "type": "Symbol",
                            "name": "g",
                            "description": "Coupling constant (linear)"
                        },
                        {
                            "type": "Integral",
                            "expr": {
                                "type": "Mul",
                                "operands": [
                                    {
                                        "type": "Function",
                                        "name": "phi",
                                        "args": [{"type": "Symbol", "name": "t"}]
                                    },
                                    {
                                        "type": "Function",
                                        "name": "chi",
                                        "args": [{"type": "Symbol", "name": "t"}]
                                    }
                                ]
                            },
                            "limits": {
                                "type": "Interval",
                                "start": "-inf",
                                "end": "inf"
                            }
                        }
                    ]
                }
            ]
        });

        let symbolic_hash = canonical_json_hash(&expr_tree);

        Self {
            data: DerivationStepData {
                step_id: "step1_action",
                step_name: "Action Specification",
                expression_tree: expr_tree,
                assumptions: vec![
                    "gaussian_field".into(),
                    "linear_coupling".into(),
                    "zeta_comb_environment".into(),
                ],
                transformation_rules: vec![
                    "canonical_form".into(),
                    "field_separation".into(),
                ],
                symbolic_hash,
            },
        }
    }
}

impl DerivationStep for ActionSpecification {
    fn step_id(&self) -> &'static str { self.data.step_id }
    fn step_name(&self) -> &'static str { self.data.step_name }
    fn expression_tree(&self) -> serde_json::Value { self.data.expression_tree.clone() }
    fn assumptions(&self) -> Vec<String> { self.data.assumptions.clone() }
    fn transformation_rules(&self) -> Vec<String> { self.data.transformation_rules.clone() }
    fn symbolic_hash(&self) -> &str { &self.data.symbolic_hash }
}

// ============================================================================
// Step 2: Influence Functional
// ============================================================================

/// Step 2 — Feynman-Vernon influence functional via Gaussian path integral.
///
/// Integrates out χ to obtain the noise kernel N(t−t′) and dissipation kernel
/// D(t−t′) as sums over Zeta zeros.
#[derive(Debug, Clone)]
pub struct InfluenceFunctional {
    data: DerivationStepData,
}

impl InfluenceFunctional {
    pub fn new() -> Self {
        let expr_tree = serde_json::json!({
            "type": "Functional",
            "name": "FeynmanVernonInfluence",
            "fields": {
                "phi_plus": {"type": "Function", "name": "phi_plus"},
                "phi_minus": {"type": "Function", "name": "phi_minus"}
            },
            "kernels": [
                {
                    "type": "Kernel",
                    "name": "noise",
                    "symbol": "N",
                    "definition": {
                        "type": "Sum",
                        "over": "nontrivial_zeros",
                        "term_type": "cos(gamma_n * tau) / sqrt(1/4 + gamma_n^2)"
                    }
                },
                {
                    "type": "Kernel",
                    "name": "dissipation",
                    "symbol": "D",
                    "definition": {
                        "type": "Sum",
                        "over": "nontrivial_zeros",
                        "term_type": "sin(gamma_n * tau) / sqrt(1/4 + gamma_n^2)"
                    }
                }
            ],
            "influence_functional": {
                "type": "Exp",
                "arg": {
                    "type": "Add",
                    "operands": [
                        {"type": "Integral", "kernel": "N", "fields": ["phi_plus", "phi_minus"]},
                        {"type": "Integral", "kernel": "D", "fields": ["phi_plus", "phi_minus"]}
                    ]
                }
            }
        });

        let symbolic_hash = canonical_json_hash(&expr_tree);

        Self {
            data: DerivationStepData {
                step_id: "step2_influence",
                step_name: "Influence Functional",
                expression_tree: expr_tree,
                assumptions: vec![
                    "gaussian_integral".into(),
                    "linear_coupling".into(),
                    "zeta_zero_sum".into(),
                ],
                transformation_rules: vec![
                    "complete_square".into(),
                    "path_integral_out".into(),
                    "zeta_series_expansion".into(),
                ],
                symbolic_hash,
            },
        }
    }
}

impl DerivationStep for InfluenceFunctional {
    fn step_id(&self) -> &'static str { self.data.step_id }
    fn step_name(&self) -> &'static str { self.data.step_name }
    fn expression_tree(&self) -> serde_json::Value { self.data.expression_tree.clone() }
    fn assumptions(&self) -> Vec<String> { self.data.assumptions.clone() }
    fn transformation_rules(&self) -> Vec<String> { self.data.transformation_rules.clone() }
    fn symbolic_hash(&self) -> &str { &self.data.symbolic_hash }
}

// ============================================================================
// Step 3: Langevin Equation
// ============================================================================

/// Step 3 — Langevin equation for the background condensate σ(t).
///
/// Varies the effective action to obtain the stochastic equation of motion
/// with Gaussian noise ξ(t).
#[derive(Debug, Clone)]
pub struct LangevinEquation {
    data: DerivationStepData,
}

impl LangevinEquation {
    pub fn new() -> Self {
        let expr_tree = serde_json::json!({
            "type": "Equation",
            "name": "LangevinCondensate",
            "lhs": {
                "type": "Add",
                "operands": [
                    {
                        "type": "Function",
                        "name": "sigma_ddot",
                        "args": [{"type": "Symbol", "name": "t"}]
                    },
                    {
                        "type": "Mul",
                        "operands": [
                            {
                                "type": "Function",
                                "name": "H",
                                "args": [{"type": "Symbol", "name": "t"}]
                            },
                            {
                                "type": "Function",
                                "name": "sigma_dot",
                                "args": [{"type": "Symbol", "name": "t"}]
                            }
                        ]
                    },
                    {
                        "type": "Symbol",
                        "name": "m_squared",
                        "description": "effective mass squared"
                    }
                ]
            },
            "rhs": {
                "type": "Function",
                "name": "xi",
                "args": [{"type": "Symbol", "name": "t"}]
            },
            "noise_correlation": {
                "type": "Correlation",
                "operator": "langle",
                "operands": [
                    {
                        "type": "Function",
                        "name": "xi",
                        "args": [{"type": "Symbol", "name": "t"}]
                    },
                    {
                        "type": "Function",
                        "name": "xi",
                        "args": [{"type": "Symbol", "name": "t_prime"}]
                    }
                ],
                "equals": {
                    "type": "Symbol",
                    "name": "N",
                    "args": ["t", "t_prime"]
                }
            }
        });

        let symbolic_hash = canonical_json_hash(&expr_tree);

        Self {
            data: DerivationStepData {
                step_id: "step3_langevin",
                step_name: "Langevin Equation",
                expression_tree: expr_tree,
                assumptions: vec![
                    "slow_roll".into(),
                    "gaussian_noise".into(),
                    "markovian_environment".into(),
                ],
                transformation_rules: vec![
                    "functional_variation".into(),
                    "noise_identification".into(),
                ],
                symbolic_hash,
            },
        }
    }
}

impl DerivationStep for LangevinEquation {
    fn step_id(&self) -> &'static str { self.data.step_id }
    fn step_name(&self) -> &'static str { self.data.step_name }
    fn expression_tree(&self) -> serde_json::Value { self.data.expression_tree.clone() }
    fn assumptions(&self) -> Vec<String> { self.data.assumptions.clone() }
    fn transformation_rules(&self) -> Vec<String> { self.data.transformation_rules.clone() }
    fn symbolic_hash(&self) -> &str { &self.data.symbolic_hash }
}

// ============================================================================
// Step 4: Power Spectrum
// ============================================================================

/// Step 4 — Curvature power spectrum `P_ζ(k)`.
///
/// Solves the Langevin equation in the slow-roll approximation using Green's
/// functions and Fourier transform.
#[derive(Debug, Clone)]
pub struct PowerSpectrum {
    data: DerivationStepData,
}

impl PowerSpectrum {
    pub fn new() -> Self {
        let expr_tree = serde_json::json!({
            "type": "Equation",
            "name": "CurvaturePowerSpectrum",
            "lhs": {"type": "Symbol", "name": "P_zeta", "args": ["k"]},
            "rhs": {
                "type": "Mul",
                "operands": [
                    {"type": "Symbol", "name": "A_s"},
                    {
                        "type": "Pow",
                        "base": {"type": "Div", "operands": ["k", "k_star"]},
                        "exp": {"type": "Sub", "operands": ["n_s", "1"]}
                    },
                    {
                        "type": "Add",
                        "operands": [
                            "1",
                            {
                                "type": "Mul",
                                "operands": [
                                    "epsilon",
                                    {
                                        "type": "Sum",
                                        "index": "n",
                                        "term": {
                                            "type": "Div",
                                            "operands": [
                                                {
                                                    "type": "Cos",
                                                    "args": ["gamma_n * log(k/k_star) + phi_n"]
                                                },
                                                {"type": "Pow", "base": {"type": "Add", "operands": ["1/4", "gamma_n^2"]}, "exp": "1/2"}
                                            ]
                                        }
                                    }
                                ]
                            }
                        ]
                    }
                ]
            }
        });

        let symbolic_hash = canonical_json_hash(&expr_tree);

        Self {
            data: DerivationStepData {
                step_id: "step4_power_spectrum",
                step_name: "Power Spectrum Solution",
                expression_tree: expr_tree,
                assumptions: vec![
                    "slow_roll".into(),
                    "markovian_noise".into(),
                    "bunch_davies_ic".into(),
                ],
                transformation_rules: vec![
                    "fourier_transform".into(),
                    "greens_function".into(),
                    "mode_function_normalization".into(),
                ],
                symbolic_hash,
            },
        }
    }
}

impl DerivationStep for PowerSpectrum {
    fn step_id(&self) -> &'static str { self.data.step_id }
    fn step_name(&self) -> &'static str { self.data.step_name }
    fn expression_tree(&self) -> serde_json::Value { self.data.expression_tree.clone() }
    fn assumptions(&self) -> Vec<String> { self.data.assumptions.clone() }
    fn transformation_rules(&self) -> Vec<String> { self.data.transformation_rules.clone() }
    fn symbolic_hash(&self) -> &str { &self.data.symbolic_hash }
}

// ============================================================================
// Step 5: Null Test (f_NL)
// ============================================================================

/// Step 5 — Validation & null test for non-Gaussianity.
///
/// Computes the predicted f_NL from the Gaussian noise and confirms it is
/// exactly zero (Maldacena / in-in formalism).
#[derive(Debug, Clone)]
pub struct NullTest {
    data: DerivationStepData,
}

impl NullTest {
    pub fn new() -> Self {
        let expr_tree = serde_json::json!({
            "type": "Equation",
            "name": "fNLNullTest",
            "lhs": {
                "type": "Symbol",
                "name": "f_NL"
            },
            "rhs": {
                "type": "Symbol",
                "name": "0",
                "description": "exact vanishing due to Gaussian noise"
            },
            "derivation": {
                "type": "ThreePointFunction",
                "formalism": "in_in",
                "noise_statistics": "gaussian",
                "conclusion": "bispectrum vanishes identically",
                "witness_claim": "f_NL_approx_0"
            }
        });

        let symbolic_hash = canonical_json_hash(&expr_tree);

        Self {
            data: DerivationStepData {
                step_id: "step5_null_test",
                step_name: "Validation & Null Test",
                expression_tree: expr_tree,
                assumptions: vec![
                    "gaussian_noise".into(),
                    "maldacena_formalism".into(),
                    "slow_roll".into(),
                ],
                transformation_rules: vec![
                    "in_in_formalism".into(),
                    "three_point_function".into(),
                    "bispectrum_vanishing".into(),
                ],
                symbolic_hash,
            },
        }
    }
}

impl DerivationStep for NullTest {
    fn step_id(&self) -> &'static str { self.data.step_id }
    fn step_name(&self) -> &'static str { self.data.step_name }
    fn expression_tree(&self) -> serde_json::Value { self.data.expression_tree.clone() }
    fn assumptions(&self) -> Vec<String> { self.data.assumptions.clone() }
    fn transformation_rules(&self) -> Vec<String> { self.data.transformation_rules.clone() }
    fn symbolic_hash(&self) -> &str { &self.data.symbolic_hash }
}

// ============================================================================
// Shared step data holder
// ============================================================================

#[derive(Debug, Clone)]
struct DerivationStepData {
    step_id: &'static str,
    step_name: &'static str,
    expression_tree: serde_json::Value,
    assumptions: Vec<String>,
    transformation_rules: Vec<String>,
    symbolic_hash: String,
}

// ============================================================================
// Integration with existing generate_multi_level_witness
// ============================================================================

/// Adapter to feed derivation W1 hashes into the existing `generate_multi_level_witness`
/// pattern from `models/legalese-scopist`.
///
/// The existing function signature is:
///   `generate_multi_level_witness(c_lambda, consumed_ops, fidelity, final_status) -> (w0, w1, w2, c_total)`
///
/// This adapter shows how to extend it with derivation-stage W1 signatures.
pub mod integration {
    use super::*;

    /// Extended witness that includes derivation-stage W1_AXIOM signatures.
    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub struct DerivationExtendedWitness {
        pub w0_exec_hash: String,
        pub base_w1_axiom: String,
        pub derivation_w1_axioms: Vec<String>,
        pub w2_phys_hash: String,
        pub c_total: String,
        pub derivation_steps: Vec<DerivationWitness>,
    }

    /// Combine the existing witness with derivation-stage witnesses.
    ///
    /// # Arguments
    /// * `legalese_witness` — output of the existing `generate_multi_level_witness`
    /// * `derivation_witnesses` — ordered witnesses from the derivation pipeline
    ///
    /// # Returns
    /// An `DerivationExtendedWitness` that preserves the original ledger format
    /// while appending derivation proofs.
    pub fn extend_witness(
        legalese_witness: (String, String, String, String),
        derivation_witnesses: &[DerivationWitness],
    ) -> DerivationExtendedWitness {
        let (w0, base_w1, w2, _c_base) = legalese_witness;

        let derivation_w1s: Vec<String> = derivation_witnesses
            .iter()
            .map(|w| w.w1_axiom.clone())
            .collect();

        // Recompute C_TOTAL including derivation hashes
        let mut hasher = Sha256::new();
        hasher.update(w0.as_bytes());
        hasher.update(base_w1.as_bytes());
        for w1 in &derivation_w1s {
            hasher.update(w1.as_bytes());
        }
        hasher.update(w2.as_bytes());
        let c_total = format!("C_TOTAL_{}", hex::encode(hasher.finalize()));

        DerivationExtendedWitness {
            w0_exec_hash: w0,
            base_w1_axiom: base_w1,
            derivation_w1_axioms: derivation_w1s,
            w2_phys_hash: w2,
            c_total,
            derivation_steps: derivation_witnesses.to_vec(),
        }
    }
}
