//! # Hologram ONNX Compiler - Simplified Single-Pass
//!
//! Fast ONNX model compiler using HologramGraph and hologram-hrm Atlas
//! for O(1) lookup-based inference.
//!
//! ## Overview
//!
//! The simplified compiler transforms ONNX models into `.holo` binaries
//! in a single linear flow, replacing the old 5-pass pipeline with a simpler,
//! more maintainable architecture.
//!
//! ## Compilation Flow
//!
//! ```text
//! ONNX → HologramGraph → Optimize → Execute → Serialize
//! ```
//!
//! ### Step 1: Load ONNX → HologramGraph
//!
//! - Parse ONNX protobuf
//! - Build petgraph-based HologramGraph
//! - Apply user-provided or auto-detected input shapes
//!
//! ### Step 2: Optimize Graph
//!
//! - Subgraph pattern detection
//! - Operator fusion (Add+Relu, etc.)
//! - Dead code elimination
//!
//! ### Step 3: Execute Operators
//!
//! - Load hologram-hrm Atlas
//! - Execute macro-generated operators on sample patterns
//! - Build hash tables for O(1) lookup
//!
//! ### Step 4: Serialize Binary
//!
//! - Write .holo format (header + manifest + address space + hash tables)
//! - Memory-map friendly layout
//!
//! ## Usage
//!
//! ```no_run
//! use hologram_onnx_compiler::Compiler;
//!
//! let compiler = Compiler::new()
//!     .with_memory_budget(2048)
//!     .with_verbose(true);
//!
//! compiler.compile("model.onnx", "model.holo")?;
//! # Ok::<(), hologram_onnx_compiler::CompilerError>(())
//! ```
//!
//! ## Performance
//!
//! - **Compilation**: Fast (<1s for small models)
//! - **Code Reduction**: 77% less code vs old pipeline (940 vs 4,046 lines)
//! - **Maintainability**: Single linear flow, easier to understand
//!
//! ## Architecture
//!
//! This compiler implements the Hologram approach:
//!
//! - Griess algebra embedding (196,884 dimensions)
//! - Pre-computation of all operation results
//! - Perfect hash tables for O(1) pattern lookup
//! - SIMD-aligned binary format (.holo)
//! - Zero-copy runtime execution

// Module declarations
pub mod compiler; // Simplified single-pass compiler
pub mod config;
pub mod error;
pub mod hrm; // HRM components (graph, ops, types, runtime)
pub mod numeric_types;
pub mod proto;
pub mod safetensors_loader; // SafeTensors weight loader

// Re-exports for convenient access
pub use error::{CompilerError, Result};
pub use safetensors_loader::load_safetensors;

// Simplified Compiler API
pub use compiler::{
    CompilationStats, Compiler, ExecutionResults, GraphExecutor, GraphOptimizer, HoloSerializer,
    OperationMetadata as CompilerOperationMetadata, OptimizationStats, SerializerStats,
};

// HRM component re-exports
pub use hrm::types::{
    AddressSpace, CollectionManifest, DiscretizationStrategy, EmbeddingCache, ExtendedAddress, FactorizedResults,
    OperationMetadata, OperationStats, PerfectHashTable,
};

// ONNX Operations for HRM
pub use hrm::ops::{
    // Math ops
    AddOp,
    // Shape ops
    ArgMaxOp,
    // Normalization ops
    AttentionOp,
    BiasGeluOp,
    // Tensor ops
    ConcatOp,
    ConstantOp,
    DivOp,
    FlattenOp,
    GatherOp,
    // Matrix ops
    GemmOp,
    LayerNormalizationOp,
    MatMulOp,
    MulOp,
    // Central enum and trait
    OnnxHRMNode,
    OnnxOperator,
    RangeOp,
    // Activation ops
    ReluOp,
    ReshapeOp,
    ShapeOp,
    SigmoidOp,
    SkipLayerNormalizationOp,
    SliceOp,
    SubOp,
    TanhOp,
    UnsqueezeOp,
};

/// Get the version of the hologram-onnx-compiler library
pub fn version() -> &'static str {
    env!("CARGO_PKG_VERSION")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_version() {
        let ver = version();
        assert!(!ver.is_empty());
        assert!(ver.contains('.'));
    }

    #[test]
    fn test_compiler_exports() {
        // Verify new simplified compiler is accessible
        let _compiler_type = std::any::type_name::<Compiler>();
        let _stats_type = std::any::type_name::<CompilationStats>();
    }
}
