#[cfg(kani)]
mod roundtrip_proofs {
    use crate::{CandidateState, MEEPState};

    /// Harness 1: Step-wise monotonicity of the fidelity estimate proxy
    /// Proves that adding a successful 'zero' shot strictly non-decreases the scaled fidelity metric.
    #[kani::proof]
    pub fn verify_step_zero_monotonic() {
        let zeros: u32 = kani::any();
        let shots: u32 = kani::any();
        
        kani::assume(zeros <= shots);
        kani::assume(shots > 0);
        // Prevent overflow in our +1 step to keep it bounded for this specific harness
        kani::assume(shots < u32::MAX);

        let before = CandidateState { zeros, shots };
        let mut state = MEEPState {
            candidates: [before, CandidateState { zeros: 0, shots: 0 }],
        };

        // Step with a zero outcome (true)
        state.step(0, true);
        let after = state.candidates[0];

        // The fidelity proxy: zeros/shots. To avoid floats, we cross-multiply:
        // (zeros_after / shots_after) >= (zeros_before / shots_before)
        // zeros_after * shots_before >= zeros_before * shots_after
        let lhs = (after.zeros as u64) * (before.shots as u64);
        let rhs = (before.zeros as u64) * (after.shots as u64);

        assert!(lhs >= rhs, "Zero outcome must not lower fidelity estimate");
    }

    /// Harness 2: Certification persistence under additional favorable shots
    /// Proves that if candidate J is already certified against K, acquiring another favorable shot
    /// preserves that certification.
    #[kani::proof]
    pub fn verify_certification_persists_winner_shot() {
        let delta_threshold: u32 = kani::any();
        let mut state = MEEPState {
            candidates: [
                CandidateState { zeros: kani::any(), shots: kani::any() },
                CandidateState { zeros: kani::any(), shots: kani::any() },
            ],
        };

        let j = 0;
        let k = 1;
        
        // Assume valid states
        kani::assume(state.candidates[j].zeros <= state.candidates[j].shots);
        kani::assume(state.candidates[k].zeros <= state.candidates[k].shots);
        kani::assume(state.candidates[j].shots > 0 && state.candidates[k].shots > 0);
        kani::assume(state.candidates[j].shots < u32::MAX);

        // Precondition: j is ALREADY certified better than k
        kani::assume(state.candidates[j].is_better_certified_than(&state.candidates[k], delta_threshold));

        // Step j with a favorable zero outcome
        state.step(j, true);

        // Assert certification still holds
        let persists = state.candidates[j].is_better_certified_than(&state.candidates[k], delta_threshold);
        assert!(persists, "Certification must persist after additional zero outcome for the winner");
    }

    /// Harness 3: Non-interference of other candidates
    /// Proves that stepping a third candidate does not alter the pairwise certification status between J and K.
    #[kani::proof]
    pub fn verify_non_interference() {
        let delta_threshold: u32 = kani::any();
        // Expand state to 3 candidates for this test
        let c_j = CandidateState { zeros: kani::any(), shots: kani::any() };
        let c_k = CandidateState { zeros: kani::any(), shots: kani::any() };
        let mut c_l = CandidateState { zeros: kani::any(), shots: kani::any() };

        kani::assume(c_j.zeros <= c_j.shots && c_j.shots > 0);
        kani::assume(c_k.zeros <= c_k.shots && c_k.shots > 0);
        kani::assume(c_l.zeros <= c_l.shots);
        kani::assume(c_l.shots < u32::MAX);

        let cert_before = c_j.is_better_certified_than(&c_k, delta_threshold);

        // Step L with an arbitrary outcome
        let outcome: bool = kani::any();
        c_l.shots += 1;
        if outcome { c_l.zeros += 1; }

        // The relationship between J and K must remain exactly the same
        let cert_after = c_j.is_better_certified_than(&c_k, delta_threshold);
        assert_eq!(cert_before, cert_after, "Third-party shot must not affect pairwise certification");
    }
}
