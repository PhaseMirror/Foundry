//! ONNX Shape Inference
//!
//! Propagates tensor shapes through the computation graph using ONNX operator semantics.
//!
//! ## Algorithm
//!
//! 1. Start with known input shapes (from user or auto-detection)
//! 2. Traverse graph in topological order
//! 3. For each operation, infer output shapes from input shapes using operator-specific rules
//! 4. Store inferred shapes in HologramGraph.shapes map
//!
//! ## Supported Operations
//!
//! - **Element-wise**: Add, Sub, Mul, Div, Relu, Sigmoid, Tanh (broadcasting)
//! - **Matrix ops**: MatMul, Gemm
//! - **Shape ops**: Reshape, Transpose, Concat, Squeeze, Unsqueeze
//! - **Reductions**: ReduceSum, ReduceMean, ReduceMax, ReduceMin
//! - **Normalization**: LayerNormalization, BatchNormalization

use crate::hrm::graph::HologramGraph;
use crate::{CompilerError, Result};
use ahash::AHashMap;

/// Shape inference engine
pub struct ShapeInference {
    verbose: bool,
}

impl ShapeInference {
    pub fn new() -> Self {
        Self { verbose: false }
    }

    pub fn with_verbose(mut self, verbose: bool) -> Self {
        self.verbose = verbose;
        self
    }

    /// Infer shapes for entire graph
    ///
    /// # Arguments
    ///
    /// * `graph` - Graph to infer shapes for
    /// * `input_shapes` - Known input shapes (name → shape)
    ///
    /// # Returns
    ///
    /// Updated graph with shapes filled in
    pub fn infer_shapes(
        &self,
        graph: &mut HologramGraph,
        input_shapes: &std::collections::HashMap<String, Vec<i64>>,
    ) -> Result<()> {
        if self.verbose {
            println!("   🔍 Inferring tensor shapes...");
        }

        // Initialize shapes for graph inputs
        for (name, shape) in input_shapes {
            // Find the node that produces this input tensor
            if graph.graph_inputs().iter().any(|v| &v.name == name) && self.verbose {
                println!("      Input '{}': {:?}", name, shape);
            }
            // Graph inputs don't have a producer node - they're external
            // We'll handle them when processing operations that consume them
        }

        // Initialize shapes for initializers (constant weights)
        for (name, tensor) in graph.initializers_map() {
            let shape: Vec<i64> = tensor.dims.clone();
            if self.verbose {
                println!("      Initializer '{}': {:?}", name, shape);
            }
            // Initializers also don't have producer nodes
        }

        // Traverse graph in topological order
        let topo_order = graph.topological_sort()?;

        for node_id in topo_order {
            // Clone node data to avoid borrow conflicts
            let (node_op_type, node_input_names, node_attributes, output_names) = {
                let node = graph
                    .node(node_id)
                    .ok_or_else(|| CompilerError::InvalidModel(format!("Node {:?} not found", node_id)))?;
                (
                    node.op_type.clone(),
                    node.input_names.clone(),
                    node.attributes.clone(),
                    node.output_names.clone(),
                )
            };

            if self.verbose {
                println!(
                    "      Processing {:?}: {} (outputs: {:?})",
                    node_id, node_op_type, output_names
                );
            }

            // Gather input shapes
            let mut input_shapes_for_op: Vec<Vec<i64>> = Vec::new();

            for input_name in &node_input_names {
                if input_name.is_empty() {
                    continue;
                }

                // Check if this is a graph input
                if let Some(shape) = input_shapes.get(input_name) {
                    input_shapes_for_op.push(shape.clone());
                } else if let Some((producer_id, output_slot)) = graph.tensor_producers().get(input_name) {
                    // Get shape from upstream node's output
                    if let Some(shape) = graph.shapes.get(&(*producer_id, *output_slot)) {
                        input_shapes_for_op.push(shape.clone());
                    } else {
                        return Err(CompilerError::InvalidModel(format!(
                            "Shape not yet inferred for tensor '{}' (producer {:?}, op_type: {})",
                            input_name, producer_id, node_op_type
                        )));
                    }
                } else if let Some(initializer) = graph.initializers_map().get(input_name) {
                    // Use initializer shape
                    input_shapes_for_op.push(initializer.dims.clone());
                } else {
                    return Err(CompilerError::InvalidModel(format!(
                        "Unknown input tensor '{}' for node {:?}",
                        input_name, node_id
                    )));
                }
            }

            // Convert attributes Vec to HashMap for easier lookup
            let attributes: AHashMap<String, crate::proto::AttributeProto> = node_attributes
                .iter()
                .map(|attr| (attr.name.clone(), attr.clone()))
                .collect();

            // Special handling for Reshape/Expand with constant/Shape second input (constant folding)
            let output_shapes = if (node_op_type == "Reshape" || node_op_type == "Expand") && node_input_names.len() >= 2 {
                // Check if second input is a constant initializer
                if let Some(initializer) = graph.initializers_map().get(&node_input_names[1]) {
                    // Read the actual shape values from the constant tensor
                    use crate::proto::tensor_proto::DataType;
                    let target_shape: Vec<i64> = match DataType::try_from(initializer.data_type) {
                        Ok(DataType::Int64) => {
                            if !initializer.int64_data.is_empty() {
                                initializer.int64_data.clone()
                            } else if !initializer.raw_data.is_empty() {
                                // Parse raw bytes as i64 array
                                initializer.raw_data
                                    .chunks_exact(8)
                                    .map(|chunk| i64::from_le_bytes([
                                        chunk[0], chunk[1], chunk[2], chunk[3],
                                        chunk[4], chunk[5], chunk[6], chunk[7],
                                    ]))
                                    .collect()
                            } else {
                                vec![]
                            }
                        }
                        Ok(DataType::Int32) => {
                            initializer.int32_data.iter().map(|&x| x as i64).collect()
                        }
                        _ => {
                            if self.verbose {
                                println!("         [Reshape] Unsupported shape tensor type: {:?}", initializer.data_type);
                            }
                            vec![]
                        }
                    };

                    if !target_shape.is_empty() {
                        // Handle -1 dimension (infer from total elements)
                        let resolved_shape = if target_shape.contains(&-1) {
                            if input_shapes_for_op.is_empty() {
                                target_shape
                            } else {
                                let input_size: i64 = input_shapes_for_op[0].iter().product();
                                let known_size: i64 = target_shape.iter()
                                    .filter(|&&d| d != -1)
                                    .product();

                                if known_size == 0 {
                                    target_shape
                                } else {
                                    let inferred_dim = input_size / known_size;
                                    target_shape.iter()
                                        .map(|&d| if d == -1 { inferred_dim } else { d })
                                        .collect()
                                }
                            }
                        } else {
                            target_shape
                        };

                        if self.verbose {
                            println!("         [Reshape constant folding] Using constant shape: {:?}", resolved_shape);
                        }
                        vec![resolved_shape]
                    } else {
                        self.infer_op_output_shapes(&node_op_type, &input_shapes_for_op, &attributes)?
                    }
                } else if let Some((producer_id, _)) = graph.tensor_producers().get(&node_input_names[1]) {
                    if let Some(producer_node) = graph.node(*producer_id) {
                        if producer_node.op_type == "Shape" && !producer_node.input_names.is_empty() {
                            // Get the shape of the Shape node's input
                            let shape_input_name = &producer_node.input_names[0];
                            if self.verbose {
                                println!("         [Reshape constant folding] Shape node's input: {}", shape_input_name);
                            }
                            if let Some((shape_producer_id, output_slot)) = graph.tensor_producers().get(shape_input_name) {
                                if let Some(original_shape) = graph.shapes.get(&(*shape_producer_id, *output_slot)) {
                                    if self.verbose {
                                        println!("         [Reshape constant folding] Using shape: {:?}", original_shape);
                                    }
                                    // Use the original tensor's shape as the Reshape output
                                    vec![original_shape.clone()]
                                } else {
                                    self.infer_op_output_shapes(&node_op_type, &input_shapes_for_op, &attributes)?
                                }
                            } else if let Some(shape) = input_shapes.get(shape_input_name) {
                                // Shape node's input is a graph input
                                vec![shape.clone()]
                            } else if let Some(initializer) = graph.initializers_map().get(shape_input_name) {
                                // Shape node's input is an initializer
                                vec![initializer.dims.clone()]
                            } else {
                                self.infer_op_output_shapes(&node_op_type, &input_shapes_for_op, &attributes)?
                            }
                        } else {
                            self.infer_op_output_shapes(&node_op_type, &input_shapes_for_op, &attributes)?
                        }
                    } else {
                        self.infer_op_output_shapes(&node_op_type, &input_shapes_for_op, &attributes)?
                    }
                } else {
                    self.infer_op_output_shapes(&node_op_type, &input_shapes_for_op, &attributes)?
                }
            } else {
                self.infer_op_output_shapes(&node_op_type, &input_shapes_for_op, &attributes)?
            };

            // Store output shapes
            for (slot, shape) in output_shapes.iter().enumerate() {
                graph.shapes.insert((node_id, slot as u8), shape.clone());
            }

            if self.verbose {
                println!("         → Inferred output shapes: {}", format_shapes(&output_shapes));
            }
        }

        if self.verbose {
            println!("   ✓ Shape inference complete");
        }

        Ok(())
    }

    /// Infer output shapes for a specific operation
    fn infer_op_output_shapes(
        &self,
        op_type: &str,
        input_shapes: &[Vec<i64>],
        attributes: &AHashMap<String, crate::proto::AttributeProto>,
    ) -> Result<Vec<Vec<i64>>> {
        match op_type {
            // Element-wise operations (broadcasting)
            "Add" | "Sub" | "Mul" | "Div" | "Equal" | "Greater" | "Less" => {
                if input_shapes.len() != 2 {
                    return Err(CompilerError::InvalidModel(format!(
                        "{} requires 2 inputs, got {}",
                        op_type,
                        input_shapes.len()
                    )));
                }
                Ok(vec![broadcast_shapes(&input_shapes[0], &input_shapes[1])?])
            }

            // Unary element-wise operations (including Cast and Softmax which preserve shape)
            "Relu" | "Sigmoid" | "Tanh" | "Softmax" | "Gelu" | "Neg" | "Abs" | "Sqrt" | "Exp" | "Log" | "Cast" => {
                if input_shapes.is_empty() {
                    return Err(CompilerError::InvalidModel(format!(
                        "{} requires at least 1 input",
                        op_type
                    )));
                }
                Ok(vec![input_shapes[0].clone()])
            }

            // Expand - broadcast input to target shape
            "Expand" => {
                if input_shapes.len() != 2 {
                    return Err(CompilerError::InvalidModel(format!(
                        "Expand requires 2 inputs, got {}",
                        input_shapes.len()
                    )));
                }
                // Second input is the target shape
                // The output shape is the broadcast result
                Ok(vec![input_shapes[1].clone()])
            }

            // Matrix multiplication
            "MatMul" => {
                if input_shapes.len() != 2 {
                    return Err(CompilerError::InvalidModel(format!(
                        "MatMul requires 2 inputs, got {}",
                        input_shapes.len()
                    )));
                }
                self.infer_matmul_shape(&input_shapes[0], &input_shapes[1])
            }

            // Gemm: Y = alpha * A * B + beta * C
            "Gemm" => {
                if input_shapes.len() < 2 {
                    return Err(CompilerError::InvalidModel(format!(
                        "Gemm requires at least 2 inputs, got {}",
                        input_shapes.len()
                    )));
                }

                let trans_a = get_int_attr(attributes, "transA").unwrap_or(0) != 0;
                let trans_b = get_int_attr(attributes, "transB").unwrap_or(0) != 0;

                let a_shape = if trans_a {
                    vec![input_shapes[0][1], input_shapes[0][0]]
                } else {
                    input_shapes[0].clone()
                };

                let b_shape = if trans_b {
                    vec![input_shapes[1][1], input_shapes[1][0]]
                } else {
                    input_shapes[1].clone()
                };

                self.infer_matmul_shape(&a_shape, &b_shape)
            }

            // Reshape
            "Reshape" => {
                if input_shapes.len() != 2 {
                    return Err(CompilerError::InvalidModel(format!(
                        "Reshape requires 2 inputs, got {}",
                        input_shapes.len()
                    )));
                }
                // Second input is the target shape (as a 1D tensor)
                // For now, we can't infer this statically without evaluating the shape tensor
                // Return the second input's values as the output shape
                // This is a simplification - full implementation would evaluate constant shape tensors
                Ok(vec![input_shapes[1].clone()])
            }

            // Transpose
            "Transpose" => {
                if input_shapes.is_empty() {
                    return Err(CompilerError::InvalidModel("Transpose requires 1 input".to_string()));
                }

                let perm = get_ints_attr(attributes, "perm");
                let output_shape = if let Some(perm) = perm {
                    // Validate permutation indices before applying
                    for &idx in perm.iter() {
                        if (idx as usize) >= input_shapes[0].len() {
                            return Err(CompilerError::InvalidModel(format!(
                                "Transpose perm index {} out of bounds for input rank {}",
                                idx, input_shapes[0].len()
                            )));
                        }
                    }
                    // Apply permutation
                    perm.iter().map(|&i| input_shapes[0][i as usize]).collect()
                } else {
                    // Default: reverse dimensions
                    input_shapes[0].iter().rev().copied().collect()
                };

                Ok(vec![output_shape])
            }

            // Concat
            "Concat" => {
                if input_shapes.is_empty() {
                    return Err(CompilerError::InvalidModel(
                        "Concat requires at least 1 input".to_string(),
                    ));
                }

                let axis = get_int_attr(attributes, "axis")
                    .ok_or_else(|| CompilerError::InvalidModel("Concat requires 'axis' attribute".to_string()))?
                    as usize;

                let mut output_shape = input_shapes[0].clone();
                for input_shape in &input_shapes[1..] {
                    output_shape[axis] += input_shape[axis];
                }

                Ok(vec![output_shape])
            }

            // Squeeze
            "Squeeze" => {
                if input_shapes.is_empty() {
                    return Err(CompilerError::InvalidModel("Squeeze requires 1 input".to_string()));
                }

                let axes = if input_shapes.len() > 1 {
                    // axes provided as second input
                    // Simplified: assume we're removing dimension 0
                    vec![0i64]
                } else {
                    get_ints_attr(attributes, "axes").unwrap_or_else(|| {
                        // Remove all dimensions of size 1
                        input_shapes[0]
                            .iter()
                            .enumerate()
                            .filter(|(_, &dim)| dim == 1)
                            .map(|(i, _)| i as i64)
                            .collect()
                    })
                };

                let output_shape: Vec<i64> = input_shapes[0]
                    .iter()
                    .enumerate()
                    .filter(|(i, _)| !axes.contains(&(*i as i64)))
                    .map(|(_, &dim)| dim)
                    .collect();

                Ok(vec![output_shape])
            }

            // Unsqueeze
            "Unsqueeze" => {
                if input_shapes.is_empty() {
                    return Err(CompilerError::InvalidModel("Unsqueeze requires 1 input".to_string()));
                }

                let axes = if input_shapes.len() > 1 {
                    // axes provided as second input (ONNX opset 13+)
                    // Simplified: assume adding dimension at 0
                    vec![0i64]
                } else {
                    get_ints_attr(attributes, "axes").ok_or_else(|| {
                        CompilerError::InvalidModel("Unsqueeze requires 'axes' attribute or second input".to_string())
                    })?
                };

                let mut output_shape = input_shapes[0].clone();
                for &axis in &axes {
                    let axis = if axis < 0 {
                        (output_shape.len() as i64 + axis + 1) as usize
                    } else {
                        axis as usize
                    };
                    output_shape.insert(axis, 1);
                }

                Ok(vec![output_shape])
            }

            // Reductions
            "ReduceSum" | "ReduceMean" | "ReduceMax" | "ReduceMin" => {
                if input_shapes.is_empty() {
                    return Err(CompilerError::InvalidModel(format!("{} requires 1 input", op_type)));
                }

                let keepdims = get_int_attr(attributes, "keepdims").unwrap_or(1) != 0;
                let axes = get_ints_attr(attributes, "axes").unwrap_or_else(|| {
                    // Default: reduce all dimensions
                    (0..input_shapes[0].len() as i64).collect()
                });

                let output_shape = if keepdims {
                    input_shapes[0]
                        .iter()
                        .enumerate()
                        .map(|(i, &dim)| if axes.contains(&(i as i64)) { 1 } else { dim })
                        .collect()
                } else {
                    input_shapes[0]
                        .iter()
                        .enumerate()
                        .filter(|(i, _)| !axes.contains(&(*i as i64)))
                        .map(|(_, &dim)| dim)
                        .collect()
                };

                Ok(vec![output_shape])
            }

            // Gather
            "Gather" => {
                if input_shapes.len() != 2 {
                    return Err(CompilerError::InvalidModel(format!(
                        "Gather requires 2 inputs, got {}",
                        input_shapes.len()
                    )));
                }

                let axis = get_int_attr(attributes, "axis").unwrap_or(0) as usize;
                let data_shape = &input_shapes[0];
                let indices_shape = &input_shapes[1];

                // Output shape: data_shape[:axis] + indices_shape + data_shape[axis+1:]
                let mut output_shape = Vec::new();
                output_shape.extend_from_slice(&data_shape[..axis]);
                output_shape.extend_from_slice(indices_shape);
                output_shape.extend_from_slice(&data_shape[axis + 1..]);

                Ok(vec![output_shape])
            }

            // LayerNormalization
            "LayerNormalization" => {
                if input_shapes.is_empty() {
                    return Err(CompilerError::InvalidModel(
                        "LayerNormalization requires at least 1 input".to_string(),
                    ));
                }
                // Output has same shape as input
                Ok(vec![input_shapes[0].clone()])
            }

            // Constant
            "Constant" => {
                // Get shape from value attribute's TensorProto
                if let Some(value_attr) = attributes.get("value") {
                    if let Some(ref tensor) = value_attr.t {
                        // Return the shape from the tensor
                        return Ok(vec![tensor.dims.clone()]);
                    }
                }
                // Fallback: scalar constant
                Ok(vec![vec![]])
            }

            // Shape
            "Shape" => {
                if input_shapes.is_empty() {
                    return Err(CompilerError::InvalidModel("Shape requires 1 input".to_string()));
                }
                // Output is a 1D tensor with size = rank of input
                // The VALUES are the input's dimensions, but we only track shapes here
                // For input shape [2, 128, 768], output shape is [3]
                Ok(vec![vec![input_shapes[0].len() as i64]])
            }

            // Flatten
            "Flatten" => {
                if input_shapes.is_empty() {
                    return Err(CompilerError::InvalidModel("Flatten requires 1 input".to_string()));
                }

                let axis = get_int_attr(attributes, "axis").unwrap_or(1) as usize;
                let dim1: i64 = input_shapes[0][..axis].iter().product();
                let dim2: i64 = input_shapes[0][axis..].iter().product();

                Ok(vec![vec![dim1, dim2]])
            }

            // Slice
            "Slice" => {
                if input_shapes.is_empty() {
                    return Err(CompilerError::InvalidModel(
                        "Slice requires at least 1 input".to_string(),
                    ));
                }
                // Simplified: return input shape (actual slicing would modify dimensions)
                Ok(vec![input_shapes[0].clone()])
            }

            // Attention (custom op)
            "Attention" => {
                if input_shapes.is_empty() {
                    return Err(CompilerError::InvalidModel(
                        "Attention requires at least 1 input".to_string(),
                    ));
                }
                // Attention preserves shape (for self-attention)
                Ok(vec![input_shapes[0].clone()])
            }

            // BiasGelu (custom op)
            "BiasGelu" => {
                if input_shapes.is_empty() {
                    return Err(CompilerError::InvalidModel(
                        "BiasGelu requires at least 1 input".to_string(),
                    ));
                }
                // BiasGelu preserves shape
                Ok(vec![input_shapes[0].clone()])
            }

            // SkipLayerNormalization (custom op)
            "SkipLayerNormalization" => {
                if input_shapes.is_empty() {
                    return Err(CompilerError::InvalidModel(
                        "SkipLayerNormalization requires at least 1 input".to_string(),
                    ));
                }
                // SkipLayerNormalization has 4 outputs:
                // 1. Y (normalized output) - same shape as input
                // 2. Mean (optional) - empty in CLIP
                // 3. InvStdDev (optional) - empty in CLIP
                // 4. Input (residual/skip connection) - same shape as input
                Ok(vec![
                    input_shapes[0].clone(), // Y - normalized output
                    vec![],                  // Mean - optional (empty)
                    vec![],                  // InvStdDev - optional (empty)
                    input_shapes[0].clone(), // Input - residual/skip output
                ])
            }

            // ArgMax
            "ArgMax" => {
                if input_shapes.is_empty() {
                    return Err(CompilerError::InvalidModel("ArgMax requires 1 input".to_string()));
                }

                let keepdims = get_int_attr(attributes, "keepdims").unwrap_or(1) != 0;
                let axis = get_int_attr(attributes, "axis").unwrap_or(-1);

                let axis = if axis < 0 {
                    (input_shapes[0].len() as i64 + axis) as usize
                } else {
                    axis as usize
                };

                let output_shape = if keepdims {
                    input_shapes[0]
                        .iter()
                        .enumerate()
                        .map(|(i, &dim)| if i == axis { 1 } else { dim })
                        .collect()
                } else {
                    input_shapes[0]
                        .iter()
                        .enumerate()
                        .filter(|(i, _)| *i != axis)
                        .map(|(_, &dim)| dim)
                        .collect()
                };

                Ok(vec![output_shape])
            }

            // Range
            "Range" => {
                // Range outputs a 1D tensor - shape depends on start/limit/delta
                // Simplified: return 1D tensor
                Ok(vec![vec![1]])
            }

            _ => {
                // Unknown operation - return input shape as fallback
                if !input_shapes.is_empty() {
                    Ok(vec![input_shapes[0].clone()])
                } else {
                    Ok(vec![vec![1]])
                }
            }
        }
    }

    /// Infer MatMul output shape
    fn infer_matmul_shape(&self, a_shape: &[i64], b_shape: &[i64]) -> Result<Vec<Vec<i64>>> {
        if a_shape.len() < 2 || b_shape.len() < 2 {
            return Err(CompilerError::InvalidModel(format!(
                "MatMul requires 2D+ inputs, got shapes {:?} and {:?}",
                a_shape, b_shape
            )));
        }

        let m = a_shape[a_shape.len() - 2];
        let k1 = a_shape[a_shape.len() - 1];
        let k2 = b_shape[b_shape.len() - 2];
        let n = b_shape[b_shape.len() - 1];

        if k1 != k2 {
            return Err(CompilerError::InvalidModel(format!(
                "MatMul dimension mismatch: {} != {}",
                k1, k2
            )));
        }

        // Handle batched matmul (shapes like [B, M, K] × [B, K, N] → [B, M, N])
        let mut output_shape = Vec::new();

        // Broadcast batch dimensions if present
        if a_shape.len() > 2 || b_shape.len() > 2 {
            let max_len = a_shape.len().max(b_shape.len());
            for i in 0..(max_len - 2) {
                let a_dim = if i < a_shape.len() - 2 { a_shape[i] } else { 1 };
                let b_dim = if i < b_shape.len() - 2 { b_shape[i] } else { 1 };
                output_shape.push(a_dim.max(b_dim));
            }
        }

        output_shape.push(m);
        output_shape.push(n);

        Ok(vec![output_shape])
    }
}

impl Default for ShapeInference {
    fn default() -> Self {
        Self::new()
    }
}

/// Broadcast two shapes according to NumPy broadcasting rules
fn broadcast_shapes(shape1: &[i64], shape2: &[i64]) -> Result<Vec<i64>> {
    let max_len = shape1.len().max(shape2.len());
    let mut output_shape = Vec::new();

    for i in 0..max_len {
        let dim1 = if i < shape1.len() {
            shape1[shape1.len() - 1 - i]
        } else {
            1
        };
        let dim2 = if i < shape2.len() {
            shape2[shape2.len() - 1 - i]
        } else {
            1
        };

        if dim1 == dim2 || dim1 == 1 || dim2 == 1 {
            output_shape.push(dim1.max(dim2));
        } else {
            return Err(CompilerError::InvalidModel(format!(
                "Incompatible broadcast dimensions: {} and {}",
                dim1, dim2
            )));
        }
    }

    output_shape.reverse();
    Ok(output_shape)
}

/// Get integer attribute value
fn get_int_attr(attrs: &AHashMap<String, crate::proto::AttributeProto>, name: &str) -> Option<i64> {
    attrs.get(name).and_then(|attr| {
        if attr.r#type == crate::proto::attribute_proto::AttributeType::Int as i32 {
            Some(attr.i)
        } else {
            None
        }
    })
}

/// Get integer array attribute value
fn get_ints_attr(attrs: &AHashMap<String, crate::proto::AttributeProto>, name: &str) -> Option<Vec<i64>> {
    attrs.get(name).and_then(|attr| {
        if attr.r#type == crate::proto::attribute_proto::AttributeType::Ints as i32 {
            Some(attr.ints.clone())
        } else {
            None
        }
    })
}

/// Format shapes for display
fn format_shapes(shapes: &[Vec<i64>]) -> String {
    shapes.iter().map(|s| format!("{:?}", s)).collect::<Vec<_>>().join(", ")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_broadcast_same_shape() {
        let shape = broadcast_shapes(&[2, 3, 4], &[2, 3, 4]).unwrap();
        assert_eq!(shape, vec![2, 3, 4]);
    }

    #[test]
    fn test_broadcast_with_ones() {
        let shape = broadcast_shapes(&[2, 1, 4], &[2, 3, 4]).unwrap();
        assert_eq!(shape, vec![2, 3, 4]);
    }

    #[test]
    fn test_broadcast_different_ranks() {
        let shape = broadcast_shapes(&[3, 4], &[2, 3, 4]).unwrap();
        assert_eq!(shape, vec![2, 3, 4]);
    }

    #[test]
    fn test_broadcast_incompatible() {
        let result = broadcast_shapes(&[2, 3], &[2, 4]);
        assert!(result.is_err());
    }
}
