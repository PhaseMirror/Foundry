// Graph module for Hologram ONNX Compiler
//
// This module provides an intermediate representation (IR) for ONNX models
// that enables advanced optimizations including:
// - Common Subexpression Elimination (CSE)
// - Dead Code Elimination (DCE)
// - Arithmetic simplification
// - Constant folding
// - Consumer tracking for memory management
//
// The graph IR separates graph structure from tensor data, enabling
// efficient dependency analysis and optimization passes.

pub mod ir;
pub mod memory;
pub mod optimizer;
pub mod passes;

// Re-exports for convenience
pub use ir::{Dependency, GraphNode, HologramGraph, NodeId};
pub use memory::{ConsumerMap, EmbeddedInput};
pub use optimizer::GraphOptimizer;
pub use passes::OptimizationPass;
