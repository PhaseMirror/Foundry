use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct State(pub Vec<i32>);

pub const PRIME_MAP: [u64; 3] = [2, 3, 5];
pub const NODES: [&str; 3] = ["A", "B", "C"];

pub fn prime_support(state: &State) -> Vec<String> {
    state.0.iter().enumerate()
        .filter(|&(_, &exp)| exp > 0)
        .map(|(i, _)| NODES[i].to_string())
        .collect()
}

pub fn prime_signature(state: &State) -> String {
    let support: Vec<(&str, i32)> = NODES.iter().zip(state.0.iter())
        .filter(|&(_, &exp)| exp > 0)
        .map(|(&id, &exp)| (id, exp))
        .collect();
    
    if support.is_empty() {
        return "1".to_string();
    }
    
    support.iter()
        .map(|&(id, exp)| {
            let p = PRIME_MAP[NODES.iter().position(|&n| n == id).unwrap()];
            if exp == 1 {
                format!("{}", p)
            } else {
                format!("{}^{}", p, exp)
            }
        })
        .collect::<Vec<String>>()
        .join("·")
}

pub fn prime_product(state: &State) -> f64 {
    state.0.iter().enumerate().fold(1.0, |acc, (i, &exp)| {
        acc * (PRIME_MAP[i] as f64).powi(exp)
    })
}

pub fn l1_norm(state: &State) -> i32 {
    state.0.iter().map(|&exp| exp.abs()).sum()
}

pub fn normalized_profile(state: &State) -> Vec<f64> {
    let norm = l1_norm(state) as f64;
    if norm == 0.0 {
        return vec![0.0; state.0.len()];
    }
    state.0.iter().map(|&exp| exp as f64 / norm).collect()
}
