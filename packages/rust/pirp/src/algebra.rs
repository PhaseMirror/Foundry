use serde::{Deserialize, Serialize};

pub fn is_idempotent(value: f64, weights: &[f64], tol: f64) -> bool {
    let result = evaluate_weighted_conjunction(
        &vec![value; weights.len()], 
        weights
    );
    (result.score - value).abs() < tol
}

pub fn zero_absorbs(weights: &[f64], tol: f64) -> bool {
    let n = weights.len();
    for i in 0..n {
        let mut inputs = vec![0.5; n];
        inputs[i] = 0.0;
        let result = evaluate_weighted_conjunction(&inputs, weights);
        let expected: f64 = inputs.iter().zip(weights).map(|(&v, &wt)| v * wt).sum();
        if (result.score - expected).abs() > tol {
            return false;
        }
    }
    true
}

pub fn one_boundary(weights: &[f64], tol: f64) -> bool {
    let inputs = vec![1.0; weights.len()];
    let result = evaluate_weighted_conjunction(&inputs, weights);
    (result.score - 1.0).abs() < tol
}

pub fn elasticity(inputs: &[f64], weights: &[f64], index: usize) -> f64 {
    let f0 = evaluate_weighted_conjunction(inputs, weights).score;
    if f0 == 0.0 {
        return 0.0;
    }
    weights[index] * inputs[index] / f0
}

pub fn lipschitz_bound(weights: &[f64]) -> f64 {
    weights.iter().sum()
}

pub fn continuity_holds(inputs1: &[f64], inputs2: &[f64], weights: &[f64], tol: f64) -> bool {
    let f1 = evaluate_weighted_conjunction(inputs1, weights).score;
    let f2 = evaluate_weighted_conjunction(inputs2, weights).score;
    let l = lipschitz_bound(weights);
    let max_diff = inputs1.iter().zip(inputs2).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    (f1 - f2).abs() <= l * max_diff + tol
}

pub fn weight_concentration(weights: &[f64]) -> f64 {
    weights.iter().map(|wi| wi * wi).sum()
}

pub fn weight_entropy(weights: &[f64]) -> f64 {
    -weights.iter().filter(|&&wi| wi > 0.0).map(|&wi| wi * wi.ln()).sum::<f64>()
}

pub fn effective_inputs(weights: &[f64]) -> f64 {
    weight_entropy(weights).exp()
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OperatorResult {
    pub score: f64,
}

pub fn evaluate_weighted_conjunction(inputs: &[f64], weights: &[f64]) -> OperatorResult {
    let score = inputs.iter().zip(weights).map(|(&v, &wt)| v * wt).sum();
    OperatorResult { score }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_algebraic_properties() {
        let weights = vec![0.5, 0.5];
        assert!(one_boundary(&weights, 1e-12));
        assert!(zero_absorbs(&weights, 1e-12));
        assert!(is_idempotent(0.5, &weights, 1e-12));
        
        let l = lipschitz_bound(&weights);
        assert!((l - 1.0).abs() < 1e-12);
    }
}
