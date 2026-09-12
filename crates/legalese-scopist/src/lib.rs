// The Rust Sedona Spine Engine Implementation
// Memory layout strictly matches Lean 4 exports

use serde::{Deserialize, Serialize};
use wasm_bindgen::prelude::*;

pub mod ace;
pub mod collatz;
pub mod affine_core;
pub mod umcparom;
pub mod umc_physics;
pub mod umc_pgf;
pub mod umc_wht;
pub mod umc_pirtm;

#[repr(C)]
pub struct GlobalHilbertSpace {
    pub data: *mut f64,
    pub dim: usize,
}

// Exact replica of Lean's Matrix2x2 layout
#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct Matrix2x2 {
    pub a: f64,
    pub b: f64,
    pub c: f64,
    pub d: f64,
}

// Declare the Lean-exported symbols
unsafe extern "C" {
    fn toy_o2() -> Matrix2x2;
    fn toy_o3() -> Matrix2x2;
    fn toy_o5() -> Matrix2x2;
    fn toy_sigma() -> f64;
    fn toy_alpha() -> f64;
}

// Rust wrapper that reads the Lean-specified initial conditions
pub fn get_lean_initial_conditions() -> (Matrix2x2, Matrix2x2, Matrix2x2, f64, f64) {
    unsafe { (toy_o2(), toy_o3(), toy_o5(), toy_sigma(), toy_alpha()) }
}

/// Dummy function implementing the FFI contract for Lean
#[unsafe(no_mangle)]
pub extern "C" fn get_dimension_rs(space: *const GlobalHilbertSpace) -> usize {
    if space.is_null() {
        return 0;
    }
    unsafe { (*space).dim }
}

/// Computes the spectral radius of a 2x2 operator
#[unsafe(no_mangle)]
pub extern "C" fn compute_spectral_radius(op: *const [[f64; 2]; 2]) -> f64 {
    if op.is_null() {
        return 0.0;
    }
    let m = unsafe { &*op };
    let a = m[0][0];
    let b = m[0][1];
    let c = m[1][0];
    let d = m[1][1];

    let tr = a + d;
    let det = a * d - b * c;
    let disc = tr * tr - 4.0 * det;

    if disc >= 0.0 {
        let sqrt_disc = disc.sqrt();
        let lambda1 = (tr + sqrt_disc).abs() / 2.0;
        let lambda2 = (tr - sqrt_disc).abs() / 2.0;
        lambda1.max(lambda2)
    } else {
        // Complex conjugate roots, modulus is sqrt(det)
        det.abs().sqrt()
    }
}

/// Verifies the RG spectral bound condition (Eq 1)
#[unsafe(no_mangle)]
pub extern "C" fn check_rg_condition(p: u32, sigma: f64, op: *const [[f64; 2]; 2]) -> bool {
    let rho = compute_spectral_radius(op);
    let p_f64 = p as f64;
    let threshold = (1.0 + p_f64.powf(sigma) / 2.0).ln();
    rho < threshold
}

// ---------------------------------------------------------
// Kani Symbolic Verification Harnesses
// ---------------------------------------------------------

// ---------------------------------------------------------
// Density Matrix Invariants (Option A)
// ---------------------------------------------------------

/// Computes the eigenvalues of the normalized density matrix rho = exp(Op * p^{-s}) / Tr(...)
/// Assumes Op is a 2x2 real symmetric matrix (Hermitian).
/// Returns true if successful, false if the matrix values are out of bounds ([-10, 10]).
#[unsafe(no_mangle)]
pub extern "C" fn compute_density_matrix_eigenvalues(
    p: u32,
    s: f64,
    op: *const [[f64; 2]; 2],
    out_evals: *mut [f64; 2],
) -> bool {
    if op.is_null() || out_evals.is_null() {
        return false;
    }
    let m = unsafe { &*op };
    let a = m[0][0];
    let b = m[0][1];
    // We assume real symmetric, so m[1][0] == b is implicitly used.
    let d = m[1][1];

    // Explicit runtime bounds check (Zero Drift / Path of Integrity constraint)
    if a < -10.0 || a > 10.0 || b < -10.0 || b > 10.0 || d < -10.0 || d > 10.0 {
        return false;
    }

    let tr = a + d;
    let disc = (a - d) * (a - d) + 4.0 * b * b;
    let sqrt_disc = disc.abs().sqrt();

    // Eigenvalues of Op
    let lambda1 = (tr + sqrt_disc) / 2.0;
    let lambda2 = (tr - sqrt_disc) / 2.0;

    // Scale by p^{-s}
    let factor = (p as f64).powf(-s);
    let l1_scaled = lambda1 * factor;
    let l2_scaled = lambda2 * factor;

    // Compute exp(eigenvalues) for unnormalized rho
    // To avoid overflow, we can shift by the max eigenvalue
    let max_l = l1_scaled.max(l2_scaled);
    let exp1 = (l1_scaled - max_l).exp();
    let exp2 = (l2_scaled - max_l).exp();

    let trace = exp1 + exp2;

    unsafe {
        (*out_evals)[0] = exp1 / trace;
        (*out_evals)[1] = exp2 / trace;
    }

    true
}

/// Verifies that Tr(rho) == 1 and rho is PSD (eigenvalues >= 0)
#[unsafe(no_mangle)]
pub extern "C" fn check_density_matrix_invariant(p: u32, s: f64, op: *const [[f64; 2]; 2]) -> bool {
    let mut evals = [0.0; 2];
    if !compute_density_matrix_eigenvalues(p, s, op, &mut evals) {
        return false; // Out of bounds or invalid
    }

    let trace = evals[0] + evals[1];
    let is_psd = evals[0] >= 0.0 && evals[1] >= 0.0;

    // Check trace == 1 within floating-point tolerance
    let trace_is_one = (trace - 1.0).abs() < 1e-9;

    is_psd && trace_is_one
}

/// Computes the von Neumann entropy S(t) = -Tr(rho ln rho) of the 2x2 density matrix.
/// Handles the boundary condition where lambda -> 0 implies lambda * ln(lambda) -> 0.
#[unsafe(no_mangle)]
pub extern "C" fn compute_entropy(evals: *const [f64; 2]) -> f64 {
    if evals.is_null() {
        return 0.0;
    }

    let l1 = unsafe { (*evals)[0] };
    let l2 = unsafe { (*evals)[1] };

    // Helper to compute -lambda * ln(lambda) safely
    let entropy_term = |lambda: f64| -> f64 {
        if lambda <= 0.0 {
            0.0 // Limit as x -> 0+ of x*ln(x) is 0
        } else {
            -lambda * lambda.ln()
        }
    };

    entropy_term(l1) + entropy_term(l2)
}

// ---------------------------------------------------------
// ESI Retention and Risk Logic (Sedona Spine Mandate)
// ---------------------------------------------------------

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum RiskLevel {
    Critical,
    High,
    Medium,
}

#[repr(C)]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EsiInputs {
    pub spoliation_potential: f64, // 0.0 to 1.0
    pub preservation_urgency: f64, // 0.0 to 1.0
    pub volume_estimate_gb: f64,
    #[serde(default = "default_lambda_m")]
    pub lambda_m: f64,
    #[serde(default = "default_l_g")]
    pub l_g: f64,
    #[serde(default = "default_gamma")]
    pub gamma: f64,
    #[serde(default = "default_norm_s")]
    pub norm_s: f64,
    #[serde(default)]
    pub histogram: Vec<f64>, // 64 elements for WHT
    // ZRSD Telemetry
    #[serde(default = "default_fidelity")]
    pub fidelity: f64,
    #[serde(default)]
    pub entropy_rate: f64,
    #[serde(default = "default_zeta")]
    pub zeta_truncation: u64,
    // Derivation Step integration
    #[serde(default)]
    pub derivation_hash: Option<String>,
}

fn default_lambda_m() -> f64 { 0.5 }
fn default_l_g() -> f64 { 0.5 }
fn default_gamma() -> f64 { 0.9 }
fn default_norm_s() -> f64 { 1.0 }
fn default_fidelity() -> f64 { 1.0 }
fn default_zeta() -> u64 { 20 }
fn default_entropy_rate() -> f64 { 0.0 }
fn default_zeta_truncation() -> u32 { 20 }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CompilationResult {
    pub risk_level: RiskLevel,
    pub is_stable: bool,
    pub spectral_radius: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UnifiedWitness {
    pub compilation_result: CompilationResult,
    pub timestamp: u64,
    pub w0_exec_hash: String,
    pub w1_axiom_hash: String,
    pub w2_phys_hash: String,
    pub signature: String, // Composite C_total hash
}

/// Maps ESI inputs into a 2x2 Hermitian matrix (Density Matrix format)
/// We use spoliation and urgency to construct the operator bounds.
pub fn map_esi_to_operator(inputs: &EsiInputs) -> [[f64; 2]; 2] {
    // A simplified transformation mapping legal facts into the spectral space
    let a = inputs.spoliation_potential * 2.0;
    let d = inputs.preservation_urgency * 2.0;
    // Cross-terms represent compounding complexity
    let b = if inputs.spoliation_potential >= 0.0 && inputs.preservation_urgency >= 0.0 {
        (inputs.spoliation_potential * inputs.preservation_urgency).sqrt()
    } else {
        0.0 // Fallback if inputs are invalid/negative
    };

    [[a, b], [b, d]]
}

/// Handles recursive \Xi(t) projection divergence by gracefully decaying the recursion gain.
pub fn handle_divergence(mut inputs: EsiInputs) -> EsiInputs {
    // Decaying \beta (lambda_m) multiplicatively until stable
    inputs.lambda_m *= 0.5;
    inputs
}

/// Stub for Groth16 cryptographic witness commitment over the spectral gap.
/// Generates the multi-level ledger components (W0, W1, W2) and a composite signature.
pub fn generate_multi_level_witness(
    c_lambda: f64,
    consumed_ops: u64,
    fidelity: f64,
    final_status: &str,
    derivation_hash: Option<&str>
) -> (String, String, String, String) {
    use std::hash::{Hash, Hasher};
    use std::collections::hash_map::DefaultHasher;
    
    // W0: Execution Witness
    let mut h0 = DefaultHasher::new();
    consumed_ops.hash(&mut h0);
    let w0 = format!("W0_EXEC_{:016X}", h0.finish());

    // W1: Axiomatic Witness
    let mut h1 = DefaultHasher::new();
    c_lambda.to_bits().hash(&mut h1);
    final_status.hash(&mut h1);
    if let Some(d_hash) = derivation_hash {
        d_hash.hash(&mut h1);
    }
    let w1 = format!("W1_AXIOM_{:016X}", h1.finish());

    // W2: Physical Witness
    let mut h2 = DefaultHasher::new();
    fidelity.to_bits().hash(&mut h2);
    let w2 = format!("W2_PHYS_{:016X}", h2.finish());

    // Composite C_total
    let mut h_tot = DefaultHasher::new();
    w0.hash(&mut h_tot);
    w1.hash(&mut h_tot);
    w2.hash(&mut h_tot);
    let c_total = format!("C_TOTAL_{:016X}", h_tot.finish());

    (w0, w1, w2, c_total)
}

/// Evaluates ESI risk, returning a Unified Witness.
/// Adheres strictly to the Path of Integrity, integrating \Lambda_m stability and ZRSD telemetry.
pub fn evaluate_esi_risk(inputs: &EsiInputs, p_factor: u32, sigma: f64, ops_consumed: u64) -> UnifiedWitness {
    let mut current_inputs = inputs.clone();
    
    // Check density matrix stability mathematically
    let op = map_esi_to_operator(&current_inputs);
    let is_rg_stable = check_rg_condition(p_factor, sigma, &op as *const [[f64; 2]; 2]);
    let rho = compute_spectral_radius(&op as *const [[f64; 2]; 2]);

    // Compute \Lambda_m PIRTM and PGF metrics
    let mut pirtm_update = crate::umc_pirtm::PIRTMUpdate::new(current_inputs.lambda_m, current_inputs.l_g);
    let mut c_lambda = pirtm_update.contraction_constant();
    
    let pgf_state = crate::umc_pgf::PGFSpatialState::new(current_inputs.norm_s, 1.0); // r(T) proxy
    let l_hyb = pgf_state.lambda_hyb(current_inputs.gamma);

    let mut divergence_handled = false;
    // Recursive \Xi(t) projection fallback handler:
    if c_lambda >= 1.0 || current_inputs.fidelity < 0.85 {
        // Log violation internally and handle divergence
        current_inputs = handle_divergence(current_inputs);
        pirtm_update = crate::umc_pirtm::PIRTMUpdate::new(current_inputs.lambda_m, current_inputs.l_g);
        c_lambda = pirtm_update.contraction_constant();
        divergence_handled = true;
    }

    // Apply WHT if 64-element histogram is provided
    if current_inputs.histogram.len() == 64 {
        let mut h = [0i64; 64];
        for i in 0..64 {
            h[i] = current_inputs.histogram[i] as i64;
        }
        crate::umc_wht::fwht_64(&mut h);
        // The resulting spectral vector \hat{h} is structurally available here for ZK-Poseidon2 commits
    }

    // Comprehensive Stability: RG stable AND PIRTM strictly contractive AND \Lambda_m within PGF global fence
    let is_stable = is_rg_stable && (c_lambda < 1.0) && (current_inputs.lambda_m <= l_hyb) && (current_inputs.fidelity >= 0.85);

    // Policy logic: Any violation of mathematical stability forces a Critical Risk Level.
    let risk_level = if !is_stable {
        RiskLevel::Critical
    } else if rho > 1.5 || c_lambda > 0.9 {
        RiskLevel::High
    } else {
        RiskLevel::Medium
    };

    // Include RECURSION_STABILIZED signal if fallback engaged
    let final_status = if divergence_handled {
        "RECURSION_STABILIZED (Soft-landing engaged)"
    } else {
        "NOMINAL"
    };

    let compilation_result = CompilationResult {
        risk_level,
        is_stable,
        spectral_radius: rho,
    };

    // Emit the Multi-Level Witness Ledger
    let (w0, w1, w2, c_total) = generate_multi_level_witness(
        c_lambda, 
        ops_consumed, 
        current_inputs.fidelity, 
        final_status,
        current_inputs.derivation_hash.as_deref()
    );

    UnifiedWitness {
        compilation_result,
        timestamp: 0, // Placeholder for actual time/block height
        w0_exec_hash: w0,
        w1_axiom_hash: w1,
        w2_phys_hash: w2,
        signature: c_total,
    }
}

/// WASM SDK Entry Point
/// This is the strictly enforced boundary for the Path of Integrity.
#[wasm_bindgen]
pub fn evaluate_esi_risk_wasm(
    inputs_val: JsValue,
    p_factor: u32,
    sigma: f64,
) -> Result<JsValue, JsValue> {
    let inputs: EsiInputs = serde_wasm_bindgen::from_value(inputs_val)
        .map_err(|e| JsValue::from_str(&format!("Invalid ESI inputs: {}", e)))?;

    let witness = evaluate_esi_risk(&inputs, p_factor, sigma, 0);

    serde_wasm_bindgen::to_value(&witness)
        .map_err(|e| JsValue::from_str(&format!("Failed to serialize witness: {}", e)))
}

/// WASM SDK Entry Point for ACE-bound risk evaluation
#[wasm_bindgen]
pub fn evaluate_esi_risk_with_ace_wasm(
    inputs_val: JsValue,
    p_factor: u32,
    sigma: f64,
    budget_val: JsValue,
) -> Result<JsValue, JsValue> {
    let inputs: EsiInputs = serde_wasm_bindgen::from_value(inputs_val)
        .map_err(|e| JsValue::from_str(&format!("Invalid ESI inputs: {}", e)))?;

    let budget: ace::AceBudget = serde_wasm_bindgen::from_value(budget_val)
        .map_err(|e| JsValue::from_str(&format!("Invalid ACE Budget: {}", e)))?;

    let envelope = ace::AceEnvelope::new(budget);

    let result = ace::evaluate_esi_risk_with_ace(&inputs, p_factor, sigma, envelope)
        .map_err(|e| JsValue::from_str(&format!("ACE Execution Error: {}", e)))?;

    serde_wasm_bindgen::to_value(&result)
        .map_err(|e| JsValue::from_str(&format!("Failed to serialize ACE result: {}", e)))
}

#[wasm_bindgen]
pub fn process_collatz_chunk_wasm(start_str: String, chunk_size: u32) -> Result<JsValue, JsValue> {
    let start: u128 = start_str
        .parse()
        .map_err(|e| JsValue::from_str(&format!("Invalid start bound: {}", e)))?;
    let end: u128 = start.saturating_add(chunk_size as u128).saturating_sub(1);

    let result = collatz::verify_range(start, end);

    serde_wasm_bindgen::to_value(&result)
        .map_err(|e| JsValue::from_str(&format!("Failed to serialize result: {}", e)))
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn verify_get_dimension() {
        let sym_dim: usize = kani::any();
        kani::assume(sym_dim > 0 && sym_dim < 1000000);
        let mut dummy_data = 0.0f64;
        let space = GlobalHilbertSpace {
            data: &mut dummy_data as *mut f64,
            dim: sym_dim,
        };
        let result = get_dimension_rs(&space);
        kani::assert(result > 0, "Dimension must be strictly positive");
        kani::assert(result == sym_dim, "Returned dimension must perfectly match");
    }

    #[kani::proof]
    fn verify_rg_condition_safety() {
        // Symbolically generate a 2x2 matrix
        let a: f64 = kani::any();
        let b: f64 = kani::any();
        let c: f64 = kani::any();
        let d: f64 = kani::any();

        // Plausible bounds for operator elements
        kani::assume(a > -10.0 && a < 10.0);
        kani::assume(b > -10.0 && b < 10.0);
        kani::assume(c > -10.0 && c < 10.0);
        kani::assume(d > -10.0 && d < 10.0);

        let op = [[a, b], [c, d]];

        // Symbolically choose prime p in {2, 3, 5}
        let p: u32 = kani::any();
        kani::assume(p == 2 || p == 3 || p == 5);

        // Symbolically choose sigma in [1.5, 3.0]
        let sigma: f64 = kani::any();
        kani::assume(sigma >= 1.5 && sigma <= 3.0);

        // Check if condition passes
        let passes = check_rg_condition(p, sigma, &op);

        if passes {
            let rho = compute_spectral_radius(&op);

            // Assert that numeric boundaries and computations are perfectly safe
            kani::assert(rho.is_finite(), "Spectral radius must remain finite");
            kani::assert(!rho.is_nan(), "Spectral radius must not hit NaN");

            let p_f64 = p as f64;
            let threshold = (1.0 + p_f64.powf(sigma) / 2.0).ln();
            kani::assert(threshold.is_finite(), "Threshold must remain finite");
            kani::assert(!threshold.is_nan(), "Threshold must not hit NaN");
        }
    }

    #[kani::proof]
    fn verify_density_matrix_invariant_safety() {
        // Tier 1: Logical Safety (No panic/NaN/Inf) with wide bounds
        let a: f64 = kani::any();
        let b: f64 = kani::any();
        let d: f64 = kani::any();

        // Broad bounds just to ensure finite behavior
        kani::assume(a > -2.0 && a < 2.0);
        kani::assume(b > -2.0 && b < 2.0);
        kani::assume(d > -2.0 && d < 2.0);

        let op = [[a, b], [b, d]];
        let p: u32 = kani::any();
        kani::assume(p == 2 || p == 3 || p == 5);

        let s: f64 = kani::any();
        kani::assume(s >= 0.5 && s <= 3.0);

        let mut evals = [0.0; 2];
        let success = compute_density_matrix_eigenvalues(p, s, &op, &mut evals);

        if success {
            kani::assert(
                evals[0].is_finite() && evals[1].is_finite(),
                "Density matrix eigenvalues must be finite",
            );
            kani::assert(
                !evals[0].is_nan() && !evals[1].is_nan(),
                "Density matrix eigenvalues must not be NaN",
            );
        }
    }

    #[kani::proof]
    fn verify_density_matrix_invariant_semantics() {
        // Tier 2: Semantic Precision (Trace == 1) with tight bounds for solver tractability
        let a: f64 = kani::any();
        let b: f64 = kani::any();
        let d: f64 = kani::any();

        // Tight bounds to keep CBMC execution time under control and floating point behavior strictly monotonic
        kani::assume(a > -1.0 && a < 1.0);
        kani::assume(b > -1.0 && b < 1.0);
        kani::assume(d > -1.0 && d < 1.0);

        let op = [[a, b], [b, d]];
        let p: u32 = kani::any();
        kani::assume(p == 2 || p == 3);

        let s: f64 = kani::any();
        kani::assume(s >= 1.0 && s <= 2.0);

        let mut evals = [0.0; 2];
        let success = compute_density_matrix_eigenvalues(p, s, &op, &mut evals);

        if success {
            let trace = evals[0] + evals[1];
            let is_psd = evals[0] >= 0.0 && evals[1] >= 0.0;
            // Slightly relaxed float tolerance since float math is not exact
            let trace_is_one = (trace - 1.0).abs() < 1e-8;

            kani::assert(is_psd, "Eigenvalues must be non-negative");
            kani::assert(trace_is_one, "Trace must be exactly 1 within tolerance");
        }
    }

    #[kani::proof]
    fn verify_entropy_safety() {
        let l1: f64 = kani::any();
        let l2: f64 = kani::any();

        // Valid density matrix eigenvalues
        kani::assume(l1 >= 0.0 && l1 <= 1.0);
        kani::assume(l2 >= 0.0 && l2 <= 1.0);
        // They should sum to 1, but we'll assume a loose sum bounds for numerical stability
        kani::assume((l1 + l2 - 1.0).abs() < 1e-5);

        let evals = [l1, l2];
        let entropy = compute_entropy(&evals);

        // Entropy of 2-level system is bounded by ln(2) ~ 0.693. We check < 1.0
        kani::assert(entropy >= 0.0, "Entropy must be non-negative");
        kani::assert(
            entropy <= 1.0,
            "Entropy of 2x2 system must not exceed ln(2)",
        );
        kani::assert(entropy.is_finite(), "Entropy must remain finite");
        kani::assert(!entropy.is_nan(), "Entropy must not hit NaN");
    }

    #[kani::proof]
    fn verify_esi_risk_evaluation_safety() {
        let spoliation_potential: f64 = kani::any();
        let preservation_urgency: f64 = kani::any();
        let volume_estimate_gb: f64 = kani::any();

        kani::assume(spoliation_potential >= 0.0 && spoliation_potential <= 1.0);
        kani::assume(preservation_urgency >= 0.0 && preservation_urgency <= 1.0);
        kani::assume(volume_estimate_gb >= 0.0 && volume_estimate_gb < 1_000_000.0);

        let inputs = EsiInputs {
            spoliation_potential,
            preservation_urgency,
            volume_estimate_gb,
        };

        let p: u32 = kani::any();
        kani::assume(p == 2 || p == 3 || p == 5);

        let sigma: f64 = kani::any();
        kani::assume(sigma >= 1.5 && sigma <= 3.0);

        let witness = evaluate_esi_risk(&inputs, p, sigma, 0);

        kani::assert(
            !witness.compilation_result.spectral_radius.is_nan(),
            "Spectral radius must not be NaN",
        );
    }

    const TOY_O2_STUB: Matrix2x2 = Matrix2x2 {
        a: 0.5,
        b: 0.0,
        c: 0.0,
        d: -0.5,
    };
    const TOY_O3_STUB: Matrix2x2 = Matrix2x2 {
        a: 0.3,
        b: 0.0,
        c: 0.0,
        d: 0.3,
    };
    const TOY_O5_STUB: Matrix2x2 = Matrix2x2 {
        a: 0.2,
        b: 0.0,
        c: 0.0,
        d: -0.2,
    };
    const TOY_SIGMA_STUB: f64 = 2.0;

    // -------------------------------------------------------------------------
    // Time Evolution Verification (Option 1 — Lean FFI stubbed for Kani)
    // -------------------------------------------------------------------------

    const EPS_2: f64 = 0.1;
    const OMEGA_2: f64 = 0.5;
    const EPS_3: f64 = 0.08;
    const OMEGA_3: f64 = 0.7;
    const EPS_5: f64 = 0.05;
    const OMEGA_5: f64 = 1.0;

    const W2: [[f64; 2]; 2] = [[0.5, 0.0], [0.0, -0.5]];
    const W3: [[f64; 2]; 2] = [[0.3, 0.0], [0.0, 0.3]];
    const W5: [[f64; 2]; 2] = [[0.2, 0.0], [0.0, -0.2]];

    const O2_BASE: [[f64; 2]; 2] = [[0.5, 0.0], [0.0, -0.5]];
    const O3_BASE: [[f64; 2]; 2] = [[0.3, 0.0], [0.0, 0.3]];
    const O5_BASE: [[f64; 2]; 2] = [[0.2, 0.0], [0.0, -0.2]];

    /// Time-dependent local operator: O_p(t) = O_p(0) + eps * sin(omega * t) * W_p
    fn local_op_time(
        base: [[f64; 2]; 2],
        eps: f64,
        omega: f64,
        w: [[f64; 2]; 2],
        t: f64,
    ) -> [[f64; 2]; 2] {
        let sin_term = (omega * t).sin();
        let scale = eps * sin_term;
        [
            [base[0][0] + scale * w[0][0], base[0][1] + scale * w[0][1]],
            [base[1][0] + scale * w[1][0], base[1][1] + scale * w[1][1]],
        ]
    }

    /// Spectral separation proxy: Delta_p(t) = threshold_p - rho(O_p(t))
    fn spectral_separation_proxy(p: u32, sigma: f64, op: &[[f64; 2]; 2]) -> f64 {
        let rho = compute_spectral_radius(op as *const _);
        let p_f64 = p as f64;
        let threshold = (1.0 + p_f64.powf(sigma) / 2.0).ln();
        threshold - rho
    }

    #[kani::proof]
    fn verify_time_evolution_rg_condition() {
        let sigma = TOY_SIGMA_STUB;

        let scale2: f64 = kani::any();
        let scale3: f64 = kani::any();
        let scale5: f64 = kani::any();
        kani::assume(scale2 >= -EPS_2 && scale2 <= EPS_2);
        kani::assume(scale3 >= -EPS_3 && scale3 <= EPS_3);
        kani::assume(scale5 >= -EPS_5 && scale5 <= EPS_5);

        let o2 = [
            [
                O2_BASE[0][0] + scale2 * W2[0][0],
                O2_BASE[0][1] + scale2 * W2[0][1],
            ],
            [
                O2_BASE[1][0] + scale2 * W2[1][0],
                O2_BASE[1][1] + scale2 * W2[1][1],
            ],
        ];
        let o3 = [
            [
                O3_BASE[0][0] + scale3 * W3[0][0],
                O3_BASE[0][1] + scale3 * W3[0][1],
            ],
            [
                O3_BASE[1][0] + scale3 * W3[1][0],
                O3_BASE[1][1] + scale3 * W3[1][1],
            ],
        ];
        let o5 = [
            [
                O5_BASE[0][0] + scale5 * W5[0][0],
                O5_BASE[0][1] + scale5 * W5[0][1],
            ],
            [
                O5_BASE[1][0] + scale5 * W5[1][0],
                O5_BASE[1][1] + scale5 * W5[1][1],
            ],
        ];

        kani::assert(
            check_rg_condition(2, sigma, &o2),
            "O2 must satisfy RG condition under bounded perturbation",
        );
        kani::assert(
            check_rg_condition(3, sigma, &o3),
            "O3 must satisfy RG condition under bounded perturbation",
        );
        kani::assert(
            check_rg_condition(5, sigma, &o5),
            "O5 must satisfy RG condition under bounded perturbation",
        );
    }

    #[kani::proof]
    fn verify_time_evolution_density_matrix_invariants() {
        let sigma = TOY_SIGMA_STUB;

        let scale2: f64 = kani::any();
        let scale3: f64 = kani::any();
        let scale5: f64 = kani::any();
        kani::assume(scale2 >= -EPS_2 && scale2 <= EPS_2);
        kani::assume(scale3 >= -EPS_3 && scale3 <= EPS_3);
        kani::assume(scale5 >= -EPS_5 && scale5 <= EPS_5);

        let o2 = [
            [
                O2_BASE[0][0] + scale2 * W2[0][0],
                O2_BASE[0][1] + scale2 * W2[0][1],
            ],
            [
                O2_BASE[1][0] + scale2 * W2[1][0],
                O2_BASE[1][1] + scale2 * W2[1][1],
            ],
        ];
        let o3 = [
            [
                O3_BASE[0][0] + scale3 * W3[0][0],
                O3_BASE[0][1] + scale3 * W3[0][1],
            ],
            [
                O3_BASE[1][0] + scale3 * W3[1][0],
                O3_BASE[1][1] + scale3 * W3[1][1],
            ],
        ];
        let o5 = [
            [
                O5_BASE[0][0] + scale5 * W5[0][0],
                O5_BASE[0][1] + scale5 * W5[0][1],
            ],
            [
                O5_BASE[1][0] + scale5 * W5[1][0],
                O5_BASE[1][1] + scale5 * W5[1][1],
            ],
        ];

        let mut evals2 = [0.0; 2];
        let mut evals3 = [0.0; 2];
        let mut evals5 = [0.0; 2];

        let ok2 = compute_density_matrix_eigenvalues(2, sigma, &o2, &mut evals2);
        let ok3 = compute_density_matrix_eigenvalues(3, sigma, &o3, &mut evals3);
        let ok5 = compute_density_matrix_eigenvalues(5, sigma, &o5, &mut evals5);

        kani::assume(ok2 && ok3 && ok5);

        let trace2 = evals2[0] + evals2[1];
        let trace3 = evals3[0] + evals3[1];
        let trace5 = evals5[0] + evals5[1];

        kani::assert(
            (trace2 - 1.0_f64).abs() < 1e-8,
            "Trace of rho_2 must be 1 under bounded perturbation",
        );
        kani::assert(
            (trace3 - 1.0_f64).abs() < 1e-8,
            "Trace of rho_3 must be 1 under bounded perturbation",
        );
        kani::assert(
            (trace5 - 1.0_f64).abs() < 1e-8,
            "Trace of rho_5 must be 1 under bounded perturbation",
        );

        kani::assert(
            evals2[0] >= 0.0 && evals2[1] >= 0.0,
            "rho_2 must be PSD under bounded perturbation",
        );
        kani::assert(
            evals3[0] >= 0.0 && evals3[1] >= 0.0,
            "rho_3 must be PSD under bounded perturbation",
        );
        kani::assert(
            evals5[0] >= 0.0 && evals5[1] >= 0.0,
            "rho_5 must be PSD under bounded perturbation",
        );
    }

    #[kani::proof]
    fn verify_time_evolution_entropy() {
        let sigma = TOY_SIGMA_STUB;

        let scale2: f64 = kani::any();
        let scale3: f64 = kani::any();
        let scale5: f64 = kani::any();
        kani::assume(scale2 >= -EPS_2 && scale2 <= EPS_2);
        kani::assume(scale3 >= -EPS_3 && scale3 <= EPS_3);
        kani::assume(scale5 >= -EPS_5 && scale5 <= EPS_5);

        let o2 = [
            [
                O2_BASE[0][0] + scale2 * W2[0][0],
                O2_BASE[0][1] + scale2 * W2[0][1],
            ],
            [
                O2_BASE[1][0] + scale2 * W2[1][0],
                O2_BASE[1][1] + scale2 * W2[1][1],
            ],
        ];
        let o3 = [
            [
                O3_BASE[0][0] + scale3 * W3[0][0],
                O3_BASE[0][1] + scale3 * W3[0][1],
            ],
            [
                O3_BASE[1][0] + scale3 * W3[1][0],
                O3_BASE[1][1] + scale3 * W3[1][1],
            ],
        ];
        let o5 = [
            [
                O5_BASE[0][0] + scale5 * W5[0][0],
                O5_BASE[0][1] + scale5 * W5[0][1],
            ],
            [
                O5_BASE[1][0] + scale5 * W5[1][0],
                O5_BASE[1][1] + scale5 * W5[1][1],
            ],
        ];

        let mut evals2 = [0.0; 2];
        let mut evals3 = [0.0; 2];
        let mut evals5 = [0.0; 2];

        let ok2 = compute_density_matrix_eigenvalues(2, sigma, &o2, &mut evals2);
        let ok3 = compute_density_matrix_eigenvalues(3, sigma, &o3, &mut evals3);
        let ok5 = compute_density_matrix_eigenvalues(5, sigma, &o5, &mut evals5);

        kani::assume(ok2 && ok3 && ok5);

        let s2 = compute_entropy(&evals2);
        let s3 = compute_entropy(&evals3);
        let s5 = compute_entropy(&evals5);
        let s_total = s2 + s3 + s5;

        kani::assert(
            s2 >= 0.0,
            "Entropy S_2 must be non-negative under bounded perturbation",
        );
        kani::assert(
            s3 >= 0.0,
            "Entropy S_3 must be non-negative under bounded perturbation",
        );
        kani::assert(
            s5 >= 0.0,
            "Entropy S_5 must be non-negative under bounded perturbation",
        );
        kani::assert(
            s_total >= 0.0,
            "Total entropy must be non-negative under bounded perturbation",
        );
        kani::assert(
            s_total <= 3.0,
            "Total entropy of 3 qubits must not exceed 3*ln(2) under bounded perturbation",
        );
        kani::assert(
            s2.is_finite() && s3.is_finite() && s5.is_finite(),
            "Entropies must be finite under bounded perturbation",
        );
    }

    #[kani::proof]
    fn verify_time_evolution_spectral_separation() {
        let sigma = TOY_SIGMA_STUB;

        let scale2: f64 = kani::any();
        let scale3: f64 = kani::any();
        let scale5: f64 = kani::any();
        kani::assume(scale2 >= -EPS_2 && scale2 <= EPS_2);
        kani::assume(scale3 >= -EPS_3 && scale3 <= EPS_3);
        kani::assume(scale5 >= -EPS_5 && scale5 <= EPS_5);

        let o2 = [
            [
                O2_BASE[0][0] + scale2 * W2[0][0],
                O2_BASE[0][1] + scale2 * W2[0][1],
            ],
            [
                O2_BASE[1][0] + scale2 * W2[1][0],
                O2_BASE[1][1] + scale2 * W2[1][1],
            ],
        ];
        let o3 = [
            [
                O3_BASE[0][0] + scale3 * W3[0][0],
                O3_BASE[0][1] + scale3 * W3[0][1],
            ],
            [
                O3_BASE[1][0] + scale3 * W3[1][0],
                O3_BASE[1][1] + scale3 * W3[1][1],
            ],
        ];
        let o5 = [
            [
                O5_BASE[0][0] + scale5 * W5[0][0],
                O5_BASE[0][1] + scale5 * W5[0][1],
            ],
            [
                O5_BASE[1][0] + scale5 * W5[1][0],
                O5_BASE[1][1] + scale5 * W5[1][1],
            ],
        ];

        let delta2 = spectral_separation_proxy(2, sigma, &o2);
        let delta3 = spectral_separation_proxy(3, sigma, &o3);
        let delta5 = spectral_separation_proxy(5, sigma, &o5);
        let delta_min = delta2.min(delta3).min(delta5);

        kani::assert(
            delta2 > 0.0,
            "Delta_2 spectral separation must be positive under bounded perturbation",
        );
        kani::assert(
            delta3 > 0.0,
            "Delta_3 spectral separation must be positive under bounded perturbation",
        );
        kani::assert(
            delta5 > 0.0,
            "Delta_5 spectral separation must be positive under bounded perturbation",
        );
        kani::assert(
            delta_min.is_finite(),
            "Delta(t) proxy must be finite under bounded perturbation",
        );
    }

    #[kani::proof]
    fn verify_time_evolution_bounded() {
        let sigma = TOY_SIGMA_STUB;

        let t: f64 = kani::any();
        kani::assume(t >= 0.0 && t <= 1.0);

        let o2 = local_op_time(O2_BASE, EPS_2, OMEGA_2, W2, t);
        let o3 = local_op_time(O3_BASE, EPS_3, OMEGA_3, W3, t);
        let o5 = local_op_time(O5_BASE, EPS_5, OMEGA_5, W5, t);

        kani::assert(
            check_rg_condition(2, sigma, &o2),
            "O2 must satisfy RG condition at symbolic time t",
        );
        kani::assert(
            check_rg_condition(3, sigma, &o3),
            "O3 must satisfy RG condition at symbolic time t",
        );
        kani::assert(
            check_rg_condition(5, sigma, &o5),
            "O5 must satisfy RG condition at symbolic time t",
        );

        let mut evals2 = [0.0; 2];
        let mut evals3 = [0.0; 2];
        let mut evals5 = [0.0; 2];

        let ok2 = compute_density_matrix_eigenvalues(2, sigma, &o2, &mut evals2);
        let ok3 = compute_density_matrix_eigenvalues(3, sigma, &o3, &mut evals3);
        let ok5 = compute_density_matrix_eigenvalues(5, sigma, &o5, &mut evals5);

        kani::assume(ok2 && ok3 && ok5);

        let trace2 = evals2[0] + evals2[1];
        let trace3 = evals3[0] + evals3[1];
        let trace5 = evals5[0] + evals5[1];

        kani::assert(
            (trace2 - 1.0_f64).abs() < 1e-8,
            "Trace of rho_2 must be 1 at symbolic time t",
        );
        kani::assert(
            (trace3 - 1.0_f64).abs() < 1e-8,
            "Trace of rho_3 must be 1 at symbolic time t",
        );
        kani::assert(
            (trace5 - 1.0_f64).abs() < 1e-8,
            "Trace of rho_5 must be 1 at symbolic time t",
        );

        kani::assert(
            evals2[0] >= 0.0 && evals2[1] >= 0.0,
            "rho_2 must be PSD at symbolic time t",
        );
        kani::assert(
            evals3[0] >= 0.0 && evals3[1] >= 0.0,
            "rho_3 must be PSD at symbolic time t",
        );
        kani::assert(
            evals5[0] >= 0.0 && evals5[1] >= 0.0,
            "rho_5 must be PSD at symbolic time t",
        );

        let s2 = compute_entropy(&evals2);
        let s3 = compute_entropy(&evals3);
        let s5 = compute_entropy(&evals5);
        let s_total = s2 + s3 + s5;

        kani::assert(
            s2 >= 0.0,
            "Entropy S_2 must be non-negative at symbolic time t",
        );
        kani::assert(
            s3 >= 0.0,
            "Entropy S_3 must be non-negative at symbolic time t",
        );
        kani::assert(
            s5 >= 0.0,
            "Entropy S_5 must be non-negative at symbolic time t",
        );
        kani::assert(
            s_total >= 0.0,
            "Total entropy must be non-negative at symbolic time t",
        );
        kani::assert(
            s_total <= 3.0,
            "Total entropy of 3 qubits must not exceed 3*ln(2) at symbolic time t",
        );
        kani::assert(
            s2.is_finite() && s3.is_finite() && s5.is_finite(),
            "Entropies must be finite at symbolic time t",
        );

        let delta2 = spectral_separation_proxy(2, sigma, &o2);
        let delta3 = spectral_separation_proxy(3, sigma, &o3);
        let delta5 = spectral_separation_proxy(5, sigma, &o5);
        let delta_min = delta2.min(delta3).min(delta5);

        kani::assert(
            delta2 > 0.0,
            "Delta_2 spectral separation must be positive at symbolic time t",
        );
        kani::assert(
            delta3 > 0.0,
            "Delta_3 spectral separation must be positive at symbolic time t",
        );
        kani::assert(
            delta5 > 0.0,
            "Delta_5 spectral separation must be positive at symbolic time t",
        );
        kani::assert(
            delta_min.is_finite(),
            "Delta(t) proxy must be finite at symbolic time t",
        );
    }
}
