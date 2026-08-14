pub mod barrett;
pub mod bigint;
pub mod certificate;
pub mod executor;
pub mod guards;
/// AIR (Algebraic Intermediate Representation) for MR64 primality testing
///
/// This module defines the constraint system for 64-bit Miller-Rabin primality testing.
///
/// Columns:
/// - n: candidate number
/// - a, b: intermediate values for modular arithmetic
/// - t, q, r: quotient and remainder for Barrett reduction
/// - acc: accumulator for exponentiation
/// - exp_bit: current bit of exponent
/// - s_hit: selector for constraint activation
/// - flags: control flags
pub mod miller_rabin;
pub mod support;

pub use bigint::{BigInt, Modulus};
pub use certificate::{CertificateError, PrattCertificate};
pub mod primality;

use goldilocks::GoldilocksField;
use miller_rabin::{miller_rabin_64, trace_to_field};
use serde::{Deserialize, Serialize};
use support::support_window;

pub const NUM_COLUMNS: usize = 10;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MR64Air {
    /// Number of rows in the trace
    pub trace_len: usize,
    /// Public inputs (candidate number)
    pub public_inputs: Vec<u64>,
}

impl MR64Air {
    pub fn new(n: u64) -> Self {
        let preview = miller_rabin_64(n);
        let steps = preview.trace_steps.len().max(1);
        let mut trace_len = steps.next_power_of_two().max(1024);
        let window = support_window();
        assert!(
            trace_len <= window.max_trace_rows,
            "Trace length {} exceeds support window max {} rows. Adjust support_window.json to widen the window or reject the input.",
            trace_len,
            window.max_trace_rows
        );

        if trace_len < steps {
            trace_len = steps;
        }

        Self {
            trace_len,
            public_inputs: vec![n],
        }
    }

    /// Generate execution trace for MR64 test
    ///
    /// Executes Miller-Rabin primality test and converts to field trace
    pub fn generate_trace(&self, n: u64) -> Vec<Vec<GoldilocksField>> {
        // Execute MR64 algorithm
        let result = miller_rabin_64(n);

        // Convert to field trace
        trace_to_field(&result, self.trace_len)
    }

    /// Evaluate AIR constraints at a given row
    ///
    /// Returns constraint polynomial evaluations that must be zero
    /// for a valid trace.
    ///
    /// TODO: Implement full constraint system:
    /// 1. Boundary constraints (initial and final values)
    /// 2. Transition constraints (row[i] -> row[i+1])
    /// 3. Range checks for field elements
    /// 4. Barrett reduction constraints
    /// 5. Witness loop constraints
    pub fn evaluate_constraints(
        &self,
        _row: &[GoldilocksField],
        _next_row: &[GoldilocksField],
    ) -> Vec<GoldilocksField> {
        // TODO: Return actual constraint evaluations
        vec![]
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_air_creation() {
        let air = MR64Air::new(17);
        assert!(air.trace_len.is_power_of_two());
        assert_eq!(air.public_inputs[0], 17);
    }
}
