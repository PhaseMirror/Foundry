//! `lorenz-attractor-rust` — Production-grade execution and verification engine for the Multiplicity-Enhanced Lorenz Attractor.
//!
//! # Architecture & Capabilities
//!
//! - **Core Foundations (`core`):** High-precision floating-point & integer fixed-point representations, LorenzPoint vector algebra, and prime parameter spectrum $(p_1, p_2, p_3)$.
//! - **Spectral & Jacobian Dynamics (`jacobian`):** 3x3 Jacobian evaluation, trace invariant $\operatorname{Tr}(J) = -(\sigma + 1 + \beta)$, eigenvalue multiplicity metric $\Lambda(t)$, and volume contraction verification.
//! - **Coupled Dynamic Solvers (`dynamics`):** 3rd-order tensor interactions $T_{ijk}$, harmonic oscillator feedback, Multiplicity adaptive gain, Euler, and 4th-Order Runge-Kutta (RK4) integrators.
//! - **Cognitive Sovereign Logic Gatekeeper (`csl`):** Fail-closed verification of physical and formal invariants on every state transition.
//! - **Lyapunov & Phase Space Diagnostics (`lyapunov`):** Largest Lyapunov Exponent (LLE) estimator via shadow orbit method, kinetic energy, and boundedness analysis.
//! - **Cryptographic Audit Trail (`witness`):** Deterministic SHA-256 `UnifiedWitness` generation and JSON Subsystem Certification.

pub mod core;
pub mod jacobian;
pub mod dynamics;
pub mod csl;
pub mod lyapunov;
pub mod witness;

// Top-level re-exports for convenient API access
pub use crate::core::{
    LorenzPoint, LorenzParams, PrimeLorenzParams, LorenzState,
    LAMBDA_M, PHI, FP_DEN,
};
pub use crate::jacobian::{
    Jacobian3D, compute_spectral_multiplicity, instantaneous_stability_rate,
};
pub use crate::dynamics::{
    TensorCoupling, HarmonicFeedback, MultiplicityFeedback,
    classical_velocity, unified_velocity, euler_step, rk4_step,
    simulate_trajectory, IntegratorMethod,
};
pub use crate::csl::{
    CSLConstraintConfig, CSLValidationResult, validate_csl_transition,
};
pub use crate::lyapunov::{
    TrajectoryMetrics, estimate_lyapunov_exponent, analyze_trajectory,
};
pub use crate::witness::{
    UnifiedWitness, generate_unified_witness, SubsystemCertificate,
};
