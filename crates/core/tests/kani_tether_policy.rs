#[cfg(kani)]
mod tether_policy_proofs {
    use pirtm_rs::tether_policy::{TetherPolicy, NodeState};

    #[kani::proof]
    fn tether_state_never_jumps_from_kill_to_execution() {
        let policy = TetherPolicy::default();
        let coverage: f64 = kani::any();
        let drift: f64 = kani::any();
        kani::assume(coverage >= 0.0 && coverage <= 1.0);
        kani::assume(drift >= 0.0 && drift <= 1.0);

        let state = policy.process_telemetry(coverage, drift).1;
        // If we are in SigGovKill, a subsequent call (with same or worse params) must stay SigGovKill
        if state == NodeState::SigGovKill {
            // Worse or same parameters (more drift or less coverage)
            let worse_coverage: f64 = kani::any();
            let worse_drift: f64 = kani::any();
            kani::assume(worse_coverage <= coverage);
            kani::assume(worse_drift >= drift);
            kani::assume(worse_coverage >= 0.0 && worse_drift <= 1.0);
            let next_state = policy.process_telemetry(worse_coverage, worse_drift).1;
            assert!(next_state != NodeState::Execution, "SigGovKill must not transition to Execution");
        }
    }

    #[kani::proof]
    fn tether_tau_below_safe_implies_kill() {
        let policy = TetherPolicy::default();
        let coverage: f64 = kani::any();
        let drift: f64 = kani::any();
        kani::assume(coverage >= 0.0 && coverage <= 1.0);
        kani::assume(drift >= 0.0 && drift <= 1.0);

        let tau = policy.compute_tau(coverage, drift);
        kani::assume(tau <= policy.tau_safe);
        let state = policy.process_telemetry(coverage, drift).1;
        assert_eq!(state, NodeState::SigGovKill);
    }

    #[kani::proof]
    fn tether_execution_only_if_tau_above_crit() {
        let policy = TetherPolicy::default();
        let coverage: f64 = kani::any();
        let drift: f64 = kani::any();
        kani::assume(coverage >= 0.0 && coverage <= 1.0);
        kani::assume(drift >= 0.0 && drift <= 1.0);

        let state = policy.process_telemetry(coverage, drift).1;
        if state == NodeState::Execution {
            let tau = policy.compute_tau(coverage, drift);
            assert!(tau > policy.tau_crit);
        }
    }
}
