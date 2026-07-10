use std::collections::HashMap;
use serde::{Deserialize, Serialize};

pub fn get_prime_factors(n: u64) -> HashMap<u64, u32> {
    if n <= 1 {
        return HashMap::new();
    }
    
    let mut factors = HashMap::new();
    let mut d = 2;
    let mut temp = n;
    while d * d <= temp {
        while temp % d == 0 {
            *factors.entry(d).or_insert(0) += 1;
            temp /= d;
        }
        d += 1;
    }
    if temp > 1 {
        *factors.entry(temp).or_insert(0) += 1;
    }
    factors
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrimeAnchor {
    pub value: u64,
}

impl PrimeAnchor {
    pub fn new(value: u64) -> Self {
        PrimeAnchor { value }
    }

    pub fn decompose(&self) -> HashMap<u64, u32> {
        get_prime_factors(self.value)
    }
}
