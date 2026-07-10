use serde::{Deserialize, Serialize};
use num_bigint::BigInt;
use crate::GoldilocksField;

pub const N0: usize = 64;

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ConvergenceWitness {
    pub h_hat: Vec<GoldilocksField>,
    pub current_mu: Vec<GoldilocksField>,
    pub support_mask: Vec<u8>,
    pub x_n_witness: GoldilocksField,
    pub sigma_norm: GoldilocksField,
    pub step_n: GoldilocksField,
    pub r_raw: GoldilocksField,
    pub max_wac: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ConvergencePublicInputs {
    pub epsilon: GoldilocksField,
    pub delta: GoldilocksField,
    pub beta: GoldilocksField,
    pub tau_min: GoldilocksField,
    pub alpha_m: GoldilocksField,
    pub retry_nonce: GoldilocksField,
    pub x_n: GoldilocksField,
    pub r_t: GoldilocksField,
    pub max_wac_product: GoldilocksField,
    pub is_valid: GoldilocksField,
    pub cas_commitment: BigInt,
}

pub struct AceAir {
    pub n0: usize,
}

impl AceAir {
    pub fn new() -> Self {
        Self {
            n0: N0,
        }
    }

    pub fn check_mu_step_constraint(&self, mu: &[GoldilocksField], step_n: GoldilocksField, h_hat: &[GoldilocksField]) -> Result<(), String> {
        for i in 0..self.n0 {
            let lhs = mu[i] * step_n;
            let rhs = h_hat[i];
            if lhs != rhs {
                return Err(format!("mu_step_n[{}] violation: lhs={:?}, rhs={:?}", i, lhs, rhs));
            }
        }
        Ok(())
    }

    pub fn check_xn_contraction_constraint(&self, x_n_witness: GoldilocksField, sigma_norm: GoldilocksField, x_n_public: GoldilocksField, scale: GoldilocksField) -> Result<(), String> {
        let lhs = x_n_witness * sigma_norm;
        let rhs = x_n_public * scale;
        if lhs != rhs {
            return Err(format!("xn_contraction violation: lhs={:?}, rhs={:?}", lhs, rhs));
        }
        Ok(())
    }

    pub fn check_rt_relu_constraint(&self, r_t: GoldilocksField, r_raw: GoldilocksField) -> Result<(), String> {
        let diff = r_raw - r_t;
        let res = r_t * diff;
        if res != GoldilocksField::ZERO {
             return Err(format!("rt_relu violation: lhs={:?}", res));
        }
        Ok(())
    }
}
