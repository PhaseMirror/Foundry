use num_prime::nt_funcs::is_prime;

#[derive(Debug, Clone)]
pub struct PrimeGateResult {
    pub epoch_index: u64,
    pub is_prime: bool,
}

pub struct PrimeGate;

impl PrimeGate {
    pub fn new() -> Self {
        Self
    }

    pub fn evaluate(&self, epoch_index: u64) -> PrimeGateResult {
        let is_prime = is_prime(&epoch_index, None).probably();
        PrimeGateResult {
            epoch_index,
            is_prime,
        }
    }
}
