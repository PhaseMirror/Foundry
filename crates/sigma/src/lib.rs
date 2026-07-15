use archivum::{ArchivumError, ConflictLogSchema};
pub use archivum::{TransitionBlock, WitnessLedger};
use postcard::{from_bytes, to_allocvec};
use std::fs;
use std::sync::Arc;
use thiserror::Error;
use tracing::{info, Level};

#[macro_use]
mod logging;

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct StateTransition {
    pub id: String,
    pub r_sc: f64,
    pub l_eff: f64,
}

include!(concat!(env!("OUT_DIR"), "/thresholds.rs"));

impl Thresholds {


    pub fn from_json_file(path: &str) -> Result<Self, ArchivumError> {
        let contents = fs::read_to_string(path)?;
        let t: Self = serde_json::from_str(&contents)?;
        Self::validate(&t).map_err(|e| ArchivumError::Validation(e))?;
        Ok(t)
    }

    pub fn to_postcard(&self) -> Vec<u8> {
        to_allocvec(self).expect("postcard serialization")
    }

    pub fn from_postcard(bytes: &[u8]) -> Result<Self, postcard::Error> {
        Ok(from_bytes(bytes)?)
    }

    pub fn validate(t: &Self) -> Result<(), String> {
        if !(0.0 < t.tau_r && t.tau_r < 100.0) {
            return Err(format!("tau_r={} outside (0,100)", t.tau_r));
        }
        if !(0.0 < t.l_eff_max && t.l_eff_max < 10.0) {
            return Err(format!("max_l_eff={} outside (0,10)", t.l_eff_max));
        }
        if !(t.rpi_upper >= 1 && t.rpi_upper <= 7) {
            return Err(format!("rpi_upper={} outside [1,7]", t.rpi_upper));
        }
        if t.lambda1_positive != true {
            return Err("lambda1_positive must be true".into());
        }
        if t.atlas_signature != (10, 14) {
            return Err(format!("atlas_signature={:?} != (10,14)", t.atlas_signature));
        }
        if !(t.contractivity_margin > 0.0 && t.contractivity_margin < 1.0) {
            return Err(format!("contractivity_margin={} outside (0,1)", t.contractivity_margin));
        }
        Ok(())
    }
}

pub struct DissonanceCheck {
    pub passes_tau_r: bool,
    pub passes_l_eff: bool,
    pub r_sc: f64,
    pub l_eff: f64,
}

pub struct PolicyEngine;

impl PolicyEngine {
    pub fn new() -> Self {
        Self
    }
    
    pub fn run(&self, transition: &StateTransition, thresholds: &Thresholds) -> DissonanceCheck {
        DissonanceCheck {
            passes_tau_r: (transition.r_sc - thresholds.tau_r).abs() < 1e-6,
            passes_l_eff: transition.l_eff < thresholds.l_eff_max,
            r_sc: transition.r_sc,
            l_eff: transition.l_eff,
        }
    }
}

#[derive(Debug, Error)]
pub enum DissonanceError {
    #[error("Threshold Violation: R_sc={r_sc}, L_eff={l_eff}")]
    ThresholdViolation { r_sc: f64, l_eff: f64 },
}

impl DissonanceError {
    pub fn breach_type(&self) -> &'static str {
        match self {
            Self::ThresholdViolation { .. } => "ThresholdViolation",
        }
    }
}

pub struct SigmaKernel {
    engine: Arc<PolicyEngine>,
    ledger: WitnessLedger,
    thresholds: Thresholds,
}

impl SigmaKernel {
    pub fn new(engine: PolicyEngine, ledger: WitnessLedger, thresholds: Thresholds) -> Self {
        Self {
            engine: Arc::new(engine),
            ledger,
            thresholds,
        }
    }

    pub fn from_lean_export(engine: PolicyEngine, ledger: WitnessLedger, postcard_path: &str, json_path: &str) -> Self {
        match std::fs::read(postcard_path) {
            Ok(bytes) => {
                match Thresholds::from_postcard(&bytes) {
                    Ok(thresholds) => {
                        log_threshold_load!("✅", "postcard zero-copy");
                        Self::new(engine, ledger, thresholds)
                    }
                    Err(e) => {
                        log_deser_detail!(Level::ERROR, e, postcard_path, bytes.len(), "zero-copy failure");
                        Self::load_json_fallback(engine, ledger, json_path)
                    }
                }
            }
            Err(_) => {
                info!("Postcard file missing, falling back to JSON");
                Self::load_json_fallback(engine, ledger, json_path)
            }
        }
    }

    fn load_json_fallback(engine: PolicyEngine, ledger: WitnessLedger, json_path: &str) -> Self {
        match Thresholds::from_json_file(json_path) {
            Ok(thresholds) => {
                log_threshold_load!("✅", "json fallback");
                Self::new(engine, ledger, thresholds)
            }
            Err(e) => {
                log_error!(e, file = json_path, context = "json fallback failed");
                let thresholds = Thresholds::default();
                Self::new(engine, ledger, thresholds)
            }
        }
    }

    pub fn evaluate(&mut self, transition: StateTransition) -> Result<TransitionBlock, DissonanceError> {
        log_governed_transition!(&transition.id, "pending");
        
        let check = self.engine.run(&transition, &self.thresholds);
        
        // 1. Construct the SpectralState from the evaluated transitions.
        let state = SpectralState {
            resonance_functional: check.r_sc,
            drift: check.r_sc - self.thresholds.r_sc_reference, // Using a basic drift proxy for now
            effective_lipschitz: check.l_eff,
        };

        // 2. Guardian Lock: Pass through sigma_check
        let witness_result = sigma_check(&state, self.thresholds.tau_r);

        match witness_result {
            Ok(witness) => {
                // Emit Archivum Witness (Examiner lock evidence)
                let proof = archivum::SigmaProof::new(
                    hex::encode(witness.state_hash),
                    witness.invariant_holds,
                    format!("{:?}", witness.dissonance_level),
                );
                let _ = self.ledger.stamp_sigma_proof(&proof);

                let block = TransitionBlock::new_ratified(transition.id);
                self.ledger.append_block(&block).map_err(|_| DissonanceError::ThresholdViolation { r_sc: check.r_sc, l_eff: check.l_eff })?;
                Ok(block)
            }
            Err(SigmaViolation::InvariantBreach { l_eff, drift }) => {
                let breach_type = if l_eff >= 1.0 { "LipschitzContraction".to_string() } else { "ResonanceDelta".to_string() };
                log_dissonance_trap!(transition.id, breach_type, format!("R_sc={}, L_eff={}, drift={}", check.r_sc, check.l_eff, drift));
                let log = ConflictLogSchema::new(&transition.id, check.r_sc, check.l_eff, self.thresholds.tau_r, breach_type);
                
                let md_log = mirror_dissonance::schemas::ConflictLogSchema {
                    receipt_hash: log.receipt_hash.clone(),
                    r_sc: log.r_sc,
                    l_eff: log.l_eff,
                    tau_r: log.tau_r,
                    breach_type: log.breach_type.clone(),
                    timestamp: chrono::Utc::now().to_rfc3339(),
                };
                let violations = mirror_dissonance::check_physical_dissonance(&md_log);
                if !violations.is_empty() {
                    let _ = self.ledger.stamp_pweh(&log);
                }
                Err(DissonanceError::ThresholdViolation { r_sc: check.r_sc, l_eff: check.l_eff })
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sigma_kernel_binding() {
        let engine = PolicyEngine::new();
        let ledger = WitnessLedger::new("test_witnesses.jsonl");
        let thresholds = Thresholds::default();
        let mut kernel = SigmaKernel::new(engine, ledger, thresholds);

        // Pass case
        let pass_tx = StateTransition {
            id: "tx-pass-201".to_string(),
            r_sc: 47.06998778,
            l_eff: 0.15,
        };
        let block = kernel.evaluate(pass_tx).unwrap();
        assert!(block.ratified);
        assert!(kernel.ledger.contains_pweh_for(&block));

        // Violation case (force L_eff breach)
        let fail_tx = StateTransition {
            id: "tx-fail-101".to_string(),
            r_sc: 47.06998778,
            l_eff: 1.5,
        };
        let err = kernel.evaluate(fail_tx).unwrap_err();
        assert!(matches!(err, DissonanceError::ThresholdViolation { .. }));
        assert!(kernel.ledger.has_conflict_log());
    }

    #[test]
    fn test_tau_r_violation() {
        let engine = PolicyEngine::new();
        let ledger = WitnessLedger::new("test_witnesses_tau.jsonl");
        let thresholds = Thresholds::default();
        let mut kernel = SigmaKernel::new(engine, ledger, thresholds);

        let fail_tx = StateTransition {
            id: "tx-tau-fail".to_string(),
            r_sc: 1000.0, // High r_sc to force a tau_r drift violation
            l_eff: 0.5,
        };
        let err = kernel.evaluate(fail_tx).unwrap_err();
        assert!(matches!(err, DissonanceError::ThresholdViolation { .. }));
    }

    #[test]
    fn test_logging_macros_compile() {
        let _ = log_deser_detail!(Level::ERROR, "test", "file", 10, "ctx");
        log_threshold_load!("ok", "postcard");
        log_governed_transition!("tx-1", "pweh-1");
        log_dissonance_trap!("tx-2", "trap", "details");
        log_validation_failure!("field", 42, 7);
        log_error!("err", field = "value");
    }
}

// --- ADR-062 SigmaKernel Production Implementation ---

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SpectralState {
    pub resonance_functional: f64,
    pub drift: f64,
    pub effective_lipschitz: f64,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, PartialEq)]
pub enum DissonanceLevel {
    Safe,
    Warning,
    Critical,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SigmaWitness {
    pub state_hash: [u8; 32],
    pub invariant_holds: bool,
    pub dissonance_level: DissonanceLevel,
    pub timestamp: i64,
}

pub enum SigmaViolation {
    InvariantBreach { l_eff: f64, drift: f64 },
}

pub fn sigma_check(
    state: &SpectralState,
    tau_r: f64,
) -> Result<SigmaWitness, SigmaViolation> {
    let invariant_holds = state.effective_lipschitz < 1.0 && state.drift <= tau_r;
    
    let dissonance = match () {
        _ if state.effective_lipschitz >= 1.0 => DissonanceLevel::Critical,
        _ if state.drift > tau_r => DissonanceLevel::Critical,
        _ if state.drift > 0.9 * tau_r => DissonanceLevel::Warning,
        _ => DissonanceLevel::Safe,
    };
    
    if !invariant_holds {
        return Err(SigmaViolation::InvariantBreach {
            l_eff: state.effective_lipschitz,
            drift: state.drift,
        });
    }
    
    let witness = SigmaWitness {
        state_hash: blake3::hash(&serde_json::to_vec(state).unwrap()).into(),
        invariant_holds,
        dissonance_level: dissonance.clone(),
        timestamp: chrono::Utc::now().timestamp(),
    };

    Ok(witness)
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn verify_sigma_check_soundness() {
        let r_sc: f64 = kani::any();
        let drift: f64 = kani::any();
        let l_eff: f64 = kani::any();
        let tau_r: f64 = kani::any();
        
        kani::assume(r_sc.is_finite() && drift.is_finite() && l_eff.is_finite() && tau_r.is_finite());
        kani::assume(tau_r > 0.0);
        
        let state = SpectralState {
            resonance_functional: r_sc,
            drift,
            effective_lipschitz: l_eff,
        };
        
        let result = sigma_check(&state, tau_r);
        
        match result {
            Ok(witness) => {
                kani::assert(l_eff < 1.0, "Effective Lipschitz must be strictly less than 1.0 on success");
                kani::assert(drift <= tau_r, "Drift must be less than or equal to tau_r on success");
                kani::assert(witness.invariant_holds, "Witness must correctly record that invariants hold");
                kani::assert(witness.dissonance_level != DissonanceLevel::Critical, "Witness cannot record Critical on success");
            }
            Err(_) => {
                kani::assert(l_eff >= 1.0 || drift > tau_r, "Sigma Kernel rejected a valid state transition");
            }
        }
    }
}
