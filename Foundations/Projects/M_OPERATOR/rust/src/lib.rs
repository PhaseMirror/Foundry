//! `m-operator-rust` — Production-grade execution and verification engine for the Multiplicity Operator (M) C*-Algebra and CSL Dynamics.
//!
//! # Architecture
//!
//! - **Core Foundations (`core`):** Multiplicity constants ($\phi \approx 1.618, \lambda_m \approx 0.618, \delta_I \approx 0.382$), 3D vector algebra $\mathbb{R}^3$, and agent representations.
//! - **Transformation Algebra (`algebra`):** Multiplicity Operator $T_{p_i}(M)$, non-linear regularization $R_{\text{nl}}$, self-referential gradient transformation $\delta_I \nabla T$, and fractal residuals.
//! - **Categorical Semantic Lawfulness (`csl`):** Multi-agent simulation substrate ($N=100$ agents, $T=100$ steps), linear vs cubic repair protocols, ethical drift $\delta_E$, and Shannon entropy $H_{\text{ethics}}$.
//! - **Quantum Multiplicity Intelligence (`qmi`):** Quantum Bayesian Networks (QBNs), unitary rotation evolution $U_q = e^{-i q H}$, and recursive weight optimization.
//! - **Cryptographic Audit Trail (`witness`):** Deterministic SHA-256 `UnifiedWitness` generation and Subsystem Certification.

pub mod core;
pub mod algebra;
pub mod csl;
pub mod qmi;
pub mod witness;

// Top-level public re-exports
pub use crate::core::{
    MVector3, AgentState, PHI, LAMBDA_M, DELTA_I, ALPHA_NL, EPSILON_CSL, FP_DEN,
};
pub use crate::algebra::{
    MOperatorOutput, evaluate_m_operator, nonlinear_regularization,
    self_referential_term, fractal_residual, iterate_normalized_m_operator,
};
pub use crate::csl::{
    CSLSimulationConfig, CSLSimulationSummary, RepairProtocol,
    compute_repair_1d, compute_repair_3d, compute_peer_coupling,
    step_multi_agent_csl, calculate_ethical_entropy, run_csl_benchmark,
    CSLValidationResult, validate_csl_agent_transition,
};
pub use crate::qmi::{
    Complex64, QBNState, quantum_bayesian_update, apply_unitary_rotation,
    qmi_step, recursive_weight_update,
};
pub use crate::witness::{
    UnifiedWitness, generate_unified_witness, SubsystemCertificate,
};
