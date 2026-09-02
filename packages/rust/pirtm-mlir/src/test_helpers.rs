// crates/pirtm-mlir/test_helpers.rs

//! Test helper utilities for E2E pipeline tests.

pub use crate::{lower_program, PirtmOp};
pub use pirtm_parser::parse;

/// Result of running a pipeline test.
pub struct PipelineResult {
    pub mlir: String,
}

/// Execute the parse → lower pipeline for a full program.
pub fn run_pipeline(source: &str) -> PipelineResult {
    let program = parse(source).expect("parse failed");
    let mlir = lower_program(&program).expect("lower failed");
    PipelineResult { mlir }
}

/// Execute the full program pipeline (multiple statements).
pub fn run_program_pipeline(source: &str) -> Result<String, String> {
    let program = parse(source)?;
    lower_program(&program)
}

/// Count occurrences of a pattern in a string (for assertions).
pub fn count_pattern(s: &str, pat: &str) -> usize {
    s.matches(pat).count()
}


/// Macro for E2E tests: parses source, validates MLIR contains expected fragments.
#[macro_export]
macro_rules! e2e_test {
    ($name:ident, $source:expr, [$($expected:expr),* $(,)?] $(,)?) => {
        #[test]
        fn $name() {
            let result = run_pipeline($source);
            let expected_list = [$($expected),*];
            for expected in expected_list {
                assert!(result.mlir.contains(expected), "missing: {}", expected);
            }
        }
    };
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_run_pipeline_basic() {
        let result = run_pipeline("Ap(2)");
        assert!(!result.mlir.is_empty());
        assert!(result.mlir.contains("pirtm"));
    }
}
