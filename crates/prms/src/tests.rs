#[cfg(test)]
mod tests {
    use crate::*;

    // -----------------------------------------------------------------------
    // Lineage metrics tests
    // -----------------------------------------------------------------------

    #[test]
    fn test_lineage_valid() {
        let metrics = LineageMetrics {
            data_age: 100,
            max_allowed_age: 10000,
            non_zero_channels: 5,
            total_channels: 10,
            measurement_variance: 50,
        };
        assert!(metrics.validate().is_ok());
    }

    #[test]
    fn test_lineage_nonzero_exceeds_total() {
        let metrics = LineageMetrics {
            data_age: 100,
            max_allowed_age: 10000,
            non_zero_channels: 15,
            total_channels: 10,
            measurement_variance: 50,
        };
        assert!(metrics.validate().is_err());
    }

    #[test]
    fn test_lineage_total_exceeds_scale() {
        let metrics = LineageMetrics {
            data_age: 100,
            max_allowed_age: 10000,
            non_zero_channels: 5,
            total_channels: 10001,
            measurement_variance: 50,
        };
        assert!(metrics.validate().is_err());
    }

    #[test]
    fn test_lineage_age_exceeds_max() {
        let metrics = LineageMetrics {
            data_age: 20000,
            max_allowed_age: 10000,
            non_zero_channels: 5,
            total_channels: 10,
            measurement_variance: 50,
        };
        assert!(metrics.validate().is_err());
    }

    #[test]
    fn test_lineage_hash_deterministic() {
        let metrics = LineageMetrics {
            data_age: 100,
            max_allowed_age: 10000,
            non_zero_channels: 5,
            total_channels: 10,
            measurement_variance: 50,
        };
        assert_eq!(metrics.hash(), metrics.hash());
    }

    // -----------------------------------------------------------------------
    // Compliance budget tests
    // -----------------------------------------------------------------------

    #[test]
    fn test_budget_valid() {
        let budget = ComplianceBudget {
            max_allowed_cond: 1000,
            p7_admissibility_threshold: 500,
        };
        assert!(budget.validate().is_ok());
    }

    #[test]
    fn test_budget_zero_max_allowed() {
        let budget = ComplianceBudget {
            max_allowed_cond: 0,
            p7_admissibility_threshold: 500,
        };
        assert!(budget.validate().is_err());
    }

    #[test]
    fn test_budget_exceeds_scale() {
        let budget = ComplianceBudget {
            max_allowed_cond: 10001,
            p7_admissibility_threshold: 500,
        };
        assert!(budget.validate().is_err());
    }

    #[test]
    fn test_budget_hash_deterministic() {
        let budget = ComplianceBudget {
            max_allowed_cond: 1000,
            p7_admissibility_threshold: 500,
        };
        assert_eq!(budget.hash(), budget.hash());
    }

    // -----------------------------------------------------------------------
    // Engine tests
    // -----------------------------------------------------------------------

    #[test]
    fn test_check_lineage_success() {
        let engine = PrmsEngine;
        let metrics = LineageMetrics {
            data_age: 100,
            max_allowed_age: 10000,
            non_zero_channels: 5,
            total_channels: 10,
            measurement_variance: 50,
        };
        let witness = engine.check_lineage(&metrics).unwrap();
        assert_eq!(witness.data_age, 100);
        assert_eq!(witness.non_zero_channels, 5);
        assert_eq!(witness.total_channels, 10);
    }

    #[test]
    fn test_check_lineage_failure() {
        let engine = PrmsEngine;
        let metrics = LineageMetrics {
            data_age: 100,
            max_allowed_age: 10000,
            non_zero_channels: 15,
            total_channels: 10,
            measurement_variance: 50,
        };
        assert!(engine.check_lineage(&metrics).is_err());
    }

    #[test]
    fn test_check_compliance_success() {
        let engine = PrmsEngine;
        let budget = ComplianceBudget {
            max_allowed_cond: 1000,
            p7_admissibility_threshold: 500,
        };
        let frame = engine.check_compliance(&budget, 500).unwrap();
        assert_eq!(frame.cond_number, 500);
        assert!(frame.provenance_valid);
    }

    #[test]
    fn test_check_compliance_failure() {
        let engine = PrmsEngine;
        let budget = ComplianceBudget {
            max_allowed_cond: 100,
            p7_admissibility_threshold: 50,
        };
        let result = engine.check_compliance(&budget, 200);
        assert!(result.is_err());
    }

    #[test]
    fn test_check_compliance_with_witness() {
        let engine = PrmsEngine;
        let budget = ComplianceBudget {
            max_allowed_cond: 1000,
            p7_admissibility_threshold: 500,
        };
        let (frame, witness) = engine.check_compliance_with_witness(&budget, 500).unwrap();
        assert_eq!(frame.cond_number, 500);
        assert_eq!(witness.cond_number, 500);
        assert!(witness.telemetry_hash != [0u8; 32]);
    }

    // -----------------------------------------------------------------------
    // Telemetry frame tests
    // -----------------------------------------------------------------------

    #[test]
    fn test_frame_validation_success() {
        let frame = TelemetryFrame::new(0, 500, true);
        let budget = ComplianceBudget {
            max_allowed_cond: 1000,
            p7_admissibility_threshold: 500,
        };
        assert!(frame.validate(&budget).is_ok());
    }

    #[test]
    fn test_frame_validation_provenance_false() {
        let frame = TelemetryFrame::new(0, 500, false);
        let budget = ComplianceBudget {
            max_allowed_cond: 1000,
            p7_admissibility_threshold: 500,
        };
        assert!(frame.validate(&budget).is_err());
    }

    #[test]
    fn test_frame_validation_cond_exceeds_budget() {
        let frame = TelemetryFrame::new(0, 2000, true);
        let budget = ComplianceBudget {
            max_allowed_cond: 1000,
            p7_admissibility_threshold: 500,
        };
        assert!(frame.validate(&budget).is_err());
    }

    // -----------------------------------------------------------------------
    // Determinism tests
    // -----------------------------------------------------------------------

    #[test]
    fn test_determinism_lineage() {
        let engine = PrmsEngine;
        let metrics = LineageMetrics {
            data_age: 100,
            max_allowed_age: 10000,
            non_zero_channels: 5,
            total_channels: 10,
            measurement_variance: 50,
        };
        let w1 = engine.check_lineage(&metrics).unwrap();
        let w2 = engine.check_lineage(&metrics).unwrap();
        assert_eq!(w1.lineage_hash, w2.lineage_hash);
    }

    #[test]
    fn test_determinism_compliance() {
        let engine = PrmsEngine;
        let budget = ComplianceBudget {
            max_allowed_cond: 1000,
            p7_admissibility_threshold: 500,
        };
        let f1 = engine.check_compliance(&budget, 500).unwrap();
        let f2 = engine.check_compliance(&budget, 500).unwrap();
        assert_eq!(f1.cond_number, f2.cond_number);
        assert_eq!(f1.provenance_valid, f2.provenance_valid);
    }

    // -----------------------------------------------------------------------
    // Lean parity tests
    // -----------------------------------------------------------------------

    #[test]
    fn test_lean_parity_scale() {
        assert_eq!(crate::SCALE, 10000);
    }

    #[test]
    fn test_lean_parity_lineage_validation() {
        let metrics = LineageMetrics {
            data_age: 5,
            max_allowed_age: 100,
            non_zero_channels: 3,
            total_channels: 5,
            measurement_variance: 10,
        };
        assert!(metrics.validate().is_ok());
    }

    #[test]
    fn test_lean_parity_budget_validation() {
        let budget = ComplianceBudget {
            max_allowed_cond: 1000,
            p7_admissibility_threshold: 500,
        };
        assert!(budget.validate().is_ok());
    }

    #[test]
    fn test_lean_parity_frame_validity() {
        let frame = TelemetryFrame::new(0, 500, true);
        let budget = ComplianceBudget {
            max_allowed_cond: 1000,
            p7_admissibility_threshold: 500,
        };
        assert!(frame.validate(&budget).is_ok());
    }

    // -----------------------------------------------------------------------
    // Boundary tests
    // -----------------------------------------------------------------------

    #[test]
    fn test_boundary_cond_equals_max() {
        let engine = PrmsEngine;
        let budget = ComplianceBudget {
            max_allowed_cond: 1000,
            p7_admissibility_threshold: 500,
        };
        let frame = engine.check_compliance(&budget, 1000).unwrap();
        assert_eq!(frame.cond_number, 1000);
    }

    #[test]
    fn test_boundary_cond_exceeds_max_by_one() {
        let engine = PrmsEngine;
        let budget = ComplianceBudget {
            max_allowed_cond: 1000,
            p7_admissibility_threshold: 500,
        };
        assert!(engine.check_compliance(&budget, 1001).is_err());
    }

    #[test]
    fn test_boundary_zero_channels() {
        let metrics = LineageMetrics {
            data_age: 0,
            max_allowed_age: 10000,
            non_zero_channels: 0,
            total_channels: 0,
            measurement_variance: 0,
        };
        assert!(metrics.validate().is_ok());
    }

    #[test]
    fn test_witness_hash_changes_with_input() {
        let engine = PrmsEngine;
        let budget = ComplianceBudget {
            max_allowed_cond: 1000,
            p7_admissibility_threshold: 500,
        };
        let (_, w1) = engine.check_compliance_with_witness(&budget, 500).unwrap();
        let (_, w2) = engine.check_compliance_with_witness(&budget, 600).unwrap();
        assert_ne!(w1.telemetry_hash, w2.telemetry_hash);
    }
}
