//! Elastic Tether — Test Suite
//!
//! Run with: cargo test
//!
//! Kani verification (requires Kani installation):
//!   cargo kani --tests

#[cfg(test)]
mod tests {
    use elastic_tether::*;

    #[test]
    fn test_is_accessible_2() {
        assert!(is_accessible(2));
    }

    #[test]
    fn test_is_accessible_4() {
        assert!(is_accessible(4));
    }

    #[test]
    fn test_not_accessible_7() {
        assert!(!is_accessible(7));
    }

    #[test]
    fn test_cmt_gap_reduction() {
        assert!(max_cmt_gap(100_000) <= 2);
    }

    #[test]
    fn test_lag_nonnegative() {
        let state = AgentState {
            head_pos: 100,
            tail_pos: 50,
            params: SafetyParams {
                cost_interrogate: 10,
                v_max: 100,
                v_min: 1,
            },
        };
        assert!(state.lag() >= 0);
    }

    #[test]
    fn test_lead_region_vmin() {
        let state = AgentState {
            head_pos: 5000,
            tail_pos: 1000,
            params: SafetyParams {
                cost_interrogate: 10,
                v_max: 100,
                v_min: 1,
            },
        };
        assert!(state.in_lead_region());
        assert_eq!(state.head_velocity(0.0), 1);
    }

    #[test]
    fn test_tether_potential_nonnegative() {
        let state = AgentState {
            head_pos: 100,
            tail_pos: 50,
            params: SafetyParams {
                cost_interrogate: 10,
                v_max: 100,
                v_min: 1,
            },
        };
        assert!(state.tether_potential(1.0) >= 0.0);
    }

    #[test]
    fn test_cmt_navigate() {
        let next = cmt_navigate(10, 100);
        assert!(next.is_some());
        assert!(next.unwrap() > 10);
    }

    #[test]
    fn test_pi_known_values() {
        assert_eq!(pi(10), 4); // primes: 2,3,5,7
        assert_eq!(pi(100), 25);
    }
}
