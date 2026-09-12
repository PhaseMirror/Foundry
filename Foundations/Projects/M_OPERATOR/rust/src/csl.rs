use serde::{Deserialize, Serialize};
use crate::core::{MVector3, AgentState, EPSILON_CSL};

/// Repair operator protocol type.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum RepairProtocol {
    Linear,
    Cubic,
}

/// Configuration for Multi-Agent CSL Simulation.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CSLSimulationConfig {
    pub agent_count: usize,
    pub step_count: usize,
    pub alpha_repair: f64,
    pub beta_coupling: f64,
    pub noise_scale: f64,
    pub epsilon_threshold: f64,
    pub protocol: RepairProtocol,
}

impl Default for CSLSimulationConfig {
    fn default() -> Self {
        Self {
            agent_count: 50,
            step_count: 100,
            alpha_repair: 0.3,
            beta_coupling: 0.05,
            noise_scale: 0.05,
            epsilon_threshold: EPSILON_CSL,
            protocol: RepairProtocol::Cubic,
        }
    }
}

/// Aggregated statistical metrics for a multi-agent simulation run.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CSLSimulationSummary {
    pub target_name: String,
    pub target_vector: MVector3,
    pub protocol: RepairProtocol,
    pub mean_drift: f64,
    pub ethical_entropy: f64,
    pub total_collapses: u64,
    pub convergence_step: Option<usize>,
    pub final_coherence_rate: f64,
}

/// Compute 1D restoring step under chosen repair protocol.
pub fn compute_repair_1d(s: f64, target: f64, alpha: f64, protocol: RepairProtocol) -> f64 {
    let diff = s - target;
    match protocol {
        RepairProtocol::Linear => -alpha * diff,
        RepairProtocol::Cubic => -alpha * diff.powi(3),
    }
}

/// Compute 3D restoring vector.
pub fn compute_repair_3d(v: &MVector3, target: &MVector3, alpha: f64, protocol: RepairProtocol) -> MVector3 {
    MVector3::new(
        compute_repair_1d(v.x, target.x, alpha, protocol),
        compute_repair_1d(v.y, target.y, alpha, protocol),
        compute_repair_1d(v.z, target.z, alpha, protocol),
    )
}

/// Compute peer-to-peer coupling adjustment for agent $i$.
pub fn compute_peer_coupling(
    agents: &[AgentState],
    idx: usize,
    beta: f64,
) -> MVector3 {
    if agents.len() <= 1 {
        return MVector3::zero();
    }

    let curr = &agents[idx].position;
    let mut sum_diff = MVector3::zero();

    // Couple with adjacent neighbors in ring topology
    let prev_idx = if idx == 0 { agents.len() - 1 } else { idx - 1 };
    let next_idx = (idx + 1) % agents.len();

    let p_prev = &agents[prev_idx].position;
    let p_next = &agents[next_idx].position;

    sum_diff = sum_diff.add(&p_prev.sub(curr));
    sum_diff = sum_diff.add(&p_next.sub(curr));

    sum_diff.scale(beta * 0.5)
}

/// Pseudo-random deterministic noise vector for agent at time t.
pub fn deterministic_agent_noise(agent_id: usize, t: u64, scale: f64) -> MVector3 {
    let nx = (((agent_id as f64 * 13.0 + t as f64 * 37.0).sin()) * scale).clamp(-scale, scale);
    let ny = (((agent_id as f64 * 17.0 + t as f64 * 41.0).cos()) * scale).clamp(-scale, scale);
    let nz = (((agent_id as f64 * 19.0 + t as f64 * 43.0).sin()) * scale).clamp(-scale, scale);
    MVector3::new(nx, ny, nz)
}

/// Advance multi-agent population by one discrete time step.
pub fn step_multi_agent_csl(
    agents: &[AgentState],
    target: &MVector3,
    config: &CSLSimulationConfig,
    t: u64,
) -> Vec<AgentState> {
    let mut next_agents = Vec::with_capacity(agents.len());

    for (i, agent) in agents.iter().enumerate() {
        let repair = compute_repair_3d(&agent.position, target, config.alpha_repair, config.protocol);
        let coupling = compute_peer_coupling(agents, i, config.beta_coupling);
        let noise = deterministic_agent_noise(agent.id, t, config.noise_scale);

        let mut next_pos = agent.position.add(&repair).add(&coupling).add(&noise);
        next_pos = next_pos.clamp(50.0);

        let drift = next_pos.dist(target);
        let is_coherent = drift <= config.epsilon_threshold;
        let collapses = if is_coherent { agent.collapse_count } else { agent.collapse_count + 1 };

        next_agents.push(AgentState {
            id: agent.id,
            time: t + 1,
            position: next_pos,
            drift,
            collapse_count: collapses,
            is_coherent,
        });
    }

    next_agents
}

/// Calculate discrete Shannon entropy of ethical drift distribution across agents.
pub fn calculate_ethical_entropy(agents: &[AgentState], bin_size: f64) -> f64 {
    if agents.is_empty() {
        return 0.0;
    }

    let mut bins = std::collections::HashMap::new();
    for a in agents {
        let bin_idx = (a.drift / bin_size).floor() as i64;
        *bins.entry(bin_idx).or_insert(0usize) += 1;
    }

    let total = agents.len() as f64;
    let mut entropy = 0.0;
    for &count in bins.values() {
        let p = count as f64 / total;
        if p > 0.0 {
            entropy -= p * p.ln();
        }
    }

    entropy
}

/// Run a full multi-agent simulation benchmark for a given attractor target.
pub fn run_csl_benchmark(
    target_name: &str,
    target: MVector3,
    config: &CSLSimulationConfig,
) -> CSLSimulationSummary {
    let mut agents = Vec::with_capacity(config.agent_count);

    // Initialize agents distributed around target
    for i in 0..config.agent_count {
        let offset = ((i as f64 * 0.1).sin() * 0.5, (i as f64 * 0.1).cos() * 0.5, 0.2);
        let init_pos = MVector3::new(target.x + offset.0, target.y + offset.1, target.z + offset.2);
        agents.push(AgentState::new(i, 0, init_pos, &target, config.epsilon_threshold));
    }

    let mut total_collapses = 0u64;
    let mut convergence_step = None;
    let mut drift_sum = 0.0;

    for t in 0..config.step_count {
        agents = step_multi_agent_csl(&agents, &target, config, t as u64);

        let mean_t_drift = agents.iter().map(|a| a.drift).sum::<f64>() / agents.len() as f64;
        drift_sum += mean_t_drift;

        let collapses_t = agents.iter().filter(|a| !a.is_coherent).count() as u64;
        total_collapses += collapses_t;

        if convergence_step.is_none() && mean_t_drift < (config.epsilon_threshold * 0.5) {
            convergence_step = Some(t);
        }
    }

    let mean_drift = drift_sum / config.step_count as f64;
    let entropy = calculate_ethical_entropy(&agents, 0.02);
    let coherent_count = agents.iter().filter(|a| a.is_coherent).count();
    let final_coherence_rate = coherent_count as f64 / agents.len() as f64;

    CSLSimulationSummary {
        target_name: target_name.to_string(),
        target_vector: target,
        protocol: config.protocol,
        mean_drift,
        ethical_entropy: entropy,
        total_collapses,
        convergence_step,
        final_coherence_rate,
    }
}

/// CSL Gatekeeper: Fail-closed validation for lawful state transitions.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CSLValidationResult {
    pub is_lawful: bool,
    pub reason: String,
    pub witness_digest: String,
}

pub fn validate_csl_agent_transition(
    st_prev: &AgentState,
    st_curr: &AgentState,
    max_drift_allowed: f64,
) -> CSLValidationResult {
    if st_curr.time != st_prev.time + 1 {
        return CSLValidationResult {
            is_lawful: false,
            reason: "Temporal progression broken".to_string(),
            witness_digest: "ERR_CSL_TEMPORAL_NON_MONOTONIC".to_string(),
        };
    }

    if st_curr.drift > max_drift_allowed {
        return CSLValidationResult {
            is_lawful: false,
            reason: "Ethical drift exceeded allowable tolerance".to_string(),
            witness_digest: "ERR_CSL_ETHICAL_DRIFT_EXCEEDED".to_string(),
        };
    }

    CSLValidationResult {
        is_lawful: true,
        reason: "Agent transition satisfies CSL constraints lawfully".to_string(),
        witness_digest: "CSL_WITNESS_VERIFIED_STABLE".to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cubic_repair_convergence() {
        let target = MVector3::phi_target();
        let config = CSLSimulationConfig {
            agent_count: 10,
            step_count: 50,
            protocol: RepairProtocol::Cubic,
            ..Default::default()
        };

        let summary = run_csl_benchmark("Phi", target, &config);
        assert!(summary.mean_drift < 1.0);
        assert!(summary.final_coherence_rate >= 0.0);
    }

    #[test]
    fn test_csl_gatekeeper_validation() {
        let target = MVector3::phi_target();
        let st0 = AgentState::new(0, 0, MVector3::new(1.62, 1.62, 1.62), &target, 0.05);
        let st1 = AgentState::new(0, 1, MVector3::new(1.618, 1.618, 1.618), &target, 0.05);

        let res = validate_csl_agent_transition(&st0, &st1, 0.5);
        assert!(res.is_lawful);
    }
}
