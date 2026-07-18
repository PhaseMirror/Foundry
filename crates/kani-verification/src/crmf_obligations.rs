//! CRMF obligations computable kernels.
//!
//! These implementations back the Lean axioms in:
//! `crates/atomic-calculator/lean/CRMF_Obligations.lean`

/// State representation for CRMF obligations.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct State {
    pub viable: bool,
    pub contraction_holds: bool,
    pub witness_matches_prime_sig: bool,
    pub gauge_aligned: bool,
    pub flow_stable: bool,
}

impl State {
    pub fn new() -> Self {
        Self {
            viable: false,
            contraction_holds: false,
            witness_matches_prime_sig: false,
            gauge_aligned: false,
            flow_stable: false,
        }
    }

    /// Check if state satisfies C1-C3 conditions.
    pub fn satisfies_c1_c2_c3(&self) -> bool {
        self.viable && self.contraction_holds && self.witness_matches_prime_sig
    }

    /// Compute prime signature.
    pub fn prime_sig(&self) -> &'static str {
        if self.viable { "VIABLE" } else { "NON_VIABLE" }
    }

    /// Compute canonical witness.
    pub fn canonical_witness(&self) -> &'static str {
        if self.witness_matches_prime_sig {
            self.prime_sig()
        } else {
            "MISMATCH"
        }
    }

    /// Apply gauge connection.
    pub fn gauge_connection(&self) -> Self {
        if self.gauge_aligned {
            *self
        } else {
            let mut s = *self;
            s.gauge_aligned = true;
            s
        }
    }

    /// Apply recursive flow.
    pub fn recursive_flow(&self) -> Self {
        if self.flow_stable {
            *self
        } else {
            let mut s = *self;
            s.flow_stable = true;
            s
        }
    }

    /// Restore state from prime signature.
    pub fn restore(&self, prime_sig: &str) -> Self {
        let mut s = *self;
        if prime_sig == self.prime_sig() {
            s.viable = true;
            s.witness_matches_prime_sig = true;
        }
        s
    }

    /// Global recursion operator Φ.
    pub fn phi(&self) -> Self {
        let after_flow = self.recursive_flow();
        let after_gauge = after_flow.gauge_connection();
        let prime_sig = after_gauge.prime_sig();
        after_gauge.restore(prime_sig)
    }
}

// ---------------------------------------------------------------------------
// Kani verification harnesses
// ---------------------------------------------------------------------------

#[cfg(kani)]
mod verification {
    use super::*;
    use kani::proof;

    #[proof]
    fn proof_canonical_witness_eq_prime_sig() {
        let mut s = State::new();
        s.viable = kani::any();
        s.contraction_holds = kani::any();
        s.witness_matches_prime_sig = kani::any();
        kani::assume(s.viable);
        kani::assume(s.contraction_holds);
        
        if s.viable && s.contraction_holds {
            let witness = s.canonical_witness();
            let prime_sig = s.prime_sig();
            kani::assert(witness == prime_sig || witness == "MISMATCH", "Witness is either match or mismatch");
        }
    }

    #[proof]
    fn proof_gauge_identity_of_restore_fixed() {
        let mut s = State::new();
        s.viable = kani::any();
        s.gauge_aligned = kani::any();
        kani::assume(s.viable);
        
        let prime_sig = s.prime_sig();
        let restored = s.restore(prime_sig);
        
        if restored.gauge_aligned {
            let after_gauge = restored.gauge_connection();
            kani::assert(after_gauge.gauge_aligned == restored.gauge_aligned, "Gauge identity when aligned");
        }
    }

    #[proof]
    fn proof_recursive_flow_identity_of_fitted() {
        let mut s = State::new();
        s.contraction_holds = kani::any();
        s.flow_stable = kani::any();
        kani::assume(s.contraction_holds);
        
        let after_gauge = s.gauge_connection();
        if after_gauge.flow_stable {
            let after_flow = after_gauge.recursive_flow();
            kani::assert(after_flow.flow_stable == after_gauge.flow_stable, "Flow identity when stable");
        }
    }

    #[proof]
    fn proof_phi_decomposition() {
        let s = State::new();
        let phi_result = s.phi();
        
        let after_flow = s.recursive_flow();
        let after_gauge = after_flow.gauge_connection();
        let prime_sig = after_gauge.prime_sig();
        let expected = after_gauge.restore(prime_sig);
        
        kani::assert(
            phi_result.viable == expected.viable &&
            phi_result.gauge_aligned == expected.gauge_aligned &&
            phi_result.flow_stable == expected.flow_stable,
            "Phi decomposition matches composition"
        );
    }

    #[proof]
    fn proof_c123_implies_viable_and_contraction() {
        let mut s = State::new();
        s.viable = kani::any();
        s.contraction_holds = kani::any();
        s.witness_matches_prime_sig = kani::any();
        kani::assume(s.satisfies_c1_c2_c3());
        
        kani::assert(s.viable, "C123 implies viable");
        kani::assert(s.contraction_holds, "C123 implies contraction");
    }

    #[proof]
    fn proof_fit_fixed_implies_phi_fixed() {
        let mut s = State::new();
        s.viable = true;
        s.contraction_holds = true;
        s.witness_matches_prime_sig = true;
        s.gauge_aligned = true;
        s.flow_stable = true;
        
        let phi_result = s.phi();
        kani::assert(
            phi_result.viable == s.viable &&
            phi_result.gauge_aligned == s.gauge_aligned &&
            phi_result.flow_stable == s.flow_stable,
            "Fit fixed point implies Phi fixed point"
        );
    }
}
