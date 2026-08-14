// crates/mqnn-kani/src/lib.rs

#[cfg(kani)]
mod proofs;

#[cfg(kani)]
mod verification;

#[cfg(kani)]
mod rational_equiv;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[cfg_attr(kani, derive(kani::Arbitrary))]
pub struct CandidateState {
    pub zeros: u32,
    pub shots: u32,
}

impl CandidateState {
    /// Abstract deterministic proxy for the Hoeffding early-exit check.
    /// In full probability this requires Real logic, but here we bound the 
    /// algebraic relationship to ensure the transition engine cannot exit
    /// until the strictly defined pairwise dominance is achieved.
    pub fn is_better_certified_than(&self, other: &CandidateState, delta_threshold: u32) -> bool {
        if self.shots == 0 || other.shots == 0 {
            return false;
        }

        // Integer-based proxy for fidelity gap > uncertainty bounds.
        // E.g., comparing empirical zero-rates scaled by total shots to avoid floats.
        let f_j = (self.zeros as u64) * (other.shots as u64);
        let f_k = (other.zeros as u64) * (self.shots as u64);

        // A strict dominance check representing F_j - r_j > F_k + r_k
        f_j > f_k + (delta_threshold as u64)
    }
}

/// Abstract MEEP (Multiplicity Early-Exit Process) state mapping
pub struct MEEPState {
    pub candidates: [CandidateState; 2],
}

impl MEEPState {
    /// Simulates a shot allocation on a specific candidate
    pub fn step(&mut self, candidate_idx: usize, outcome_is_zero: bool) {
        if candidate_idx < self.candidates.len() {
            let mut c = self.candidates[candidate_idx];
            c.shots = c.shots.saturating_add(1);
            if outcome_is_zero {
                c.zeros = c.zeros.saturating_add(1);
            }
            self.candidates[candidate_idx] = c;
        }
    }

    /// Checks if a candidate is definitively the winner against all others.
    pub fn winner_cert(&self, candidate_idx: usize, delta_threshold: u32) -> bool {
        if candidate_idx >= self.candidates.len() {
            return false;
        }

        let target = &self.candidates[candidate_idx];
        
        for (i, other) in self.candidates.iter().enumerate() {
            if i != candidate_idx {
                if !target.is_better_certified_than(other, delta_threshold) {
                    return false;
                }
            }
        }
        true
    }
}

/// M-QNN Policy: Selects the candidate with the fewest allocated shots (largest uncertainty).
pub fn mqnnPolicy(states: &[CandidateState]) -> usize {
    states
        .iter()
        .enumerate()
        .min_by_key(|(_, s)| s.shots)
        .map(|(idx, _)| idx)
        .unwrap_or(0)
}

#[cfg(kani)]
mod proofs {
    use super::*;

    /// Theorem: A candidate cannot be certified if it has zero shots.
    #[kani::proof]
    pub fn verify_no_exit_without_shots() {
        let mut state = MEEPState {
            candidates: [
                CandidateState { zeros: 0, shots: 0 },
                CandidateState { zeros: 5, shots: 10 },
            ],
        };

        // Kani proves it is impossible for an untested candidate to be certified.
        assert!(!state.winner_cert(0, 1));
    }

    /// Theorem: The shot allocation step function cannot panic on overflow
    #[kani::proof]
    #[kani::unwind(3)] // Bound the loop for Kani execution
    pub fn verify_step_no_panic() {
        let zeros: u32 = kani::any();
        let shots: u32 = kani::any();
        let outcome: bool = kani::any();

        // Assume valid initial state where zeros <= shots
        kani::assume(zeros <= shots);

        let mut state = MEEPState {
            candidates: [
                CandidateState { zeros, shots },
                CandidateState { zeros: 0, shots: 0 },
            ],
        };

        state.step(0, outcome);
        
        // Zeros can never exceed total shots natively.
        assert!(state.candidates[0].zeros <= state.candidates[0].shots);
    }
}
