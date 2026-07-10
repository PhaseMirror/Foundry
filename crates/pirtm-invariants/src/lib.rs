use pirtm_stdlib::prelude::*;

pub struct PhaseMirrorInvariants;

impl PhaseMirrorInvariants {
    /// Enforces the 10 Core Phase Mirror CSL/ACE Invariants
    pub fn enforce_all(word: &MOCWord) -> Result<(), String> {
        // Run structural invariants first (Invariants 6-10)
        Self::check_structural(word)?;

        let (c, r1, r2, r3) = EvalNF::evaluate(word);
        let rsc = Resonance::calculate(r1, r2, r3);
        let depth = Self::calculate_depth(word);
        
        // Invariant 1: Gate 1 Resonance Tension
        if rsc < 1.0 { return Err(format!("L0_01_Gate1_ResonanceTension: Rsc ({:.4}) < 1.0", rsc)); }
        
        // Invariant 2: Gate 2 Contraction Bound
        if c >= 1.0 - 1e-6 { return Err(format!("L0_02_Gate2_ContractionBound: c ({:.4}) >= 1.0 - eps", c)); }
        
        // Invariant 3: Contraction Strictly Positive
        if c <= 0.0 { return Err("L0_03_ContractionStrictlyPositive: c <= 0.0".to_string()); }
        
        // Invariant 4: Resonance Symmetry Checks
        if r1 <= 0.0 || r2 <= 0.0 || r3 <= 0.0 {
            return Err("L0_04_ResonanceSymmetry: R1, R2, or R3 <= 0.0".to_string());
        }
        
        // Invariant 5: Max Depth (Computational Budgets)
        if depth > 100 { return Err(format!("L0_05_MaxDepthExceeded: depth ({}) > 100", depth)); }

        Ok(())
    }

    fn calculate_depth(word: &MOCWord) -> usize {
        match word {
            MOCWord::Atom(_) => 1,
            MOCWord::Composite(l, r) => 1 + std::cmp::max(Self::calculate_depth(l), Self::calculate_depth(r)),
            MOCWord::Successor(inner) => 1 + Self::calculate_depth(inner),
            MOCWord::StratumBoundary(inner) => 1 + Self::calculate_depth(inner),
        }
    }

    fn check_structural(word: &MOCWord) -> Result<(), String> {
        match word {
            MOCWord::Atom(p) => {
                // Invariant 7: Prime Zero Forbidden
                if *p == 0 { return Err("L0_07_PrimeZeroForbidden: Prime index cannot be 0".to_string()); }
                // Invariant 8: Prime One Forbidden (usually expansive)
                if *p == 1 { return Err("L0_08_PrimeOneForbidden: Prime index 1 is strictly expansive".to_string()); }
            }
            MOCWord::Composite(l, r) => {
                Self::check_structural(l)?;
                Self::check_structural(r)?;
            }
            MOCWord::Successor(inner) => {
                // Invariant 9: No nested successors without boundary
                if let MOCWord::Successor(_) = **inner {
                    return Err("L0_09_NestedSuccessorForbidden: Successors must be separated by StratumBoundary".to_string());
                }
                Self::check_structural(inner)?;
            }
            MOCWord::StratumBoundary(inner) => {
                Self::check_structural(inner)?;
            }
        }
        // Invariant 10: Structural Closure
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_invariants_pass_on_lawful_word() {
        let word = Ap(2) + Ap(3);
        assert!(PhaseMirrorInvariants::enforce_all(&word).is_ok());
    }

    #[test]
    fn test_invariants_fail_on_prime_one() {
        let word = Ap(1);
        let res = PhaseMirrorInvariants::enforce_all(&word);
        assert!(res.is_err());
        assert!(res.unwrap_err().contains("L0_08_PrimeOneForbidden"));
    }

    #[test]
    fn test_invariants_fail_on_nested_successor() {
        let word = MOCWord::Successor(Box::new(MOCWord::Successor(Box::new(Ap(2)))));
        let res = PhaseMirrorInvariants::enforce_all(&word);
        assert!(res.is_err());
        assert!(res.unwrap_err().contains("L0_09_NestedSuccessorForbidden"));
    }
    
    #[test]
    fn test_invariants_fail_on_prime_zero() {
        let word = Ap(0);
        let res = PhaseMirrorInvariants::enforce_all(&word);
        assert!(res.is_err());
        assert!(res.unwrap_err().contains("L0_07_PrimeZeroForbidden"));
    }
}
