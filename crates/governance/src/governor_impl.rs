use crate::{EtpGovernor, CostInterrogateMetrics, ElasticVelocityResult, ContractionCertificate, ProposalCheckResult};

pub struct ProductionEtpGovernor {
    pub base_v_max: f64,
}

impl EtpGovernor for ProductionEtpGovernor {
    fn calculate_elastic_velocity(
        &self,
        head_position: f64,
        tail_position: f64,
        cost_interrogate: &CostInterrogateMetrics,
        v_max: f64,
        _verified_multiplicity: Option<f64>,
    ) -> ElasticVelocityResult {
        let span = (head_position - tail_position).abs();
        let latency_factor = 1.0 / (cost_interrogate.p99_ms.max(1.0) / 100.0);
        let velocity = span * latency_factor;
        
        let braking_active = velocity > v_max;
        
        ElasticVelocityResult {
            max_velocity: v_max,
            ell_safe: v_max * 0.8,
            data_debt: if braking_active { velocity - v_max } else { 0.0 },
            region: if braking_active { "UNVERIFIED".to_string() } else { "VERIFIED".to_string() },
            braking_active,
        }
    }

    fn check_proposal(
        &self,
        _proposal_hash: &str,
        _head_position: f64,
        _tail_position: f64,
        _cost_interrogate: &CostInterrogateMetrics,
        certificate: &ContractionCertificate,
        depends_only_on_verified: bool,
        current_velocity: f64,
    ) -> ProposalCheckResult {
        let authorized = certificate.is_stable && (!depends_only_on_verified || certificate.metadata.contains_key("audit_verified"));
        let data_debt = if authorized { 0.0 } else { current_velocity };
        
        ProposalCheckResult {
            authorized,
            data_debt,
            braking_triggered: !authorized,
        }
    }
}
