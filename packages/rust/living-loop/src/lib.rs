use adr_verifier::{KernelBoundaryConfig, PhaseMirrorRegistry};
use nalgebra::{DMatrix, DVector};
use pirtm_core::audit::AuditChain;
use pirtm_core::gate::{EmissionGate, EmissionPolicy, GatedOutput};
use pirtm_core::spectral::SpectralGovernor;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use thiserror::Error;

pub mod brauer;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/// Canonical prime-to-exponent map (ADR-0008).
///
/// A signature is a fixed-length vector where each entry `s_i` is the
/// exponent of the `i`-th prime in the canonical factorisation of the
/// transition's integer identifier.  Two transitions with identical
/// signatures are structurally equivalent.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Signature {
    pub exponents: Vec<u64>,
}

impl Signature {
    pub fn hash(&self) -> String {
        let bytes: Vec<u8> = self
            .exponents
            .iter()
            .flat_map(|e| e.to_le_bytes())
            .collect();
        hex::encode(Sha256::digest(&bytes))
    }

    pub fn is_canonical(&self) -> bool {
        self.exponents.iter().all(|&e| e < 1 << 32)
    }
}

/// The spectral-radius bound below which contraction is certified.
const DEFAULT_RHO_CEILING: f64 = 1.0;

pub use brauer::{brauer_ovals_strictly_contracting, cassini_radius};

/// How the ContractionWitness was established.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum WitnessProvenance {
    /// All Gershgorin disks lie strictly inside the open unit disk.
    /// Analytic, O(n²), no iteration required.
    AnalyticGershgorin,
    /// Gershgorin inconclusive, but all Brauer ovals of Cassini lie
    /// strictly inside the unit disk.  Analytic, O(n²) pairwise
    /// products, still no iteration.
    AnalyticBrauer,
    /// Both analytic tests inconclusive; power iteration or tighter
    /// bound used.  The witness is numerical with a residual bound.
    Numeric,
}

/// Certificate that the spectral radius of the transition operator is
/// strictly below the ceiling (ADR-0009).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContractionWitness {
    pub spectral_radius: f64,
    pub rho_ceiling: f64,
    pub contracted: bool,
    pub provenance: WitnessProvenance,
    pub max_disk_radius: f64,
    pub gershgorin_stable: bool,
    pub signature_hash: String,
    pub audit_event_hash: String,
}

impl ContractionWitness {
    pub fn hold(reason: &str, signature: &Signature) -> Self {
        Self {
            spectral_radius: f64::NAN,
            rho_ceiling: DEFAULT_RHO_CEILING,
            contracted: false,
            provenance: WitnessProvenance::Numeric,
            max_disk_radius: f64::NAN,
            gershgorin_stable: false,
            signature_hash: signature.hash(),
            audit_event_hash: reason.to_string(),
        }
    }
}

/// Configuration for a single loop iteration.
pub struct LoopParams {
    /// Transition operator matrix (xi_t).
    pub xi: DMatrix<f64>,
    /// Resonance coupling matrix (lambda_t).
    pub lambda: DMatrix<f64>,
    /// State vector at time t.
    pub x_t: DVector<f64>,
    /// Nonlinear operator T(x).
    pub t_op: fn(&DVector<f64>) -> DVector<f64>,
    /// Projection operator P(x).
    pub p_op: fn(&DVector<f64>) -> DVector<f64>,
    /// Operator norm ||T||.
    pub op_norm: f64,
    /// Contraction parameter epsilon.
    pub epsilon: f64,
    /// Current time step.
    pub t: usize,
    /// Emission policy.
    pub emission_policy: EmissionPolicy,
    /// Attenuation floor (only used when policy is Attenuate).
    pub attenuation_floor: f64,
}

/// Result of one loop iteration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoopOutput {
    pub gated: GatedOutput,
    pub witness: ContractionWitness,
    pub audit_entry_json: String,
    pub emitted: bool,
}

/// The audit-chain entry enriched with provenance metadata.
/// This is what gets serialized to `audit_entry_json`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EnrichedAuditEntry {
    /// Sequence number in the chain.
    pub sequence: usize,
    /// SHA-256 hash of this event.
    pub event_hash: String,
    /// Running chain hash.
    pub chain_hash: String,
    /// Step info from the recurrence.
    pub step: usize,
    pub q: f64,
    pub epsilon: f64,
    pub n_xi: f64,
    pub n_lam: f64,
    pub projected: bool,
    pub residual: f64,
    // --- provenance fields (ADR-0009) ---
    pub provenance: WitnessProvenance,
    pub spectral_radius: f64,
    pub max_disk_radius: f64,
    pub contracted: bool,
}

/// Failure modes for the living loop.
#[derive(Debug, Error)]
pub enum LoopError {
    #[error("ADR boundary violation: {0}")]
    BoundaryViolation(String),

    #[error("Signature not canonical: exponents exceed 2^32")]
    NonCanonicalSignature,

    #[error("Registry JSON parse error: {0}")]
    RegistryParse(String),

    #[error("Registry file not found: {0}")]
    RegistryNotFound(String),

    #[error("Emission gate suppressed output")]
    GateSuppressed,
}

// ---------------------------------------------------------------------------
// Pipeline
// ---------------------------------------------------------------------------

/// Run one iteration of the living loop.
///
/// 1. Validate ADR boundary (fail-fast).
/// 2. Check signature is canonical.
/// 3. Compute spectral radius via SpectralGovernor.
/// 4. Emit ContractionWitness if ρ < 1.
/// 5. Pass through EmissionGate (accept / attenuate / hold / suppress).
/// 6. Seal with AuditChain.
/// 7. Return LoopOutput or LoopError.
pub fn run_loop(
    params: &LoopParams,
    signature: &Signature,
    registry_json: &str,
    audit_chain: &mut AuditChain,
) -> Result<LoopOutput, LoopError> {
    // 1. ADR boundary guard
    let registry =
        PhaseMirrorRegistry::from_json_str(registry_json)
            .map_err(|e| LoopError::RegistryParse(e.to_string()))?;
    let config = KernelBoundaryConfig::default();
    if let Err(violation) = registry.verify_boundary(&config) {
        return Err(LoopError::BoundaryViolation(violation.to_string()));
    }

    // 2. Canonical signature check
    if !signature.is_canonical() {
        return Err(LoopError::NonCanonicalSignature);
    }

    // 3. Spectral radius computation
    let xi_vecs: Vec<Vec<f64>> = (0..params.xi.nrows())
        .map(|i| (0..params.xi.ncols()).map(|j| params.xi[(i, j)]).collect())
        .collect();
    let metrics = SpectralGovernor::hybrid_spectral_radius(&xi_vecs);
    let rho = metrics.spectral_radius;

    // 4. Contraction witness — hybrid cascade:
    //    Gershgorin (cheapest) → Brauer (tighter, still analytic) → Numeric
    let gershgorin = SpectralGovernor::gershgorin_disks_from_matrix(&params.xi);
    let contracted = rho < DEFAULT_RHO_CEILING;

    // Gershgorin: all disks strictly inside unit disk
    let gershgorin_proves = gershgorin.is_stable
        && gershgorin
            .disks
            .iter()
            .all(|d| d.center.abs() + d.radius < DEFAULT_RHO_CEILING);

    // Brauer: all Cassini ovals strictly inside unit disk (O(n²), still analytic)
    let brauer_proves = if gershgorin_proves {
        false // Gershgorin already sufficient; skip O(n²) check
    } else {
        brauer_ovals_strictly_contracting(&params.xi)
    };

    let provenance = if gershgorin_proves {
        WitnessProvenance::AnalyticGershgorin
    } else if brauer_proves {
        WitnessProvenance::AnalyticBrauer
    } else {
        WitnessProvenance::Numeric
    };

    // 5. Emission gate
    let gate = EmissionGate::new(params.emission_policy, None, params.attenuation_floor);
    let gated = gate.call(
        &params.x_t,
        &params.xi,
        &params.lambda,
        params.t_op,
        &DVector::zeros(params.x_t.len()), // g_t placeholder
        params.p_op,
        params.epsilon,
        params.op_norm,
        params.t,
    );

    // 6. Audit seal
    let audit_event = audit_chain.append_step(&gated.info);

    // 7. Build witness
    let max_disk_radius = gershgorin
        .disks
        .iter()
        .map(|d| d.radius)
        .fold(0.0_f64, f64::max);
    let witness = ContractionWitness {
        spectral_radius: rho,
        rho_ceiling: DEFAULT_RHO_CEILING,
        contracted,
        provenance,
        max_disk_radius,
        gershgorin_stable: gershgorin.is_stable,
        signature_hash: signature.hash(),
        audit_event_hash: audit_event.event_hash.clone(),
    };

    // 8. Enriched audit entry — provenance + radius in the chain
    let enriched = EnrichedAuditEntry {
        sequence: audit_event.sequence,
        event_hash: audit_event.event_hash.clone(),
        chain_hash: audit_event.chain_hash.clone(),
        step: gated.info.step,
        q: gated.info.q,
        epsilon: gated.info.epsilon,
        n_xi: gated.info.n_xi,
        n_lam: gated.info.n_lam,
        projected: gated.info.projected,
        residual: gated.info.residual,
        provenance,
        spectral_radius: rho,
        max_disk_radius,
        contracted,
    };

    let emitted = gated.emitted;

    Ok(LoopOutput {
        gated,
        witness,
        audit_entry_json: serde_json::to_string(&enriched).unwrap_or_default(),
        emitted,
    })
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;
    use pirtm_core::gate::EmissionPolicy;

    fn identity_op(x: &DVector<f64>) -> DVector<f64> {
        x.clone()
    }

    fn identity_proj(x: &DVector<f64>) -> DVector<f64> {
        x.clone()
    }

    fn stable_params() -> LoopParams {
        let dim = 3;
        // Diagonal matrix with spectral radius 0.5
        let xi = DMatrix::from_diagonal(&DVector::from_vec(vec![0.5, 0.5, 0.5]));
        let lambda = DMatrix::zeros(dim, dim);
        let x_t = DVector::from_vec(vec![1.0, 0.5, -0.3]);

        LoopParams {
            xi,
            lambda,
            x_t,
            t_op: identity_op,
            p_op: identity_proj,
            op_norm: 1.0,
            epsilon: 0.1,
            t: 1,
            emission_policy: EmissionPolicy::PassThrough,
            attenuation_floor: 0.1,
        }
    }

    fn clean_registry_json() -> String {
        serde_json::json!({
            "version": "2.0",
            "generated_utc": "2026-08-25T00:00:00Z",
            "lean": {
                "decls": 1200,
                "sorry_total": 195,
                "sorry_manifested": true,
                "axioms_total": 441,
                "axioms_postulates": 155,
                "axioms_manifested": true,
                "mathlib_imports": 0
            },
            "manifest": {
                "entries": 620,
                "permitted_leaves": 606,
                "drift": 0,
                "overdue": 0,
                "reentrant_adrs": 0
            },
            "tensions": {
                "open": 0,
                "total_score": 0.0
            },
            "plan_adrs": []
        })
        .to_string()
    }

    #[test]
    fn test_signature_hash_deterministic() {
        let sig = Signature {
            exponents: vec![1, 0, 2, 0, 3],
        };
        assert_eq!(sig.hash(), sig.hash());
        assert!(sig.is_canonical());
    }

    #[test]
    fn test_signature_non_canonical() {
        let sig = Signature {
            exponents: vec![1, 1 << 32, 0],
        };
        assert!(!sig.is_canonical());
    }

    #[test]
    fn test_contraction_witness_holds() {
        let sig = Signature { exponents: vec![0] };
        let w = ContractionWitness::hold("test reason", &sig);
        assert!(!w.contracted);
        assert_eq!(w.audit_event_hash, "test reason");
    }

    #[test]
    fn test_run_loop_clean_registry() {
        let params = stable_params();
        let sig = Signature {
            exponents: vec![1, 0, 1],
        };
        let mut chain = AuditChain::new();

        let result = run_loop(&params, &sig, &clean_registry_json(), &mut chain);
        assert!(result.is_ok(), "loop should succeed with clean registry");

        let out = result.unwrap();
        assert!(out.witness.contracted, "spectral radius should be < 1");
        assert!(out.witness.gershgorin_stable);
        assert_eq!(out.witness.provenance, WitnessProvenance::AnalyticGershgorin);
        assert!(out.witness.max_disk_radius < 1.0);
        assert!(!out.audit_entry_json.is_empty());
    }

    #[test]
    fn test_run_loop_boundary_violation() {
        let params = stable_params();
        let sig = Signature {
            exponents: vec![1, 0, 1],
        };
        let mut chain = AuditChain::new();

        // Registry with drift > 0 → boundary violation
        let bad_registry = serde_json::json!({
            "version": "2.0",
            "generated_utc": "2026-08-25T00:00:00Z",
            "lean": {
                "decls": 1200,
                "sorry_total": 195,
                "sorry_manifested": true,
                "axioms_total": 441,
                "axioms_postulates": 155,
                "axioms_manifested": true,
                "mathlib_imports": 0
            },
            "manifest": {
                "entries": 620,
                "permitted_leaves": 606,
                "drift": 1,
                "overdue": 0,
                "reentrant_adrs": 0
            },
            "tensions": {
                "open": 0,
                "total_score": 0.0
            },
            "plan_adrs": []
        })
        .to_string();

        let result = run_loop(&params, &sig, &bad_registry, &mut chain);
        assert!(result.is_err());
        match result.unwrap_err() {
            LoopError::BoundaryViolation(_) => {}
            other => panic!("expected BoundaryViolation, got {:?}", other),
        }
    }

    #[test]
    fn test_run_loop_non_canonical_signature() {
        let params = stable_params();
        let sig = Signature {
            exponents: vec![1, 1 << 32],
        };
        let mut chain = AuditChain::new();

        let result = run_loop(&params, &sig, &clean_registry_json(), &mut chain);
        assert!(matches!(result, Err(LoopError::NonCanonicalSignature)));
    }

    #[test]
    fn test_run_loop_registry_not_found() {
        let params = stable_params();
        let sig = Signature { exponents: vec![0] };
        let mut chain = AuditChain::new();

        let result = run_loop(&params, &sig, "{invalid json", &mut chain);
        assert!(matches!(result, Err(LoopError::RegistryParse(_))));
    }

    #[test]
    fn test_run_loop_unstable_operator() {
        // Spectral radius > 1 → witness.contracted = false
        let dim = 2;
        let xi = DMatrix::from_diagonal(&DVector::from_vec(vec![1.5, 0.5]));
        let params = LoopParams {
            xi,
            lambda: DMatrix::zeros(dim, dim),
            x_t: DVector::from_vec(vec![1.0, 0.0]),
            t_op: identity_op,
            p_op: identity_proj,
            op_norm: 1.0,
            epsilon: 0.1,
            t: 1,
            emission_policy: EmissionPolicy::PassThrough,
            attenuation_floor: 0.1,
        };
        let sig = Signature { exponents: vec![1] };
        let mut chain = AuditChain::new();

        let out = run_loop(&params, &sig, &clean_registry_json(), &mut chain).unwrap();
        assert!(!out.witness.contracted, "ρ=1.5 should not contract");
        assert!(out.witness.spectral_radius > 1.0);
        // Gershgorin disks at center=1.5, radius=0 — outside unit disk
        assert_eq!(out.witness.provenance, WitnessProvenance::Numeric);
    }

    #[test]
    fn test_run_loop_brauer_path() {
        // 3×3 non-symmetric matrix where Gershgorin fails but Brauer succeeds:
        // Row 0: center=0.9, radius=0.3 → |0.9|+0.3=1.2 > 1 (fails)
        // Pair (0,1): alpha=0.9, beta=0.9, gamma=0.3*0.0=0.0
        //   r_ij = 0.5*(1.8 + 0) = 0.9 < 1 (passes)
        // Eigenvalues: 0.9, 0.9, 0.5 → ρ = 0.9 < 1
        let xi = DMatrix::from_row_slice(
            3,
            3,
            &[
                0.9, 0.3, 0.0, // row 0: R_0 = 0.3
                0.0, 0.9, 0.0, // row 1: R_1 = 0.0
                0.0, 0.0, 0.5, // row 2: R_2 = 0.0
            ],
        );
        let params = LoopParams {
            xi,
            lambda: DMatrix::zeros(3, 3),
            x_t: DVector::from_vec(vec![1.0, 0.0, 0.0]),
            t_op: identity_op,
            p_op: identity_proj,
            op_norm: 1.0,
            epsilon: 0.1,
            t: 1,
            emission_policy: EmissionPolicy::PassThrough,
            attenuation_floor: 0.1,
        };
        let sig = Signature { exponents: vec![1] };
        let mut chain = AuditChain::new();

        let out = run_loop(&params, &sig, &clean_registry_json(), &mut chain).unwrap();
        assert!(out.witness.contracted, "ρ=0.9 should contract");
        assert_eq!(out.witness.provenance, WitnessProvenance::AnalyticBrauer);
        assert!(out.witness.max_disk_radius > 0.9); // Gershgorin radius > 0.9
    }

    #[test]
    fn test_run_loop_attenuate_policy() {
        let mut params = stable_params();
        params.emission_policy = EmissionPolicy::Attenuate;
        params.attenuation_floor = 0.5;

        let sig = Signature { exponents: vec![1] };
        let mut chain = AuditChain::new();

        let out = run_loop(&params, &sig, &clean_registry_json(), &mut chain).unwrap();
        assert!(out.witness.contracted);
        // Attenuation may or may not emit depending on residual, but loop completes
        assert!(!out.audit_entry_json.is_empty());
    }

    #[test]
    fn test_run_loop_multiple_steps_audit_chain_grows() {
        let params = stable_params();
        let sig = Signature { exponents: vec![1] };
        let mut chain = AuditChain::new();

        for t in 0..5 {
            let mut p = stable_params();
            p.t = t;
            run_loop(&p, &sig, &clean_registry_json(), &mut chain).unwrap();
        }
        // AuditChain should have 5 events
        let chain_json = serde_json::to_string(&chain).unwrap();
        assert!(chain_json.contains("\"sequence\":0"));
        assert!(chain_json.contains("\"sequence\":4"));
    }
}
