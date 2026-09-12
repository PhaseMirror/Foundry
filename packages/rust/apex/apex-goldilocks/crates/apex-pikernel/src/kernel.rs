use std::collections::HashMap;
use ndarray::Array1;
use anyhow::Result;
use num_traits::{Zero, Signed};
use crate::projectors::PiIndexGrid;
use crate::l1proj::{project_weighted_l1_ball, Rational};
use crate::certificates::{slope_upper_bound, gap_lower_bound};
use crate::ledger::Ledger;

pub trait Proposer: std::fmt::Debug {
    fn propose(&self, c: &Array1<Rational>) -> Array1<Rational>;
}

#[derive(Debug)]
pub struct DefaultProposer {
    pub damping: Rational,
}

impl DefaultProposer {
    pub fn new(damping: Rational) -> Self {
        Self { damping }
    }
}

impl Proposer for DefaultProposer {
    fn propose(&self, c: &Array1<Rational>) -> Array1<Rational> {
        c.mapv(|ci| ci * self.damping)
    }
}

#[derive(Debug)]
pub struct PiKernel<'a> {
    pub grid: &'a PiIndexGrid,
    pub alphas: HashMap<Vec<usize>, Rational>,
    pub weights: HashMap<Vec<usize>, Array1<Rational>>,
    pub taus: HashMap<Vec<usize>, Rational>,
    pub k: ndarray::Array2<Rational>,
    pub proposer: Box<dyn Proposer>,
    pub ledger: Option<Box<dyn Ledger>>,
    pub step_count: usize,
}

impl<'a> PiKernel<'a> {
    pub fn new(
        grid: &'a PiIndexGrid,
        alphas: HashMap<Vec<usize>, Rational>,
        weights: HashMap<Vec<usize>, Array1<Rational>>,
        taus: HashMap<Vec<usize>, Rational>,
        k: ndarray::Array2<Rational>,
        proposer: Option<Box<dyn Proposer>>,
        ledger: Option<Box<dyn Ledger>>,
    ) -> Result<Self> {
        let m = grid.pi_ids.len();
        if k.nrows() != m || k.ncols() != m {
            anyhow::bail!("K must be {}x{}", m, m);
        }

        Ok(Self {
            grid,
            alphas,
            weights,
            taus,
            k,
            proposer: proposer.unwrap_or_else(|| {
                Box::new(DefaultProposer::new(Rational::new(9, 10)))
            }),
            ledger,
            step_count: 0,
        })
    }

    pub fn step(&mut self, x: &Array1<Rational>) -> Result<StepResult> {
        let m = self.grid.pi_ids.len();
        let mut alpha_vec = Array1::zeros(m);
        for (i, pi_id) in self.grid.pi_ids.iter().enumerate() {
            alpha_vec[i] = *self.alphas.get(pi_id).unwrap_or(&Rational::zero());
        }

        let slope_ub = slope_upper_bound(alpha_vec.view(), self.k.view());
        let gap_lb = gap_lower_bound(slope_ub);

        let mut x_new = Array1::zeros(x.len());
        let mut touched = Vec::new();

        for pi_id in &self.grid.pi_ids {
            let indices = self.grid.indices(pi_id).unwrap();
            let mut c = Array1::zeros(indices.len());
            for (i, &idx) in indices.iter().enumerate() {
                c[i] = x[idx];
            }

            let prop = self.proposer.propose(&c);
            let w = self.weights.get(pi_id).unwrap();
            let tau = *self.taus.get(pi_id).unwrap();

            let (c_safe, lam) = project_weighted_l1_ball(&prop, w, tau, 60);

            // Change norm (using L1 for exactness)
            let mut norm = Rational::zero();
            for i in 0..c.len() {
                norm = norm + (c_safe[i] - c[i]).abs();
            }

            if norm > Rational::zero() {
                touched.push(pi_id.clone());

                if let Some(ledger) = &mut self.ledger {
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

                    ledger.append(record)?;
                }
            }

            for (i, &idx) in indices.iter().enumerate() {
                x_new[idx] = c_safe[i];
            }
        }

        self.step_count += 1;

        Ok(StepResult {
            x_new,
            slope_ub,
            gap_lb,
            touched,
            step: self.step_count - 1,
        })
    }
}

#[derive(Debug)]
pub struct StepResult {
    pub x_new: Array1<Rational>,
    pub slope_ub: Rational,
    pub gap_lb: Rational,
    pub touched: Vec<Vec<usize>>,
    pub step: usize,
}
