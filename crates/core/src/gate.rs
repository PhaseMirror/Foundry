use crate::recurrence::{step, Operator, Projector};
use crate::types::StepInfo;
use nalgebra::{DMatrix, DVector};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
pub enum EmissionPolicy {
    PassThrough,
    Suppress,
    Hold,
    Attenuate,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GatedOutput {
    pub x_next: DVector<f64>,
    pub info: StepInfo,
    pub emitted: bool,
    pub policy_applied: String,
    pub suppression_reason: String,
}

pub type CustomPredicate = fn(&DVector<f64>, &StepInfo) -> bool;

pub struct EmissionGate {
    pub policy: EmissionPolicy,
    pub custom_predicate: Option<CustomPredicate>,
    pub attenuation_floor: f64,
}

impl EmissionGate {
    pub fn new(
        policy: EmissionPolicy,
        custom_predicate: Option<CustomPredicate>,
        attenuation_floor: f64,
    ) -> Self {
        Self {
            policy,
            custom_predicate,
            attenuation_floor,
        }
    }

    pub fn call(
        &self,
        x_t: &DVector<f64>,
        xi_t: &DMatrix<f64>,
        lam_t: &DMatrix<f64>,
        t_op: Operator,
        g_t: &DVector<f64>,
        p_op: Projector,
        epsilon: f64,
        op_norm_t: f64,
        t: usize,
    ) -> GatedOutput {
        let (x_next, info) = step(x_t, xi_t, lam_t, t_op, g_t, p_op, epsilon, op_norm_t, t);

        let contraction_ok = !info.projected;
        let mut custom_ok = true;
        if let Some(pred) = self.custom_predicate {
            custom_ok = pred(&x_next, &info);
        }

        if contraction_ok && custom_ok {
            return GatedOutput {
                x_next,
                info,
                emitted: true,
                policy_applied: "none".to_string(),
                suppression_reason: "".to_string(),
            };
        }

        let mut reason = Vec::new();
        if !contraction_ok {
            reason.push(format!("projection_triggered(q={:.4})", info.q));
        }
        if !custom_ok {
            reason.push("custom_predicate_failed".to_string());
        }
        let suppression_reason = reason.join("; ");

        match self.policy {
            EmissionPolicy::PassThrough => GatedOutput {
                x_next,
                info,
                emitted: true,
                policy_applied: "pass_through".to_string(),
                suppression_reason,
            },
            EmissionPolicy::Suppress => GatedOutput {
                x_next: DVector::zeros(x_t.len()),
                info,
                emitted: false,
                policy_applied: "suppress".to_string(),
                suppression_reason,
            },
            EmissionPolicy::Hold => GatedOutput {
                x_next: x_t.clone(),
                info,
                emitted: false,
                policy_applied: "hold".to_string(),
                suppression_reason,
            },
            EmissionPolicy::Attenuate => {
                let margin = (1.0 - epsilon - info.q).max(0.0);
                let scale = margin.max(self.attenuation_floor);
                GatedOutput {
                    x_next: x_next * scale,
                    info,
                    emitted: true,
                    policy_applied: format!("attenuate(scale={:.4})", scale),
                    suppression_reason,
                }
            }
        }
    }
}

pub fn gated_run(
    x0: &DVector<f64>,
    xi_seq: &[DMatrix<f64>],
    lam_seq: &[DMatrix<f64>],
    g_seq: &[DVector<f64>],
    t_op: Operator,
    p_op: Projector,
    gate: &EmissionGate,
    epsilon: f64,
    op_norm_t: f64,
) -> (DVector<f64>, Vec<DVector<f64>>, Vec<GatedOutput>) {
    let mut x = x0.clone();
    let mut history = vec![x.clone()];
    let mut outputs = Vec::new();

    let t_max = xi_seq.len().min(lam_seq.len()).min(g_seq.len());

    for t in 0..t_max {
        let out = gate.call(
            &x,
            &xi_seq[t],
            &lam_seq[t],
            t_op,
            &g_seq[t],
            p_op,
            epsilon,
            op_norm_t,
            t,
        );
        x = out.x_next.clone();
        history.push(x.clone());
        outputs.push(out);
    }

    (x, history, outputs)
}
