use std::collections::HashMap;
use ndarray::Array1;
use anyhow::Result;
use num_traits::{Zero, ToPrimitive, Signed};
use crate::projectors::{ProjectorFamily, PiIndexGrid};
use crate::l1proj::Rational;
use crate::ledger::{Ledger, DefaultLedger, PoseidonLedger};
use crate::mub_audit::{mub_drift_audit, MubAuditResult};
use crate::routing::{build_channel_blocks, CHANNEL_MAP};

pub struct HologramAdapterConfig {
    pub families: Vec<ProjectorFamily>,
    pub alphas: HashMap<Vec<usize>, Rational>,
    pub weights: HashMap<Vec<usize>, Array1<Rational>>,
    pub taus: HashMap<Vec<usize>, Rational>,
    pub k: ndarray::Array2<Rational>,
    pub use_poseidon: bool,
    pub ledger_path: Option<String>,
    pub mub_threshold: f64,
    pub tau_shrink_factor: Rational,
}

pub struct HologramAdapterManaged {
    pub grid: PiIndexGrid,
    pub alphas: HashMap<Vec<usize>, Rational>,
    pub weights: HashMap<Vec<usize>, Array1<Rational>>,
    pub taus: HashMap<Vec<usize>, Rational>,
    pub k: ndarray::Array2<Rational>,
    pub mub_threshold: f64,
    pub tau_shrink_factor: Rational,
    pub ledger: Box<dyn Ledger>,
    pub channel_atoms: HashMap<u32, Vec<Vec<usize>>>,
    pub channel_indices: HashMap<u32, Vec<usize>>,
    pub mub_alarms: usize,
    pub total_steps: usize,
    pub step_count: usize,
}

impl HologramAdapterManaged {
    pub fn new(config: HologramAdapterConfig) -> Result<Self> {
        let grid = PiIndexGrid::new(config.families).map_err(|e| anyhow::anyhow!(e))?;
        let channel_primes: Vec<u32> = CHANNEL_MAP.keys().cloned().collect();
        let (channel_atoms, channel_indices) = build_channel_blocks(&grid, &channel_primes);
        
        let ledger: Box<dyn Ledger> = if config.use_poseidon {
            Box::new(PoseidonLedger::new(config.ledger_path))
        } else {
            Box::new(DefaultLedger::new(config.ledger_path))
        };

        Ok(Self {
            grid,
            alphas: config.alphas,
            weights: config.weights,
            taus: config.taus,
            k: config.k,
            mub_threshold: config.mub_threshold,
            tau_shrink_factor: config.tau_shrink_factor,
            ledger,
            channel_atoms,
            channel_indices,
            mub_alarms: 0,
            total_steps: 0,
            step_count: 0,
        })
    }

    pub fn step(&mut self, x: &Array1<Rational>) -> Result<AdapterStepResult> {
        let m = self.grid.pi_ids.len();
        let mut alpha_vec = Array1::zeros(m);
        for (i, pi_id) in self.grid.pi_ids.iter().enumerate() {
            alpha_vec[i] = *self.alphas.get(pi_id).unwrap_or(&Rational::zero());
        }

        let slope_ub = crate::certificates::slope_upper_bound(alpha_vec.view(), self.k.view());
        let gap_lb = crate::certificates::gap_lower_bound(slope_ub);

        let mut x_new = Array1::zeros(x.len());
        let mut touched = Vec::new();

        for pi_id in &self.grid.pi_ids {
            let indices = self.grid.indices(pi_id).unwrap();
            let mut c = Array1::zeros(indices.len());
            for (i, &idx) in indices.iter().enumerate() {
                c[i] = x[idx];
            }

            // Using default proposer logic (0.9 damping)
            let damping = Rational::new(9, 10);
            let prop = c.mapv(|ci| ci * damping);
            let w = self.weights.get(pi_id).unwrap();
            let tau = *self.taus.get(pi_id).unwrap();

            let (c_safe, lam) = crate::l1proj::project_weighted_l1_ball(&prop, w, tau, 60);

            let mut norm = Rational::zero();
            for i in 0..c.len() {
                norm = norm + (c_safe[i] - c[i]).abs();
            }

            if norm > Rational::zero() {
                touched.push(pi_id.clone());

                let mut record = HashMap::new();
                record.insert("step".to_string(), (self.step_count).into());
                record.insert("pi".to_string(), serde_json::to_value(pi_id)?);
                
                let alpha = self.alphas.get(pi_id).unwrap();
                record.insert("alpha".to_string(), format!("{}/{}", alpha.numer(), alpha.denom()).into());
                record.insert("tau".to_string(), format!("{}/{}", tau.numer(), tau.denom()).into());
                record.insert("lambda_soft".to_string(), format!("{}/{}", lam.numer(), lam.denom()).into());
                
                let mut weight_sum = Rational::zero();
                for i in 0..c_safe.len() {
                    weight_sum = weight_sum + (w[i] * c_safe[i].abs());
                }
                record.insert("l1_weight_sum".to_string(), format!("{}/{}", weight_sum.numer(), weight_sum.denom()).into());
                record.insert("change_norm".to_string(), format!("{}/{}", norm.numer(), norm.denom()).into());

                self.ledger.append(record)?;
            }

            for (i, &idx) in indices.iter().enumerate() {
                x_new[idx] = c_safe[i];
            }
        }

        let audit = mub_drift_audit(&x_new, self.mub_threshold);
        if audit.alarm {
            self.mub_alarms += 1;
            for pi_id in &self.grid.pi_ids {
                if let Some(t) = self.taus.get_mut(pi_id) {
                    *t = *t * self.tau_shrink_factor;
                }
            }
        }

        self.step_count += 1;
        self.total_steps += 1;

        Ok(AdapterStepResult {
            x_new,
            slope_ub,
            gap_lb,
            touched,
            audit,
            mub_alarms: self.mub_alarms,
            step: self.step_count - 1,
        })
    }
}

pub struct AdapterStepResult {
    pub x_new: Array1<Rational>,
    pub slope_ub: Rational,
    pub gap_lb: Rational,
    pub touched: Vec<Vec<usize>>,
    pub audit: MubAuditResult,
    pub mub_alarms: usize,
    pub step: usize,
}
