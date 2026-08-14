use num_rational::Ratio;
use num_bigint::BigInt;
use std::collections::HashMap;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct PrimeWord {
    pub exponents: Vec<u32>,
    pub primes: Vec<u64>,
}

impl PrimeWord {
    pub fn new(exponents: Vec<u32>, primes: Vec<u64>) -> Self {
        Self { exponents, primes }
    }

    pub fn omega(&self) -> u32 {
        self.exponents.iter().sum()
    }

    pub fn n(&self) -> BigInt {
        let mut n = BigInt::from(1);
        for (p, k) in self.primes.iter().zip(self.exponents.iter()) {
            n *= BigInt::from(*p).pow(*k);
        }
        n
    }
}

pub fn prime_words_up_to(omega_max: u32, primes: Vec<u64>) -> Vec<PrimeWord> {
    let mut results = Vec::new();
    let num_primes = primes.len();
    
    fn helper(depth: usize, current: &mut Vec<u32>, remaining: u32, num_primes: usize, primes: &[u64], results: &mut Vec<PrimeWord>) {
        if depth == num_primes {
            results.push(PrimeWord::new(current.clone(), primes.to_vec()));
            return;
        }
        for k in 0..=remaining {
            current.push(k);
            helper(depth + 1, current, remaining - k, num_primes, primes, results);
            current.pop();
        }
    }
    
    helper(0, &mut Vec::new(), omega_max, num_primes, &primes, &mut results);
    results
}

pub type PrimeState = HashMap<PrimeWord, Ratio<BigInt>>;

pub fn project_to_omega(state: &PrimeState) -> HashMap<u32, Ratio<BigInt>> {
    let mut result = HashMap::new();
    for (w, coeff) in state {
        let omega = w.omega();
        let entry = result.entry(omega).or_insert_with(|| Ratio::from(BigInt::from(0)));
        *entry += coeff;
    }
    result
}
