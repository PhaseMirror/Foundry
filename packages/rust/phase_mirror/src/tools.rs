// src/tools.rs
use once_cell::sync::Lazy;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Comprehensive set of tools the agent can invoke.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub enum Tool {
    ApplyDRMMOperator,
    VerifyDRMMProof,
    NormalizePrimeWeights,
    CheckContraction,
    ComputeFixedPoint,
    SpectralEstimate,
    TensorReduce,
    ExportLeanCertificate,
    ImportLeanTheorem,
    // Future extensions…
}

/// Mapping from CNL verb strings to tools.
pub static TOOL_REGISTRY: Lazy<HashMap<&'static str, Tool>> = Lazy::new(|| {
    let mut m = HashMap::new();
    m.insert("apply_drmm", Tool::ApplyDRMMOperator);
    m.insert("verify_drmm", Tool::VerifyDRMMProof);
    m.insert("normalize_prime_weights", Tool::NormalizePrimeWeights);
    m.insert("check_contraction", Tool::CheckContraction);
    m.insert("compute_fixed_point", Tool::ComputeFixedPoint);
    m.insert("spectral_estimate", Tool::SpectralEstimate);
    m.insert("tensor_reduce", Tool::TensorReduce);
    m.insert("export_lean_certificate", Tool::ExportLeanCertificate);
    m.insert("import_lean_theorem", Tool::ImportLeanTheorem);
    m
});

/// Four‑gate predicate stub – in production this consults the Sedona Spine engine.
pub fn four_gate_check(tool: &Tool) -> bool {
    // TODO: integrate with Rust → SDK → CONTRACT → UI chain.
    let _ = tool; // silence unused warning
    true
}
