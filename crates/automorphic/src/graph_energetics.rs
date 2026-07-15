use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphVertex {
    pub id: u64,
    pub prime_label: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphEdge {
    pub source: GraphVertex,
    pub target: GraphVertex,
    pub weight: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphStructure {
    pub vertices: Vec<GraphVertex>,
    pub edges: Vec<GraphEdge>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CertifiedGraphEnergetics {
    pub graph: GraphStructure,
    pub energy_bound: f64,
}

#[derive(Debug, thiserror::Error)]
pub enum EnergyViolation {
    #[error("energy bound exceeded: {current} > {bound}")]
    BoundExceeded { current: f64, bound: f64 },
}

impl CertifiedGraphEnergetics {
    pub fn update_edge(
        &mut self,
        edge_idx: usize,
        new_weight: f64,
    ) -> Result<(), EnergyViolation> {
        let delta = new_weight - self.graph.edges[edge_idx].weight;
        let new_energy = self.graph_energy() + delta;
        if new_energy > self.energy_bound {
            return Err(EnergyViolation::BoundExceeded {
                current: new_energy,
                bound: self.energy_bound,
            });
        }
        self.graph.edges[edge_idx].weight = new_weight;
        Ok(())
    }

    pub fn graph_energy(&self) -> f64 {
        self.graph.edges.iter().map(|e| e.weight).sum()
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn proof_update_edge_preserves_bound() {
        let mut cert = CertifiedGraphEnergetics {
            graph: GraphStructure {
                vertices: vec![
                    GraphVertex { id: 0, prime_label: 2 },
                    GraphVertex { id: 1, prime_label: 3 },
                ],
                edges: vec![GraphEdge {
                    source: GraphVertex { id: 0, prime_label: 2 },
                    target: GraphVertex { id: 1, prime_label: 3 },
                    weight: 0.5,
                }],
            },
            energy_bound: 1.0,
        };
        
        let new_weight = kani::any::<f64>();
        kani::assume(new_weight > 0.0 && new_weight < 2.0);
        
        let res = cert.update_edge(0, new_weight);
        if res.is_ok() {
            kani::assert(cert.graph_energy() <= cert.energy_bound, "Energy bound violated after update");
        }
    }
}
