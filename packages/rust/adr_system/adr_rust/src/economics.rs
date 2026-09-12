//! # CryptoEconomic Layer
//! Calculates the target valuation for the Multiplicity Stablecoin (MSC).

pub struct NetworkHealth {
    pub sovereignty_index: f64,
    pub coherence_index: f64,
}

impl NetworkHealth {
    pub fn new(sovereignty_index: f64, coherence_index: f64) -> Self {
        Self {
            sovereignty_index,
            coherence_index,
        }
    }
}

pub struct EconomicOracle {
    current_valuation: f64,
}

impl EconomicOracle {
    pub fn new(current_valuation: f64) -> Self {
        Self { current_valuation }
    }

    /// Compute the target valuation based on structural metrics
    /// V_target = 1 + S + C
    pub fn compute_target_valuation(&self, health: &NetworkHealth) -> f64 {
        1.0 + health.sovereignty_index + health.coherence_index
    }

    /// Determines if the Phase Mirror should mint (true) or burn (false) tokens
    pub fn should_mint(&self, health: &NetworkHealth) -> bool {
        let target = self.compute_target_valuation(health);
        self.current_valuation > target
    }

    pub fn update_valuation(&mut self, new_val: f64) {
        self.current_valuation = new_val;
    }
}
