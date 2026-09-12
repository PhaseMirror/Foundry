// src/drmm_state.rs
use serde::{Serialize, Deserialize};
use crate::ir::Expr;

/// Canonical representation of the DRMM system state.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct DRMMState {
    pub timestep: u64,
    pub tensor_state: Expr, // placeholder for a tensor expression
    pub prime_weights: Vec<f64>,
    pub entropy: f64,
    pub recursion_depth: usize,
    pub lawful: bool,
}
