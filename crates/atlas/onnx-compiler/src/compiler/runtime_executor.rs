//! Runtime Graph Executor
//!
//! This module provides hybrid execution:
//! O(1) lookup for known patterns, O(n) execution for novel inputs.
//!
//! When an input pattern is not found in the pre-computed hash table,
//! this executor runs the operator graph to compute the result on-the-fly.

use crate::error::{CompilerError, Result};
use crate::hrm::graph::HologramGraph;
use crate::hrm::ops::{OnnxHRMNode, OnnxOperator};
use hologram::Atlas;
use std::collections::HashMap;

/// Serializable initializer (model weights/constants)
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SerializableInitializer {
    /// Tensor name
    pub name: String,
    /// Tensor shape
    pub dims: Vec<i64>,
    /// Flattened f32 data
    pub data: Vec<f32>,
}

/// Serializable graph representation for .holo files
///
/// This is a simplified representation that can be easily serialized
/// and deserialized for runtime execution.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SerializableGraph {
    /// Nodes in execution order
    pub nodes: Vec<SerializableNode>,
    /// Edges: (from_node, to_node, input_index)
    pub edges: Vec<(usize, usize, usize)>,
    /// Initializers (model weights/constants)
    pub initializers: Vec<SerializableInitializer>,
    /// Graph input tensor name
    pub input_name: Option<String>,
    /// Graph output tensor name
    pub output_name: Option<String>,
}

/// Serializable node representation
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SerializableNode {
    /// Node index
    pub index: usize,
    /// Operation type
    pub op_type: String,
    /// Operation name
    pub name: String,
    /// Input names
    pub input_names: Vec<String>,
    /// Output names
    pub output_names: Vec<String>,
    /// Expected output shapes (from ONNX shape inference)
    pub output_shapes: Vec<Vec<i64>>,
}

impl SerializableGraph {
    /// Convert a HologramGraph to serializable format
    pub fn from_hologram_graph(graph: &HologramGraph) -> Result<Self> {
        let mut nodes = Vec::new();
        let mut edges = Vec::new();
        let mut initializers = Vec::new();

        // Get the underlying petgraph
        let petgraph = graph.petgraph();

        // Get graph inputs/outputs
        let graph_inputs = graph.graph_inputs();
        let graph_outputs = graph.graph_outputs();

        // Get input and output names
        let input_name = graph_inputs.first().map(|i| i.name.clone());
        let output_name = graph_outputs.first().map(|o| o.name.clone());

        // Convert nodes
        for node_idx in petgraph.node_indices() {
            let node_weight = petgraph.node_weight(node_idx).ok_or_else(|| {
                CompilerError::InvalidModel(format!("Node {:?} has no weight", node_idx))
            })?;

            // Extract output shapes from graph
            let output_shapes: Vec<Vec<i64>> = (0..node_weight.output_names.len())
                .map(|slot| {
                    graph.shapes
                        .get(&(node_idx, slot as u8))
                        .cloned()
                        .unwrap_or_default()
                })
                .collect();

            nodes.push(SerializableNode {
                index: node_idx.index(),
                op_type: node_weight.op_type.clone(),
                name: node_weight.name.clone(),
                input_names: node_weight.input_names.clone(),
                output_names: node_weight.output_names.clone(),
                output_shapes,
            });
        }

        // Convert edges
        for edge_idx in petgraph.edge_indices() {
            if let Some((from, to)) = petgraph.edge_endpoints(edge_idx) {
                if let Some(weight) = petgraph.edge_weight(edge_idx) {
                    // Extract input slot from Dependency enum
                    let input_idx = match weight {
                        crate::hrm::graph::ir::Dependency::Data { input_slot, .. } => *input_slot as usize,
                        crate::hrm::graph::ir::Dependency::Schedule => 0, // Schedule edges don't carry data
                    };
                    edges.push((from.index(), to.index(), input_idx));
                }
            }
        }

        // Convert initializers (model weights/constants)
        for (name, tensor_proto) in graph.initializers_map() {
            // Extract f32 data from TensorProto
            let data = Self::extract_f32_data(tensor_proto)?;

            // Skip empty initializers (external data not loaded)
            if data.is_empty() && !tensor_proto.dims.is_empty() {
                eprintln!("Warning: Initializer '{}' has shape {:?} but no data (likely external data not loaded)",
                    name, tensor_proto.dims);
                continue;
            }

            initializers.push(SerializableInitializer {
                name: name.clone(),
                dims: tensor_proto.dims.clone(),
                data,
            });
        }

        Ok(Self {
            nodes,
            edges,
            initializers,
            input_name,
            output_name,
        })
    }

    /// Extract f32 data from TensorProto
    fn extract_f32_data(tensor: &crate::proto::TensorProto) -> Result<Vec<f32>> {
        use crate::proto::tensor_proto::DataType;

        // Handle different data storage formats
        if !tensor.float_data.is_empty() {
            // Data stored as repeated floats
            Ok(tensor.float_data.clone())
        } else if !tensor.int64_data.is_empty() {
            // Data stored as int64 - convert to f32
            Ok(tensor.int64_data.iter().map(|&i| i as f32).collect())
        } else if !tensor.int32_data.is_empty() {
            // Data stored as int32 - convert to f32
            Ok(tensor.int32_data.iter().map(|&i| i as f32).collect())
        } else if !tensor.raw_data.is_empty() {
            // Data stored as raw bytes
            let data_type = DataType::try_from(tensor.data_type)
                .map_err(|_| CompilerError::InvalidModel(format!("Unknown data type: {}", tensor.data_type)))?;

            match data_type {
                DataType::Float => {
                    // Convert raw bytes to f32
                    let mut result = Vec::new();
                    for chunk in tensor.raw_data.chunks_exact(4) {
                        let bytes: [u8; 4] = chunk.try_into()
                            .map_err(|_| CompilerError::InvalidModel("Invalid raw data alignment".to_string()))?;
                        result.push(f32::from_le_bytes(bytes));
                    }
                    Ok(result)
                }
                DataType::Int64 => {
                    // Convert raw bytes to i64, then to f32
                    let mut result = Vec::new();
                    for chunk in tensor.raw_data.chunks_exact(8) {
                        let bytes: [u8; 8] = chunk.try_into()
                            .map_err(|_| CompilerError::InvalidModel("Invalid raw data alignment".to_string()))?;
                        result.push(i64::from_le_bytes(bytes) as f32);
                    }
                    Ok(result)
                }
                DataType::Int32 => {
                    // Convert raw bytes to i32, then to f32
                    let mut result = Vec::new();
                    for chunk in tensor.raw_data.chunks_exact(4) {
                        let bytes: [u8; 4] = chunk.try_into()
                            .map_err(|_| CompilerError::InvalidModel("Invalid raw data alignment".to_string()))?;
                        result.push(i32::from_le_bytes(bytes) as f32);
                    }
                    Ok(result)
                }
                _ => Err(CompilerError::UnsupportedOp(
                    format!("Unsupported initializer data type: {:?}", data_type)
                ))
            }
        } else {
            // Empty tensor
            Ok(Vec::new())
        }
    }
}

/// Runtime graph executor for fallback computation
///
/// When an input pattern is not found in the pre-computed hash table,
/// this executor runs the operator graph to compute the result on-the-fly.
pub struct RuntimeExecutor {
    graph: SerializableGraph,
    atlas: Atlas,
    execution_order: Vec<usize>,
}

impl RuntimeExecutor {
    /// Create a new runtime executor
    pub fn new(graph: SerializableGraph) -> Result<Self> {
        let atlas = Atlas::with_cache()
            .map_err(|e| CompilerError::InvalidModel(format!("Failed to initialize Atlas: {}", e)))?;

        // Compute topological execution order
        let execution_order = Self::topological_sort(&graph)?;

        Ok(Self {
            graph,
            atlas,
            execution_order,
        })
    }

    /// Compute topological sort of graph nodes
    fn topological_sort(graph: &SerializableGraph) -> Result<Vec<usize>> {
        let mut in_degree: HashMap<usize, usize> = HashMap::new();
        let mut out_edges: HashMap<usize, Vec<usize>> = HashMap::new();

        // Initialize in-degrees
        for node in &graph.nodes {
            in_degree.insert(node.index, 0);
            out_edges.insert(node.index, Vec::new());
        }

        // Count incoming edges
        for &(from, to, _) in &graph.edges {
            *in_degree.get_mut(&to).unwrap() += 1;
            out_edges.get_mut(&from).unwrap().push(to);
        }

        // Kahn's algorithm
        let mut queue: Vec<usize> = in_degree
            .iter()
            .filter(|(_, &deg)| deg == 0)
            .map(|(&idx, _)| idx)
            .collect();

        let mut result = Vec::new();

        while let Some(node_idx) = queue.pop() {
            result.push(node_idx);

            if let Some(neighbors) = out_edges.get(&node_idx) {
                for &neighbor in neighbors {
                    let deg = in_degree.get_mut(&neighbor).unwrap();
                    *deg -= 1;
                    if *deg == 0 {
                        queue.push(neighbor);
                    }
                }
            }
        }

        // Check for cycles
        if result.len() != graph.nodes.len() {
            return Err(CompilerError::InvalidModel(
                "Graph contains cycles - cannot execute".to_string(),
            ));
        }

        Ok(result)
    }

    /// Infer output shape based on operation type and input shapes
    fn infer_output_shape(
        op_type: &str,
        input_shapes: &[Vec<i64>],
        output_len: usize,
    ) -> Result<Vec<i64>> {
        match op_type {
            // Element-wise operations: output shape = input shape
            "Add" | "Sub" | "Mul" | "Div" | "Relu" | "Sigmoid" | "Tanh" | "Softmax" |
            "Abs" | "Neg" | "Sqrt" | "Exp" | "Ceil" | "Floor" | "LeakyRelu" | "Log" |
            "Reciprocal" | "Sign" | "Round" | "Sin" | "Cos" | "Tan" | "Asin" | "Acos" |
            "Atan" | "Sinh" | "Cosh" | "Atanh" | "Cbrt" | "Erf" | "Expm1" | "Log1p" |
            "IsNaN" | "IsInf" | "Not" | "Elu" | "Selu" | "Softsign" | "Softplus" |
            "HardSigmoid" | "HardSwish" | "Shrink" | "Min" | "Max" | "Pow" | "Mod" |
            "Atan2" | "And" | "Or" | "Xor" | "GreaterOrEqual" | "LessOrEqual" |
            "PRelu" | "Mean" | "Greater" | "Less" | "Equal" | "Cast" | "Gelu" => {
                // Use first input shape (broadcasting handled by operator)
                Ok(input_shapes.first().cloned().unwrap_or_else(|| vec![output_len as i64]))
            }

            // MatMul: A[..., M, K] × B[..., K, N] → [..., M, N]
            "MatMul" => {
                if input_shapes.len() < 2 {
                    return Ok(vec![output_len as i64]);
                }
                let a_shape = &input_shapes[0];
                let b_shape = &input_shapes[1];

                if a_shape.len() < 2 || b_shape.len() < 2 {
                    // Fallback to 1D if shapes are incomplete
                    return Ok(vec![output_len as i64]);
                }

                // For 2D: [M, K] × [K, N] → [M, N]
                let m = a_shape[a_shape.len() - 2];
                let n = b_shape[b_shape.len() - 1];

                // Include batch dimensions if present
                let mut output_shape = a_shape[..a_shape.len() - 2].to_vec();
                output_shape.push(m);
                output_shape.push(n);

                Ok(output_shape)
            }

            // Gemm: similar to MatMul
            "Gemm" => {
                if input_shapes.is_empty() {
                    return Ok(vec![output_len as i64]);
                }
                // Simplified: assume 2D output [M, N]
                let a_shape = &input_shapes[0];
                if a_shape.len() >= 2 {
                    let m = a_shape[a_shape.len() - 2];
                    // Output is typically [M, N] - use output_len to infer N
                    let n = (output_len as i64) / m;
                    Ok(vec![m, n])
                } else {
                    Ok(vec![output_len as i64])
                }
            }

            // Gather: output shape depends on indices shape
            "Gather" => {
                // Simplified: use output length
                Ok(vec![output_len as i64])
            }

            // Reshape: output shape should be specified in node, fallback to 1D
            "Reshape" | "Flatten" | "Squeeze" | "Unsqueeze" => {
                Ok(vec![output_len as i64])
            }

            // Reduce operations: typically reduce to smaller shape
            "ReduceMean" | "ReduceSum" | "ReduceMax" | "ReduceMin" => {
                // Simplified: return 1D
                Ok(vec![output_len as i64])
            }

            // Layer normalization: same shape as input
            "LayerNormalization" => {
                Ok(input_shapes.first().cloned().unwrap_or_else(|| vec![output_len as i64]))
            }

            // Concat: concatenate along specified axis
            "Concat" => {
                Ok(vec![output_len as i64])
            }

            // Default: 1D shape based on output length
            _ => Ok(vec![output_len as i64]),
        }
    }

    /// Execute the graph with the given input
    pub fn execute(&mut self, input: &[f32]) -> Result<Vec<f32>> {
        // Cache for intermediate results: tensor_name -> (data, shape)
        let mut tensor_cache: HashMap<String, (Vec<f32>, Vec<i64>)> = HashMap::new();

        // Pre-load initializers (model weights/constants) into cache with their shapes
        for initializer in &self.graph.initializers {
            tensor_cache.insert(
                initializer.name.clone(),
                (initializer.data.clone(), initializer.dims.clone())
            );
        }

        // Store input data with input tensor name
        // For graphs with multiple inputs, we only receive data for the first input
        // Generate default values for any additional inputs
        let graph_inputs: Vec<String> = self.graph.nodes.iter()
            .flat_map(|n| n.input_names.iter())
            .filter(|name| !name.is_empty())
            .filter(|name| !self.graph.initializers.iter().any(|init| &init.name == *name))
            .filter(|name| !self.graph.nodes.iter().any(|n| n.output_names.contains(name)))
            .map(|s| s.clone())
            .collect::<std::collections::HashSet<_>>()
            .into_iter()
            .collect();

        if let Some(ref input_name) = self.graph.input_name {
            // Store the provided input
            let input_shape = vec![input.len() as i64];
            tensor_cache.insert(input_name.clone(), (input.to_vec(), input_shape));

            // Generate default values for other graph inputs
            for graph_input in &graph_inputs {
                if graph_input != input_name && !tensor_cache.contains_key(graph_input) {
                    // Generate default input (all ones for attention masks, zeros for others)
                    let default_data = if graph_input.contains("mask") {
                        vec![1.0; input.len()]
                    } else {
                        vec![0.0; input.len()]
                    };
                    let default_shape = vec![default_data.len() as i64];
                    eprintln!("INFO: Auto-generating input '{}' with {} elements", graph_input, default_data.len());
                    tensor_cache.insert(graph_input.clone(), (default_data, default_shape));
                }
            }
        } else {
            return Err(CompilerError::InvalidModel(
                "No input tensor name found in graph".to_string(),
            ));
        }

        // Execute nodes in topological order
        for &node_idx in &self.execution_order {
            let node = self.graph.nodes.iter()
                .find(|n| n.index == node_idx)
                .ok_or_else(|| CompilerError::InvalidModel(
                    format!("Node {} not found in graph", node_idx)
                ))?;

            // Collect inputs for this node by tensor name
            let mut node_inputs: Vec<Vec<f32>> = Vec::new();
            let mut input_shapes: Vec<Vec<i64>> = Vec::new();
            let mut missing_inputs = Vec::new();

            for input_name in &node.input_names {
                if let Some((input_data, input_shape)) = tensor_cache.get(input_name) {
                    node_inputs.push(input_data.clone());
                    input_shapes.push(input_shape.clone());
                } else {
                    missing_inputs.push(input_name.clone());
                }
            }

            // Skip nodes that don't have all required inputs yet
            if !missing_inputs.is_empty() {
                continue;
            }

            // Create operator from node metadata
            let operator = OnnxOperator::from_node_metadata(
                &node.op_type,
                &input_shapes,
                node_inputs.first().map(|i| i.len()).unwrap_or(0),
            )?;

            // Convert Vec<Vec<f32>> to Vec<&[f32]> for execution
            let input_refs: Vec<&[f32]> = node_inputs.iter().map(|v| v.as_slice()).collect();

            // Execute operator
            let output = operator.execute(&self.atlas, &input_refs).map_err(|e| {
                CompilerError::InvalidModel(format!(
                    "Error executing {} (node '{}' idx {}): {}",
                    node.op_type, node.name, node_idx, e
                ))
            })?;

            // Use serialized output shapes if available, otherwise infer
            let output_shape = if !node.output_shapes.is_empty() && !node.output_shapes[0].is_empty() {
                node.output_shapes[0].clone()
            } else {
                Self::infer_output_shape(
                    &node.op_type,
                    &input_shapes,
                    output.len(),
                )?
            };

            // Store result in cache with output tensor name
            if let Some(output_name) = node.output_names.first() {
                tensor_cache.insert(output_name.clone(), (output, output_shape));
            }
        }

        // Extract output by tensor name
        if let Some(ref output_name) = self.graph.output_name {
            tensor_cache.get(output_name)
                .map(|(data, _shape)| data.clone())
                .ok_or_else(|| CompilerError::InvalidModel(
                    format!("Output tensor '{}' not found in results", output_name)
                ))
        } else {
            Err(CompilerError::InvalidModel(
                "No output tensor name found in graph".to_string(),
            ))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_runtime_executor_creation() {
        let graph = SerializableGraph {
            nodes: vec![],
            edges: vec![],
            initializers: vec![],
            input_name: None,
            output_name: None,
        };
        // Empty graph should succeed (no cycles)
        let _executor = RuntimeExecutor::new(graph);
    }
}
