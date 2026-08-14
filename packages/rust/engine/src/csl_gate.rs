use crate::csl::{evaluate_csl, CSLVerdict};
use crate::gate::{EmissionGate, GatedOutput};
use crate::recurrence::{Operator, Projector};
use crate::types::StepInfo;
use nalgebra::DVector;
use nalgebra::DMatrix;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CSLGatedOutput {
    pub x_next: DVector<f64>,
    pub info: StepInfo,
    pub gate_output: GatedOutput,
    pub csl_verdict: CSLVerdict,
    pub emitted: bool,
    pub silenced: bool,
    pub final_policy: String,
}

pub struct CSLEmissionGate<'a> {
    pub contraction_gate: EmissionGate,
    pub subjects: Option<Vec<DVector<f64>>>,
    pub csl_filter: Option<Operator<'a>>,
    pub epsilon_n: f64,
    pub epsilon_c: f64,
    pub norm_growth_limit: f64,
    pub residual_limit: f64,
}

impl<'a> CSLEmissionGate<'a> {
    pub fn new(
        contraction_gate: EmissionGate,
        subjects: Option<Vec<DVector<f64>>>,
        csl_filter: Option<Operator<'a>>,
        epsilon_n: f64,
        epsilon_c: f64,
        norm_growth_limit: f64,
        residual_limit: f64,
    ) -> Self {
        Self {
            contraction_gate,
            subjects,
            csl_filter,
            epsilon_n,
            epsilon_c,
            norm_growth_limit,
            residual_limit,
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
        step_index: usize,
        epsilon: f64,
        op_norm_t: f64,
    ) -> CSLGatedOutput {
        let gate_output = self.contraction_gate.call(
            x_t, xi_t, lam_t, t_op, g_t, p_op, epsilon, op_norm_t, step_index,
        );

        if !gate_output.emitted {
            let skip_verdict = CSLVerdict {
                neutrality: true,
                beneficence: true,
                silence_triggered: false,
                commutes: true,
                violations: Vec::new(),
                detail: serde_json::json!({"skipped": "contraction_gated"}),
            };
            return CSLGatedOutput {
                x_next: gate_output.x_next.clone(),
                info: gate_output.info.clone(),
                gate_output,
                csl_verdict: skip_verdict,
                emitted: false,
                silenced: false,
                final_policy: "contraction_gated".to_string(),
            };
        }

        let verdict = evaluate_csl(
            t_op,
            x_t,
            &gate_output.x_next,
            &gate_output.info,
            step_index,
            self.subjects.as_deref(),
            self.csl_filter,
            self.epsilon_n,
            self.epsilon_c,
            self.norm_growth_limit,
            self.residual_limit,
        );

        if verdict.silence_triggered {
            return CSLGatedOutput {
                x_next: x_t.clone(),
                info: gate_output.info.clone(),
                gate_output,
                csl_verdict: verdict,
                emitted: false,
                silenced: true,
                final_policy: "csl_silenced".to_string(),
            };
        }

        if !verdict.commutes {
            return CSLGatedOutput {
                x_next: x_t.clone(),
                info: gate_output.info.clone(),
                gate_output,
                csl_verdict: verdict,
                emitted: false,
                silenced: true,
                final_policy: "csl_silenced(non_commuting)".to_string(),
            };
        }

        CSLGatedOutput {
            x_next: gate_output.x_next.clone(),
            info: gate_output.info.clone(),
            gate_output,
            csl_verdict: verdict,
            emitted: true,
            silenced: false,
            final_policy: "emitted".to_string(),
        }
    }
}
