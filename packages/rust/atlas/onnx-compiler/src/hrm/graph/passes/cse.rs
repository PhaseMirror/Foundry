// Common Subexpression Elimination (CSE)
//
// Detects and merges duplicate operations that have:
// - Same operation type
// - Same inputs
// - Same attributes

use super::OptimizationPass;
use crate::hrm::graph::ir::{Dependency, HologramGraph};
use anyhow::Result;
use petgraph::stable_graph::EdgeReference;
use petgraph::visit::EdgeRef;
use petgraph::Direction;
use rustc_hash::FxHashMap;
use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};

/// Common Subexpression Elimination pass
pub struct CommonSubexpressionElimination;

impl CommonSubexpressionElimination {
    /// Compute hash for a node based on its operation and inputs
    fn hash_node(&self, graph: &HologramGraph, node_id: petgraph::graph::NodeIndex) -> u64 {
        let mut hasher = DefaultHasher::new();
        let petgraph = graph.petgraph();
        let node = &petgraph[node_id];

        // Hash operation type and domain
        node.op_type.hash(&mut hasher);
        node.domain.hash(&mut hasher);

        // Hash attributes
        let mut attrs = node.attributes.clone();
        attrs.sort_by(|a, b| a.name.cmp(&b.name));
        for attr in &attrs {
            attr.name.hash(&mut hasher);
            if !attr.s.is_empty() {
                attr.s.hash(&mut hasher);
            }
            attr.i.hash(&mut hasher);
            attr.f.to_bits().hash(&mut hasher);
        }

        // Hash input nodes
        let mut inputs: Vec<_> = petgraph
            .edges_directed(node_id, Direction::Incoming)
            .map(|e: EdgeReference<Dependency>| (e.source().index(), 0u8)) // Simplified
            .collect();
        inputs.sort_unstable();
        inputs.hash(&mut hasher);

        hasher.finish()
    }

    /// Check if two nodes are structurally identical
    fn nodes_identical(
        &self,
        graph: &HologramGraph,
        node_a: petgraph::graph::NodeIndex,
        node_b: petgraph::graph::NodeIndex,
    ) -> bool {
        let petgraph = graph.petgraph();
        let na = &petgraph[node_a];
        let nb = &petgraph[node_b];

        // Same operation type and domain
        if na.op_type != nb.op_type || na.domain != nb.domain {
            return false;
        }

        // Same number of inputs
        let inputs_a: Vec<_> = petgraph.edges_directed(node_a, Direction::Incoming).collect();
        let inputs_b: Vec<_> = petgraph.edges_directed(node_b, Direction::Incoming).collect();

        if inputs_a.len() != inputs_b.len() {
            return false;
        }

        // Same input sources (simplified check)
        let mut sources_a: Vec<_> = inputs_a
            .iter()
            .map(|e: &EdgeReference<Dependency>| e.source().index())
            .collect();
        let mut sources_b: Vec<_> = inputs_b
            .iter()
            .map(|e: &EdgeReference<Dependency>| e.source().index())
            .collect();
        sources_a.sort_unstable();
        sources_b.sort_unstable();

        if sources_a != sources_b {
            return false;
        }

        // Same attributes
        let mut attrs_a = na.attributes.clone();
        let mut attrs_b = nb.attributes.clone();
        attrs_a.sort_by(|a, b| a.name.cmp(&b.name));
        attrs_b.sort_by(|a, b| a.name.cmp(&b.name));

        if attrs_a.len() != attrs_b.len() {
            return false;
        }

        for (aa, ab) in attrs_a.iter().zip(attrs_b.iter()) {
            if aa.name != ab.name || aa.i != ab.i || aa.f != ab.f || aa.s != ab.s {
                return false;
            }
        }

        true
    }
}

impl OptimizationPass for CommonSubexpressionElimination {
    fn name(&self) -> &str {
        "CommonSubexpressionElimination"
    }

    fn run(&self, graph: &mut HologramGraph) -> Result<bool> {
        let mut hash_groups: FxHashMap<u64, Vec<petgraph::graph::NodeIndex>> = FxHashMap::default();

        // Group nodes by hash
        for node_id in graph.petgraph().node_indices() {
            let node = &graph.petgraph()[node_id];

            // Skip graph outputs
            if graph.is_graph_output(node_id) {
                continue;
            }

            // Skip constants (already deduplicated by ONNX)
            if node.op_type == "Constant" {
                continue;
            }

            let hash = self.hash_node(graph, node_id);
            hash_groups.entry(hash).or_default().push(node_id);
        }

        // Find and merge duplicates
        let mut removed_any = false;
        for (_, group) in hash_groups.iter() {
            if group.len() < 2 {
                continue;
            }

            for i in 0..group.len() {
                for j in (i + 1)..group.len() {
                    let node_a = group[i];
                    let node_b = group[j];

                    // Check if truly identical
                    if !self.nodes_identical(graph, node_a, node_b) {
                        continue;
                    }

                    // Replace uses of node_b with node_a
                    let output_names_b = graph.node(node_b).unwrap().output_names.clone();
                    let output_names_a = graph.node(node_a).unwrap().output_names.clone();

                    for (slot, output_b_name) in output_names_b.iter().enumerate() {
                        if let Some(output_a_name) = output_names_a.get(slot) {
                            graph.replace_tensor(output_b_name, output_a_name);
                        }
                    }

                    // Remove node_b
                    let _ = graph.remove_node(node_b);
                    removed_any = true;
                }
            }
        }

        Ok(removed_any)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cse_empty_graph() {
        let mut graph = HologramGraph::new();
        let cse = CommonSubexpressionElimination;
        let changed = cse.run(&mut graph).unwrap();
        assert!(!changed);
    }
}
