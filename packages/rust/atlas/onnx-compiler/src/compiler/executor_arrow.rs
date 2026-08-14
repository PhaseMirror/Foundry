//! Arrow-based Graph Execution Engine
//!
//! This is a refactored executor that uses ArrowTensor for zero-copy operations.
//! Executes ONNX operators on sample patterns using:
//! - ArrowTensor for O(1) zero-copy access
//! - hologram-hrm Atlas for Griess embeddings
//! - Macro-generated operators (54+ ops)
//! - Adaptive pattern sampling (prevents memory explosion)

use crate::compiler::{ExecutionResults, OperationMetadata};
use crate::hrm::arrow_tensor::ArrowTensor;
use crate::hrm::graph::{HologramGraph, NodeId};
use crate::hrm::ops::{OnnxHRMNode, OnnxOperator};
use crate::{CompilerError, Result};
use ahash::AHashMap;
use arrow_array::Float32Array;
use hologram::Atlas;
use std::sync::Arc;

/// Arrow-based operator execution engine with zero-copy tensor operations
pub struct ArrowGraphExecutor {
    memory_budget: usize,
    verbose: bool,
    parallel: bool,
}

impl ArrowGraphExecutor {
    pub fn new() -> Self {
        Self {
            memory_budget: 2048,
            verbose: false,
            parallel: false,
        }
    }

    pub fn with_memory_budget(mut self, mb: usize) -> Self {
        self.memory_budget = mb;
        self
    }

    pub fn with_verbose(mut self, verbose: bool) -> Self {
        self.verbose = verbose;
        self
    }

    pub fn with_parallel(mut self, parallel: bool) -> Self {
        self.parallel = parallel;
        self
    }

    /// Execute all operators in topological order using ArrowTensor
    ///
    /// # Arguments
    ///
    /// * `graph` - The computation graph to execute
    /// * `input_shapes` - Resolved input shapes (from shape inference)
    pub fn execute(
        &self,
        graph: &HologramGraph,
        input_shapes: &std::collections::HashMap<String, Vec<i64>>,
    ) -> Result<ExecutionResults> {
        // Create Atlas for HRM integration
        let atlas = Atlas::with_cache()?;

        if self.verbose {
            println!("   ✓ Loaded Atlas with {} canonical vectors", 96);
        }

        // Determine pattern counts using adaptive sampling
        let pattern_counts = self.compute_pattern_counts(graph)?;

        let total_patterns: usize = pattern_counts.values().sum();

        if self.verbose {
            println!(
                "   ✓ Adaptive sampling: {} total patterns across {} operations",
                total_patterns,
                graph.petgraph().node_count()
            );
        }

        // Pre-generate patterns for graph inputs using resolved shapes (as ArrowTensor)
        let mut input_tensor_patterns: AHashMap<String, Vec<ArrowTensor>> = AHashMap::new();
        for input in graph.graph_inputs() {
            // Use resolved shape from shape inference
            let pattern_size = if let Some(shape) = input_shapes.get(&input.name) {
                // Calculate total elements from resolved shape
                let total: i64 = shape.iter().product();
                total.max(1) as usize
            } else {
                // Fallback: extract from ONNX metadata
                if let Some(ref type_proto) = input.r#type {
                    if let Some(ref value) = type_proto.value {
                        use crate::proto::type_proto::Value;
                        if let Value::TensorType(ref tensor_type) = value {
                            if let Some(ref shape_proto) = tensor_type.shape {
                                let total_elements: i64 = shape_proto
                                    .dim
                                    .iter()
                                    .map(|d| {
                                        if let Some(ref dim_value) = d.value {
                                            use crate::proto::tensor_shape_proto::dimension::Value as DimValue;
                                            match dim_value {
                                                DimValue::DimValue(v) => *v,
                                                DimValue::DimParam(_) => 1, // Dynamic dimension
                                            }
                                        } else {
                                            1
                                        }
                                    })
                                    .product();
                                total_elements.max(1) as usize
                            } else {
                                256
                            }
                        } else {
                            256
                        }
                    } else {
                        256
                    }
                } else {
                    256
                }
            };

            let patterns = self.generate_arrow_patterns_with_size(64, pattern_size)?;
            input_tensor_patterns.insert(input.name.clone(), patterns);
        }

        // Execute operators in topological order
        let topo_order = graph.topological_sort()?;

        let mut hash_tables: Vec<AHashMap<u64, ArrowTensor>> = Vec::new();
        let mut metadata: Vec<OperationMetadata> = Vec::new();
        let mut results: AHashMap<NodeId, Vec<ArrowTensor>> = AHashMap::new();

        for node_id in topo_order {
            let node = graph.node(node_id).ok_or_else(|| {
                CompilerError::InvalidModel(format!("Node {:?} not found", node_id))
            })?;

            // Get pattern count for this operation
            let num_patterns = pattern_counts.get(&node_id).copied().unwrap_or(64);

            // Gather input patterns from upstream nodes or graph inputs
            let mut input_patterns: Vec<Vec<ArrowTensor>> = Vec::new();

            for input_name in &node.input_names {
                if input_name.is_empty() {
                    continue; // Skip empty inputs
                }

                // Check if this is a graph input
                if let Some(patterns) = input_tensor_patterns.get(input_name) {
                    input_patterns.push(patterns.clone());
                } else if let Some((producer_id, _output_slot)) =
                    graph.tensor_producers().get(input_name)
                {
                    // Get patterns from upstream node
                    let patterns = results.get(producer_id).ok_or_else(|| {
                        CompilerError::InvalidModel(format!(
                            "Producer node {:?} for tensor '{}' not yet executed for node {:?}",
                            producer_id, input_name, node_id
                        ))
                    })?;
                    input_patterns.push(patterns.clone());
                } else if let Some(initializer) = graph.initializers_map().get(input_name) {
                    // This is an initializer (constant weight/tensor)
                    let init_patterns =
                        self.extract_initializer_arrow_patterns(initializer, num_patterns)?;
                    input_patterns.push(init_patterns);
                } else {
                    // Unknown input - log warning but continue
                    if self.verbose {
                        eprintln!(
                            "   ⚠ Warning: Unknown input '{}' for node {:?}",
                            input_name, node_id
                        );
                    }
                }
            }

            // Determine number of patterns to execute
            let num_patterns_to_execute = if input_patterns.is_empty() {
                num_patterns
            } else {
                input_patterns[0].len()
            };

            // Get operator instance
            let input_shapes_all = self.get_input_shapes(node_id, graph, input_shapes);

            // Use first input's pattern size, or default
            let pattern_size = if !input_patterns.is_empty() && !input_patterns[0].is_empty() {
                input_patterns[0][0].len()
            } else {
                self.estimate_pattern_size(node, graph)
            };

            // Build input shapes
            let node_input_shapes: Vec<Vec<i64>> = if !input_shapes_all.is_empty() {
                input_shapes_all
                    .iter()
                    .enumerate()
                    .map(|(i, shape_opt)| {
                        if let Some(shape) = shape_opt {
                            shape.clone()
                        } else {
                            // Infer shape from input pattern if available
                            if i < input_patterns.len() && !input_patterns[i].is_empty() {
                                vec![input_patterns[i][0].len() as i64]
                            } else {
                                vec![pattern_size as i64]
                            }
                        }
                    })
                    .collect()
            } else {
                input_patterns
                    .iter()
                    .map(|patterns| vec![patterns[0].len() as i64])
                    .collect()
            };

            let operator =
                OnnxOperator::from_node_metadata(&node.op_type, &node_input_shapes, pattern_size)?;

            // Execute operator on each pattern (parallel or sequential)
            // Use zero-copy ArrowTensor access
            let pattern_results: Vec<(u64, ArrowTensor)> = if self.parallel {
                use rayon::prelude::*;

                (0..num_patterns_to_execute)
                    .into_par_iter()
                    .map(|i| -> Result<(u64, ArrowTensor)> {
                        // Gather input slices for this pattern index (zero-copy)
                        let inputs_for_pattern: Vec<&[f32]> = input_patterns
                            .iter()
                            .map(|pat_list| {
                                let pattern_idx = i.min(pat_list.len() - 1);
                                pat_list[pattern_idx].values()
                            })
                            .collect();

                        // Execute operator with Atlas (returns Vec<f32>)
                        let mut output = operator.execute(&atlas, &inputs_for_pattern)?;

                        // Ensure scalar outputs are represented as 1-element vectors
                        if output.is_empty() {
                            output = vec![0.0];
                        }

                        // Convert to ArrowTensor
                        let output_tensor =
                            ArrowTensor::from_vec(output, vec![pattern_size as i64])?;

                        // Hash input pattern
                        let hash = if !inputs_for_pattern.is_empty() {
                            let mut combined = Vec::new();
                            for input in &inputs_for_pattern {
                                combined.extend_from_slice(input);
                            }
                            self.hash_pattern(&combined)
                        } else {
                            self.hash_pattern(&[i as f32])
                        };

                        Ok((hash, output_tensor))
                    })
                    .collect::<Result<Vec<_>>>()?
            } else {
                // Sequential execution
                let mut results_vec = Vec::new();
                for i in 0..num_patterns_to_execute {
                    // Gather input slices for this pattern index (zero-copy)
                    let inputs_for_pattern: Vec<&[f32]> = input_patterns
                        .iter()
                        .map(|pat_list| {
                            let pattern_idx = i.min(pat_list.len() - 1);
                            pat_list[pattern_idx].values()
                        })
                        .collect();

                    // Execute operator with Atlas
                    let mut output = operator.execute(&atlas, &inputs_for_pattern)?;

                    // Ensure scalar outputs are represented as 1-element vectors
                    if output.is_empty() {
                        output = vec![0.0];
                    }

                    // Convert to ArrowTensor
                    let output_tensor = ArrowTensor::from_vec(output, vec![pattern_size as i64])?;

                    // Hash input pattern
                    let hash = if !inputs_for_pattern.is_empty() {
                        let mut combined = Vec::new();
                        for input in &inputs_for_pattern {
                            combined.extend_from_slice(input);
                        }
                        self.hash_pattern(&combined)
                    } else {
                        self.hash_pattern(&[i as f32])
                    };

                    results_vec.push((hash, output_tensor));
                }
                results_vec
            };

            // Build hash table and pattern results from collected data
            let mut hash_table: AHashMap<u64, ArrowTensor> = AHashMap::new();
            let mut final_pattern_results = Vec::new();

            for (hash, output_tensor) in pattern_results {
                hash_table.insert(hash, output_tensor.clone());
                final_pattern_results.push(output_tensor);
            }

            // Store results for downstream operations
            results.insert(node_id, final_pattern_results.clone());

            // Convert hash table to Vec format for ExecutionResults
            hash_tables.push(hash_table);

            // Store metadata
            let output_size = if !final_pattern_results.is_empty() {
                final_pattern_results[0].len() as i64
            } else {
                pattern_size as i64
            };

            metadata.push(OperationMetadata {
                op_type: node.op_type.clone(),
                input_shapes: self.get_input_shapes(node_id, graph, input_shapes),
                output_shapes: vec![vec![output_size]],
            });
        }

        // Convert ArrowTensor hash tables to HashMap<u64, Vec<f32>> for backward compatibility
        let hash_tables_vec: Vec<std::collections::HashMap<u64, Vec<f32>>> = hash_tables
            .into_iter()
            .map(|ht| {
                ht.into_iter()
                    .map(|(k, v)| (k, v.to_vec_f32()))
                    .collect()
            })
            .collect();

        Ok(ExecutionResults {
            total_patterns,
            hash_tables: hash_tables_vec,
            metadata,
        })
    }

    /// Compute adaptive pattern counts per operation
    fn compute_pattern_counts(&self, graph: &HologramGraph) -> Result<AHashMap<NodeId, usize>> {
        let mut counts = AHashMap::new();

        for node_id in graph.petgraph().node_indices() {
            if let Some(node) = graph.node(node_id) {
                let count = match node.op_type.as_str() {
                    // Simple element-wise operations
                    "Relu" | "Sigmoid" | "Tanh" | "Add" | "Sub" | "Mul" | "Div" => 64,

                    // Matrix operations (more patterns needed)
                    "MatMul" | "Gemm" => 128,

                    // Complex operations
                    "Attention" | "Softmax" | "LayerNormalization" => 256,

                    // Shape operations (minimal patterns)
                    "Reshape" | "Transpose" | "Flatten" | "Squeeze" | "Unsqueeze" => 32,

                    // Constant operations (single pattern)
                    "Constant" | "Shape" => 1,

                    // Default
                    _ => 64,
                };

                counts.insert(node_id, count);
            }
        }

        Ok(counts)
    }

    /// Generate Arrow-backed patterns with specified size
    fn generate_arrow_patterns_with_size(
        &self,
        num_patterns: usize,
        pattern_size: usize,
    ) -> Result<Vec<ArrowTensor>> {
        let mut patterns = Vec::new();

        for i in 0..num_patterns {
            let pattern: Vec<f32> = (0..pattern_size)
                .map(|j| ((i * pattern_size + j) as f32 * 0.01) % 2.0 - 1.0)
                .collect();

            let tensor = ArrowTensor::from_vec(pattern, vec![pattern_size as i64])?;
            patterns.push(tensor);
        }

        Ok(patterns)
    }

    /// Extract ArrowTensor patterns from initializer tensor data
    fn extract_initializer_arrow_patterns(
        &self,
        initializer: &crate::proto::TensorProto,
        num_patterns: usize,
    ) -> Result<Vec<ArrowTensor>> {
        // Parse tensor data to f32 values
        let values = self.parse_tensor_to_f32(initializer)?;

        if values.is_empty() {
            return self.generate_arrow_patterns_with_size(num_patterns, 256);
        }

        // Initializers are constant weights - use the FULL tensor as-is
        // Return the same ArrowTensor repeated num_patterns times (Arc clone is cheap)
        let tensor = ArrowTensor::from_vec(values, vec![initializer.dims.iter().product()])?;
        Ok(vec![tensor; num_patterns])
    }

    /// Parse TensorProto to f32 values (same as before)
    fn parse_tensor_to_f32(&self, tensor: &crate::proto::TensorProto) -> Result<Vec<f32>> {
        use crate::proto::tensor_proto::DataType;

        let data_type = DataType::try_from(tensor.data_type).unwrap_or(DataType::Undefined);

        match data_type {
            DataType::Float => {
                if !tensor.float_data.is_empty() {
                    Ok(tensor.float_data.clone())
                } else if !tensor.raw_data.is_empty() {
                    let mut values = Vec::new();
                    for chunk in tensor.raw_data.chunks_exact(4) {
                        let bytes: [u8; 4] = chunk.try_into().map_err(|_| {
                            CompilerError::InvalidModel("Invalid raw_data size".to_string())
                        })?;
                        values.push(f32::from_le_bytes(bytes));
                    }
                    Ok(values)
                } else {
                    Ok(vec![])
                }
            }
            DataType::Double => {
                if !tensor.double_data.is_empty() {
                    Ok(tensor.double_data.iter().map(|&x| x as f32).collect())
                } else if !tensor.raw_data.is_empty() {
                    let mut values = Vec::new();
                    for chunk in tensor.raw_data.chunks_exact(8) {
                        let bytes: [u8; 8] = chunk.try_into().map_err(|_| {
                            CompilerError::InvalidModel("Invalid raw_data size".to_string())
                        })?;
                        values.push(f64::from_le_bytes(bytes) as f32);
                    }
                    Ok(values)
                } else {
                    Ok(vec![])
                }
            }
            DataType::Int32 | DataType::Int64 => {
                if !tensor.int32_data.is_empty() {
                    Ok(tensor.int32_data.iter().map(|&x| x as f32).collect())
                } else if !tensor.int64_data.is_empty() {
                    Ok(tensor.int64_data.iter().map(|&x| x as f32).collect())
                } else {
                    Ok(vec![])
                }
            }
            _ => Ok(vec![]),
        }
    }

    /// Estimate pattern size (number of elements) for an operation
    fn estimate_pattern_size(
        &self,
        node: &crate::hrm::graph::GraphNode,
        _graph: &HologramGraph,
    ) -> usize {
        match node.op_type.as_str() {
            "Constant" | "Shape" => 1,
            "Add" | "Sub" | "Mul" | "Div" | "Relu" | "Sigmoid" | "Tanh" => 256,
            "MatMul" | "Gemm" => 1024,
            _ => 512,
        }
    }

    /// Hash an input pattern for O(1) lookup
    fn hash_pattern(&self, pattern: &[f32]) -> u64 {
        use std::hash::{Hash, Hasher};

        let mut hasher = ahash::AHasher::default();

        for &val in pattern {
            val.to_bits().hash(&mut hasher);
        }

        hasher.finish()
    }

    /// Get input shapes for an operation
    fn get_input_shapes(
        &self,
        node_id: NodeId,
        graph: &HologramGraph,
        resolved_input_shapes: &std::collections::HashMap<String, Vec<i64>>,
    ) -> Vec<Option<Vec<i64>>> {
        let node = match graph.node(node_id) {
            Some(n) => n,
            None => return vec![],
        };

        node.input_names
            .iter()
            .filter_map(|input_name| {
                if input_name.is_empty() {
                    return None;
                }

                // First check if this is a graph input (use resolved shapes)
                if let Some(shape) = resolved_input_shapes.get(input_name) {
                    return Some(Some(shape.clone()));
                }

                // Check if this is a producer from the graph
                if let Some((producer_id, output_slot)) = graph.tensor_producers().get(input_name) {
                    Some(graph.shapes.get(&(*producer_id, *output_slot)).cloned())
                } else if let Some(initializer) = graph.initializers_map().get(input_name) {
                    Some(Some(initializer.dims.clone()))
                } else {
                    Some(None)
                }
            })
            .collect()
    }
}

impl Default for ArrowGraphExecutor {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_executor_creation() {
        let executor = ArrowGraphExecutor::new();
        assert_eq!(executor.memory_budget, 2048);
        assert!(!executor.verbose);
    }

    #[test]
    fn test_hash_pattern() {
        let executor = ArrowGraphExecutor::new();

        let pattern1 = vec![1.0, 2.0, 3.0];
        let pattern2 = vec![1.0, 2.0, 3.0];
        let pattern3 = vec![1.0, 2.0, 4.0];

        // Same patterns should hash to same value
        assert_eq!(
            executor.hash_pattern(&pattern1),
            executor.hash_pattern(&pattern2)
        );

        // Different patterns should hash to different values (usually)
        assert_ne!(
            executor.hash_pattern(&pattern1),
            executor.hash_pattern(&pattern3)
        );
    }

    #[test]
    fn test_generate_arrow_patterns() {
        let executor = ArrowGraphExecutor::new();
        let patterns = executor.generate_arrow_patterns_with_size(10, 256).unwrap();

        assert_eq!(patterns.len(), 10);
        for pattern in &patterns {
            assert_eq!(pattern.len(), 256);
            assert_eq!(pattern.shape(), &[256]);
        }
    }
}
