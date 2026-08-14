//! Core data structures for MoonshineHRM compilation pipeline

use ahash::AHashMap;
use hologram::GriessVector;
use ordered_float::OrderedFloat;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::time::Duration;

/// Constant tensor: (data, shape)
///
/// Represents a constant tensor from ONNX initializers.
/// Used for operations like Gather, Slice that require constant inputs.
pub type ConstantTensor = (Vec<f32>, Vec<i64>);

/// Mapping from operation_id to constant tensors
pub type OperationConstantInputs = HashMap<usize, Vec<ConstantTensor>>;

/// Collection manifest from Pass 1
///
/// Contains all information needed for subsequent compilation passes:
/// - Unique values needing embedding
/// - Operation statistics and patterns
/// - Calculated optimal pattern counts
/// - Resource requirement estimates
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CollectionManifest {
    /// All unique float values across the model (deduped)
    pub unique_values: Vec<f32>,

    /// Mapping: operation_id → indices into unique_values
    pub operation_value_map: HashMap<usize, Vec<usize>>,

    /// Constant input tensors per operation (for ops like Gather, Slice, etc.)
    ///
    /// Maps operation_id → Vec of constant tensors
    /// Each constant tensor is stored as (tensor_data, shape)
    /// Example: For Gather, this contains the indices tensor
    pub operation_constant_inputs: OperationConstantInputs,

    /// Statistics for each operation
    pub operation_stats: Vec<OperationStats>,

    /// Calculated optimal number of patterns per operation
    pub patterns_per_operation: Vec<usize>,

    /// Total memory needed for address space (bytes)
    pub total_memory_needed: usize,

    /// Estimated compilation time
    pub estimated_compilation_time: Duration,

    /// Discretization strategy per operation
    pub discretization_strategies: Vec<DiscretizationStrategy>,

    /// User-specified input shapes for shape-specific compilation
    ///
    /// Maps input tensor names to their dimensions (e.g., "input_ids" → [1, 77])
    /// When provided, enables 100% pre-compilation for models with these exact shapes
    pub user_input_shapes: Option<HashMap<String, Vec<i64>>>,
}

/// Statistics for a single operation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OperationStats {
    /// Operation type (MatMul, Conv, Add, etc.)
    pub op_type: String,

    /// Operation ID in graph
    pub op_id: usize,

    /// Input tensor dimensions
    pub input_shapes: Vec<Vec<i64>>,

    /// Output tensor dimensions
    pub output_shapes: Vec<Vec<i64>>,

    /// Number of weight parameters
    pub num_weights: usize,

    /// Number of unique weight values
    pub num_unique_weights: usize,

    /// Input size in elements
    pub input_size: usize,

    /// Output size in elements
    pub output_size: usize,

    /// Average compute time per pattern (ms)
    pub avg_compute_time_ms: u64,

    /// Estimated patterns needed for target accuracy
    pub estimated_patterns_for_accuracy: usize,
}

/// Discretization strategy for operation inputs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DiscretizationStrategy {
    /// Quantize to N-bit integers (e.g., INT8 = 8 bits = 256 values)
    Quantized {
        bits: u8,
        scale: f32,
        zero_point: i32,
    },

    /// Use fixed vocabulary (for embedding layers)
    Vocabulary { size: usize, values: Vec<f32> },

    /// Hash-based bucketing (for continuous values)
    HashedBuckets {
        num_buckets: usize,
        bucket_ranges: Vec<(f32, f32)>,
    },

    /// Statistical clustering (learned from training data)
    Clustered {
        num_clusters: usize,
        centroids: Vec<Vec<f32>>,
    },
}

/// Embedding cache from Pass 2
///
/// Maps unique float values to their GriessVector embeddings.
/// Enables value reuse: if a weight has 1M parameters but only 10K unique values,
/// we only embed 10K values.
#[derive(Debug, Clone)]
pub struct EmbeddingCache {
    /// All unique embeddings (indexed)
    pub embeddings: Vec<GriessVector>,

    /// Index mapping: value → embedding_index
    pub value_to_index: AHashMap<OrderedFloat<f32>, usize>,

    /// Reverse mapping for debugging
    pub index_to_value: Vec<f32>,
}

/// Factorized results from Pass 3
///
/// Contains the pre-computed address space and hash tables for O(1) runtime lookup.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FactorizedResults {
    /// Address space containing all pre-computed results
    pub address_space: AddressSpace,

    /// Per-operation hash tables: input_hash → address
    pub hash_tables: Vec<PerfectHashTable>,

    /// Metadata for each operation
    pub operation_metadata: Vec<OperationMetadata>,
}

/// Extended address space (supports >1.18M addresses)
///
/// Uses expanded addressing scheme:
/// - 96 classes × 480 pages × 256 bytes × 65536 sub_index = 773B addresses
/// - Still O(1) address calculation (just arithmetic)
///
/// OPTIMIZATION: Supports memory-mapped files to avoid loading entire
/// address space into RAM. Use `with_mmap()` for compilation.
///
/// OPTIMIZATION: Supports sparse storage for small models to avoid
/// huge allocations from hash-based factorization. Use `with_sparse_threshold()`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AddressSpace {
    /// Number of classes (default: 96)
    pub num_classes: usize,

    /// Pages per class (default: 480, expanded from 48)
    pub pages_per_class: usize,

    /// Bytes per page (default: 256)
    pub bytes_per_page: usize,

    /// Sub-indices per byte (default: 65536, new dimension)
    pub sub_indices_per_byte: usize,

    /// Stored results: address → result data
    /// Uses flat layout for SIMD alignment
    ///
    /// NOTE: When using mmap, this Vec is empty and file_path is Some
    /// NOTE: When using sparse storage, this Vec is empty and sparse_data is used
    pub data: Vec<u8>,

    /// Result size tracking (bytes per result)
    pub result_sizes: HashMap<ExtendedAddress, usize>,

    /// Optional: Memory-mapped file path (for large compilations)
    #[serde(skip)]
    #[serde(default)]
    pub file_path: Option<std::path::PathBuf>,

    /// Optional: Memory-mapped region (not serialized, reconstructed on load)
    #[serde(skip)]
    #[serde(default)]
    mmap: Option<std::sync::Arc<parking_lot::RwLock<memmap2::MmapMut>>>,

    /// Sparse storage for small models (HashMap-based, no huge allocations)
    ///
    /// For small models, hash-based factorization can produce huge address offsets
    /// (e.g., 334 GB for a model with 100 patterns). HashMap storage avoids this.
    #[serde(skip_serializing_if = "HashMap::is_empty")]
    #[serde(default)]
    pub sparse_data: HashMap<ExtendedAddress, Vec<u8>>,

    /// Use sparse storage instead of dense Vec
    ///
    /// Small models (< 10,000 patterns) use HashMap, large models use Vec/mmap
    #[serde(default)]
    pub use_sparse: bool,
}

/// Extended address with sub-byte granularity
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct ExtendedAddress {
    pub class: u8,      // 0-95
    pub page: u16,      // 0-479 (expanded)
    pub byte: u8,       // 0-255
    pub sub_index: u16, // 0-65535 (new dimension)
}

impl ExtendedAddress {
    /// Compute linear offset in address space
    ///
    /// This is O(1) - just arithmetic, no loops
    #[inline]
    pub fn to_offset(&self, space: &AddressSpace) -> usize {
        let class_offset = self.class as usize
            * space.pages_per_class
            * space.bytes_per_page
            * space.sub_indices_per_byte;
        let page_offset = self.page as usize * space.bytes_per_page * space.sub_indices_per_byte;
        let byte_offset = self.byte as usize * space.sub_indices_per_byte;
        let sub_offset = self.sub_index as usize;

        class_offset + page_offset + byte_offset + sub_offset
    }

    /// Create from linear offset
    #[inline]
    pub fn from_offset(offset: usize, space: &AddressSpace) -> Self {
        let sub_index = (offset % space.sub_indices_per_byte) as u16;
        let offset = offset / space.sub_indices_per_byte;

        let byte = (offset % space.bytes_per_page) as u8;
        let offset = offset / space.bytes_per_page;

        let page = (offset % space.pages_per_class) as u16;
        let offset = offset / space.pages_per_class;

        let class = offset as u8;

        Self {
            class,
            page,
            byte,
            sub_index,
        }
    }
}

/// Perfect hash table for O(1) lookup
///
/// Maps input hashes to addresses in the address space
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PerfectHashTable {
    /// Entries: hash → address
    /// Stored as HashMap for serialization compatibility
    #[serde(
        serialize_with = "serialize_ahashmap",
        deserialize_with = "deserialize_ahashmap"
    )]
    pub entries: AHashMap<u64, ExtendedAddress>,

    /// Collision count (should be near zero)
    pub collision_count: usize,
}

// Serialization helpers for AHashMap
fn serialize_ahashmap<S>(
    map: &AHashMap<u64, ExtendedAddress>,
    serializer: S,
) -> Result<S::Ok, S::Error>
where
    S: serde::Serializer,
{
    use serde::Serialize;
    // Convert u64 keys to strings for JSON compatibility
    let string_map: HashMap<String, ExtendedAddress> = map
        .iter()
        .map(|(&k, &v)| (k.to_string(), v))
        .collect();
    string_map.serialize(serializer)
}

fn deserialize_ahashmap<'de, D>(deserializer: D) -> Result<AHashMap<u64, ExtendedAddress>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    use serde::Deserialize;
    // Parse string keys back to u64
    let string_map: HashMap<String, ExtendedAddress> = HashMap::deserialize(deserializer)?;
    string_map
        .into_iter()
        .map(|(k, v)| {
            k.parse::<u64>()
                .map(|k_parsed| (k_parsed, v))
                .map_err(serde::de::Error::custom)
        })
        .collect::<Result<AHashMap<_, _>, _>>()
}

impl PerfectHashTable {
    /// Create from hash map
    pub fn from_hashmap(map: HashMap<u64, ExtendedAddress>) -> crate::Result<Self> {
        Ok(Self {
            entries: map.into_iter().collect(),
            collision_count: 0,
        })
    }

    /// Lookup address by input hash (O(1))
    pub fn lookup(&self, hash: u64) -> crate::Result<ExtendedAddress> {
        self.entries
            .get(&hash)
            .copied()
            .ok_or(crate::CompilerError::MissingHashEntry(hash))
    }
}

/// Metadata for operation execution
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OperationMetadata {
    /// Operation type
    pub op_type: String,

    /// Input shapes (None if dynamic)
    pub input_shapes: Vec<Option<Vec<i64>>>,

    /// Output shapes (None if dynamic)
    pub output_shapes: Vec<Option<Vec<i64>>>,

    /// Memory requirements (bytes)
    pub memory_required: usize,

    /// Estimated execution time (nanoseconds)
    pub estimated_latency_ns: u64,

    /// Optimizations applied
    pub optimizations_applied: Vec<String>,

    /// Number of inputs
    pub input_count: usize,

    /// Output size (total elements)
    pub output_size: usize,

    /// Is this an output operation?
    pub is_output: bool,

    /// Number of pre-computed patterns
    pub num_patterns: usize,
}

/// Builder for OperationMetadata
///
/// Provides a clean, fluent API for constructing OperationMetadata instances.
///
/// # Example
///
/// ```
/// use hologram_onnx_compiler::hrm::types::OperationMetadata;
///
/// let metadata = OperationMetadata::builder("MatMul")
///     .with_input_shapes(vec![vec![4, 8], vec![8, 3]])
///     .with_output_shapes(vec![vec![4, 3]])
///     .with_output_size(12)
///     .with_num_patterns(1024)
///     .build();
/// ```
#[derive(Debug, Clone)]
pub struct OperationMetadataBuilder {
    op_type: String,
    input_shapes: Vec<Option<Vec<i64>>>,
    output_shapes: Vec<Option<Vec<i64>>>,
    memory_required: usize,
    estimated_latency_ns: u64,
    optimizations_applied: Vec<String>,
    input_count: usize,
    output_size: usize,
    is_output: bool,
    num_patterns: usize,
}

impl OperationMetadata {
    /// Create a new builder for OperationMetadata
    ///
    /// # Arguments
    ///
    /// * `op_type` - Operation type (e.g., "MatMul", "Add", "Conv")
    pub fn builder(op_type: impl Into<String>) -> OperationMetadataBuilder {
        OperationMetadataBuilder::new(op_type)
    }
}

impl OperationMetadataBuilder {
    /// Create a new builder with required operation type
    pub fn new(op_type: impl Into<String>) -> Self {
        Self {
            op_type: op_type.into(),
            input_shapes: Vec::new(),
            output_shapes: Vec::new(),
            memory_required: 0,
            estimated_latency_ns: 0,
            optimizations_applied: Vec::new(),
            input_count: 0,
            output_size: 0,
            is_output: false,
            num_patterns: 0,
        }
    }

    /// Set input shapes (converts Vec<Vec<i64>> to Vec<Option<Vec<i64>>>)
    pub fn with_input_shapes(mut self, shapes: Vec<Vec<i64>>) -> Self {
        self.input_shapes = shapes.into_iter().map(Some).collect();
        self.input_count = self.input_shapes.len();
        self
    }

    /// Set input shapes from OperationStats
    pub fn with_input_shapes_from_stats(
        mut self,
        stats: &crate::hrm::types::OperationStats,
    ) -> Self {
        self.input_shapes = stats.input_shapes.iter().map(|s| Some(s.clone())).collect();
        self.input_count = stats.input_shapes.len();
        self
    }

    /// Set output shapes (converts Vec<Vec<i64>> to Vec<Option<Vec<i64>>>)
    pub fn with_output_shapes(mut self, shapes: Vec<Vec<i64>>) -> Self {
        self.output_shapes = shapes.into_iter().map(Some).collect();
        self
    }

    /// Set output shapes from OperationStats
    pub fn with_output_shapes_from_stats(
        mut self,
        stats: &crate::hrm::types::OperationStats,
    ) -> Self {
        self.output_shapes = stats
            .output_shapes
            .iter()
            .map(|s| Some(s.clone()))
            .collect();
        self
    }

    /// Set memory required (in bytes)
    pub fn with_memory_required(mut self, bytes: usize) -> Self {
        self.memory_required = bytes;
        self
    }

    /// Calculate memory required from output size (assumes f32 elements)
    pub fn with_memory_from_output_size(mut self, output_size: usize) -> Self {
        self.memory_required = output_size * std::mem::size_of::<f32>();
        self
    }

    /// Set estimated latency (in nanoseconds)
    pub fn with_estimated_latency_ns(mut self, latency_ns: u64) -> Self {
        self.estimated_latency_ns = latency_ns;
        self
    }

    /// Set optimizations applied
    pub fn with_optimizations(mut self, optimizations: Vec<String>) -> Self {
        self.optimizations_applied = optimizations;
        self
    }

    /// Add a single optimization
    pub fn add_optimization(mut self, optimization: impl Into<String>) -> Self {
        self.optimizations_applied.push(optimization.into());
        self
    }

    /// Set input count explicitly
    pub fn with_input_count(mut self, count: usize) -> Self {
        self.input_count = count;
        self
    }

    /// Set output size (total elements)
    pub fn with_output_size(mut self, size: usize) -> Self {
        self.output_size = size;
        self
    }

    /// Set output size from OperationStats
    pub fn with_output_size_from_stats(
        mut self,
        stats: &crate::hrm::types::OperationStats,
    ) -> Self {
        self.output_size = stats.output_size;
        self
    }

    /// Mark as output operation
    pub fn is_output(mut self, is_output: bool) -> Self {
        self.is_output = is_output;
        self
    }

    /// Set number of pre-computed patterns
    pub fn with_num_patterns(mut self, num_patterns: usize) -> Self {
        self.num_patterns = num_patterns;
        self
    }

    /// Convenience method to set all fields from OperationStats
    pub fn from_stats(mut self, stats: &crate::hrm::types::OperationStats) -> Self {
        self.input_shapes = stats.input_shapes.iter().map(|s| Some(s.clone())).collect();
        self.output_shapes = stats
            .output_shapes
            .iter()
            .map(|s| Some(s.clone()))
            .collect();
        self.input_count = stats.input_shapes.len();
        self.output_size = stats.output_size;
        self.memory_required = stats.output_size * std::mem::size_of::<f32>();
        self
    }

    /// Build the OperationMetadata
    pub fn build(self) -> OperationMetadata {
        OperationMetadata {
            op_type: self.op_type,
            input_shapes: self.input_shapes,
            output_shapes: self.output_shapes,
            memory_required: self.memory_required,
            estimated_latency_ns: self.estimated_latency_ns,
            optimizations_applied: self.optimizations_applied,
            input_count: self.input_count,
            output_size: self.output_size,
            is_output: self.is_output,
            num_patterns: self.num_patterns,
        }
    }
}

impl AddressSpace {
    /// Create with default dimensions (expanded from original)
    pub fn new() -> Self {
        Self::with_dimensions(96, 480, 256, 65536)
    }

    /// Create with custom dimensions
    pub fn with_dimensions(
        num_classes: usize,
        pages_per_class: usize,
        bytes_per_page: usize,
        sub_indices_per_byte: usize,
    ) -> Self {
        Self {
            num_classes,
            pages_per_class,
            bytes_per_page,
            sub_indices_per_byte,
            data: Vec::new(), // Allocated on demand
            result_sizes: HashMap::new(),
            file_path: None,
            mmap: None,
            sparse_data: HashMap::new(),
            use_sparse: false,
        }
    }

    /// Allocate space for capacity addresses
    pub fn with_capacity(capacity_bytes: usize) -> Self {
        let mut space = Self::new();
        space.data = Vec::with_capacity(capacity_bytes);
        space
    }

    /// Create with sparse storage for models
    ///
    /// Hash-based factorization produces sparse offsets across the 772 GB theoretical
    /// address space. For most models (< 1M patterns), HashMap storage avoids
    /// catastrophic memory allocations from these sparse addresses.
    ///
    /// # Arguments
    ///
    /// * `pattern_count` - Total number of patterns in the model
    /// * `threshold` - Pattern count threshold for sparse storage (default: 1,000,000)
    ///
    /// # Returns
    ///
    /// AddressSpace configured for sparse or dense storage based on pattern count
    pub fn with_sparse_threshold(pattern_count: usize, threshold: Option<usize>) -> Self {
        let threshold = threshold.unwrap_or(1_000_000);
        let use_sparse = pattern_count < threshold;

        if use_sparse {
            tracing::info!(
                "Using sparse storage for model ({} patterns < {} threshold)",
                pattern_count,
                threshold
            );
        }

        Self {
            num_classes: 96,
            pages_per_class: 480,
            bytes_per_page: 256,
            sub_indices_per_byte: 65536,
            data: Vec::new(),
            result_sizes: HashMap::new(),
            file_path: None,
            mmap: None,
            sparse_data: if use_sparse {
                HashMap::with_capacity(pattern_count)
            } else {
                HashMap::new()
            },
            use_sparse,
        }
    }

    /// Create with memory-mapped file backing (OPTIMIZED for large compilations)
    ///
    /// This avoids loading the entire address space into RAM. The OS handles
    /// paging automatically, keeping memory usage low.
    ///
    /// # Arguments
    ///
    /// * `capacity_bytes` - Expected size of address space
    /// * `temp_dir` - Directory for temporary mmap file (will be cleaned up)
    ///
    /// # Returns
    ///
    /// AddressSpace backed by mmap file, not RAM
    pub fn with_mmap(
        capacity_bytes: usize,
        temp_dir: Option<&std::path::Path>,
    ) -> crate::Result<Self> {
        use std::fs::OpenOptions;

        // Create temporary file
        let dir = temp_dir.unwrap_or_else(|| std::path::Path::new("/tmp"));
        std::fs::create_dir_all(dir).map_err(|e| {
            crate::CompilerError::InvalidModel(format!("Failed to create temp dir: {}", e))
        })?;

        let file_path = dir.join(format!("hologram_address_space_{}.tmp", std::process::id()));

        // Create file and set size
        let file = OpenOptions::new()
            .read(true)
            .write(true)
            .create(true)
            .truncate(true)
            .open(&file_path)
            .map_err(|e| {
                crate::CompilerError::InvalidModel(format!("Failed to create mmap file: {}", e))
            })?;

        file.set_len(capacity_bytes as u64).map_err(|e| {
            crate::CompilerError::InvalidModel(format!("Failed to set mmap file size: {}", e))
        })?;

        // Create memory mapping
        let mmap = unsafe {
            memmap2::MmapMut::map_mut(&file).map_err(|e| {
                crate::CompilerError::InvalidModel(format!("Failed to create mmap: {}", e))
            })?
        };

        tracing::info!(
            "Created memory-mapped address space: {} MB at {}",
            capacity_bytes / (1024 * 1024),
            file_path.display()
        );

        Ok(Self {
            num_classes: 96,
            pages_per_class: 480,
            bytes_per_page: 256,
            sub_indices_per_byte: 65536,
            data: Vec::new(), // Empty - using mmap instead
            result_sizes: HashMap::new(),
            file_path: Some(file_path),
            mmap: Some(std::sync::Arc::new(parking_lot::RwLock::new(mmap))),
            sparse_data: HashMap::new(),
            use_sparse: false, // mmap doesn't use sparse storage
        })
    }

    /// Check if this address space is using memory mapping
    pub fn is_mmap(&self) -> bool {
        self.mmap.is_some()
    }

    /// Store result at address
    ///
    /// Works with sparse HashMap, Vec-based, or mmap-based address spaces
    pub fn store(&mut self, address: ExtendedAddress, data: &[u8]) -> crate::Result<()> {
        // SPARSE MODE: Use HashMap for small models to avoid huge allocations
        if self.use_sparse {
            self.sparse_data.insert(address, data.to_vec());
            self.result_sizes.insert(address, data.len());
            return Ok(());
        }

        // DENSE MODE: Use Vec or mmap for large models
        let offset = address.to_offset(self);
        let end = offset + data.len();

        if let Some(mmap) = &self.mmap {
            // Using memory-mapped file
            let mut mmap_write = mmap.write();

            if end > mmap_write.len() {
                return Err(crate::CompilerError::InvalidAddress(format!(
                    "Address {:?} offset {} exceeds mmap size {}",
                    address,
                    end,
                    mmap_write.len()
                )));
            }

            // Copy data to mmap
            mmap_write[offset..end].copy_from_slice(data);
        } else {
            // Using Vec (original behavior)
            if end > self.data.len() {
                self.data.resize(end, 0);
            }
            self.data[offset..end].copy_from_slice(data);
        }

        // Track size
        self.result_sizes.insert(address, data.len());

        Ok(())
    }

    /// Retrieve result from address
    ///
    /// Works with sparse HashMap, Vec-based, or mmap-based address spaces
    pub fn retrieve(&self, address: ExtendedAddress) -> crate::Result<Vec<u8>> {
        // SPARSE MODE: Retrieve from HashMap
        if self.use_sparse {
            return self
                .sparse_data
                .get(&address)
                .cloned()
                .ok_or_else(|| crate::CompilerError::InvalidAddress(format!("{:?}", address)));
        }

        // DENSE MODE: Retrieve from Vec or mmap
        let offset = address.to_offset(self);
        let size = self
            .result_sizes
            .get(&address)
            .ok_or_else(|| crate::CompilerError::InvalidAddress(format!("{:?}", address)))?;

        if let Some(mmap) = &self.mmap {
            // Using memory-mapped file - copy data out
            let mmap_read = mmap.read();
            Ok(mmap_read[offset..offset + size].to_vec())
        } else {
            // Using Vec (original behavior)
            Ok(self.data[offset..offset + size].to_vec())
        }
    }

    /// Get pointer to address (zero-copy)
    pub fn get_pointer(&self, address: ExtendedAddress) -> crate::Result<*const u8> {
        let offset = address.to_offset(self);

        if offset >= self.data.len() {
            return Err(crate::CompilerError::InvalidAddress(format!(
                "{:?}",
                address
            )));
        }

        Ok(&self.data[offset] as *const u8)
    }

    /// Total capacity (number of addresses)
    pub fn capacity(&self) -> usize {
        self.num_classes * self.pages_per_class * self.bytes_per_page * self.sub_indices_per_byte
    }
}

impl Default for AddressSpace {
    fn default() -> Self {
        Self::new()
    }
}

impl EmbeddingCache {
    /// Create empty cache
    pub fn new() -> Self {
        Self {
            embeddings: Vec::new(),
            value_to_index: AHashMap::new(),
            index_to_value: Vec::new(),
        }
    }

    /// Create with capacity
    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            embeddings: Vec::with_capacity(capacity),
            value_to_index: AHashMap::with_capacity(capacity),
            index_to_value: Vec::with_capacity(capacity),
        }
    }

    /// Get embedding for value
    pub fn get(&self, value: f32) -> Option<&GriessVector> {
        let index = self.value_to_index.get(&OrderedFloat(value))?;
        self.embeddings.get(*index)
    }

    /// Insert value and embedding
    pub fn insert(&mut self, value: f32, embedding: GriessVector) -> usize {
        if let Some(&index) = self.value_to_index.get(&OrderedFloat(value)) {
            return index;
        }

        let index = self.embeddings.len();
        self.embeddings.push(embedding);
        self.value_to_index.insert(OrderedFloat(value), index);
        self.index_to_value.push(value);

        index
    }
}

impl Default for EmbeddingCache {
    fn default() -> Self {
        Self::new()
    }
}

/// Checkpoint data for Pass 3 compilation
///
/// Allows resuming interrupted compilation from the last saved operation.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CompilationCheckpoint {
    /// Last completed operation ID
    pub last_completed_op_id: usize,

    /// Partial address space (incrementally built)
    pub address_space: AddressSpace,

    /// Hash tables for completed operations
    pub hash_tables: Vec<PerfectHashTable>,

    /// Operation metadata for completed operations
    pub operation_metadata: Vec<OperationMetadata>,

    /// Timestamp of checkpoint creation (Unix timestamp seconds)
    pub timestamp_secs: u64,

    /// Compiler version (for compatibility checks)
    pub compiler_version: String,
}

impl CompilationCheckpoint {
    /// Create new checkpoint
    pub fn new(
        last_completed_op_id: usize,
        address_space: AddressSpace,
        hash_tables: Vec<PerfectHashTable>,
        operation_metadata: Vec<OperationMetadata>,
    ) -> Self {
        let timestamp_secs = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();

        Self {
            last_completed_op_id,
            address_space,
            hash_tables,
            operation_metadata,
            timestamp_secs,
            compiler_version: env!("CARGO_PKG_VERSION").to_string(),
        }
    }

    /// Save checkpoint to file
    pub fn save(&self, path: &std::path::Path) -> crate::Result<()> {
        let bytes = bincode::serialize(self).map_err(|e| {
            crate::CompilerError::BinaryGenerationError(format!(
                "Checkpoint serialization failed: {}",
                e
            ))
        })?;

        std::fs::write(path, bytes)?;

        Ok(())
    }

    /// Load checkpoint from file
    pub fn load(path: &std::path::Path) -> crate::Result<Self> {
        let bytes = std::fs::read(path)?;

        let checkpoint: Self = bincode::deserialize(&bytes).map_err(|e| {
            crate::CompilerError::ParseError(format!("Checkpoint deserialization failed: {}", e))
        })?;

        // Version check (optional - could warn or error on mismatch)
        if checkpoint.compiler_version != env!("CARGO_PKG_VERSION") {
            tracing::warn!(
                "Checkpoint was created with different compiler version: {} (current: {})",
                checkpoint.compiler_version,
                env!("CARGO_PKG_VERSION")
            );
        }

        Ok(checkpoint)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_extended_address_roundtrip() {
        let space = AddressSpace::new();

        let addr = ExtendedAddress {
            class: 42,
            page: 123,
            byte: 200,
            sub_index: 30000,
        };

        let offset = addr.to_offset(&space);
        let recovered = ExtendedAddress::from_offset(offset, &space);

        assert_eq!(addr, recovered);
    }

    #[test]
    fn test_address_space_capacity() {
        let space = AddressSpace::new();

        // 96 * 480 * 256 * 65536 = 773,094,113,280 addresses
        assert_eq!(space.capacity(), 773_094_113_280);
    }

    #[test]
    fn test_address_space_store_retrieve() {
        let mut space = AddressSpace::new();

        let addr = ExtendedAddress {
            class: 0,
            page: 0,
            byte: 0,
            sub_index: 0,
        };

        let data = vec![1u8, 2, 3, 4, 5];
        space.store(addr, &data).unwrap();

        let retrieved = space.retrieve(addr).unwrap();
        assert_eq!(retrieved, &data[..]);
    }

    #[test]
    fn test_embedding_cache() {
        let mut cache = EmbeddingCache::new();

        let embedding = GriessVector::identity();

        let index1 = cache.insert(1.0, embedding.clone());
        let index2 = cache.insert(1.0, embedding.clone()); // Should return same index

        assert_eq!(index1, index2);
        assert_eq!(cache.embeddings.len(), 1);
    }
}
