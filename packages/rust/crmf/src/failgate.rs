//! UCC fail-closed interlocks for ADR-0013.
//!
//! ADR-0013 §"Fail-Closed Interlocks": any unmodeled associator defect
//! (`‖Δ‖ > ε`) or expansive transition automatically triggers a non-maskable
//! `SIG_GOV_KILL` (`L0_HALT`) before unverified side effects materialize.
//!
//! This module provides the two pure gates that constitute the L0
//! gatekeeper:
//! - the **contractivity gate**: accept iff `Λ_m < 1` (fixed-point scaled);
//! - the **fail latch**: a non-maskable kill latch that never un-halts.

/// Fixed-point scale for the contractivity invariant `Λ_m`. A sealed
/// `lambda_m` value must satisfy `lambda_m < CONTRACTIVITY_SCALE`.
pub const CONTRACTIVITY_SCALE: u64 = 1_000_000_000;

/// Scaled associator-defect bound `ε`. A measured norm `‖Δ‖` is a defect
/// exactly when `‖Δ‖ > ε` (ADR-0013 §"Fail-Closed Interlocks").
pub const ASSOCIATOR_EPSILON_SCALED: u64 = 1;

/// The governance signal emitted by the fail latch.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum GovSignal {
    Nominal,
    SigGovKill,
}

impl GovSignal {
    #[inline]
    pub const fn is_kill(&self) -> bool {
        matches!(self, GovSignal::SigGovKill)
    }
}

/// Contractivity gate. A proposed transition clears the Kiln gate exactly when
/// the fixed-point contractivity invariant satisfies `Λ_m < 1`.
#[inline]
pub const fn is_contractive(lambda_m_scaled: u64) -> bool {
    lambda_m_scaled < CONTRACTIVITY_SCALE
}

/// Associator-defect predicate. `‖Δ‖` measured in the same fixed-point scaling.
#[inline]
pub const fn is_associator_defect(norm_scaled: u64) -> bool {
    norm_scaled > ASSOCIATOR_EPSILON_SCALED
}

/// Non-maskable fail-closed latch.
///
/// Invariants (proved by the Kani harnesses in this module and the Lean mirror
/// in `lean/MTPI/ADR0013.lean`):
/// - **fail-closed:** a defect or expansive flag always produces `SigGovKill`
///   and latches the latch;
/// - **no un-halt:** once killed, every subsequent commit stays `SigGovKill`;
/// - **no false kills:** with no prior kill, no defect and no expansion, the
///   commit is `Nominal`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct FailLatch {
    killed: bool,
}

impl FailLatch {
    pub const fn new() -> Self {
        Self { killed: false }
    }

    #[inline]
    pub const fn is_killed(&self) -> bool {
        self.killed
    }

    /// Commit a proposed transition's verdict to the latch.
    ///
    /// `associator_defect` is `is_associator_defect(‖Δ‖)`; `expansive`
    /// reports an unauthorized recursion escalation or forbidden prime channel
    /// (ADR-0013 §"Integration with the Universal Closure Calculator").
    pub fn commit(&mut self, associator_defect: bool, expansive: bool) -> GovSignal {
        if self.killed || associator_defect || expansive {
            self.killed = true;
            GovSignal::SigGovKill
        } else {
            GovSignal::Nominal
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn contractivity_gate_threshold_adr_0013() {
        assert!(is_contractive(CONTRACTIVITY_SCALE - 1));
        assert!(!is_contractive(CONTRACTIVITY_SCALE));
        assert!(!is_contractive(u64::MAX));
    }

    #[test]
    fn associator_defect_threshold_adr_0013() {
        assert!(!is_associator_defect(ASSOCIATOR_EPSILON_SCALED));
        assert!(is_associator_defect(ASSOCIATOR_EPSILON_SCALED + 1));
    }

    #[test]
    fn fail_closed_defect_triggers_kill_adr_0013() {
        let mut latch = FailLatch::new();
        assert_eq!(
            latch.commit(is_associator_defect(2), false),
            GovSignal::SigGovKill
        );
        assert!(latch.is_killed());
    }

    #[test]
    fn fail_closed_expansion_triggers_kill_adr_0013() {
        let mut latch = FailLatch::new();
        assert_eq!(latch.commit(false, true), GovSignal::SigGovKill);
        assert!(latch.is_killed());
    }

    #[test]
    fn nominal_transition_does_not_kill_adr_0013() {
        let mut latch = FailLatch::new();
        assert_eq!(latch.commit(false, false), GovSignal::Nominal);
        assert!(!latch.is_killed());
    }

    #[test]
    fn latch_never_unhalts_adr_0013() {
        let mut latch = FailLatch::new();
        let _ = latch.commit(true, false);
        assert!(latch.is_killed());
        // Further nominals no longer rescue the system.
        let _ = latch.commit(false, false);
        assert!(latch.is_killed());
        assert_eq!(latch.commit(false, false), GovSignal::SigGovKill);
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    /// The contractivity gate never admits `Λ_m ≥ 1`.
    #[kani::proof]
    pub fn contractivity_gate_rejects_at_or_above_scale() {
        let v: u64 = kani::any();
        kani::assume(v >= CONTRACTIVITY_SCALE);
        assert!(!is_contractive(v));
    }

    /// A defect (`‖Δ‖ > ε`) always produces a kill, regardless of the
    /// expansion flag: the interlock is fail-closed.
    #[kani::proof]
    pub fn defect_or_expansion_always_kills() {
        let defect: bool = kani::any();
        let expansive: bool = kani::any();
        let mut latch = FailLatch::new();
        kani::assume(defect || expansive);
        assert!(latch.commit(defect, expansive) == GovSignal::SigGovKill);
        assert!(latch.is_killed());
    }

    /// No false kills: nominal commits stay nominal on a fresh latch.
    #[kani::proof]
    pub fn nominal_commit_does_not_kill() {
        let mut latch = FailLatch::new();
        assert!(latch.commit(false, false) == GovSignal::Nominal);
        assert!(!latch.is_killed());
    }

    /// The latch never un-halts: once killed, every further commit (any input)
    /// reports `SigGovKill` and keeps the latch killed.
    #[kani::proof]
    pub fn latch_never_unhalts() {
        let d0: bool = kani::any();
        let e0: bool = kani::any();
        let d1: bool = kani::any();
        let e1: bool = kani::any();
        let mut latch = FailLatch::new();
        let first = latch.commit(d0, e0);
        if first == GovSignal::SigGovKill {
            assert!(latch.is_killed());
            assert!(latch.commit(d1, e1) == GovSignal::SigGovKill);
            assert!(latch.is_killed());
        }
    }

    /// A kill is warranted: it implies prior kill, defect, or expansion.
    #[kani::proof]
    pub fn kill_requires_evidence() {
        let defect: bool = kani::any();
        let expansive: bool = kani::any();
        let mut latch = FailLatch::new();
        let sig = latch.commit(defect, expansive);
        if sig == GovSignal::SigGovKill {
            assert!(defect || expansive);
        } else {
            assert!(!defect && !expansive);
        }
    }
}