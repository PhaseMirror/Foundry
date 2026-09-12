use crate::adaptive::AdaptiveMargin;
use crate::audit::AuditChain;
use crate::certify::{ace_certificate, AceCertificate};
use crate::gate::{EmissionGate, EmissionPolicy, GatedOutput, CustomPredicate};
use crate::recurrence::{Operator, Projector};
use crate::telemetry::TelemetryBus;
use crate::types::StepInfo;
use nalgebra::{DMatrix, DVector};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QARIConfig {
    pub dim: usize,
    pub epsilon: f64,
    pub op_norm_t: f64,
    pub emission_policy: EmissionPolicy,
    pub adaptive: bool,
    pub audit: bool,
    pub max_steps: usize,
    pub convergence_tol: f64,
}

impl Default for QARIConfig {
    fn default() -> Self {
        Self {
            dim: 0,
            epsilon: 0.05,
            op_norm_t: 1.0,
            emission_policy: EmissionPolicy::Suppress,
            adaptive: true,
            audit: true,
            max_steps: 1000,
            convergence_tol: 1e-6,
        }
    }
}

pub struct QARISession<'a> {
    pub config: QARIConfig,
    pub p_op: Projector<'a>,
    pub gate: EmissionGate,
    pub margin: Option<AdaptiveMargin>,
    pub telemetry: TelemetryBus,
    pub audit: Option<AuditChain>,
    pub step_count: usize,
    pub infos: Vec<StepInfo>,
    pub current_epsilon: f64,
}

fn identity_projector(x: &DVector<f64>) -> DVector<f64> {
    x.clone()
}

impl<'a> QARISession<'a> {
    pub fn new(
        config: QARIConfig,
        projector: Option<Projector<'a>>,
        custom_predicate: Option<CustomPredicate>,
        telemetry: Option<TelemetryBus>,
    ) -> Self {
        let p_op: Projector<'a> = projector.unwrap_or(&identity_projector);
        let gate = EmissionGate::new(config.emission_policy, custom_predicate, 0.01);
        let margin = if config.adaptive {
            Some(AdaptiveMargin::new(config.epsilon))
        } else {
            None
        };
        let telemetry = telemetry.unwrap_or_else(|| TelemetryBus::new(Vec::new()));
        let audit = if config.audit { Some(AuditChain::new()) } else { None };

        Self {
            current_epsilon: config.epsilon,
            config,
            p_op,
            gate,
            margin,
            telemetry,
            audit,
            step_count: 0,
            infos: Vec::new(),
        }
    }

    pub fn step(
        &mut self,
        x_t: &DVector<f64>,
        xi_t: &DMatrix<f64>,
        lam_t: &DMatrix<f64>,
        t_op: Operator,
        g_t: &DVector<f64>,
    ) -> Result<GatedOutput, String> {
        if self.step_count >= self.config.max_steps {
            return Err(format!("QARISession exceeded max_steps ({})", self.config.max_steps));
        }

        let result = self.gate.call(
            x_t,
            xi_t,
            lam_t,
            t_op,
            g_t,
            self.p_op,
            self.current_epsilon,
            self.config.op_norm_t,
            self.step_count,
        );

        self.infos.push(result.info.clone());
        self.telemetry.emit_step(self.step_count, &result.info);
        self.telemetry.emit_gate(self.step_count, &result);

        if let Some(audit) = &mut self.audit {
            audit.append_step(&result.info);
            audit.append_gate(
                self.step_count,
                result.emitted,
                &result.policy_applied,
                &result.suppression_reason,
            );
        }

        if let Some(margin) = &mut self.margin {
            self.current_epsilon = margin.update(&result.info);
        }

        self.step_count += 1;
        Ok(result)
    }

    pub fn certify(&mut self, tail_norm: f64) -> Result<AceCertificate, String> {
        if self.infos.is_empty() {
            return Err("No steps recorded. Call step() first.".to_string());
        }
        let cert = ace_certificate(&self.infos, tail_norm);
        self.telemetry.emit_certificate(&cert);
        if let Some(audit) = &mut self.audit {
            audit.append_certificate(&cert);
        }
        Ok(cert)
    }

    pub fn summary(&self) -> serde_json::Value {
        if self.infos.is_empty() {
            return serde_json::json!({"steps": 0});
        }
        let qs: Vec<f64> = self.infos.iter().map(|i| i.q).collect();
        let q_max = qs.iter().fold(f64::NEG_INFINITY, |a, &b| a.max(b));
        let q_min = qs.iter().fold(f64::INFINITY, |a, &b| a.min(b));
        let q_mean = qs.iter().sum::<f64>() / qs.len() as f64;
        let residual_final = self.infos.last().unwrap().residual;
        let projected_count = self.infos.iter().filter(|i| i.projected).count();

        serde_json::json!({
            "steps": self.step_count,
            "q_max": q_max,
            "q_min": q_min,
            "q_mean": q_mean,
            "residual_final": residual_final,
            "projected_count": projected_count,
            "projection_rate": projected_count as f64 / self.infos.len() as f64,
            "epsilon_current": self.current_epsilon,
            "audit_chain_length": self.audit.as_ref().map(|a| a.len()).unwrap_or(0),
        })
    }
}
