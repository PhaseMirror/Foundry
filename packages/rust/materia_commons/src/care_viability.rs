//! Care-circle governance mirroring the semantics proved in
//! `ADR/Theorems/CareViability.lean` (Lean 4, fixed-point `N = 1024`).
//!
//! # Correctness contract
//!
//! This module is a **port**, not a proof. The authoritative semantics are the
//! Lean definitions:
//!
//! * resonance floor: `rMeanPass c := 3 * 870 <= rSum c` (mean >= 0.85)
//! * viability:       `viableE c     := 0 < eSum c`
//! * audit:           `phase_mirror_audit c := decide rMeanPass && decide viableE`
//!
//! The theorem `viable_circle_prevents_burnout` states that an audit-passing
//! circle is burnout-free *under this encoding*. This port preserves the
//! encoding exactly (same integers, same strictness), so a circle passing here
//! is one whose Lean counterpart is decided `true`. Floating point is
//! deliberately avoided: it reintroduces the imprecision the fixed-point model
//! eliminated.
//!
//! # FFI status (honest scaffold)
//!
//! There is no compiled Lean staticlib and no exported symbol yet. Wiring true
//! proof-carrying FFI requires a Lean `@[export care_viability_audit]`
//! wrapper built into a staticlib plus `build.rs` link directives; until then
//! this module is self-contained integer logic and must not be advertised as
//! calling into Lean.

/// Fixed-point scale `N = 1024`, identical to `PhaseMirror.Care.Scale`.
pub const SCALE: u32 = 1024;

/// Resonance floor `⌊0.85 · N⌋ = 870`; aggregate form is `3 * RES_FLOOR <= r_sum`.
pub const RES_FLOOR: u32 = 870;

/// Contraction factor applied when capacity is depleted (no abrupt halt).
pub const CONTRACTION_FACTOR: f64 = 0.5;

/// Vital signs of one triad in `[0, N]`, mirroring `{x : Nat // x <= Scale}`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct TriadVital {
    /// Resonance coherence, scaled by [`SCALE`].
    pub r: u16,
    /// Embodied capacity, scaled by [`SCALE`].
    pub e: u16,
}

impl TriadVital {
    /// `None` iff either component exceeds `SCALE` (the Lean subtype bound).
    pub fn new(r: u16, e: u16) -> Option<Self> {
        if u32::from(r) <= SCALE && u32::from(e) <= SCALE {
            Some(Self { r, e })
        } else {
            None
        }
    }
}

/// A care circle: exactly three triads, matching `CircleVital t0 t1 t2`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CircleVital {
    pub t0: TriadVital,
    pub t1: TriadVital,
    pub t2: TriadVital,
}

impl CircleVital {
    /// `rSum`: aggregate resonance across the three triads.
    pub fn r_sum(&self) -> u32 {
        u32::from(self.t0.r) + u32::from(self.t1.r) + u32::from(self.t2.r)
    }

    /// `eSum`: aggregate embodied capacity across the three triads.
    pub fn e_sum(&self) -> u32 {
        u32::from(self.t0.e) + u32::from(self.t1.e) + u32::from(self.t2.e)
    }

    /// Threshold 1 (v2, ADR-038) — `rEachPass`: every triad at or above
    /// [`RES_FLOOR`] individually. Integer comparisons only; averaging in
    /// floating point is deliberately avoided.
    pub fn r_each_pass(&self) -> bool {
        u32::from(self.t0.r) >= RES_FLOOR
            && u32::from(self.t1.r) >= RES_FLOOR
            && u32::from(self.t2.r) >= RES_FLOOR
    }

    /// Deprecated v1 aggregate floor (`rMeanPass`), kept solely as the
    /// provenance/parity baseline that v2 strictly strengthens.
    pub fn r_mean_v1_pass(&self) -> bool {
        3 * RES_FLOOR <= self.r_sum()
    }

    /// Threshold 2 — `viableE`: strictly positive aggregate capacity.
    pub fn viable_e(&self) -> bool {
        0 < self.e_sum()
    }

    /// Ported image of `phase_mirror_audit_v2 c = true` (ADR-038).
    pub fn audit_passes(&self) -> bool {
        self.r_each_pass() && self.viable_e()
    }
}

/// Governed response for a circle state. By design there is **no** abrupt-halt
/// branch: degraded states contract or get monitored instead.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum GovernanceAction {
    /// Audit passed (`rMeanPass ∧ viableE`): evolve.
    Evolve,
    /// Resonance holds but aggregate capacity is zero (the `depletedCircle`
    /// profile): governed contraction by [`CONTRACTION_FACTOR`].
    Contract(f64),
    /// Capacity remains but resonance dropped below floor (the
    /// `strainedCircle` profile): monitor, do not halt.
    Monitor,
    /// Both thresholds failed: escalate for intervention.
    CriticalIntervention,
}

/// Map a circle state to its governance action, mirroring the four-quadrant
/// reading of the two Lean thresholds.
pub fn evaluate_state(circle: &CircleVital) -> GovernanceAction {
    match (circle.r_each_pass(), circle.viable_e()) {
        (true, true) => GovernanceAction::Evolve,
        (true, false) => GovernanceAction::Contract(CONTRACTION_FACTOR),
        (false, true) => GovernanceAction::Monitor,
        (false, false) => GovernanceAction::CriticalIntervention,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn healthy() -> CircleVital {
        CircleVital {
            t0: TriadVital::new(900, 700).unwrap(),
            t1: TriadVital::new(880, 640).unwrap(),
            t2: TriadVital::new(910, 760).unwrap(),
        }
    }

    fn strained() -> CircleVital {
        CircleVital {
            t0: TriadVital::new(800, 400).unwrap(),
            t1: TriadVital::new(790, 380).unwrap(),
            t2: TriadVital::new(810, 420).unwrap(),
        }
    }

    fn depleted() -> CircleVital {
        CircleVital {
            t0: TriadVital::new(900, 0).unwrap(),
            t1: TriadVital::new(880, 0).unwrap(),
            t2: TriadVital::new(910, 0).unwrap(),
        }
    }

    /// Parity with `example : phase_mirror_audit healthyCircle = true`.
    #[test]
    fn healthy_passes_and_evolves() {
        assert!(healthy().audit_passes());
        assert_eq!(evaluate_state(&healthy()), GovernanceAction::Evolve);
    }

    /// Parity with `example : phase_mirror_audit strainedCircle = false` and
    /// `¬ rMeanPass strainedCircle` (sum 2400 < 2610).
    #[test]
    fn strained_fails_resonance_only() {
        let s = strained();
        assert!(!s.audit_passes());
        assert!(!s.r_each_pass());
        assert!(s.viable_e());
        assert_eq!(evaluate_state(&s), GovernanceAction::Monitor);
    }

    /// Parity with `example : phase_mirror_audit depletedCircle = false` and
    /// `rMeanPass depletedCircle`: identical resonance to `healthy`, zero
    /// aggregate capacity — non-vacuity witness on both sides of the bridge.
    #[test]
    fn depleted_fails_viability_only() {
        let d = depleted();
        assert!(!d.audit_passes());
        assert!(d.r_each_pass());
        assert!(!d.viable_e());
        assert_eq!(
            evaluate_state(&d),
            GovernanceAction::Contract(CONTRACTION_FACTOR)
        );
    }

    /// The subtype bound is enforced at construction, like `{x // x ≤ Scale}`.
    #[test]
    fn out_of_range_rejected() {
        assert!(TriadVital::new(u16::MAX, 0).is_none());
        assert!(TriadVital::new(SCALE as u16, SCALE as u16).is_some());
    }

    /// Parity with `mixedCircle` (ADR-038): v1 aggregate mean passes
    /// (`2917 >= 2610`) while v2 per-triad fails (`869 < 870`).
    #[test]
    fn mixed_fails_v2_but_passed_v1() {
        let m = CircleVital {
            t0: TriadVital::new(1024, 700).unwrap(),
            t1: TriadVital::new(869, 640).unwrap(),
            t2: TriadVital::new(1024, 760).unwrap(),
        };
        assert!(!m.audit_passes());
        assert!(!m.r_each_pass());
        assert!(m.r_mean_v1_pass());
        assert_eq!(evaluate_state(&m), GovernanceAction::Monitor);
    }
}
