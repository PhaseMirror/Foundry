use serde::{Deserialize, Serialize};
use crate::core::LAMBDA_M;
use crate::stabilization::{SemanticVector, DynamicOperator, project_lambda_m, semantic_evolution_step};

/// Individual Agent in the MARCL network.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct AgentState {
    pub id: usize,
    pub psi: SemanticVector,
    pub regret: f64,
    pub resilience: f64,
}

impl AgentState {
    pub fn new(id: usize, dim: usize) -> Self {
        Self {
            id,
            psi: SemanticVector::equilibrium(dim),
            regret: 0.0,
            resilience: 1.0,
        }
    }

    /// Compute resilience rho_j = exp(-gamma * regret_j).
    pub fn compute_resilience(regret: f64, gamma: f64) -> f64 {
        (-gamma * regret).exp().clamp(0.01, 1.0)
    }

    /// Compute discrepancy delta_j = ||psi_j - Pi_{Lambda_m}(psi_j)||^2.
    pub fn compute_discrepancy(&self) -> f64 {
        let proj = project_lambda_m(&self.psi, 0.65);
        self.psi.dist_sq(&proj)
    }
}

/// Distributed MARCL Cluster State.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MARCLCluster {
    pub time: u64,
    pub agents: Vec<AgentState>,
    pub trust_matrix: Vec<Vec<f64>>,    // mu_ij in [0, 1]
    pub regret_tensor: Vec<Vec<f64>>,   // Gamma_ij
    pub godelian_ledger: Vec<Vec<f64>>, // L_ij
}

impl MARCLCluster {
    /// Initialize a 4-agent standard MARCL cluster.
    pub fn new_4agents() -> Self {
        let agents = (0..4).map(|id| AgentState::new(id, 4)).collect();
        let mut trust_matrix = vec![vec![0.5; 4]; 4];
        for i in 0..4 {
            trust_matrix[i][i] = 1.0;
        }
        let regret_tensor = vec![vec![0.0; 4]; 4];
        let godelian_ledger = vec![vec![0.0; 4]; 4];

        Self {
            time: 0,
            agents,
            trust_matrix,
            regret_tensor,
            godelian_ledger,
        }
    }

    /// Inject an epistemic shock to a specified agent.
    pub fn inject_shock(&mut self, agent_id: usize, shock_vector: SemanticVector) {
        if let Some(agent) = self.agents.get_mut(agent_id) {
            agent.psi = shock_vector;
            agent.regret = 0.8;
            agent.resilience = AgentState::compute_resilience(agent.regret, 2.0);
        }
    }

    /// Inter-agent peer correction for agent i:
    /// sum_{j != i} mu_ij * (Pi(psi_j) - psi_i)
    pub fn compute_peer_correction(&self, i: usize) -> SemanticVector {
        let current_agent = &self.agents[i];
        let dim = current_agent.psi.components.len();
        let mut corrected = current_agent.psi.components.clone();

        for k in 0..dim {
            let mut peer_sum = 0.0;
            for j in 0..self.agents.len() {
                if i != j {
                    let peer = &self.agents[j];
                    let mu = self.trust_matrix[i][j];
                    let diff = peer.psi.components[k] - current_agent.psi.components[k];
                    peer_sum += mu * diff;
                }
            }
            corrected[k] += 0.1 * peer_sum;
        }
        SemanticVector::new(corrected)
    }

    /// Perform a single step of distributed MARCL evolution.
    pub fn step(&self) -> Self {
        let next_time = self.time + 1;
        let n = self.agents.len();
        let eq = SemanticVector::equilibrium(4);
        let id_op = DynamicOperator::identity(4);

        // 1. Update semantic vectors and local regret
        let mut updated_agents = Vec::with_capacity(n);
        for i in 0..n {
            let peer_corr = self.compute_peer_correction(i);
            let local_evol = semantic_evolution_step(&peer_corr, &id_op, &eq, LAMBDA_M);

            let disc = {
                let proj = project_lambda_m(&local_evol, 0.65);
                local_evol.dist_sq(&proj)
            };

            let new_regret = if disc > 0.02 {
                (self.agents[i].regret + 0.15).min(1.0)
            } else {
                (self.agents[i].regret - 0.10).max(0.0)
            };
            let new_resilience = AgentState::compute_resilience(new_regret, 2.0);

            updated_agents.push(AgentState {
                id: i,
                psi: local_evol,
                regret: new_regret,
                resilience: new_resilience,
            });
        }

        // 2. Update dynamic trust matrix mu_ij
        let mut next_trust = self.trust_matrix.clone();
        for i in 0..n {
            for j in 0..n {
                if i != j {
                    let disc_j = self.agents[j].compute_discrepancy();
                    if disc_j > 0.02 {
                        // Penalize trust for shocked / misaligned peer
                        next_trust[i][j] = (self.trust_matrix[i][j] - 0.12).max(0.05);
                    } else {
                        // Restore trust with resilience reinforcement
                        let boost = 0.08 * updated_agents[j].resilience;
                        next_trust[i][j] = (self.trust_matrix[i][j] + boost).min(0.85);
                    }
                }
            }
        }

        // 3. Regret Transfer Tensor Gamma_ij = d(Regret_i) / d(mu_ij)
        let mut next_regret_tensor = vec![vec![0.0; n]; n];
        for i in 0..n {
            for j in 0..n {
                if i != j {
                    let disc_j = updated_agents[j].compute_discrepancy();
                    next_regret_tensor[i][j] = if disc_j > 0.02 { 1.0 } else { -1.0 };
                }
            }
        }

        // 4. Godelian Accountability Ledger: L_ij += mu_ij * rho_j * (-Gamma_ij)
        let mut next_ledger = self.godelian_ledger.clone();
        for i in 0..n {
            for j in 0..n {
                let mu = next_trust[i][j];
                let rho = updated_agents[j].resilience;
                let gamma = next_regret_tensor[i][j];
                let flow = mu * rho * (-gamma) * 0.1;
                next_ledger[i][j] += flow;
            }
        }

        Self {
            time: next_time,
            agents: updated_agents,
            trust_matrix: next_trust,
            regret_tensor: next_regret_tensor,
            godelian_ledger: next_ledger,
        }
    }

    /// Simulate MARCL evolution over N steps.
    pub fn iterate(&self, steps: usize) -> Self {
        let mut curr = self.clone();
        for _ in 0..steps {
            curr = curr.step();
        }
        curr
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_marcl_shock_trust_reallocation() {
        let mut cluster = MARCLCluster::new_4agents();
        let shock = SemanticVector::new(vec![0.95, 0.95, 0.95, 0.95]);
        cluster.inject_shock(3, shock);

        let initial_trust_to_shocked = cluster.trust_matrix[0][3];
        let step1 = cluster.step();
        let trust_after_shock = step1.trust_matrix[0][3];

        assert!(trust_after_shock < initial_trust_to_shocked, "Trust to shocked agent must drop (was {}, now {})", initial_trust_to_shocked, trust_after_shock);

        // Run recovery over 10 steps
        let recovered = step1.iterate(10);
        let final_trust = recovered.trust_matrix[0][3];
        assert!(final_trust > trust_after_shock, "Trust must recover as shock resolves (was {}, recovered to {})", trust_after_shock, final_trust);
    }
}
