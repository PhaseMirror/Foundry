use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ArchemedianError {
    #[error("Inputs must be within [0, 1]")]
    InvalidInputRange,
    #[error("ACFL operators require arity >= 2")]
    InsufficientArity,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OperatorResult {
    pub value: f64,
    pub operator: String,
    pub arity: usize,
}

fn validate_inputs(inputs: &[f64]) -> Result<Vec<f64>, ArchemedianError> {
    if inputs.len() < 2 {
        return Err(ArchemedianError::InsufficientArity);
    }
    for &value in inputs {
        if value < 0.0 || value > 1.0 {
            return Err(ArchemedianError::InvalidInputRange);
        }
    }
    Ok(inputs.to_vec())
}

fn geometric_mean(values: &[f64]) -> f64 {
    if values.iter().any(|&v| v == 0.0) {
        return 0.0;
    }
    let log_sum: f64 = values.iter().map(|&v| v.ln()).sum();
    (log_sum / values.len() as f64).exp()
}

pub fn standard_negation(value: f64) -> Result<f64, ArchemedianError> {
    if value < 0.0 || value > 1.0 {
        return Err(ArchemedianError::InvalidInputRange);
    }
    Ok(1.0 - value)
}

pub fn standard_conjunction(inputs: &[f64]) -> Result<OperatorResult, ArchemedianError> {
    let values = validate_inputs(inputs)?;
    let result = geometric_mean(&values);
    Ok(OperatorResult {
        value: result,
        operator: "standard_conjunction".to_string(),
        arity: values.len(),
    })
}

pub fn standard_disjunction(inputs: &[f64]) -> Result<OperatorResult, ArchemedianError> {
    let values = validate_inputs(inputs)?;
    let negated: Vec<f64> = values
        .iter()
        .map(|&v| standard_negation(v))
        .collect::<Result<_, _>>()?;
    
    let result = 1.0 - geometric_mean(&negated);
    Ok(OperatorResult {
        value: result,
        operator: "standard_disjunction".to_string(),
        arity: values.len(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_standard_conjunction() {
        let inputs = vec![0.5, 0.5];
        let res = standard_conjunction(&inputs).unwrap();
        assert!((res.value - 0.5).abs() < 1e-10);
    }

    #[test]
    fn test_standard_disjunction() {
        let inputs = vec![0.5, 0.5];
        let res = standard_disjunction(&inputs).unwrap();
        assert!((res.value - 0.5).abs() < 1e-10);
    }
}
