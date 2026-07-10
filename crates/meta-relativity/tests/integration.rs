//! Integration tests for Meta-Relativity.
//!
//! Based on ADR-099: Meta-Relativity — Test Suite and Certification Validation.

use meta_relativity::operators::{PrimeBlock, TimeSieve, InternalBlock, UniversalOperator};
use meta_relativity::certification::{CertificationMetrics, certify_operator};
use nalgebra::{DMatrix, DVector};

#[test]
fn test_full_workflow_integration() {
    // 1. Setup
    let prime_dim = 2;
    let prime_block = PrimeBlock {
        diagonal: DVector::from_vec(vec![0.5, 0.3]),
        off_diagonal: DMatrix::from_element(prime_dim, prime_dim, 0.1),
    };
    let time_sieve = TimeSieve { coefficients: vec![0.1, 0.2] };
    let internal_block = InternalBlock::new(DMatrix::from_row_slice(2, 2, &[1.0, 0.0, 0.0, 1.0])).unwrap();

    // 2. Operator Assembly
    let _u = UniversalOperator::assemble(prime_block, time_sieve, internal_block);

    // 3. Certification Workflow
    let metrics = CertificationMetrics { gap_lb: 0.5, slope_ub: 0.1 };
    let result = certify_operator(&metrics, 0.4, 0.1);
    
    assert!(result.is_ok());
}
