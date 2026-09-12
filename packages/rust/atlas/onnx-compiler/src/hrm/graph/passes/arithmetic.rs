// Arithmetic Elimination
//
// Simplifies arithmetic operations with identity values:
// - x + 0 → x, x - 0 → x, x * 1 → x, x / 1 → x

use super::OptimizationPass;
use crate::hrm::graph::ir::HologramGraph;
use crate::proto::TensorProto;
use anyhow::Result;

/// Arithmetic Elimination pass
pub struct ArithmeticElimination;

impl ArithmeticElimination {
    /// Check if tensor is a constant zero
    fn is_constant_zero(&self, graph: &HologramGraph, tensor_name: &str) -> bool {
        if let Some(init) = graph.initializers_map().get(tensor_name) {
            return self.is_zero_tensor(init);
        }

        // Check if produced by Constant node
        for node_id in graph.petgraph().node_indices() {
            let node = &graph.petgraph()[node_id];
            if node.op_type == "Constant" && node.output_names.contains(&tensor_name.to_string()) {
                if let Some(attr) = node.get_attribute("value") {
                    if let Some(ref tensor) = attr.t {
                        return self.is_zero_tensor(tensor);
                    }
                }
            }
        }

        false
    }

    /// Check if tensor is a constant one
    fn is_constant_one(&self, graph: &HologramGraph, tensor_name: &str) -> bool {
        if let Some(init) = graph.initializers_map().get(tensor_name) {
            return self.is_one_tensor(init);
        }

        // Check if produced by Constant node
        for node_id in graph.petgraph().node_indices() {
            let node = &graph.petgraph()[node_id];
            if node.op_type == "Constant" && node.output_names.contains(&tensor_name.to_string()) {
                if let Some(attr) = node.get_attribute("value") {
                    if let Some(ref tensor) = attr.t {
                        return self.is_one_tensor(tensor);
                    }
                }
            }
        }

        false
    }

    /// Check if all values in tensor are zero
    fn is_zero_tensor(&self, tensor: &TensorProto) -> bool {
        if !tensor.float_data.is_empty() {
            return tensor.float_data.iter().all(|&x| x == 0.0);
        }
        if !tensor.int64_data.is_empty() {
            return tensor.int64_data.iter().all(|&x| x == 0);
        }
        if !tensor.int32_data.is_empty() {
            return tensor.int32_data.iter().all(|&x| x == 0);
        }
        if !tensor.raw_data.is_empty() {
            return tensor.raw_data.iter().all(|&b| b == 0);
        }
        false
    }

    /// Check if all values in tensor are one
    fn is_one_tensor(&self, tensor: &TensorProto) -> bool {
        if !tensor.float_data.is_empty() {
            return tensor.float_data.iter().all(|&x| x == 1.0);
        }
        if !tensor.int64_data.is_empty() {
            return tensor.int64_data.iter().all(|&x| x == 1);
        }
        if !tensor.int32_data.is_empty() {
            return tensor.int32_data.iter().all(|&x| x == 1);
        }
        false
    }
}

impl OptimizationPass for ArithmeticElimination {
    fn name(&self) -> &str {
        "ArithmeticElimination"
    }

    fn run(&self, graph: &mut HologramGraph) -> Result<bool> {
        let mut removed_any = false;
        let all_nodes: Vec<_> = graph.petgraph().node_indices().collect();

        for node_id in all_nodes {
            let node = match graph.node(node_id) {
                Some(n) => n.clone(),
                None => continue,
            };

            let op_type = &node.op_type;
            let inputs = &node.input_names;
            let mut replacement_tensor: Option<String> = None;

            match op_type.as_str() {
                "Add" if inputs.len() == 2 => {
                    if self.is_constant_zero(graph, &inputs[0]) {
                        replacement_tensor = Some(inputs[1].clone());
                    } else if self.is_constant_zero(graph, &inputs[1]) {
                        replacement_tensor = Some(inputs[0].clone());
                    }
                }
                "Sub" if inputs.len() == 2 => {
                    if self.is_constant_zero(graph, &inputs[1]) {
                        replacement_tensor = Some(inputs[0].clone());
                    }
                }
                "Mul" if inputs.len() == 2 => {
                    if self.is_constant_one(graph, &inputs[0]) {
                        replacement_tensor = Some(inputs[1].clone());
                    } else if self.is_constant_one(graph, &inputs[1]) {
                        replacement_tensor = Some(inputs[0].clone());
                    }
                }
                "Div" if inputs.len() == 2 => {
                    if self.is_constant_one(graph, &inputs[1]) {
                        replacement_tensor = Some(inputs[0].clone());
                    }
                }
                _ => {}
            }

            // Apply replacement
            if let Some(replacement) = replacement_tensor {
                for output_name in &node.output_names {
                    graph.replace_tensor(output_name, &replacement);
                }
                let _ = graph.remove_node(node_id);
                removed_any = true;
            }
        }

        Ok(removed_any)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_arithmetic_elimination_empty_graph() {
        let mut graph = HologramGraph::new();
        let ae = ArithmeticElimination;
        let changed = ae.run(&mut graph).unwrap();
        assert!(!changed);
    }
}
