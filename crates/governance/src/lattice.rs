use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LatticeEdge {
    pub source: String,
    pub target: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LatticeGraph {
    pub nodes: Vec<String>,
    pub edges: Vec<LatticeEdge>,
    pub faces: Vec<Vec<String>>,
}

impl LatticeGraph {
    pub fn new(nodes: Vec<String>, edges: Vec<LatticeEdge>, faces: Vec<Vec<String>>) -> Self {
        Self { nodes, edges, faces }
    }

    /// Computes chi = V - E + F
    pub fn euler_characteristic(&self) -> i32 {
        let v = self.nodes.len() as i32;
        let e = self.edges.len() as i32;
        let f = self.faces.len() as i32;
        v - e + f
    }

    /// Simplified Gurau degree estimation for rank-d tensor graph.
    /// G = d(V-1) - (d-1)F_int
    pub fn gurau_degree(&self, d: i32) -> i32 {
        let v = self.nodes.len() as i32;
        let f_int = self.faces.len() as i32;
        d * (v - 1) - (d - 1) * f_int
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_lattice_metrics() {
        let nodes = vec!["v1".to_string(), "v2".to_string()];
        let edges = vec![
            LatticeEdge { source: "v1".to_string(), target: "v2".to_string() },
            LatticeEdge { source: "v2".to_string(), target: "v1".to_string() },
        ];
        let faces = vec![
            vec!["v1".to_string(), "v2".to_string()],
            vec!["v2".to_string(), "v1".to_string()],
        ];

        let lattice = LatticeGraph::new(nodes, edges, faces);
        assert_eq!(lattice.euler_characteristic(), 2);
        assert_eq!(lattice.gurau_degree(4), -2); // 4*(2-1) - 3*2 = 4 - 6 = -2
    }
}
