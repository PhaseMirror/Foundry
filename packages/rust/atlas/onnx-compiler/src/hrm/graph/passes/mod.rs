// Optimization passes for HologramGraph
//
// This module contains individual optimization passes that can be
// composed and applied to graphs.

mod arithmetic;
mod constant_fold;
mod cse;
mod dce;

pub use arithmetic::ArithmeticElimination;
pub use constant_fold::ConstantFolding;
pub use cse::CommonSubexpressionElimination;
pub use dce::DeadCodeElimination;

use super::ir::HologramGraph;
use anyhow::Result;

/// Optimization pass trait
///
/// Each optimization pass implements this trait to provide a
/// composable transformation on the graph.
pub trait OptimizationPass {
    /// Get the name of this pass (for logging/debugging)
    fn name(&self) -> &str;

    /// Run the optimization pass on the graph
    ///
    /// Returns `true` if the graph was modified, `false` otherwise.
    /// This is used to determine when to stop fixpoint iteration.
    fn run(&self, graph: &mut HologramGraph) -> Result<bool>;
}
