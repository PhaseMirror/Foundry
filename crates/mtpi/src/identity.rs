use std::collections::HashMap;
use num_bigint::BigUint;
use num_prime::nt_funcs::is_prime;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrimeIdentityState {
    pub value: BigUint,
    pub prime_form: HashMap<String, u32>,
    pub entropy: f64,
    pub lawful_score: f64,
}

impl PrimeIdentityState {
    pub fn from_value(n: BigUint) -> Self {
        let prime_form = get_prime_factors(&n);
        let entropy = calculate_entropy(&prime_form);
        let lawful_score = calculate_lawfulness(&prime_form);

        Self {
            value: n,
            prime_form: prime_form.iter().map(|(p, e)| (p.to_string(), *e)).collect(),
            entropy,
            lawful_score,
        }
    }
}

pub fn get_prime_factors(n: &BigUint) -> HashMap<BigUint, u32> {
    let mut factors = HashMap::new();
    if n < &BigUint::from(2u32) {
        return factors;
    }

    let mut temp = n.clone();
    let mut d = BigUint::from(2u32);

    while &temp % &d == BigUint::from(0u32) {
        *factors.entry(d.clone()).or_insert(0) += 1;
        temp /= &d;
    }

    d = BigUint::from(3u32);
    while &d * &d <= temp {
        while &temp % &d == BigUint::from(0u32) {
            *factors.entry(d.clone()).or_insert(0) += 1;
            temp /= &d;
        }
        d += 2u32;
    }

    if temp > BigUint::from(1u32) {
        *factors.entry(temp).or_insert(0) += 1;
    }

    factors
}

pub fn calculate_entropy(prime_form: &HashMap<BigUint, u32>) -> f64 {
    if prime_form.is_empty() {
        return 0.0;
    }

    let mut entropy = 0.0;
    for (prime, exponent) in prime_form {
        let p_f = prime.to_string().parse::<f64>().unwrap_or(0.0);
        if p_f > 0.0 {
            entropy += (p_f.ln() / 2.0f64.ln()) * (*exponent as f64);
        }
    }

    entropy
}

pub fn calculate_lawfulness(prime_form: &HashMap<BigUint, u32>) -> f64 {
    if prime_form.is_empty() {
        return 0.0;
    }

    let mut total_lawfulness = 0.0;
    for prime in prime_form.keys() {
        if is_prime(prime, None).probably() {
            total_lawfulness += 1.0;
        } else {
            total_lawfulness += 0.5;
        }
    }

    total_lawfulness / (prime_form.len() as f64)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;
    use num_bigint::BigUint;

    #[test]
    fn test_prime_factors() {
        let n = BigUint::from(12u32); // 2^2 * 3
        let factors = get_prime_factors(&n);
        assert_eq!(factors.get(&BigUint::from(2u32)), Some(&2));
        assert_eq!(factors.get(&BigUint::from(3u32)), Some(&1));
    }

    #[test]
    fn test_entropy() {
        let mut factors = HashMap::new();
        factors.insert(BigUint::from(2u32), 1);
        let entropy = calculate_entropy(&factors);
        assert!((entropy - 1.0).abs() < 1e-9);

        factors.insert(BigUint::from(4u32), 1);
        let entropy2 = calculate_entropy(&factors);
        assert!((entropy2 - 3.0).abs() < 1e-9);
    }
}
