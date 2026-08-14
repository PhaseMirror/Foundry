// Dead Code Elimination (DCE)
//
// Removes nodes that don't contribute to any graph output.
// Uses reverse traversal from outputs to mark reachable nodes.

use super::OptimizationPass;
use crate::hrm::graph::ir::{Dependency, HologramGraph};
use anyhow::Result;
use petgraph::stable_graph::EdgeReference;
use petgraph::visit::EdgeRef;
use petgraph::Direction;
use std::collections::HashSet;

/// Dead Code Elimination pass
///
/// Removes nodes that are not reachable from any graph output.
pub struct DeadCodeElimination;

impl OptimizationPass for DeadCodeElimination {
    fn name(&self) -> &str {
        "DeadCodeElimination"
    }

    fn run(&self, graph: &mut HologramGraph) -> Result<bool> {
        let petgraph = graph.petgraph();
        let mut live_nodes = HashSet::new();

        // Mark all graph output producers as live
        for output_info in graph.graph_outputs() {
            if let Some(_node) = graph.node_by_name(&output_info.name) {
                // Find the node ID that produces this output
                for node_id in petgraph.node_indices() {
                    let n = &petgraph[node_id];
                    if n.output_names.contains(&output_info.name) {
                        live_nodes.insert(node_id);
                    }
                }
            }
        }

        // Reverse traversal: mark all nodes that feed live nodes
        let mut changed = true;
        while changed {
            changed = false;
            for node_id in petgraph.node_indices() {
                if live_nodes.contains(&node_id) {
                    // Mark all inputs to this node as live
                    for edge in petgraph.edges_directed(node_id, Direction::Incoming) {
                        let edge_ref: EdgeReference<Dependency> = edge;
                        if live_nodes.insert(edge_ref.source()) {
                            changed = true;
                        }
                    }
                }
            }
        }

        // Remove dead nodes
        let mut removed_any = false;
        let all_nodes: Vec<_> = petgraph.node_indices().collect();
        for node_id in all_nodes {
            // Skip live nodes
            if live_nodes.contains(&node_id) {
                continue;
            }

            // Skip graph outputs (shouldn't happen but be safe)
            if graph.is_graph_output(node_id) {
                continue;
            }

            // Remove this dead node
            graph.remove_node(node_id)?;
            removed_any = true;
        }

        Ok(removed_any)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_dce_empty_graph() {
        let mut graph = HologramGraph::new();
        let dce = DeadCodeElimination;
        let changed = dce.run(&mut graph).unwrap();
        assert!(!changed);
    }
}
