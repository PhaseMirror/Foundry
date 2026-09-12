use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RuntimeTelemetry {
    pub compile_time_ms: f64,
    pub memory_allocated_mb: f64,
    pub ir_size_kb: f64,
}

impl RuntimeTelemetry {
    pub fn new(time: f64, mem: f64, ir: f64) -> Self {
        Self {
            compile_time_ms: time,
            memory_allocated_mb: mem,
            ir_size_kb: ir,
        }
    }

    /// Pulls the latest metric overlay straight from the MLIR lowering layer.
    pub fn extract_live_metrics() -> Self {
        // Mock extraction simulating the MLIR-LLVM backend profiler hooking
        Self {
            compile_time_ms: 34.8,
            memory_allocated_mb: 280.0,
            ir_size_kb: 41.0,
        }
    }
}
