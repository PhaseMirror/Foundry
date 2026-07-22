use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;

/// PWEH Trajectory to ACE-ZK ConvergenceWitness adapter.

pub use goldilocks::GOLDILOCKS_PRIME;
pub const N0: usize = 64;
/// NOTE: The canonical SCALE_GOLDILOCKS in the `goldilocks` crate is `1 << 40`.
/// This crate uses `1_000_000_000_000` (10^12) for backward compatibility.
/// Both values provide ~40 bits of fixed-point precision.
pub const SCALE_GOLDILOCKS: u64 = 1_000_000_000_000;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConvergenceWitness {
    pub h_hat: Vec<u64>,
    pub current_mu: Vec<u64>,
    pub support_mask: Vec<u32>,
    pub x_n_witness: u64,
    pub sigma_norm: u64,
    pub step_n: u64,
    pub r_raw: u64,
    pub max_wac: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConvergencePublicInputs {
    pub epsilon: u64,
    pub delta: u64,
    pub beta: u64,
    pub tau_min: u64,
    pub alpha_m: u64,
    pub retry_nonce: u64,
    pub x_n: u64,
    pub r_t: u64,
    pub max_wac_product: u64,
    pub is_valid: u32,
    pub cas_commitment: String,
}

pub fn pweh_to_witness(
    trajectory: &[Value],
    primes: &[u64],
    epsilon_scaled: u64,
) -> Result<(ConvergenceWitness, ConvergencePublicInputs), String> {
    if trajectory.is_empty() {
        return Err("Empty trajectory".to_string());
    }

    let last_step = trajectory.last().unwrap();
    let step_n = last_step.get("step_index").and_then(|v| v.as_u64()).unwrap_or(0) + 1;

    let mut h_hat = vec![0u64; N0];
    let mut current_mu = vec![0u64; N0];

    let mut prime_to_idx = HashMap::new();
    for (i, &p) in primes.iter().enumerate() {
        prime_to_idx.insert(p, i);
    }

    for record in trajectory {
        if let Some(p) = record.get("active_prime").and_then(|v| v.as_u64()) {
            if let Some(&idx) = prime_to_idx.get(&p) {
                if idx < N0 {
                    let norm = record.get("operator_norm_mult").and_then(|v| v.as_f64()).unwrap_or(0.0);
                    let norm_scaled = (norm * SCALE_GOLDILOCKS as f64) as u64;
                    h_hat[idx] = (h_hat[idx] + norm_scaled) % GOLDILOCKS_PRIME;
                }
            }
        }
    }

    // Modular inverse for mu calculation
    let inv_step_n = mod_inverse(step_n, GOLDILOCKS_PRIME);
    for i in 0..N0 {
        current_mu[i] = mul_mod(h_hat[i], inv_step_n, GOLDILOCKS_PRIME);
    }

    if !last_step.get("lambda_m_cert").and_then(|v| v.as_bool()).unwrap_or(false) {
        return Err("Trajectory failed contractivity certification".to_string());
    }

    let sigma_norm = (last_step.get("operator_norm_mult").and_then(|v| v.as_f64()).unwrap_or(0.0) * SCALE_GOLDILOCKS as f64) as u64;
    let m_bar_n = sigma_norm;
    let x_n_public = SCALE_GOLDILOCKS;

    let r_raw = if SCALE_GOLDILOCKS >= epsilon_scaled + x_n_public {
        (SCALE_GOLDILOCKS - epsilon_scaled - x_n_public) % GOLDILOCKS_PRIME
    } else {
        (GOLDILOCKS_PRIME - (epsilon_scaled + x_n_public - SCALE_GOLDILOCKS) % GOLDILOCKS_PRIME) % GOLDILOCKS_PRIME
    };

    let r_t = if r_raw < GOLDILOCKS_PRIME / 2 { r_raw } else { 0 };

    let max_wac = last_step.get("max_wac").and_then(|v| v.as_f64()).unwrap_or(0.5);
    let is_valid = if max_wac < 1.0 { 1 } else { 0 };

    let retry_nonce = last_step.get("metadata").and_then(|m| m.get("nonce")).and_then(|v| v.as_u64()).unwrap_or(0);

    // Placeholder for CAS commitment (Poseidon2)
    let cas = "0x".to_string(); // In a real implementation, call Poseidon2

    let witness = ConvergenceWitness {
        h_hat,
        current_mu,
        support_mask: vec![1; N0],
        x_n_witness: x_n_public,
        sigma_norm,
        step_n,
        r_raw,
        max_wac,
    };

    let public_inputs = ConvergencePublicInputs {
        epsilon: epsilon_scaled,
        delta: 0,
        beta: 0,
        tau_min: 0,
        alpha_m: 0,
        retry_nonce,
        x_n: m_bar_n,
        r_t,
        max_wac_product: (max_wac * SCALE_GOLDILOCKS as f64) as u64,
        is_valid,
        cas_commitment: cas,
    };

    Ok((witness, public_inputs))
}

fn mod_inverse(a: u64, m: u64) -> u64 {
    // Fermat's Little Theorem for prime m
    pow_mod(a, m - 2, m)
}

fn pow_mod(mut base: u64, mut exp: u64, m: u64) -> u64 {
    let mut res = 1;
    base %= m;
    while exp > 0 {
        if exp % 2 == 1 { res = mul_mod(res, base, m); }
        base = mul_mod(base, base, m);
        exp /= 2;
    }
    res
}

fn mul_mod(a: u64, b: u64, m: u64) -> u64 {
    (a as u128 * b as u128 % m as u128) as u64
}
