// Hologram Intermediate Representation (HIR)
//
// Graph representation of ONNX models using petgraph for optimization and analysis.
// Provides ergonomic builder API for constructing and modifying computational graphs.

use crate::proto::{AttributeProto, GraphProto, NodeProto, TensorProto, ValueInfoProto};
use anyhow::{anyhow, Context, Result};
use hologram::GriessVector;
use petgraph::algo::toposort;
use petgraph::stable_graph::{EdgeReference, NodeIndex, StableGraph};
use petgraph::visit::{EdgeRef, IntoEdgeReferences};
use petgraph::Direction;
use rustc_hash::FxHashMap;
use std::collections::HashMap;
use std::path::Path;

/// Node identifier in the graph (petgraph NodeIndex)
pub type NodeId = NodeIndex;

/// Dependency edge between nodes
#[derive(Debug, Clone)]
pub enum Dependency {
    /// Data dependency: tensor flows from source to destination
    Data {
        /// Which output slot on the source node
        output_slot: u8,
        /// Which input slot on the destination node
        input_slot: u8,
        /// Shape of the tensor
        shape: Vec<i64>,
    },
    /// Schedule dependency: enforce execution order without data transfer
    Schedule,
}

/// A node in the computation graph
#[derive(Debug, Clone)]
pub struct GraphNode {
    /// Original ONNX node name
    pub name: String,
    /// Operation type (e.g., "Add", "MatMul", "Relu")
    pub op_type: String,
    /// Operation attributes from ONNX
    pub attributes: Vec<AttributeProto>,
    /// Input tensor names from ONNX (for compatibility)
    pub input_names: Vec<String>,
    /// Output tensor names from ONNX (for compatibility)
    pub output_names: Vec<String>,
    /// Domain (e.g., "" for default ONNX)
    pub domain: String,
}

impl GraphNode {
    /// Create from ONNX NodeProto
    pub fn from_onnx_node(node: &NodeProto) -> Self {
        Self {
            name: node.name.clone(),
            op_type: node.op_type.clone(),
            attributes: node.attribute.clone(),
            input_names: node.input.clone(),
            output_names: node.output.clone(),
            domain: node.domain.clone(),
        }
    }

    /// Get attribute by name
    pub fn get_attribute(&self, name: &str) -> Option<&AttributeProto> {
        self.attributes.iter().find(|attr| attr.name == name)
    }
}

/// Hologram computation graph using petgraph
pub struct HologramGraph {
    /// The underlying petgraph structure
    graph: StableGraph<GraphNode, Dependency>,

    /// Tensor name to producer mapping: name → (node_id, output_slot)
    tensor_producers: FxHashMap<String, (NodeId, u8)>,

    /// Node name to node ID mapping
    name_to_id: FxHashMap<String, NodeId>,

    /// Graph inputs (from ONNX)
    inputs: Vec<ValueInfoProto>,

    /// Graph outputs (from ONNX)
    outputs: Vec<ValueInfoProto>,

    /// Initializers (constant weights from ONNX)
    initializers: FxHashMap<String, TensorProto>,

    /// Embedded tensors (populated during Pass 3)
    pub embeddings: FxHashMap<(NodeId, u8), GriessVector>,

    /// Shape information per tensor output
    pub shapes: FxHashMap<(NodeId, u8), Vec<i64>>,

    /// Cached consumer counts for memory management
    consumer_counts: Option<FxHashMap<(NodeId, u8), usize>>,
}

impl HologramGraph {
    /// Create a new empty graph
    pub fn new() -> Self {
        Self {
            graph: StableGraph::new(),
            tensor_producers: FxHashMap::default(),
            name_to_id: FxHashMap::default(),
            inputs: Vec::new(),
            outputs: Vec::new(),
            initializers: FxHashMap::default(),
            embeddings: FxHashMap::default(),
            shapes: FxHashMap::default(),
            consumer_counts: None,
        }
    }

    /// Convert from ONNX GraphProto
    ///
    /// If `model_dir` is provided, external data files (e.g., `.onnx.data`) will be loaded.
    pub fn from_onnx_with_path(onnx_graph: &GraphProto, model_dir: Option<&Path>) -> Result<Self> {
        let mut hir = Self::new();

        // Copy metadata
        hir.inputs = onnx_graph.input.clone();
        hir.outputs = onnx_graph.output.clone();

        // Build initializer map with external data loading
        for init in &onnx_graph.initializer {
            let mut tensor = init.clone();

            // Load external data if present
            if let Some(dir) = model_dir {
                Self::load_external_data(&mut tensor, dir)?;
            }

            hir.initializers.insert(init.name.clone(), tensor);
        }

        // Add all nodes to graph
        for onnx_node in &onnx_graph.node {
            let node_data = GraphNode::from_onnx_node(onnx_node);
            let node_id = hir.graph.add_node(node_data.clone());

            // Register output tensors
            for (output_slot, output_name) in node_data.output_names.iter().enumerate() {
                hir.tensor_producers
                    .insert(output_name.clone(), (node_id, output_slot as u8));
            }

            // Register node name
            if !node_data.name.is_empty() {
                hir.name_to_id.insert(node_data.name.clone(), node_id);
            }
        }

        // Add edges between nodes
        // Collect edge information first to avoid borrow checker issues
        let edge_info: Vec<_> = hir
            .graph
            .node_indices()
            .flat_map(|node_id| {
                let node = &hir.graph[node_id];
                node.input_names
                    .iter()
                    .enumerate()
                    .filter_map(|(input_slot, input_name)| {
                        if input_name.is_empty() || hir.initializers.contains_key(input_name) {
                            return None;
                        }
                        hir.tensor_producers
                            .get(input_name)
                            .map(|&(source_id, output_slot)| (source_id, node_id, output_slot, input_slot as u8))
                    })
                    .collect::<Vec<_>>()
            })
            .collect();

        // Now add the edges
        for (source_id, target_id, output_slot, input_slot) in edge_info {
            hir.graph.add_edge(
                source_id,
                target_id,
                Dependency::Data {
                    output_slot,
                    input_slot,
                    shape: Vec::new(),
                },
            );
        }

        Ok(hir)
    }

    /// Legacy method for backward compatibility
    pub fn from_onnx(onnx_graph: &GraphProto) -> Result<Self> {
        Self::from_onnx_with_path(onnx_graph, None)
    }

    /// Load external data into a TensorProto if present
    ///
    /// Checks if the tensor has external_data field set and loads the data from the external file.
    /// The external file path is resolved relative to `base_dir`.
    fn load_external_data(tensor: &mut TensorProto, base_dir: &Path) -> Result<()> {
        use crate::proto::tensor_proto::DataLocation;

        // Check if tensor uses external data
        let data_location = DataLocation::try_from(tensor.data_location)
            .unwrap_or(DataLocation::Default);

        if data_location != DataLocation::External || tensor.external_data.is_empty() {
            return Ok(());
        }

        // Parse external_data key-value pairs
        let mut location = None;
        let mut offset: Option<u64> = None;
        let mut length: Option<u64> = None;

        for entry in &tensor.external_data {
            match entry.key.as_str() {
                "location" => location = Some(entry.value.clone()),
                "offset" => offset = entry.value.parse().ok(),
                "length" => length = entry.value.parse().ok(),
                "checksum" => {} // Ignore checksum for now
                _ => {}
            }
        }

        let location = location.ok_or_else(|| {
            anyhow!("External data for tensor '{}' missing 'location' key", tensor.name)
        })?;

        // Construct full path
        let external_path = base_dir.join(&location);

        // Load data from file
        let file_data = std::fs::read(&external_path)
            .with_context(|| format!("Failed to load external data from {}", external_path.display()))?;

        // Extract the relevant slice
        let data_slice = if let Some(off) = offset {
            let start = off as usize;
            let end = if let Some(len) = length {
                start + (len as usize)
            } else {
                file_data.len()
            };

            &file_data[start..end]
        } else {
            &file_data[..]
        };

        // Store in raw_data
        tensor.raw_data = data_slice.to_vec();

        Ok(())
    }

    /// Convert back to ONNX GraphProto
    pub fn to_onnx(&self) -> Result<GraphProto> {
        let mut onnx_graph = GraphProto {
            input: self.inputs.clone(),
            output: self.outputs.clone(),
            initializer: self.initializers.values().cloned().collect(),
            ..Default::default()
        };

        // Convert nodes (in topological order for determinism)
        let topo_order = toposort(&self.graph, None).map_err(|_| anyhow!("Graph contains cycles"))?;

        for node_id in topo_order {
            let node = &self.graph[node_id];
            let onnx_node = NodeProto {
                name: node.name.clone(),
                op_type: node.op_type.clone(),
                input: node.input_names.clone(),
                output: node.output_names.clone(),
                attribute: node.attributes.clone(),
                domain: node.domain.clone(),
                ..Default::default()
            };
            onnx_graph.node.push(onnx_node);
        }

        Ok(onnx_graph)
    }

    /// Get node by ID
    pub fn node(&self, node_id: NodeId) -> Option<&GraphNode> {
        self.graph.node_weight(node_id)
    }

    /// Get mutable node by ID
    pub fn node_mut(&mut self, node_id: NodeId) -> Option<&mut GraphNode> {
        self.graph.node_weight_mut(node_id)
    }

    /// Get node by name
    pub fn node_by_name(&self, name: &str) -> Option<&GraphNode> {
        self.name_to_id.get(name).and_then(|&id| self.node(id))
    }

    /// Get all input edges to a node
    pub fn inputs(&self, node_id: NodeId) -> Vec<(NodeId, &Dependency)> {
        self.graph
            .edges_directed(node_id, Direction::Incoming)
            .map(|edge: EdgeReference<Dependency>| (edge.source(), edge.weight()))
            .collect()
    }

    /// Get all output edges from a node
    pub fn outputs(&self, node_id: NodeId) -> Vec<(NodeId, &Dependency)> {
        self.graph
            .edges_directed(node_id, Direction::Outgoing)
            .map(|edge: EdgeReference<Dependency>| (edge.target(), edge.weight()))
            .collect()
    }

    /// Check if a node is a graph output
    pub fn is_graph_output(&self, node_id: NodeId) -> bool {
        if let Some(node) = self.node(node_id) {
            for output_name in &node.output_names {
                if self.outputs.iter().any(|out| out.name == *output_name) {
                    return true;
                }
            }
        }
        false
    }

    /// Remove a node from the graph
    pub fn remove_node(&mut self, node_id: NodeId) -> Result<()> {
        if self.is_graph_output(node_id) {
            return Err(anyhow!("Cannot remove graph output node"));
        }

        // Remove node's output tensors from producer map
        // Clone the data we need before mutating
        let output_names = self.node(node_id).map(|n| n.output_names.clone());
        let node_name = self
            .node(node_id)
            .and_then(|n| if !n.name.is_empty() { Some(n.name.clone()) } else { None });

        if let Some(outputs) = output_names {
            for output_name in &outputs {
                self.tensor_producers.remove(output_name);
            }
        }
        if let Some(name) = node_name {
            self.name_to_id.remove(&name);
        }

        // Remove node from graph (petgraph handles edge removal)
        self.graph.remove_node(node_id);

        // Invalidate caches
        self.consumer_counts = None;

        Ok(())
    }

    /// Replace all usages of one tensor with another
    pub fn replace_tensor(&mut self, old_name: &str, new_name: &str) {
        for node in self.graph.node_weights_mut() {
            for input_name in &mut node.input_names {
                if input_name == old_name {
                    *input_name = new_name.to_string();
                }
            }
        }
        self.consumer_counts = None;
    }

    /// Start building a new operation
    pub fn add_op(&mut self, op_type: impl Into<String>) -> NewOp<'_> {
        NewOp::new(self, op_type.into())
    }

    /// Compute topological sort
    pub fn topological_sort(&self) -> Result<Vec<NodeId>> {
        toposort(&self.graph, None).map_err(|_| anyhow!("Graph contains cycles"))
    }

    /// Build consumer reference count map
    pub fn build_consumer_map(&mut self) -> &FxHashMap<(NodeId, u8), usize> {
        if self.consumer_counts.is_some() {
            return self.consumer_counts.as_ref().unwrap();
        }

        let mut counts: FxHashMap<(NodeId, u8), usize> = FxHashMap::default();

        // Count consumers for each edge
        for edge in self.graph.edge_references() {
            if let Dependency::Data { output_slot, .. } = edge.weight() {
                let key = (edge.source(), *output_slot);
                *counts.entry(key).or_insert(0) += 1;
            }
        }

        // Graph outputs count as 1 consumer
        for output_info in &self.outputs {
            if let Some(&(node_id, output_slot)) = self.tensor_producers.get(&output_info.name) {
                let key = (node_id, output_slot);
                *counts.entry(key).or_insert(0) += 1;
            }
        }

        self.consumer_counts = Some(counts);
        self.consumer_counts.as_ref().unwrap()
    }

    /// Get consumer count for a tensor output
    pub fn get_consumer_count(&self, node_id: NodeId, output_slot: u8) -> usize {
        self.consumer_counts
            .as_ref()
            .and_then(|m| m.get(&(node_id, output_slot)).copied())
            .unwrap_or(0)
    }

    /// Export to Graphviz DOT format
    pub fn visualize_dot(&self) -> String {
        use std::fmt::Write;
        let mut dot = String::new();
        writeln!(&mut dot, "digraph HologramGraph {{").unwrap();
        writeln!(&mut dot, "  rankdir=TB;").unwrap();
        writeln!(&mut dot, "  node [shape=box, style=rounded];").unwrap();

        // Add nodes
        for node_id in self.graph.node_indices() {
            let node = &self.graph[node_id];
            let label = if node.name.is_empty() {
                format!("{}\\nID: {:?}", node.op_type, node_id.index())
            } else {
                format!("{}\\n{}\\nID: {:?}", node.op_type, node.name, node_id.index())
            };

            let color = match node.op_type.as_str() {
                "Constant" => "lightgray",
                "Add" | "Sub" | "Mul" | "Div" => "lightblue",
                "MatMul" | "Gemm" => "lightgreen",
                "Relu" | "Sigmoid" | "Tanh" => "lightyellow",
                _ => "white",
            };

            writeln!(
                &mut dot,
                "  node{} [label=\"{}\", fillcolor={}, style=filled];",
                node_id.index(),
                label,
                color
            )
            .unwrap();
        }

        // Add edges
        for edge in self.graph.edge_references() {
            if let Dependency::Data {
                output_slot,
                input_slot,
                ..
            } = edge.weight()
            {
                writeln!(
                    &mut dot,
                    "  node{} -> node{} [label=\"out{}→in{}\"];",
                    edge.source().index(),
                    edge.target().index(),
                    output_slot,
                    input_slot
                )
                .unwrap();
            }
        }

        writeln!(&mut dot, "}}").unwrap();
        dot
    }

    /// Get graph statistics
    pub fn statistics(&self) -> GraphStatistics {
        let total_nodes = self.graph.node_count();
        let total_edges = self.graph.edge_count();

        let mut op_type_counts: HashMap<String, usize> = HashMap::new();
        for node in self.graph.node_weights() {
            *op_type_counts.entry(node.op_type.clone()).or_insert(0) += 1;
        }

        GraphStatistics {
            total_nodes,
            total_edges,
            num_inputs: self.inputs.len(),
            num_outputs: self.outputs.len(),
            num_initializers: self.initializers.len(),
            op_type_counts,
        }
    }

    /// Access the underlying petgraph
    pub fn petgraph(&self) -> &StableGraph<GraphNode, Dependency> {
        &self.graph
    }

    /// Access the underlying petgraph mutably
    pub fn petgraph_mut(&mut self) -> &mut StableGraph<GraphNode, Dependency> {
        &mut self.graph
    }

    /// Get graph outputs
    pub fn graph_outputs(&self) -> &[ValueInfoProto] {
        &self.outputs
    }

    /// Get graph inputs
    pub fn graph_inputs(&self) -> &[ValueInfoProto] {
        &self.inputs
    }

    /// Get initializers map
    pub fn initializers_map(&self) -> &FxHashMap<String, TensorProto> {
        &self.initializers
    }

    /// Get tensor producers map (tensor name → (producer node, output slot))
    pub fn tensor_producers(&self) -> &FxHashMap<String, (NodeId, u8)> {
        &self.tensor_producers
    }

    /// Get all downstream nodes from a given node
    ///
    /// Returns nodes that depend on this node's outputs, either directly or transitively.
    /// Useful for analyzing data flow and dependencies.
    pub fn downstream_from(&self, node_id: NodeId) -> Vec<NodeId> {
        let mut downstream = Vec::new();
        let mut visited = FxHashMap::default();
        visited.insert(node_id, ()); // Mark starting node as visited
        self.collect_downstream(node_id, &mut downstream, &mut visited);
        downstream
    }

    /// Helper to recursively collect downstream nodes
    fn collect_downstream(&self, node_id: NodeId, result: &mut Vec<NodeId>, visited: &mut FxHashMap<NodeId, ()>) {
        for (target_id, _) in self.outputs(node_id) {
            if visited.contains_key(&target_id) {
                continue;
            }
            visited.insert(target_id, ());
            result.push(target_id);
            self.collect_downstream(target_id, result, visited);
        }
    }

    /// Delete all upstream nodes leading to a given node
    ///
    /// Removes nodes that only serve to produce inputs for this node.
    /// Preserves nodes that are also used by other operations or are graph outputs.
    pub fn delete_upstream(&mut self, node_id: NodeId) -> Result<usize> {
        let mut to_delete = Vec::new();
        let mut visited = FxHashMap::default();

        visited.insert(node_id, ()); // Mark starting node as visited (don't delete it)

        // Collect upstream nodes
        self.collect_upstream(node_id, &mut to_delete, &mut visited);

        // Build set for efficient lookup
        let to_delete_set: FxHashMap<NodeId, ()> = to_delete.iter().map(|&id| (id, ())).collect();

        // Filter out nodes that shouldn't be deleted
        let filtered: Vec<NodeId> = to_delete
            .into_iter()
            .filter(|&id| {
                // Don't delete graph outputs
                if self.is_graph_output(id) {
                    return false;
                }

                // Don't delete if node has other consumers not in deletion set
                let has_other_consumers = self
                    .outputs(id)
                    .iter()
                    .any(|&(target, _)| target != node_id && !to_delete_set.contains_key(&target));

                !has_other_consumers
            })
            .collect();

        // Delete nodes
        let count = filtered.len();
        for id in filtered {
            self.remove_node(id)?;
        }

        Ok(count)
    }

    /// Helper to recursively collect upstream nodes
    fn collect_upstream(&self, node_id: NodeId, result: &mut Vec<NodeId>, visited: &mut FxHashMap<NodeId, ()>) {
        for (source_id, _) in self.inputs(node_id) {
            if visited.contains_key(&source_id) {
                continue;
            }
            visited.insert(source_id, ());
            result.push(source_id);
            self.collect_upstream(source_id, result, visited);
        }
    }

    /// Extract all constant initializers as a map
    ///
    /// Returns a dictionary mapping constant names to their tensor data.
    /// Useful for weight extraction and parameter serialization.
    pub fn extract_constants(&self) -> HashMap<String, &TensorProto> {
        self.initializers
            .iter()
            .map(|(name, tensor)| (name.clone(), tensor))
            .collect()
    }

    /// Transfer pattern results from one node to another
    ///
    /// Moves embeddings and shapes from source to target node.
    /// Useful for graph rewrites and optimization passes.
    pub fn transfer_patterns(&mut self, from_node: NodeId, from_slot: u8, to_node: NodeId, to_slot: u8) {
        // Transfer embedding if present
        if let Some(embedding) = self.embeddings.remove(&(from_node, from_slot)) {
            self.embeddings.insert((to_node, to_slot), embedding);
        }

        // Transfer shape if present
        if let Some(shape) = self.shapes.remove(&(from_node, from_slot)) {
            self.shapes.insert((to_node, to_slot), shape);
        }
    }

    /// Get hierarchical parameter path for a tensor
    ///
    /// Returns a dot-separated path like "layer.0.weight" for organizing parameters.
    /// Useful for hierarchical weight tracking and serialization.
    pub fn get_parameter_path(&self, tensor_name: &str) -> String {
        // Extract hierarchical path from tensor name
        // Common patterns: "layer.0.weight", "encoder.block.3.norm.bias"
        tensor_name.replace('/', ".")
    }

    /// Get all parameters organized by hierarchical path
    ///
    /// Returns a map of parameter paths to tensor data.
    /// Enables hierarchical parameter tracking similar to Module.serialize().
    pub fn get_parameter_dict(&self) -> HashMap<String, &TensorProto> {
        self.initializers
            .iter()
            .map(|(name, tensor)| (self.get_parameter_path(name), tensor))
            .collect()
    }

    /// Merge SafeTensors weights into graph initializers
    ///
    /// Loads weights from SafeTensors file and merges them with existing initializers.
    /// This allows loading ONNX graph structure separately from weights.
    ///
    /// # Arguments
    ///
    /// * `safetensors_weights` - Map of tensor names to TensorProto (from SafeTensors)
    /// * `overwrite` - If true, overwrite existing initializers with same name
    ///
    /// # Returns
    ///
    /// Number of weights merged
    ///
    /// # Example
    ///
    /// ```no_run
    /// use hologram_onnx_compiler::load_safetensors;
    /// # use hologram_onnx_compiler::hrm::graph::HologramGraph;
    /// # let mut graph = HologramGraph::new();
    ///
    /// let weights = load_safetensors("model.safetensors")?;
    /// let merged = graph.merge_safetensors_weights(weights, true);
    /// println!("Merged {} weights", merged);
    /// # Ok::<(), hologram_onnx_compiler::CompilerError>(())
    /// ```
    pub fn merge_safetensors_weights(
        &mut self,
        safetensors_weights: HashMap<String, TensorProto>,
        overwrite: bool,
    ) -> usize {
        let mut merged = 0;

        for (name, tensor) in safetensors_weights {
            if overwrite || !self.initializers.contains_key(&name) {
                self.initializers.insert(name, tensor);
                merged += 1;
            }
        }

        merged
    }
}

/// Builder for adding operations to the graph
pub struct NewOp<'a> {
    graph: &'a mut HologramGraph,
    node_data: GraphNode,
    inputs: Vec<(NodeId, u8, u8)>, // (source_id, output_slot, input_slot)
}

impl<'a> NewOp<'a> {
    fn new(graph: &'a mut HologramGraph, op_type: String) -> Self {
        Self {
            graph,
            node_data: GraphNode {
                name: String::new(),
                op_type,
                attributes: Vec::new(),
                input_names: Vec::new(),
                output_names: Vec::new(),
                domain: String::new(),
            },
            inputs: Vec::new(),
        }
    }

    /// Set node name
    pub fn name(mut self, name: impl Into<String>) -> Self {
        self.node_data.name = name.into();
        self
    }

    /// Add an input connection
    pub fn input(mut self, source_id: NodeId, output_slot: u8, input_slot: u8) -> Self {
        self.inputs.push((source_id, output_slot, input_slot));
        self
    }

    /// Add an attribute
    pub fn attribute(mut self, attr: AttributeProto) -> Self {
        self.node_data.attributes.push(attr);
        self
    }

    /// Set output names
    pub fn outputs(mut self, names: Vec<String>) -> Self {
        self.node_data.output_names = names;
        self
    }

    /// Finish building and add to graph
    pub fn finish(self) -> NodeId {
        let node_id = self.graph.graph.add_node(self.node_data.clone());

        // Add edges
        for (source_id, output_slot, input_slot) in self.inputs {
            self.graph.graph.add_edge(
                source_id,
                node_id,
                Dependency::Data {
                    output_slot,
                    input_slot,
                    shape: Vec::new(),
                },
            );
        }

        // Register outputs
        for (slot, name) in self.node_data.output_names.iter().enumerate() {
            self.graph.tensor_producers.insert(name.clone(), (node_id, slot as u8));
        }

        // Register name
        if !self.node_data.name.is_empty() {
            self.graph.name_to_id.insert(self.node_data.name.clone(), node_id);
        }

        node_id
    }
}

/// Graph statistics
#[derive(Debug, Clone)]
pub struct GraphStatistics {
    pub total_nodes: usize,
    pub total_edges: usize,
    pub num_inputs: usize,
    pub num_outputs: usize,
    pub num_initializers: usize,
    pub op_type_counts: HashMap<String, usize>,
}

impl std::fmt::Display for GraphStatistics {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        writeln!(f, "Graph Statistics:")?;
        writeln!(f, "  Total nodes: {}", self.total_nodes)?;
        writeln!(f, "  Total edges: {}", self.total_edges)?;
        writeln!(f, "  Graph inputs: {}", self.num_inputs)?;
        writeln!(f, "  Graph outputs: {}", self.num_outputs)?;
        writeln!(f, "  Initializers: {}", self.num_initializers)?;
        writeln!(f, "  Operation types:")?;

        let mut sorted_ops: Vec<_> = self.op_type_counts.iter().collect();
        sorted_ops.sort_by(|a, b| b.1.cmp(a.1));

        for (op_type, count) in sorted_ops {
            writeln!(f, "    {}: {}", op_type, count)?;
        }

        Ok(())
    }
}

impl Default for HologramGraph {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_empty_graph() {
        let graph = HologramGraph::new();
        assert_eq!(graph.statistics().total_nodes, 0);
        assert_eq!(graph.statistics().total_edges, 0);
    }

    #[test]
    fn test_builder_pattern() {
        let mut graph = HologramGraph::new();

        let node1 = graph.add_op("Constant").name("const1").finish();
        let _node2 = graph.add_op("Add").input(node1, 0, 0).input(node1, 0, 1).finish();

        assert_eq!(graph.statistics().total_nodes, 2);
        assert_eq!(graph.statistics().total_edges, 2);
    }

    #[test]
    fn test_downstream_from() {
        let mut graph = HologramGraph::new();

        // Build graph: const1 -> add -> relu -> output
        let const1 = graph
            .add_op("Constant")
            .name("const1")
            .outputs(vec!["c1".to_string()])
            .finish();
        let add = graph
            .add_op("Add")
            .name("add")
            .input(const1, 0, 0)
            .input(const1, 0, 1)
            .outputs(vec!["a1".to_string()])
            .finish();
        let relu = graph
            .add_op("Relu")
            .name("relu")
            .input(add, 0, 0)
            .outputs(vec!["r1".to_string()])
            .finish();

        // Get downstream from const1
        let downstream = graph.downstream_from(const1);

        // Should include add and relu
        assert_eq!(downstream.len(), 2);
        assert!(downstream.contains(&add));
        assert!(downstream.contains(&relu));
    }

    #[test]
    fn test_delete_upstream() {
        let mut graph = HologramGraph::new();

        // Build graph: const1 -> add -> relu
        let const1 = graph
            .add_op("Constant")
            .name("const1")
            .outputs(vec!["c1".to_string()])
            .finish();
        let add = graph
            .add_op("Add")
            .name("add")
            .input(const1, 0, 0)
            .input(const1, 0, 1)
            .outputs(vec!["a1".to_string()])
            .finish();
        let relu = graph
            .add_op("Relu")
            .name("relu")
            .input(add, 0, 0)
            .outputs(vec!["r1".to_string()])
            .finish();

        assert_eq!(graph.statistics().total_nodes, 3);

        // Delete upstream from relu (should remove const1 and add)
        let deleted = graph.delete_upstream(relu).unwrap();
        assert_eq!(deleted, 2);
        assert_eq!(graph.statistics().total_nodes, 1);
    }

    #[test]
    fn test_transfer_patterns() {
        let mut graph = HologramGraph::new();

        let node1 = graph.add_op("Constant").outputs(vec!["out1".to_string()]).finish();
        let node2 = graph.add_op("Add").outputs(vec!["out2".to_string()]).finish();

        // Add embedding and shape for node1
        use hologram::GriessVector;
        let embedding = GriessVector::zero();
        graph.embeddings.insert((node1, 0), embedding.clone());
        graph.shapes.insert((node1, 0), vec![1, 2, 3]);

        // Transfer patterns from node1 to node2
        graph.transfer_patterns(node1, 0, node2, 0);

        // Verify transfer
        assert!(!graph.embeddings.contains_key(&(node1, 0)));
        assert!(graph.embeddings.contains_key(&(node2, 0)));
        assert_eq!(graph.shapes.get(&(node2, 0)), Some(&vec![1, 2, 3]));
    }

    #[test]
    fn test_extract_constants() {
        let mut graph = HologramGraph::new();

        // Add some initializers
        let tensor1 = TensorProto {
            name: "weight1".to_string(),
            ..Default::default()
        };
        let tensor2 = TensorProto {
            name: "bias1".to_string(),
            ..Default::default()
        };

        graph.initializers.insert("weight1".to_string(), tensor1.clone());
        graph.initializers.insert("bias1".to_string(), tensor2.clone());

        let constants = graph.extract_constants();

        assert_eq!(constants.len(), 2);
        assert!(constants.contains_key("weight1"));
        assert!(constants.contains_key("bias1"));
    }

    #[test]
    fn test_get_parameter_path() {
        let graph = HologramGraph::new();

        // Test path conversion
        assert_eq!(graph.get_parameter_path("layer/0/weight"), "layer.0.weight");
        assert_eq!(
            graph.get_parameter_path("encoder/block/3/norm/bias"),
            "encoder.block.3.norm.bias"
        );
        assert_eq!(graph.get_parameter_path("simple_weight"), "simple_weight");
    }

    #[test]
    fn test_get_parameter_dict() {
        let mut graph = HologramGraph::new();

        // Add initializers with hierarchical names
        let tensor1 = TensorProto {
            name: "layer/0/weight".to_string(),
            ..Default::default()
        };
        let tensor2 = TensorProto {
            name: "layer/0/bias".to_string(),
            ..Default::default()
        };

        graph.initializers.insert("layer/0/weight".to_string(), tensor1);
        graph.initializers.insert("layer/0/bias".to_string(), tensor2);

        let param_dict = graph.get_parameter_dict();

        assert_eq!(param_dict.len(), 2);
        assert!(param_dict.contains_key("layer.0.weight"));
        assert!(param_dict.contains_key("layer.0.bias"));
    }
}
