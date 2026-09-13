//! Rust port of `packages/rust/atomic-calculator/civic_simulator.py`.
//!
//! Faithful reproduction of the floating-point `Multiplicity` / `CivicSimulator`
//! model (Hundian ground state target of $3.00, 10% mint/burn adjustment rate,
//! 0.2 civic-state scaling). All `f64` arithmetic mirrors Python exactly.

/// `Multiplicity` dataclass: `reciprocity` with `calculate() = 2*r + 1`.
pub struct Multiplicity {
    pub reciprocity: f64,
}

impl Multiplicity {
    pub fn new(reciprocity: f64) -> Self {
        Self { reciprocity }
    }

    pub fn calculate(&self) -> f64 {
        2.0 * self.reciprocity + 1.0
    }
}

/// `calculate_civic_state(lambda_m, factors, res, emb)` → `λ_m * Σfactors * res * emb`.
pub fn calculate_civic_state(lambda_m: f64, factors: &[f64], res: f64, emb: f64) -> f64 {
    let factor_sum: f64 = factors.iter().sum();
    lambda_m * factor_sum * res * emb
}

/// One recorded history sample, mirroring the Python dict written by `step`.
#[derive(Debug, Clone, PartialEq)]
pub struct HistoryEntry {
    pub time: i64,
    pub s_civic: f64,
    pub v_msc: f64,
    pub supply: f64,
}

/// `CivicSimulator` — stablecoin state machine with mint/burn feedback.
pub struct CivicSimulator {
    pub target_value: f64,
    pub time: i64,
    pub history: Vec<HistoryEntry>,
}

impl Default for CivicSimulator {
    fn default() -> Self {
        Self::new()
    }
}

impl CivicSimulator {
    /// `CivicSimulator()` — target value $3.00 (Hundian Ground State), t=0.
    pub fn new() -> Self {
        Self {
            target_value: 3.0,
            time: 0,
            history: Vec::new(),
        }
    }

    /// `compute_valuation(s_civic, c_t)` → `1 + S(t) + C(t)`, where
    /// `S(t) = s_civic * 0.2` (simulation scaling factor).
    pub fn compute_valuation(&self, s_civic: f64, c_t: f64) -> f64 {
        let s_t = s_civic * 0.2;
        1.0 + s_t + c_t
    }

    /// One engine step. Returns the new supply after the 10% mint/burn
    /// adjustment toward the target valuation.
    pub fn step(
        &mut self,
        factors: &[f64],
        lambda_m: f64,
        res: f64,
        emb: f64,
        c_t: f64,
        supply: f64,
    ) -> f64 {
        // Step 1: Engine computes Civic State.
        let s_civic = calculate_civic_state(lambda_m, factors, res, emb);

        // Step 2: Compute token value.
        let v_msc = self.compute_valuation(s_civic, c_t);

        // Step 3: Adjust supply based on deviation from target state ($3.0).
        let deviation = self.target_value - v_msc;
        let mint_burn_rate = 0.1; // 10% adjustment rate
        let new_supply = supply * (1.0 - (deviation * mint_burn_rate));

        self.history.push(HistoryEntry {
            time: self.time,
            s_civic,
            v_msc,
            supply,
        });
        self.time += 1;
        new_supply
    }
}

/// So the `Multiplicity` placeholder and `calculate` remain observable/tested.
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn multiplicity_calculate_is_two_r_plus_one() {
        assert_eq!(crate::Multiplicity::new(0.5).calculate(), 2.0);
        assert_eq!(crate::Multiplicity::new(1.0).calculate(), 3.0);
    }

    #[test]
    fn civic_state_is_lambda_times_factor_sum_res_emb() {
        let s = calculate_civic_state(0.5, &[1.0f64, 1.0, 1.0, 1.0], 1.0, 1.0);
        assert!((s - 2.0).abs() < 1e-12);
        let s = calculate_civic_state(0.5, &[1.5f64; 4], 0.8, 0.8);
        assert!((s - 1.92).abs() < 1e-12);
    }

    #[test]
    fn valuation_at_ground_state_with_collateral_hits_target() {
        let sim = CivicSimulator::new();
        // With base factors λ=0.5, res=emb=1: s_civic=2.0 → S=0.4, C=0.5
        // → V = 1.9. Not the target yet (3.0).
        let v = sim.compute_valuation(2.0, 0.5);
        assert!((v - 1.9).abs() < 1e-12);
    }

    #[test]
    fn step_tracks_history_and_progresses_time() {
        let mut sim = CivicSimulator::new();
        let new_supply = sim.step(&[1.0f64; 4], 0.5, 1.0, 1.0, 0.5, 10000.0);
        assert_eq!(sim.time, 1);
        assert_eq!(sim.history.len(), 1);
        let r = &sim.history[0];
        assert_eq!(r.time, 0);
        assert!((r.s_civic - 2.0).abs() < 1e-12);
        assert!((r.v_msc - 1.9).abs() < 1e-12);
        assert_eq!(r.supply, 10000.0);
        // deviation = 3.0 - 1.9 = 1.1 → supply * (1 - 0.11) = 8900.0
        assert!((new_supply - 8900.0).abs() < 1e-9);
    }

    #[test]
    fn step_at_ground_state_valuation_preserves_supply() {
        // If V_MSC equals target (3.0), deviation is zero → supply unchanged.
        let mut sim = CivicSimulator::new();
        // Need s_civic such that 1 + 0.2*s_civic + c_t = 3.0 with c_t = 0.5
        // → s_civic = 7.5. Back out factors: λ=0.5, sum=15, res*emb=1.0.
        let new_supply = sim.step(&[3.75f64; 4], 0.5, 1.0, 1.0, 0.5, 5000.0);
        assert!(
            (new_supply - 5000.0).abs() < 1e-9,
            "no deviation -> no mint/burn"
        );
    }
}
