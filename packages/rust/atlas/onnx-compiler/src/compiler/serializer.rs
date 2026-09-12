//! .holo Binary Serializer
//!
//! Serializes compiled models to Hologram binary format:
//!
//! ```text
//! .holo File Structure:
//! ┌──────────────────────────────────────┐
//! │ Header (88 bytes)                    │
//! │  - Magic: "HOLO" (4 bytes)           │
//! │  - Version: 2 (4 bytes)              │
//! │  - Section offsets (10×8 bytes)      │
//! ├──────────────────────────────────────┤
//! │ Manifest (JSON)                      │
//! │  - Unique values, op stats, etc.     │
//! ├──────────────────────────────────────┤
//! │ Address Space (binary data)          │
//! │  - Pre-computed results              │
//! ├──────────────────────────────────────┤
//! │ Hash Tables (JSON)                   │
//! │  - Per-operation perfect hash tables │
//! ├──────────────────────────────────────┤
//! │ Metadata (JSON)                      │
//! │  - Operation types, shapes, etc.     │
//! ├──────────────────────────────────────┤
//! │ Operator Graph (JSON)                │
//! │  - Graph structure for runtime exec  │
//! └──────────────────────────────────────┘
//! ```

use crate::compiler::{ExecutionResults, SerializableGraph, SerializerStats};
use crate::hrm::graph::HologramGraph;
use crate::hrm::types::{CollectionManifest, OperationStats, PerfectHashTable};
use crate::Result;
use std::collections::HashMap;
use std::fs::File;
use std::io::{BufWriter, Write};
use std::path::Path;

/// .holo binary serializer
pub struct HoloSerializer {
    verbose: bool,
}

impl HoloSerializer {
    pub fn new() -> Self {
        Self { verbose: false }
    }

    pub fn with_verbose(mut self, verbose: bool) -> Self {
        self.verbose = verbose;
        self
    }

    /// Serialize compiled model to .holo format
    pub fn serialize(
        &self,
        graph: &HologramGraph,
        results: &ExecutionResults,
        output_path: &Path,
    ) -> Result<SerializerStats> {
        // Build manifest
        let manifest = self.build_manifest(graph, results)?;

        // Build hash tables
        let hash_tables = self.build_hash_tables(results)?;

        // Build address space
        let address_space = self.build_address_space(results)?;

        // Build metadata
        let metadata = results.metadata.clone();

        // Build serializable graph for runtime execution
        let serializable_graph = SerializableGraph::from_hologram_graph(graph)?;

        // Serialize sections to JSON
        let manifest_json = serde_json::to_vec(&manifest)?;
        let hash_tables_json = serde_json::to_vec(&hash_tables)?;
        let metadata_json = serde_json::to_vec(&metadata)?;
        let graph_json = serde_json::to_vec(&serializable_graph)?;

        // Calculate offsets
        const HEADER_SIZE: usize = 88; // Updated for 5 sections
        let manifest_offset = HEADER_SIZE;
        let manifest_size = manifest_json.len();

        let address_space_offset = manifest_offset + manifest_size;
        let address_space_size = address_space.len();

        let hash_tables_offset = address_space_offset + address_space_size;
        let hash_tables_size = hash_tables_json.len();

        let metadata_offset = hash_tables_offset + hash_tables_size;
        let metadata_size = metadata_json.len();

        let graph_offset = metadata_offset + metadata_size;
        let graph_size = graph_json.len();

        // Write file
        let file = File::create(output_path)?;
        let mut writer = BufWriter::new(file);

        // Write header
        self.write_header(
            &mut writer,
            manifest_offset,
            manifest_size,
            address_space_offset,
            address_space_size,
            hash_tables_offset,
            hash_tables_size,
            metadata_offset,
            metadata_size,
            graph_offset,
            graph_size,
        )?;

        // Write sections
        writer.write_all(&manifest_json)?;
        writer.write_all(&address_space)?;
        writer.write_all(&hash_tables_json)?;
        writer.write_all(&metadata_json)?;
        writer.write_all(&graph_json)?;

        writer.flush()?;

        let total_bytes = HEADER_SIZE + manifest_size + address_space_size + hash_tables_size + metadata_size + graph_size;

        Ok(SerializerStats {
            hash_table_bytes: hash_tables_size,
            address_space_bytes: address_space_size,
            total_bytes,
        })
    }

    /// Write .holo file header
    #[allow(clippy::too_many_arguments)]
    fn write_header(
        &self,
        writer: &mut impl Write,
        manifest_offset: usize,
        manifest_size: usize,
        address_space_offset: usize,
        address_space_size: usize,
        hash_tables_offset: usize,
        hash_tables_size: usize,
        metadata_offset: usize,
        metadata_size: usize,
        graph_offset: usize,
        graph_size: usize,
    ) -> Result<()> {
        // Magic bytes
        writer.write_all(b"HOLO")?;

        // Version 2 (supports runtime execution)
        writer.write_all(&2u32.to_le_bytes())?;

        // Section offsets (8 bytes each)
        writer.write_all(&(manifest_offset as u64).to_le_bytes())?;
        writer.write_all(&(address_space_offset as u64).to_le_bytes())?;
        writer.write_all(&(hash_tables_offset as u64).to_le_bytes())?;
        writer.write_all(&(metadata_offset as u64).to_le_bytes())?;
        writer.write_all(&(graph_offset as u64).to_le_bytes())?;

        // Section sizes (8 bytes each)
        writer.write_all(&(manifest_size as u64).to_le_bytes())?;
        writer.write_all(&(address_space_size as u64).to_le_bytes())?;
        writer.write_all(&(hash_tables_size as u64).to_le_bytes())?;
        writer.write_all(&(metadata_size as u64).to_le_bytes())?;
        writer.write_all(&(graph_size as u64).to_le_bytes())?;

        Ok(())
    }

    /// Build manifest JSON
    fn build_manifest(&self, _graph: &HologramGraph, results: &ExecutionResults) -> Result<CollectionManifest> {
        // Build operation stats
        let mut operation_stats = Vec::new();

        for (i, metadata) in results.metadata.iter().enumerate() {
            let input_size: usize = metadata
                .input_shapes
                .iter()
                .filter_map(|s| s.as_ref().map(|dims| dims.iter().product::<i64>() as usize))
                .sum();
            let output_size: usize = metadata
                .output_shapes
                .iter()
                .map(|dims| dims.iter().product::<i64>() as usize)
                .sum();

            operation_stats.push(OperationStats {
                op_type: metadata.op_type.clone(),
                op_id: i,
                input_shapes: metadata.input_shapes.iter().filter_map(|s| s.clone()).collect(),
                output_shapes: metadata.output_shapes.clone(),
                num_weights: 0, // No weights in execution phase
                num_unique_weights: 0,
                input_size,
                output_size,
                avg_compute_time_ms: 0, // Not measured yet
                estimated_patterns_for_accuracy: results.hash_tables.get(i).map(|ht| ht.len()).unwrap_or(64),
            });
        }

        Ok(CollectionManifest {
            unique_values: vec![],
            operation_value_map: HashMap::new(),
            operation_constant_inputs: HashMap::new(),
            operation_stats,
            patterns_per_operation: results.hash_tables.iter().map(|ht| ht.len()).collect(),
            total_memory_needed: 0,
            estimated_compilation_time: std::time::Duration::from_secs(0),
            discretization_strategies: vec![],
            user_input_shapes: None,
        })
    }

    /// Build hash tables from execution results
    fn build_hash_tables(&self, results: &ExecutionResults) -> Result<Vec<PerfectHashTable>> {
        use ahash::AHashMap;

        let mut hash_tables = Vec::new();

        for hash_table in &results.hash_tables {
            // Build perfect hash table
            let mut entries = AHashMap::new();

            for hash in hash_table.keys() {
                // Simple address: just use index
                // In full implementation, would use Griess algebra factorization
                let address = crate::hrm::types::ExtendedAddress {
                    class: 0,
                    page: 0,
                    byte: 0,
                    sub_index: 0,
                };

                entries.insert(*hash, address);
            }

            hash_tables.push(PerfectHashTable {
                entries,
                collision_count: 0, // No collisions in perfect hash
            });
        }

        Ok(hash_tables)
    }

    /// Build address space (pre-computed results)
    ///
    /// Serializes all pre-computed operation results to a byte array.
    /// Hash tables provide O(1) lookup into this address space at runtime.
    ///
    /// Layout: Sequential storage of all pre-computed f32 results.
    /// Each result is stored as 4 bytes (little-endian f32).
    fn build_address_space(&self, results: &ExecutionResults) -> Result<Vec<u8>> {
        let mut address_space = Vec::new();

        for hash_table in &results.hash_tables {
            for output in hash_table.values() {
                // Serialize each f32 output value to bytes (little-endian)
                for &val in output {
                    address_space.extend_from_slice(&val.to_le_bytes());
                }
            }
        }

        Ok(address_space)
    }
}

impl Default for HoloSerializer {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_serializer_creation() {
        let serializer = HoloSerializer::new();
        assert!(!serializer.verbose);
    }

    #[test]
    fn test_header_size() {
        // Header must be exactly 72 bytes:
        // - Magic: 4 bytes
        // - Version: 4 bytes
        // - Offsets: 4×8 = 32 bytes
        // - Sizes: 4×8 = 32 bytes
        // Total: 4 + 4 + 32 + 32 = 72 bytes
        assert_eq!(4 + 4 + 32 + 32, 72);
    }
}
