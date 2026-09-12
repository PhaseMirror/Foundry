//! `echo-braid` — Production-grade implementation of the Echo Braid and Floer-Echo-Bundle formalism.
//!
//! Provides:
//! - Prime-indexed spectral weave and tint-bundle representations
//! - Discrete Extended Floer-Echo Differential Operator $\mathcal{F}_{\text{EB}}$
//! - Artin Braid Group Generators $\sigma_i, \sigma_i^{-1}$ and phase entanglement
//! - Picard Contraction Operator $T_\lambda$
//! - Cognitive Feedback Architecture & CSL Constraint Layer
//! - Deterministic UnifiedWitness generation

pub mod gateway;
pub use gateway::*;

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

pub const FP_DEN: u64 = 100;
pub const MAX_PHASE_DEG: u64 = 360;

#[inline]
pub fn fp_mul(a: u64, b: u64) -> u64 {
    (a * b) / FP_DEN
}

#[inline]
pub fn norm_phase(deg: u64) -> u64 {
    deg % MAX_PHASE_DEG
}

/// Perceptual / sensory resonance channel
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TintBundle {
    pub tint_id: u64,
    pub phase_deg: u64,
    pub intensity: u64,
}

/// Harmonic eigenmemory trace
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct EigenMemory {
    pub trace_id: u64,
    pub amplitude: u64,
    pub phase: u64,
}

/// Prime-indexed strand in the Echo Braid bundle
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Strand {
    pub prime: u64,
    pub tint: TintBundle,
    pub eigen: EigenMemory,
    pub position: usize,
}

impl Strand {
    pub fn new(prime: u64, tint_id: u64, phase_deg: u64, intensity: u64, amplitude: u64, pos: usize) -> Self {
        Self {
            prime,
            tint: TintBundle {
                tint_id,
                phase_deg: norm_phase(phase_deg),
                intensity: intensity.min(100),
            },
            eigen: EigenMemory {
                trace_id: prime * 100,
                amplitude: amplitude.min(100),
                phase: norm_phase(phase_deg),
            },
            position: pos,
        }
    }

    pub fn energy(&self) -> u64 {
        fp_mul(self.tint.intensity, self.eigen.amplitude)
    }
}

/// Complete state of the Echo Braid at time step `t`
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct EchoBraidState {
    pub time: u64,
    pub strands: Vec<Strand>,
    pub lambda_m: u64,
    pub spectral_coherence: u64,
}

impl EchoBraidState {
    pub fn new(time: u64, strands: Vec<Strand>, lambda_m: u64, spectral_coherence: u64) -> Self {
        Self {
            time,
            strands,
            lambda_m: lambda_m.min(100),
            spectral_coherence: spectral_coherence.min(100),
        }
    }

    pub fn total_energy(&self) -> u64 {
        self.strands.iter().map(|s| s.energy()).sum()
    }

    pub fn current_prime_sequence(&self) -> Vec<u64> {
        self.strands.iter().map(|s| s.prime).collect()
    }

    pub fn has_distinct_primes(&self) -> bool {
        let mut seen = std::collections::HashSet::new();
        for s in &self.strands {
            if !seen.insert(s.prime) {
                return false;
            }
        }
        true
    }
}

// ---------------------------------------------------------------------------
// 1. Floer-Echo-Bundle Differential Operator
// ---------------------------------------------------------------------------

pub fn apply_symplectic_j(phase_deg: u64) -> u64 {
    norm_phase(phase_deg + 90)
}

pub fn grad_hamiltonian(current: u64, target: u64) -> u64 {
    if current > target {
        (current - target) / 4
    } else {
        (target - current) / 4
    }
}

pub fn grad_potential(s1: &Strand, s2: &Strand) -> u64 {
    let diff = if s1.tint.phase_deg >= s2.tint.phase_deg {
        s1.tint.phase_deg - s2.tint.phase_deg
    } else {
        s2.tint.phase_deg - s1.tint.phase_deg
    };
    (diff * FP_DEN) / MAX_PHASE_DEG
}

pub fn tensor_coeff(p1: u64, p2: u64, lambda_m: u64) -> u64 {
    let sum = p1 + p2;
    if sum == 0 {
        0
    } else {
        (lambda_m * 100 * p1) / (sum * 100)
    }
}

pub fn stochastic_term(t: u64, lambda_m: u64, prime: u64) -> u64 {
    let seed = (t * 37 + prime * 13) % 100;
    fp_mul(seed, 100 - lambda_m) / 10
}

pub fn floer_step_strand(s: &Strand, t: u64, lambda_m: u64, neighbor: Option<&Strand>) -> Strand {
    let target_intensity = 50;
    let h_grad = grad_hamiltonian(s.tint.intensity, target_intensity);
    let new_intensity = if s.tint.intensity > target_intensity {
        s.tint.intensity - h_grad
    } else {
        s.tint.intensity + h_grad
    };

    let p_grad = neighbor.map_or(0, |n| grad_potential(s, n));
    let t_coeff = neighbor.map_or(lambda_m, |n| tensor_coeff(s.prime, n.prime, lambda_m));
    let feedback_mod = fp_mul(t_coeff, p_grad) / 10;

    let noise = stochastic_term(t, lambda_m, s.prime);
    let new_amp = if s.eigen.amplitude + noise >= feedback_mod {
        (s.eigen.amplitude + noise - feedback_mod).min(100)
    } else {
        10
    };

    let new_phase = apply_symplectic_j(s.tint.phase_deg);

    Strand {
        prime: s.prime,
        tint: TintBundle {
            tint_id: s.tint.tint_id,
            phase_deg: new_phase,
            intensity: new_intensity.min(100),
        },
        eigen: EigenMemory {
            trace_id: s.eigen.trace_id,
            amplitude: new_amp,
            phase: new_phase,
        },
        position: s.position,
    }
}

pub fn floer_step(st: &EchoBraidState) -> EchoBraidState {
    let mut new_strands = Vec::with_capacity(st.strands.len());
    let n = st.strands.len();

    for i in 0..n {
        let neighbor = if i + 1 < n { Some(&st.strands[i + 1]) } else { None };
        let updated = floer_step_strand(&st.strands[i], st.time, st.lambda_m, neighbor);
        new_strands.push(updated);
    }

    let avg_amp = if new_strands.is_empty() {
        0
    } else {
        new_strands.iter().map(|s| s.eigen.amplitude).sum::<u64>() / new_strands.len() as u64
    };
    let new_coherence = ((st.spectral_coherence * 8 + avg_amp * 2) / 10).min(100);

    EchoBraidState {
        time: st.time + 1,
        strands: new_strands,
        lambda_m: st.lambda_m,
        spectral_coherence: new_coherence,
    }
}

// ---------------------------------------------------------------------------
// 2. Artin Braid Group Operations
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BraidMove {
    CrossPos(usize),
    CrossNeg(usize),
}

pub fn apply_braid_move(st: &EchoBraidState, m: BraidMove) -> EchoBraidState {
    let (idx, is_pos) = match m {
        BraidMove::CrossPos(i) => (i, true),
        BraidMove::CrossNeg(i) => (i, false),
    };

    if idx + 1 >= st.strands.len() {
        return st.clone();
    }

    let mut new_strands = st.strands.clone();
    let phase_shift = if is_pos { 30 } else { 330 };

    let mut s1 = new_strands[idx].clone();
    let mut s2 = new_strands[idx + 1].clone();

    s1.position = idx + 1;
    s1.tint.phase_deg = norm_phase(s1.tint.phase_deg + phase_shift);

    s2.position = idx;
    s2.tint.phase_deg = norm_phase(s2.tint.phase_deg + (360 - phase_shift));

    new_strands[idx] = s2;
    new_strands[idx + 1] = s1;

    EchoBraidState {
        time: st.time,
        strands: new_strands,
        lambda_m: st.lambda_m,
        spectral_coherence: st.spectral_coherence,
    }
}

pub fn apply_braid_word(st: &EchoBraidState, word: &[BraidMove]) -> EchoBraidState {
    let mut current = st.clone();
    for &m in word {
        current = apply_braid_move(&current, m);
    }
    current
}

// ---------------------------------------------------------------------------
// 3. Picard Contraction Mapping
// ---------------------------------------------------------------------------

pub fn blend_strand(s0: &Strand, s1: &Strand, lambda_val: u64) -> Strand {
    let blend_int = (s0.tint.intensity * (100 - lambda_val) + s1.tint.intensity * lambda_val) / 100;
    let blend_amp = (s0.eigen.amplitude * (100 - lambda_val) + s1.eigen.amplitude * lambda_val) / 100;
    Strand {
        prime: s1.prime,
        tint: TintBundle {
            tint_id: s1.tint.tint_id,
            phase_deg: s1.tint.phase_deg,
            intensity: blend_int,
        },
        eigen: EigenMemory {
            trace_id: s1.eigen.trace_id,
            amplitude: blend_amp,
            phase: s1.eigen.phase,
        },
        position: s1.position,
    }
}

pub fn picard_step(base: &EchoBraidState, current: &EchoBraidState) -> EchoBraidState {
    let next_floer = floer_step(current);
    let mut blended_strands = Vec::with_capacity(base.strands.len());

    for (s0, s1) in base.strands.iter().zip(next_floer.strands.iter()) {
        blended_strands.push(blend_strand(s0, s1, base.lambda_m));
    }

    EchoBraidState {
        time: next_floer.time,
        strands: blended_strands,
        lambda_m: base.lambda_m,
        spectral_coherence: next_floer.spectral_coherence,
    }
}

pub fn iterate_picard(base: &EchoBraidState, n_steps: usize) -> EchoBraidState {
    let mut curr = base.clone();
    for _ in 0..n_steps {
        curr = picard_step(base, &curr);
    }
    curr
}

// ---------------------------------------------------------------------------
// 4. Cognitive Feedback & CSL Constraint Layer
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CSLConstraintConfig {
    pub max_allowed_error: u64,
    pub min_coherence: u64,
    pub max_energy_deviation: u64,
}

impl Default for CSLConstraintConfig {
    fn default() -> Self {
        Self {
            max_allowed_error: 40,
            min_coherence: 30,
            max_energy_deviation: 50,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ErrorPredictionState {
    pub alpha_weights: Vec<u64>,
    pub beta_weights: Vec<u64>,
    pub delta_prev: u64,
    pub delta_current: u64,
}

pub fn compute_state_velocity(st_prev: &EchoBraidState, st_curr: &EchoBraidState) -> Vec<u64> {
    st_prev
        .strands
        .iter()
        .zip(st_curr.strands.iter())
        .map(|(s0, s1)| {
            if s1.eigen.amplitude >= s0.eigen.amplitude {
                s1.eigen.amplitude - s0.eigen.amplitude
            } else {
                s0.eigen.amplitude - s1.eigen.amplitude
            }
        })
        .collect()
}

pub fn evaluate_error_prediction(pred: &ErrorPredictionState, velocities: &[u64]) -> ErrorPredictionState {
    let alpha_term = match (pred.alpha_weights.first(), velocities.first()) {
        (Some(&a), Some(&v)) => (a * v) / FP_DEN,
        _ => 0,
    };
    let beta_term = pred.beta_weights.first().map_or(0, |&b| (b * pred.delta_prev) / FP_DEN);
    let new_delta = alpha_term + beta_term;

    ErrorPredictionState {
        alpha_weights: pred.alpha_weights.clone(),
        beta_weights: pred.beta_weights.clone(),
        delta_prev: pred.delta_current,
        delta_current: new_delta,
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CSLValidationResult {
    pub is_lawful: bool,
    pub reason: String,
    pub witness_digest: String,
}

pub fn validate_csl_constraints(
    config: &CSLConstraintConfig,
    st_prev: &EchoBraidState,
    st_curr: &EchoBraidState,
    pred: &ErrorPredictionState,
) -> CSLValidationResult {
    if pred.delta_current > config.max_allowed_error {
        CSLValidationResult {
            is_lawful: false,
            reason: "Prediction discrepancy exceeds max_allowed_error".to_string(),
            witness_digest: "ERR_CSL_DELTA_OVERFLOW".to_string(),
        }
    } else if st_curr.spectral_coherence < config.min_coherence {
        CSLValidationResult {
            is_lawful: false,
            reason: "Spectral coherence collapsed below min_coherence floor".to_string(),
            witness_digest: "ERR_CSL_COHERENCE_COLLAPSE".to_string(),
        }
    } else {
        let e_prev = st_prev.total_energy();
        let e_curr = st_curr.total_energy();
        let e_diff = if e_curr >= e_prev { e_curr - e_prev } else { e_prev - e_curr };

        if e_diff > config.max_energy_deviation {
            CSLValidationResult {
                is_lawful: false,
                reason: "Total energy deviation exceeds stability ceiling".to_string(),
                witness_digest: "ERR_CSL_ENERGY_VOLATILITY".to_string(),
            }
        } else {
            CSLValidationResult {
                is_lawful: true,
                reason: "All CSL constraints satisfied lawfully".to_string(),
                witness_digest: "CSL_WITNESS_VERIFIED_STABLE".to_string(),
            }
        }
    }
}

/// UnifiedWitness: Machine-checked cryptographic audit certificate
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UnifiedWitness {
    pub time: u64,
    pub total_energy: u64,
    pub spectral_coherence: u64,
    pub is_stable: bool,
    pub signature_hash: String,
}

pub fn generate_unified_witness(st: &EchoBraidState, csl_res: &CSLValidationResult) -> UnifiedWitness {
    let payload = format!(
        "time={}|energy={}|coherence={}|lawful={}|digest={}",
        st.time,
        st.total_energy(),
        st.spectral_coherence,
        csl_res.is_lawful,
        csl_res.witness_digest
    );
    let mut hasher = Sha256::new();
    hasher.update(payload.as_bytes());
    let sig = hex::encode(hasher.finalize());

    UnifiedWitness {
        time: st.time,
        total_energy: st.total_energy(),
        spectral_coherence: st.spectral_coherence,
        is_stable: csl_res.is_lawful,
        signature_hash: sig,
    }
}
