use echonomics_engine::{HundianState, PauliKey, GateResult, SpinTag, PeriodStatus};

#[test]
fn test_property_based_pauli_capacity_and_multiplicity_bounds() {
    let mut state = HundianState::new();
    state.set_period_status("P0", PeriodStatus::Open);
    state.register_degenerate_class("facilitation");

    for i in 1..=10 {
        let key = PauliKey {
            role_class: "facilitation".into(),
            slot_id: format!("slot-{}", i),
            period_id: "P0".into(),
        };
        state.register_slot(key);
    }

    // Property 1: Filling distinct empty slots increases multiplicity M linearly up to |D| + 1
    for i in 1..=10 {
        let person = format!("person-{}", i);
        let slot = format!("slot-{}", i);
        let res = state.propose_fill(&person, "facilitation", &slot, "P0", None);
        assert_eq!(res, GateResult::OkSingle { sigma: SpinTag::Alpha });
        
        let (unpaired, spin, m) = state.calculate_multiplicity("P0");
        assert_eq!(unpaired, i);
        assert_eq!(spin, i as f64 / 2.0);
        assert_eq!(m, i + 1);
    }

    // Property 2: When all slots in D are half-filled (U = 0), pairing on slot-1 is allowed
    let pair_res = state.propose_fill("pair-person-1", "facilitation", "slot-1", "P0", None);
    assert_eq!(pair_res, GateResult::OkPair { sigma: SpinTag::Beta });

    // Property 3: Submitting a 3rd occupant on slot-1 is ALWAYS rejected by Pauli Exclusion
    let third_res = state.propose_fill("third-person", "facilitation", "slot-1", "P0", None);
    assert_eq!(third_res, GateResult::RejPauli);
}
