// Constant Folding
//
// Evaluates operations with constant inputs at compile time,
// replacing them with constant nodes.
//
// For example:
// - Constant(2) + Constant(3) → Constant(5)
// - Reshape(constant_tensor, constant_shape) → Constant(reshaped)
//
// This pass is particularly effective when combined with other passes
// that expose constant sub-expressions.

use super::OptimizationPass;
use crate::hrm::graph::ir::HologramGraph;
use anyhow::Result;

/// Constant Folding pass
///
/// Evaluates operations with all-constant inputs at compile time.
///
/// Note: This is a simplified implementation that marks opportunities
/// for constant folding but doesn't execute them. A full implementation
/// would require an ONNX runtime to evaluate the operations.
pub struct ConstantFolding;

impl ConstantFolding {
    /// Check if all inputs to a node are constants
    fn all_inputs_constant(&self, graph: &HologramGraph, node_id: petgraph::graph::NodeIndex) -> bool {
        let node = match graph.node(node_id) {
            Some(n) => n,
            None => return false,
        };

        for input_name in &node.input_names {
            // Skip empty inputs (optional inputs)
            if input_name.is_empty() {
                continue;
            }

            // Check if it's an initializer
            if graph.initializers_map().contains_key(input_name) {
                continue;
            }

            // Check if it's produced by a Constant node
            if let Some(producer_node) = graph.node_by_name(input_name) {
                if producer_node.op_type == "Constant" {
                    continue;
                }
            }

            // Not a constant
            return false;
        }

        true
    }

    /// Check if an operation is foldable
    ///
    /// Some operations can't be folded (e.g., those with dynamic behavior)
    fn is_foldable_op(&self, op_type: &str) -> bool {
        matches!(
            op_type,
            "Add" | "Sub" | "Mul" | "Div" | "Reshape" | "Transpose" | "Concat" | "Cast" | "Sqrt" | "Exp" | "Log"
        )
    }
}

impl OptimizationPass for ConstantFolding {
    fn name(&self) -> &str {
        "ConstantFolding"
    }

    fn run(&self, graph: &mut HologramGraph) -> Result<bool> {
        // This is a simplified implementation that identifies constant folding
        // opportunities but doesn't execute them.
        //
        // A full implementation would:
        // 1. Identify nodes with all-constant inputs
        // 2. Execute the operation using an ONNX runtime
        // 3. Replace the node with a Constant node containing the result
        //
        // For now, we just identify opportunities and log them.

        let mut foldable_count = 0;

        for node_id in graph.petgraph().node_indices() {
            let node = match graph.node(node_id) {
                Some(n) => n,
                None => continue,
            };

            // Skip non-foldable operations
            if !self.is_foldable_op(&node.op_type) {
                continue;
            }

            // Skip graph outputs (we want to preserve their explicit computation)
            if graph.is_graph_output(node_id) {
                continue;
            }

            // Check if all inputs are constant
            if self.all_inputs_constant(graph, node_id) {
                foldable_count += 1;
                // In a full implementation, we would:
                // 1. Evaluate the operation
                // 2. Create a new Constant node with the result
                // 3. Replace uses of the original node
                // 4. Remove the original node
                //
                // For now, just count opportunities
            }
        }

        if foldable_count > 0 {
            tracing::debug!("Found {} constant folding opportunities", foldable_count);
        }

        // Return false because we haven't actually modified the graph
        // A full implementation would return true when folding occurs
        Ok(false)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_constant_folding_empty_graph() {
        let mut graph = HologramGraph::new();
        let cf = ConstantFolding;
        let changed = cf.run(&mut graph).unwrap();
        assert!(!changed);
    }

    #[test]
    fn test_is_foldable_op() {
        let cf = ConstantFolding;
        assert!(cf.is_foldable_op("Add"));
        assert!(cf.is_foldable_op("Reshape"));
        assert!(!cf.is_foldable_op("Relu"));
    }
}
