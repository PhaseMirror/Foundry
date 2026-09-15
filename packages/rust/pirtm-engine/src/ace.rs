//! Arithmetic Control Engine (ACE) — the `SIG_GOV_KILL` veto gate.
//!
//! ADR-0066 §"The Veto Gate": when PrismPM attempts to package a
//! semantically-valid artifact, the pipeline invokes the PIRTM L0 verification
//! gate. The adversarial gain matrix Ψ is *expansive* (`ρ(Ψ) ≥ 1 − ε`), so ACE
//! rejects the transition with a fail-closed `SIG_GOV_KILL` halt regardless of
//! the semantic proof outcome.
//!
//! ## Two gates
//!
//! * [`verify_transition`] — float-level spectral-radius gate over the 2×2
//!   `GainMatrix` (the ADR's interop test),
//! * [`evaluate_ace_governance_gate`] — fixed-point gate over the CRMF
//!   envelope metrics (`Λ_m < 1` as `lambda_m < CONTRACTIVITY_SCALE`, mirroring
//!   `crmf::failgate::is_contractive`). This gate is f64-free by design so the
//!   Kani harnesses can model-check it symbolically.

use crate::canonical::UnsignedCrmfEnvelope;
use crate::tensor::{CONTRACTIVITY_SCALE, GainMatrix};

/// Contractivity slack `ε = 10⁻⁶`. A transition is admissible strictly below
/// `1 − ε`; the ADR's adversarial injection targets `ρ(Ψ) ≥ 1 − ε`.
pub const CONTRACTIVITY_EPSILON: f64 = 0.000_001;

/// The absolute contractivity threshold `r(Λ) < 1 − ε`.
#[must_use]
pub const fn contractivity_limit() -> f64 {
    1.0 - CONTRACTIVITY_EPSILON
}

/// Default bounded execution drift limit (scaled `0.03`, matching the
/// runtime's `DEFAULT_MAX_DRIFT` convention).
pub const DRIFT_LIMIT_SCALED: u64 = 30_000_000;

/// Fail-closed halt reason discriminated for audit and Kani assertions.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SigGovKill {
    /// Spectral radius breached the contractivity bound: `ρ(Ψ) ≥ 1 − ε`.
    ExpansiveState,
    /// Fixed-point contractivity invariant exceeded: `Λ_m ≥ 1.0`.
    NonContractiveLambda,
    /// Execution drift exceeded the bounded drift allowance.
    DriftBreach,
    /// The semantic (PrismPM/LexLean) model was not provably valid.
    SemanticProofInvalid,
}

impl SigGovKill {
    #[must_use]
    pub const fn reason(&self) -> &'static str {
        match self {
            Self::ExpansiveState => "SIG_GOV_KILL: expansive state — spectral radius breached the 1−ε contractivity bound",
            Self::NonContractiveLambda => "SIG_GOV_KILL: non-contractive manifold — Λ_m >= 1.0",
            Self::DriftBreach => "SIG_GOV_KILL: drift bound breached",
            Self::SemanticProofInvalid => "SIG_GOV_KILL: semantic proof not dischargeable",
        }
    }
}

/// Spectral radius of a gain matrix (delegates to `tensor::spectral_radius_2x2`).
#[must_use]
pub fn evaluate_spectral_radius(psi: &GainMatrix) -> f64 {
    psi.spectral_radius()
}

/// Fixed-point (scaled integer) spectral radius, for the f64-free governance
/// gates. The float→scaled-integer conversion happens at the telemetry
/// boundary; every downstream gate compares scaled `u64`s only.
#[must_use]
pub fn radius_scaled(psi: &GainMatrix) -> u64 {
    let rho = evaluate_spectral_radius(psi);
    // Saturating conversion: anything ≥ 1.0 maps to ≥ SCALE.
    let scaled = (rho * CONTRACTIVITY_SCALE as f64).round();
    if scaled >= u64::MAX as f64 {
        u64::MAX
    } else if scaled <= 0.0 {
        0
    } else {
        scaled as u64
    }
}

/// The veto gate. A semantically-valid PrismPM model is admitted **only if**
/// the lifted gain matrix is strictly contractive (`ρ(Ψ) < 1 − ε`). Otherwise
/// ACE issues `SigGovKill::ExpansiveState` — fail-closed, even though the Lean 4
/// semantic proofs passed.
pub fn verify_transition(psi: &GainMatrix, semantic_proof_valid: bool) -> Result<(), SigGovKill> {
    if !semantic_proof_valid {
        return Err(SigGovKill::SemanticProofInvalid);
    }
    let rho = evaluate_spectral_radius(psi);
    if rho >= contractivity_limit() {
        Err(SigGovKill::ExpansiveState)
    } else {
        Ok(())
    }
}

/// The fixed-point governance gate over the BCS-serialized failure envelope.
///
/// Fail-closed guarantee (input → output):
/// * `metrics.lambda_m >= CONTRACTIVITY_SCALE` (`Λ_m >= 1.0`) → `Err(ExpansiveState)`;
/// * `metrics.drift > DRIFT_LIMIT_SCALED` → `Err(DriftBreach)`;
/// * otherwise `Ok(())`.
///
/// All comparisons are between scaled `u64`s, making the gate completely
/// deterministic and symbolically model-checkable.
pub fn evaluate_ace_governance_gate(env: &UnsignedCrmfEnvelope) -> Result<(), SigGovKill> {
    if env.metrics.lambda_m >= CONTRACTIVITY_SCALE {
        return Err(SigGovKill::ExpansiveState);
    }
    if env.metrics.drift > DRIFT_LIMIT_SCALED {
        return Err(SigGovKill::DriftBreach);
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::canonical::MetricBounds;
    use crate::tensor::GainMatrix;

    fn env_with(lambda_m: u64, drift: u64) -> UnsignedCrmfEnvelope {
        UnsignedCrmfEnvelope {
            envelope_id: [0; 32],
            timestamp: 0,
            poseidon_commitment: [0; 32],
            sha256_anchor: [0; 32],
            ed25519_signature: [0; 64],
            metrics: MetricBounds { lambda_m, drift },
            metadata: vec![],
        }
    }

    #[test]
    fn contractive_matrix_passes_veto_gate() {
        let mut psi = GainMatrix::new_2x2();
        psi.set_weights(0.25, 0.0, 0.0, 0.5); // ρ = 0.5 < 1−ε
        let result = verify_transition(&psi, true);
        assert_eq!(result, Ok(()));
    }

    /// The ADR's adversarial scenario: semantic proofs valid, gain expansive.
    #[test]
    fn adversarial_expansion_is_vetoed_despite_valid_semantics() {
        let mut psi = GainMatrix::new_2x2();
        psi.set_weights(1.0, 0.5, 0.5, 1.0); // ρ = 1.5 ≥ 1−ε
        let result = verify_transition(&psi, true);
        assert_eq!(result, Err(SigGovKill::ExpansiveState));
    }

    #[test]
    fn invalid_semantics_are_rejected_before_gain_evaluation() {
        let psi = GainMatrix::new_2x2(); // ρ = 0.0, otherwise admissible
        let result = verify_transition(&psi, false);
        assert_eq!(result, Err(SigGovKill::SemanticProofInvalid));
    }

    #[test]
    fn fixed_point_gate_rejects_lambda_at_or_above_one() {
        assert_eq!(
            evaluate_ace_governance_gate(&env_with(1_000_000_000, 0)),
            Err(SigGovKill::ExpansiveState)
        );
        assert_eq!(
            evaluate_ace_governance_gate(&env_with(999_999_999, 0)),
            Ok(())
        );
        assert_eq!(
            evaluate_ace_governance_gate(&env_with(u64::MAX, 0)),
            Err(SigGovKill::ExpansiveState)
        );
    }

    #[test]
    fn fixed_point_gate_rejects_drift_breach() {
        assert_eq!(
            evaluate_ace_governance_gate(&env_with(0, DRIFT_LIMIT_SCALED + 1)),
            Err(SigGovKill::DriftBreach)
        );
        assert_eq!(
            evaluate_ace_governance_gate(&env_with(0, DRIFT_LIMIT_SCALED)),
            Ok(())
        );
    }
}