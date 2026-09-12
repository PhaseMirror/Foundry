//! Data types and core structures for M³EM / MQEM

use serde::{Deserialize, Serialize};

/// Identifier for a habitat patch node.
pub type NodeId = usize;

/// State vector of a habitat patch across d ecological channels (e.g. species biomass, occupancy).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PatchState {
    pub values: Vec<f64>,
}

impl PatchState {
    pub fn new(values: Vec<f64>) -> Self {
        Self { values }
    }

    pub fn zeros(d: usize) -> Self {
        Self {
            values: vec![0.0; d],
        }
    }
}

/// Dispersal edge connecting two habitat patches with coupling strength.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct DispersalEdge {
    pub source: NodeId,
    pub target: NodeId,
    pub weight: f64,
}

/// Habitat patch network graph G = (V, E).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct HabitatGraph {
    pub num_nodes: usize,
    pub edges: Vec<DispersalEdge>,
    pub adjacency_matrix: Vec<Vec<f64>>,
}

impl HabitatGraph {
    pub fn new(num_nodes: usize, edges: Vec<DispersalEdge>) -> Self {
        let mut adj = vec![vec![0.0; num_nodes]; num_nodes];
        for edge in &edges {
            if edge.source < num_nodes && edge.target < num_nodes {
                adj[edge.source][edge.target] = edge.weight;
                adj[edge.target][edge.source] = edge.weight;
            }
        }
        Self {
            num_nodes,
            edges,
            adjacency_matrix: adj,
        }
    }
}

/// Model hyper-parameters and ecological configuration.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ModelConfig {
    pub dim_d: usize,
    pub delay_tau: usize,
    pub dt: f64,
    pub noise_sigma: f64,
    pub growth_rate: f64,
    pub carrying_capacity: f64,
    pub coupling_scale: f64,
}

impl Default for ModelConfig {
    fn default() -> Self {
        Self {
            dim_d: 1,
            delay_tau: 2,
            dt: 0.05,
            noise_sigma: 0.02,
            growth_rate: 1.2,
            carrying_capacity: 10.0,
            coupling_scale: 0.15,
        }
    }
}

/// Observation record at a habitat patch node.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ObservationRecord {
    pub node_id: NodeId,
    pub time_step: usize,
    pub value: f64,
}
