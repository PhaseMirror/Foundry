// Graph optimization infrastructure
//
// This module provides the framework for applying optimization passes
// to HologramGraph. Optimization passes include:
// - Common Subexpression Elimination (CSE)
// - Dead Code Elimination (DCE)
// - Arithmetic simplification
// - Constant folding
//
// Passes are composable and run until fixpoint (no changes).

use super::ir::HologramGraph;
use super::passes::OptimizationPass;
use anyhow::Result;
use std::time::{Duration, Instant};
use tracing::{debug, info};

/// Graph optimizer
///
/// Runs a sequence of optimization passes on a HologramGraph until
/// no further changes occur (fixpoint iteration).
pub struct GraphOptimizer {
    /// Optimization passes to apply
    passes: Vec<Box<dyn OptimizationPass>>,

    /// Maximum number of iterations before stopping
    max_iterations: usize,

    /// Whether to log detailed statistics
    verbose: bool,
}

impl GraphOptimizer {
    /// Create a new graph optimizer with default settings
    pub fn new(passes: Vec<Box<dyn OptimizationPass>>) -> Self {
        Self {
            passes,
            max_iterations: 10,
            verbose: false,
        }
    }

    /// Create optimizer with custom settings
    pub fn with_settings(passes: Vec<Box<dyn OptimizationPass>>, max_iterations: usize, verbose: bool) -> Self {
        Self {
            passes,
            max_iterations,
            verbose,
        }
    }

    /// Set maximum iterations
    pub fn set_max_iterations(&mut self, max_iterations: usize) {
        self.max_iterations = max_iterations;
    }

    /// Enable verbose logging
    pub fn set_verbose(&mut self, verbose: bool) {
        self.verbose = verbose;
    }

    /// Optimize the graph
    ///
    /// Runs all passes in sequence, repeating until no changes occur
    /// or max_iterations is reached.
    ///
    /// Returns statistics about the optimization process.
    pub fn optimize(&self, graph: &mut HologramGraph) -> Result<OptimizationStats> {
        let start_time = Instant::now();
        let initial_stats = graph.statistics();

        info!("Starting graph optimization...");
        if self.verbose {
            info!("Initial graph: {}", initial_stats);
        }

        let mut total_changes = 0;
        let mut iteration = 0;
        let mut pass_stats: Vec<PassStats> = Vec::new();

        // Run passes until fixpoint or max iterations
        for iteration_num in 0..self.max_iterations {
            iteration = iteration_num + 1;
            let mut iteration_changed = false;

            debug!("Optimization iteration {}/{}", iteration, self.max_iterations);

            for pass in &self.passes {
                let pass_start = Instant::now();
                let nodes_before = graph.statistics().total_nodes;

                // Run the pass
                let changed = pass.run(graph)?;

                let pass_duration = pass_start.elapsed();
                let nodes_after = graph.statistics().total_nodes;
                let nodes_removed = nodes_before.saturating_sub(nodes_after);

                if changed {
                    iteration_changed = true;
                    total_changes += 1;

                    if self.verbose {
                        debug!(
                            "  {} - Changed: yes, Nodes removed: {}, Time: {:?}",
                            pass.name(),
                            nodes_removed,
                            pass_duration
                        );
                    }
                } else if self.verbose {
                    debug!("  {} - No changes, Time: {:?}", pass.name(), pass_duration);
                }

                pass_stats.push(PassStats {
                    pass_name: pass.name().to_string(),
                    iteration: iteration_num,
                    changed,
                    nodes_removed,
                    duration: pass_duration,
                });
            }

            if !iteration_changed {
                info!("Optimization converged after {} iterations", iteration);
                break;
            }
        }

        if iteration == self.max_iterations {
            info!(
                "Optimization stopped after reaching max iterations ({})",
                self.max_iterations
            );
        }

        let total_duration = start_time.elapsed();
        let final_stats = graph.statistics();

        let stats = OptimizationStats {
            initial_nodes: initial_stats.total_nodes,
            final_nodes: final_stats.total_nodes,
            nodes_removed: initial_stats.total_nodes - final_stats.total_nodes,
            initial_edges: initial_stats.total_edges,
            final_edges: final_stats.total_edges,
            iterations: iteration,
            total_changes,
            duration: total_duration,
            pass_stats,
        };

        if self.verbose {
            info!("Optimization complete:");
            info!(
                "  Nodes: {} → {} (removed {})",
                stats.initial_nodes, stats.final_nodes, stats.nodes_removed
            );
            info!("  Edges: {} → {}", stats.initial_edges, stats.final_edges);
            info!("  Iterations: {}", stats.iterations);
            info!("  Total time: {:?}", stats.duration);
        }

        Ok(stats)
    }
}

/// Statistics for a single pass execution
#[derive(Debug, Clone)]
pub struct PassStats {
    pub pass_name: String,
    pub iteration: usize,
    pub changed: bool,
    pub nodes_removed: usize,
    pub duration: Duration,
}

/// Overall optimization statistics
#[derive(Debug, Clone)]
pub struct OptimizationStats {
    pub initial_nodes: usize,
    pub final_nodes: usize,
    pub nodes_removed: usize,
    pub initial_edges: usize,
    pub final_edges: usize,
    pub iterations: usize,
    pub total_changes: usize,
    pub duration: Duration,
    pub pass_stats: Vec<PassStats>,
}

impl std::fmt::Display for OptimizationStats {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        writeln!(f, "Optimization Statistics:")?;
        writeln!(
            f,
            "  Nodes: {} → {} (removed {})",
            self.initial_nodes, self.final_nodes, self.nodes_removed
        )?;
        writeln!(f, "  Edges: {} → {}", self.initial_edges, self.final_edges)?;
        writeln!(f, "  Iterations: {}", self.iterations)?;
        writeln!(f, "  Total changes: {}", self.total_changes)?;
        writeln!(f, "  Total time: {:?}", self.duration)?;

        if !self.pass_stats.is_empty() {
            writeln!(f, "  Pass details:")?;
            for stat in &self.pass_stats {
                if stat.changed {
                    writeln!(
                        f,
                        "    [Iter {}] {} - Removed {} nodes ({:?})",
                        stat.iteration, stat.pass_name, stat.nodes_removed, stat.duration
                    )?;
                }
            }
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::hrm::graph::passes::DeadCodeElimination;

    #[test]
    fn test_optimizer_creation() {
        let passes: Vec<Box<dyn OptimizationPass>> = vec![Box::new(DeadCodeElimination)];
        let optimizer = GraphOptimizer::new(passes);
        assert_eq!(optimizer.max_iterations, 10);
        assert!(!optimizer.verbose);
    }

    #[test]
    fn test_optimizer_settings() {
        let passes: Vec<Box<dyn OptimizationPass>> = vec![Box::new(DeadCodeElimination)];
        let optimizer = GraphOptimizer::with_settings(passes, 5, true);
        assert_eq!(optimizer.max_iterations, 5);
        assert!(optimizer.verbose);
    }
}
