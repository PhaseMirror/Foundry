//! Reserve Network Design and Management Optimization (M³EM §3.4)

use crate::types::HabitatGraph;

/// Reserve design configuration specifying cost budgets and connectivity goals.
pub struct ReserveDesignProblem {
    pub graph: HabitatGraph,
    pub patch_costs: Vec<f64>,
    pub patch_extinction_risks: Vec<f64>,
    pub budget: f64,
}

impl ReserveDesignProblem {
    pub fn new(
        graph: HabitatGraph,
        patch_costs: Vec<f64>,
        patch_extinction_risks: Vec<f64>,
        budget: f64,
    ) -> Self {
        Self {
            graph,
            patch_costs,
            patch_extinction_risks,
            budget,
        }
    }

    /// Evaluates objective function: J(u) = Total Preserved Metapopulation Value - Connectivity Penalty.
    pub fn evaluate_objective(&self, selection: &[bool]) -> f64 {
        let n = self.graph.num_nodes;
        let mut total_cost = 0.0;
        let mut total_risk_reduction = 0.0;
        let mut connectivity_bonus = 0.0;

        for i in 0..n {
            if selection[i] {
                total_cost += self.patch_costs[i];
                total_risk_reduction += 1.0 - self.patch_extinction_risks[i];

                // Corridor connectivity bonus
                for j in (i + 1)..n {
                    if selection[j] && self.graph.adjacency_matrix[i][j] > 0.0 {
                        connectivity_bonus += self.graph.adjacency_matrix[i][j];
                    }
                }
            }
        }

        // Penalty for exceeding budget
        let budget_penalty = if total_cost > self.budget {
            10.0 * (total_cost - self.budget)
        } else {
            0.0
        };

        total_risk_reduction + 0.5 * connectivity_bonus - budget_penalty
    }

    /// Solves reserve design using Classical Simulated Annealing.
    pub fn solve_simulated_annealing<R: rand::Rng>(&self, iterations: usize, rng: &mut R) -> (Vec<bool>, f64) {
        let n = self.graph.num_nodes;
        let mut current_solution = vec![false; n];
        // Greedily pick initial within budget
        let mut current_cost = 0.0;
        for i in 0..n {
            if current_cost + self.patch_costs[i] <= self.budget {
                current_solution[i] = true;
                current_cost += self.patch_costs[i];
            }
        }

        let mut current_score = self.evaluate_objective(&current_solution);
        let mut best_solution = current_solution.clone();
        let mut best_score = current_score;

        let mut temp = 10.0;
        let cooling_rate = 0.995;

        for _ in 0..iterations {
            let flip_idx = rng.gen_range(0..n);
            let mut candidate = current_solution.clone();
            candidate[flip_idx] = !candidate[flip_idx];

            let candidate_score = self.evaluate_objective(&candidate);
            let delta = candidate_score - current_score;

            if delta > 0.0 || (delta / temp).exp() > rng.gen() {
                current_solution = candidate;
                current_score = candidate_score;

                if current_score > best_score {
                    best_solution = current_solution.clone();
                    best_score = current_score;
                }
            }

            temp *= cooling_rate;
        }

        (best_solution, best_score)
    }

    /// Formulates Quadratic Unconstrained Binary Optimization (QUBO) Hamiltonian matrix Q.
    pub fn formulate_qubo_matrix(&self) -> Vec<Vec<f64>> {
        let n = self.graph.num_nodes;
        let mut q = vec![vec![0.0; n]; n];

        for i in 0..n {
            // Linear diagonal terms (risk reduction minus cost penalty)
            q[i][i] = -(1.0 - self.patch_extinction_risks[i]) + 0.5 * self.patch_costs[i];

            for j in (i + 1)..n {
                // Off-diagonal quadratic coupling (corridor connectivity bonus)
                let w = self.graph.adjacency_matrix[i][j];
                q[i][j] = -0.5 * w;
                q[j][i] = -0.5 * w;
            }
        }

        q
    }
}
