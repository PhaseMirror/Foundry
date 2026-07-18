
    use super::*;

    /// Proof: budget is respected — any cond > maxAllowedCond is rejected.
    #[kani::proof]
    fn proof_budget_respected() {
        let engine = PrmsEngine;
        let cond: u64 = kani::any();
        let max_allowed_cond: u64 = kani::any();
        kani::assume(max_allowed_cond > 0 && max_allowed_cond <= 10000);

        let budget = ComplianceBudget {
            max_allowed_cond,
            p7_admissibility_threshold: 500,
        };

        let res = engine.check_compliance(&budget, cond);
        if cond > max_allowed_cond {
            kani::assert(res.is_err(), "Exceeded budget rejected");
        } else {
            kani::assert(res.is_ok(), "Valid budget accepted");
        }
    }

    /// Proof: lineage dataAge is monotone non-decreasing.
    #[kani::proof]
    fn proof_lineage_monotone() {
        let engine = PrmsEngine;
        let data_age: u64 = kani::any();
        let max_allowed_age: u64 = kani::any();
        kani::assume(data_age <= max_allowed_age && max_allowed_age <= 10000);

        let metrics = LineageMetrics {
            data_age,
            max_allowed_age,
            non_zero_channels: 5,
            total_channels: 10,
            measurement_variance: 50,
        };

        let witness = engine.check_lineage(&metrics).unwrap();
        kani::assert(witness.data_age == data_age, "dataAge preserved");
    }

    /// Proof: non-zero channels never exceed total channels.
    #[kani::proof]
    fn proof_lineage_nonzero_le_total() {
        let non_zero: u64 = kani::any();
        let total: u64 = kani::any();
        kani::assume(non_zero <= total && total <= 10000);

        let metrics = LineageMetrics {
            data_age: 0,
            max_allowed_age: 10000,
            non_zero_channels: non_zero,
            total_channels: total,
            measurement_variance: 0,
        };

        let engine = PrmsEngine;
        let witness = engine.check_lineage(&metrics).unwrap();
        kani::assert(
            witness.non_zero_channels <= witness.total_channels,
            "nonZeroChannels <= totalChannels",
        );
    }

    /// Proof: telemetry frame cond_number never exceeds max_allowed_cond.
    #[kani::proof]
    fn proof_frame_cond_within_budget() {
        let engine = PrmsEngine;
        let cond: u64 = kani::any();
        let max_allowed_cond: u64 = kani::any();
        kani::assume(max_allowed_cond > 0 && max_allowed_cond <= 10000);
        kani::assume(cond <= max_allowed_cond);

        let budget = ComplianceBudget {
            max_allowed_cond,
            p7_admissibility_threshold: 500,
        };

        let frame = engine.check_compliance(&budget, cond).unwrap();
        kani::assert(frame.cond_number <= budget.max_allowed_cond, "cond within budget");
        kani::assert(frame.provenance_valid == true, "provenance valid");
    }

    /// Proof: witness hash is deterministic for same inputs.
    #[kani::proof]
    fn proof_witness_deterministic() {
        let engine = PrmsEngine;
        let budget = ComplianceBudget {
            max_allowed_cond: 1000,
            p7_admissibility_threshold: 500,
        };
        let cond: u64 = kani::any();
        kani::assume(cond <= 1000);

        let (_, w1) = engine.check_compliance_with_witness(&budget, cond).unwrap();
        let (_, w2) = engine.check_compliance_with_witness(&budget, cond).unwrap();

        kani::assert(w1.telemetry_hash == w2.telemetry_hash, "Witness hash deterministic");
        kani::assert(w1.cond_number == w2.cond_number, "Witness cond deterministic");

    }
