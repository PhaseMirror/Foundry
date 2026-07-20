use serde::{Deserialize, Serialize};

#[cfg(feature = "triple-lock")]
pub mod triple_lock;

pub const SCALE: u64 = 10000;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Gate1 {
    pub f_nl: u64,
    pub coupling_strength: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Gate2 {
    pub theta_1: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Gate3 {
    pub a: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Gate4 {
    pub beta_lambda_8: u64,
    pub beta_lambda_6: u64,
    pub delta_c_ratio: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Gate5 {
    pub g1: Gate1,
    pub g2: Gate2,
    pub g3: Gate3,
    pub g4: Gate4,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MetaRelativityWitness {
    pub config_hash: [u8; 32],
    pub all_gates_valid: bool,
    pub timestamp: i64,
}

#[derive(Debug, thiserror::Error)]
pub enum MetaRelativityViolation {
    #[error("Gate1 invalid: f_nl={f_nl} ≠ 0 or coupling={coupling} > 1000")]
    Gate1Invalid { f_nl: u64, coupling: u64 },
    #[error("Gate2 invalid: theta_1={theta_1} not near 20000")]
    Gate2Invalid { theta_1: u64 },
    #[error("Gate3 invalid: a={a} not in [200,500]*SCALE")]
    Gate3Invalid { a: u64 },
    #[error("Gate4 invalid: truncation hierarchy violated")]
    Gate4Invalid,
    #[error("archivum write failed: {0}")]
    ArchivumError(String),
}

pub struct MetaRelativityEngine;

impl MetaRelativityEngine {
    pub fn check_gate5(
        &self,
        g5: &Gate5,
    ) -> Result<MetaRelativityWitness, MetaRelativityViolation> {
        if g5.g1.f_nl != 0 || g5.g1.coupling_strength > 1000 {
            return Err(MetaRelativityViolation::Gate1Invalid {
                f_nl: g5.g1.f_nl,
                coupling: g5.g1.coupling_strength,
            });
        }
        let diff = if g5.g2.theta_1 >= 2 * SCALE {
            g5.g2.theta_1 - 2 * SCALE
        } else {
            2 * SCALE - g5.g2.theta_1
        };
        if diff >= 4000 {
            return Err(MetaRelativityViolation::Gate2Invalid {
                theta_1: g5.g2.theta_1,
            });
        }
        if g5.g3.a < 200 * SCALE || g5.g3.a > 500 * SCALE {
            return Err(MetaRelativityViolation::Gate3Invalid { a: g5.g3.a });
        }
        if g5.g4.beta_lambda_8 * 100 >= g5.g4.beta_lambda_6 * 3 || g5.g4.delta_c_ratio >= 400 {
            return Err(MetaRelativityViolation::Gate4Invalid);
        }

        #[cfg(kani)]
        let config_hash = [0u8; 32];
        #[cfg(not(kani))]
        let config_hash = {
            // Using a simple hash for demonstration
            let mut h = [0u8; 32];
            h[0] = 1;
            h
        };

        #[cfg(kani)]
        let timestamp = 0;
        #[cfg(not(kani))]
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs() as i64;

        Ok(MetaRelativityWitness {
            config_hash,
            all_gates_valid: true,
            timestamp,
        })
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn proof_gate1_bounds() {
        let engine = MetaRelativityEngine;
        let g1 = Gate1 {
            f_nl: kani::any(),
            coupling_strength: kani::any(),
        };
        let g5 = Gate5 {
            g1,
            g2: Gate2 { theta_1: 20000 },
            g3: Gate3 { a: 3000000 },
            g4: Gate4 {
                beta_lambda_8: 0,
                beta_lambda_6: 100,
                delta_c_ratio: 0,
            },
        };

        let res = engine.check_gate5(&g5);
        if g5.g1.coupling_strength > 1000 {
            kani::assert(res.is_err(), "Rejects coupling > 1000");
        }
    }

    #[kani::proof]
    fn proof_gate5_implies_gates1_4() {
        let engine = MetaRelativityEngine;

        let g5 = Gate5 {
            g1: Gate1 {
                f_nl: kani::any(),
                coupling_strength: kani::any(),
            },
            g2: Gate2 {
                theta_1: kani::any(),
            },
            g3: Gate3 { a: kani::any() },
            g4: Gate4 {
                beta_lambda_8: kani::any(),
                beta_lambda_6: kani::any(),
                delta_c_ratio: kani::any(),
            },
        };

        // Assume avoiding overflow in beta_lambda_8 * 100 and beta_lambda_6 * 3
        kani::assume(g5.g4.beta_lambda_8 <= u64::MAX / 100);
        kani::assume(g5.g4.beta_lambda_6 <= u64::MAX / 3);

        let res = engine.check_gate5(&g5);

        if res.is_ok() {
            kani::assert(g5.g1.f_nl == 0, "Gate1 fnl must be 0");
            kani::assert(g5.g1.coupling_strength <= 1000, "Gate1 coupling <= 1000");

            let diff = if g5.g2.theta_1 >= 2 * SCALE {
                g5.g2.theta_1 - 2 * SCALE
            } else {
                2 * SCALE - g5.g2.theta_1
            };
            kani::assert(diff < 4000, "Gate2 theta_1 diff < 4000");

            kani::assert(
                g5.g3.a >= 200 * SCALE && g5.g3.a <= 500 * SCALE,
                "Gate3 a bounds",
            );

            kani::assert(
                g5.g4.beta_lambda_8 * 100 < g5.g4.beta_lambda_6 * 3,
                "Gate4 beta ratio",
            );
            kani::assert(g5.g4.delta_c_ratio < 400, "Gate4 delta_c bounds");
        }
    }

    /// Symbolic proof: Gate2 rejects any theta_1 outside [2*scale-4000, 2*scale+4000).
    #[kani::proof]
    fn proof_gate2_rejects_out_of_band() {
        let theta_1: u64 = kani::any();
        kani::assume(theta_1 <= u64::MAX - 2 * SCALE);

        let diff = if theta_1 >= 2 * SCALE {
            theta_1 - 2 * SCALE
        } else {
            2 * SCALE - theta_1
        };

        if diff >= 4000 {
            let g5 = Gate5 {
                g1: Gate1 { f_nl: 0, coupling_strength: 0 },
                g2: Gate2 { theta_1 },
                g3: Gate3 { a: 300 * SCALE },
                g4: Gate4 {
                    beta_lambda_8: 0,
                    beta_lambda_6: 1,
                    delta_c_ratio: 0,
                },
            };
            let engine = MetaRelativityEngine;
            let res = engine.check_gate5(&g5);
            kani::assert(res.is_err(), "Gate2 rejects out-of-band theta_1");
        }
    }

    /// Symbolic proof: Gate4 rejects beta_lambda_8 * 100 >= beta_lambda_6 * 3.
    #[kani::proof]
    fn proof_gate4_rejects_beta_violation() {
        let beta_lambda_8: u64 = kani::any();
        let beta_lambda_6: u64 = kani::any();
        kani::assume(beta_lambda_8 <= u64::MAX / 100);
        kani::assume(beta_lambda_6 <= u64::MAX / 3);

        if beta_lambda_8 * 100 >= beta_lambda_6 * 3 {
            let g5 = Gate5 {
                g1: Gate1 { f_nl: 0, coupling_strength: 0 },
                g2: Gate2 { theta_1: 2 * SCALE },
                g3: Gate3 { a: 300 * SCALE },
                g4: Gate4 {
                    beta_lambda_8,
                    beta_lambda_6,
                    delta_c_ratio: 0,
                },
            };
            let engine = MetaRelativityEngine;
            let res = engine.check_gate5(&g5);
            kani::assert(res.is_err(), "Gate4 rejects beta ratio violation");
        }
    }
}
