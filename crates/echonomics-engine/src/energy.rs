//! # echonomics_engine::energy — ADR-0004: Period-0 Energy Ledger Schema & Ground State Minimization
//!
//! Separated-ledger tracking of pairwise friction `V_pair` and nuclear purpose
//! attraction `V_nuc`, with total energy `E = V_pair - V_nuc` and ground-state
//! minimization at fixed N, D, P — independent of multiplicity M.
//!
//! Pure, side-effect-free functions over `u64`/`i64` (no hashing, no
//! allocation) so Kani can discharge them symbolically. The stateful
//! `EnergyLedgerState` engine delegates to the same pure core.

use serde::{Deserialize, Serialize};

/// Total system energy `E = V_pair - V_nuc` (i64 sign convention).
#[inline]
pub const fn calculate_total_energy(v_pair: u64, v_nuc: u64) -> i64 {
    v_pair as i64 - v_nuc as i64
}

/// Decision 1 (Separated-Ledger Mandate): the two ledgers are separated
/// exactly when `V_pair != V_nuc`.
#[inline]
pub const fn ledgers_separated(v_pair: u64, v_nuc: u64) -> bool {
    v_pair != v_nuc
}

/// Decision 3: pairwise ground state — `a` is a ground state over `b` iff
/// `E(a) <= E(b)`.
#[inline]
pub const fn is_ground_state(a_v_pair: u64, a_v_nuc: u64, b_v_pair: u64, b_v_nuc: u64) -> bool {
    calculate_total_energy(a_v_pair, a_v_nuc) <= calculate_total_energy(b_v_pair, b_v_nuc)
}

/// Binary energy-min selector used to fold toward a minimum.
#[inline]
pub const fn min_energy_pair(a_v_pair: u64, a_v_nuc: u64, b_v_pair: u64, b_v_nuc: u64) -> (u64, u64) {
    if calculate_total_energy(a_v_pair, a_v_nuc) <= calculate_total_energy(b_v_pair, b_v_nuc) {
        (a_v_pair, a_v_nuc)
    } else {
        (b_v_pair, b_v_nuc)
    }
}

/// Right fold selecting a minimum-energy state from a slice of (v_pair, v_nuc)
/// pairs. Returns the zero ledger on an empty slice.
pub fn min_of_states(states: &[(u64, u64)]) -> (u64, u64) {
    let mut best = (0u64, 0u64);
    let mut first = true;
    for &(vp, vn) in states {
        if first {
            best = (vp, vn);
            first = false;
        } else {
            best = min_energy_pair(best.0, best.1, vp, vn);
        }
    }
    best
}

/// Stateful engine that delegates to the pure energy core.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct EnergyLedgerState {
    pub v_pair: u64,
    pub v_nuc: u64,
}

/// Decision 3: a fixed physical frame in which the ground state is sought —
/// headcount `N`, degenerate role set size `D`, and period `P`. The ground
/// state minimizes `E = V_pair - V_nuc` within a frame.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct LedgerFrame {
    pub headcount: u64,          // fixed N
    pub degenerate_set_size: u64, // fixed D
    pub period: u64,             // fixed P
}

impl LedgerFrame {
    pub const fn new(headcount: u64, degenerate_set_size: u64, period: u64) -> Self {
        Self { headcount, degenerate_set_size, period }
    }
}

/// An occupancy pattern: a separated-ledger energy state plus its raw Hundian
/// multiplicity `M = n_unpaired + 1`. Multiplicity is recorded only so the
/// code can *prove* the ground state never depends on it.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct Occupancy {
    pub v_pair: u64,
    pub v_nuc: u64,
    pub multiplicity: u64,
}

impl Occupancy {
    pub const fn new(v_pair: u64, v_nuc: u64, multiplicity: u64) -> Self {
        Self { v_pair, v_nuc, multiplicity }
    }

    pub fn energy(&self) -> i64 {
        calculate_total_energy(self.v_pair, self.v_nuc)
    }
}

/// Decision 3 (independence of raw multiplicity `M`): a multiplicity-blind
/// ground-state selector over occupancies — it consults the ledger energy
/// exclusively and ignores the recorded multiplicity.
#[inline]
pub const fn adopt_ground_state(a: &Occupancy, b: &Occupancy) -> Occupancy {
    if calculate_total_energy(a.v_pair, a.v_nuc) <= calculate_total_energy(b.v_pair, b.v_nuc) {
        *a
    } else {
        *b
    }
}

/// Decision 3: two occupancies whose ledgers share the same total energy are
/// mutually ground states — regardless of their raw multiplicities `M`.
#[inline]
pub const fn ground_state_ignores_multiplicity(a: &Occupancy, b: &Occupancy) -> bool {
    // If energies are equal, each is a ground state of the other.
    (calculate_total_energy(a.v_pair, a.v_nuc) <= calculate_total_energy(b.v_pair, b.v_nuc))
        && (calculate_total_energy(b.v_pair, b.v_nuc) <= calculate_total_energy(a.v_pair, a.v_nuc))
}

impl EnergyLedgerState {
    pub fn new(v_pair: u64, v_nuc: u64) -> Self {
        Self { v_pair, v_nuc }
    }

    pub fn calculate_total_energy(&self) -> i64 {
        calculate_total_energy(self.v_pair, self.v_nuc)
    }

    pub fn is_ground_state(&self, other: &EnergyLedgerState) -> bool {
        is_ground_state(self.v_pair, self.v_nuc, other.v_pair, other.v_nuc)
    }

    pub fn ledgers_separated(&self) -> bool {
        ledgers_separated(self.v_pair, self.v_nuc)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_energy_ledger_ground_state() {
        let e1 = EnergyLedgerState::new(10, 15);
        let e2 = EnergyLedgerState::new(12, 8);

        assert_eq!(e1.calculate_total_energy(), -5);
        assert_eq!(e2.calculate_total_energy(), 4);
        assert!(e1.is_ground_state(&e2));
    }

    #[test]
    fn test_separated_ledger_mandate() {
        // V_pair != V_nuc -> separated
        assert!(ledgers_separated(5, 2));
        assert!(!ledgers_separated(5, 5));
        assert!(EnergyLedgerState::new(10, 3).ledgers_separated());
    }

    #[test]
    fn test_energy_monotonicity() {
        // increasing V_nuc lowers energy
        assert!(calculate_total_energy(10, 5) > calculate_total_energy(10, 7));
        // increasing V_pair raises energy
        assert!(calculate_total_energy(5, 3) < calculate_total_energy(8, 3));
    }

    #[test]
    fn test_ground_state_antisymm() {
        // identical energies -> mutual ground states
        let a = EnergyLedgerState::new(10, 4);
        let b = EnergyLedgerState::new(8, 2);
        assert_eq!(a.calculate_total_energy(), b.calculate_total_energy());
        assert!(a.is_ground_state(&b));
        assert!(b.is_ground_state(&a));
    }

    #[test]
    fn test_min_energy_pair() {
        // E(10,15)=-5 < E(12,8)=4 -> picks the lower-energy (10,15)
        assert_eq!(min_energy_pair(10, 15, 12, 8), (10, 15));
        // tie on energy -> keeps first
        assert_eq!(min_energy_pair(1, 1, 5, 5), (1, 1));
        // picks (12,8) when it has lower energy than (4,4): E=4 vs E=0 -> no,
        // E(12,8)=4 > E(4,4)=0 -> picks (4,4)
        assert_eq!(min_energy_pair(12, 8, 4, 4), (4, 4));
    }

    #[test]
    fn test_min_of_states() {
        let states = [(10u64, 15u64), (12u64, 8u64), (3u64, 10u64)];
        // energies: -5, 4, -7 -> min is -7 at (3,10)
        assert_eq!(min_of_states(&states), (3, 10));
        // empty -> zero ledger
        assert_eq!(min_of_states(&[]), (0, 0));
    }

    #[test]
    fn test_min_of_list_correct_picks_global_min() {
        let states = [(5u64, 2u64), (9u64, 1u64), (4u64, 4u64)];
        // energies: 3, 8, 0 -> min is 0 at (4,4)
        let (vp, vn) = min_of_states(&states);
        assert_eq!((vp, vn), (4, 4));
        assert_eq!(calculate_total_energy(vp, vn), 0);
    }

    #[test]
    fn test_ledger_frame_well_defined() {
        let frame = LedgerFrame::new(5, 3, 1);
        assert_eq!(frame.headcount, 5);
        assert_eq!(frame.degenerate_set_size, 3);
        assert_eq!(frame.period, 1);
        // ground state well-defined (a minimizer exists) within the frame
        let states = [(3u64, 10u64), (12u64, 8u64), (5u64, 2u64)];
        let (vp, vn) = min_of_states(&states);
        assert_eq!(calculate_total_energy(vp, vn), -7);
        let _ = frame;
    }

    #[test]
    fn test_ground_state_ignores_multiplicity() {
        // Same ledger energy (E = 6) with different raw multiplicities M
        let occ_a = Occupancy::new(10, 4, 2);
        let occ_b = Occupancy::new(9, 3, 7);
        assert_eq!(occ_a.energy(), occ_b.energy());
        assert!(ground_state_ignores_multiplicity(&occ_a, &occ_b));
    }

    #[test]
    fn test_adopt_ground_state_picks_lower_energy_ignoring_multiplicity() {
        // a: E(10,15) = -5, b: E(12,8) = +4 -> picks a despite b's larger M
        let a = Occupancy::new(10, 15, 2);
        let b = Occupancy::new(12, 8, 100);
        let g = adopt_ground_state(&a, &b);
        assert_eq!(g.v_pair, 10);
        assert_eq!(g.v_nuc, 15);
        assert_eq!(g.multiplicity, 2);
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    // Ground state soundness: if a is ground state over b, its energy is no
    // higher.
    #[kani::proof]
    fn verify_ground_state_energy_le() {
        let vp_a: u64 = kani::any();
        let vn_a: u64 = kani::any();
        let vp_b: u64 = kani::any();
        let vn_b: u64 = kani::any();
        kani::assume(vp_a <= i64::MAX as u64);
        kani::assume(vn_a <= i64::MAX as u64);
        kani::assume(vp_b <= i64::MAX as u64);
        kani::assume(vn_b <= i64::MAX as u64);
        kani::assume(is_ground_state(vp_a, vn_a, vp_b, vn_b));
        kani::assert(
            calculate_total_energy(vp_a, vn_a) <= calculate_total_energy(vp_b, vn_b),
            "Ground state must have no higher energy",
        );
    }

    // Ground state completeness: energy <= implies ground state.
    #[kani::proof]
    fn verify_energy_le_implies_ground_state() {
        let vp_a: u64 = kani::any();
        let vn_a: u64 = kani::any();
        let vp_b: u64 = kani::any();
        let vn_b: u64 = kani::any();
        kani::assume(vp_a <= i64::MAX as u64);
        kani::assume(vn_a <= i64::MAX as u64);
        kani::assume(vp_b <= i64::MAX as u64);
        kani::assume(vn_b <= i64::MAX as u64);
        kani::assume(calculate_total_energy(vp_a, vn_a) <= calculate_total_energy(vp_b, vn_b));
        kani::assert(is_ground_state(vp_a, vn_a, vp_b, vn_b), "Lower energy must be a ground state");
    }

    // Energy reflexivity: every state is its own ground state.
    #[kani::proof]
    fn verify_ground_state_refl() {
        let vp: u64 = kani::any();
        let vn: u64 = kani::any();
        kani::assume(vp <= i64::MAX as u64);
        kani::assume(vn <= i64::MAX as u64);
        kani::assert(is_ground_state(vp, vn, vp, vn), "Reflexivity of ground state");
    }

    // Energy antisymmetry: mutual ground states have equal energy.
    #[kani::proof]
    fn verify_ground_state_antisymm() {
        let vp_a: u64 = kani::any();
        let vn_a: u64 = kani::any();
        let vp_b: u64 = kani::any();
        let vn_b: u64 = kani::any();
        kani::assume(vp_a <= i64::MAX as u64);
        kani::assume(vn_a <= i64::MAX as u64);
        kani::assume(vp_b <= i64::MAX as u64);
        kani::assume(vn_b <= i64::MAX as u64);
        kani::assume(is_ground_state(vp_a, vn_a, vp_b, vn_b));
        kani::assume(is_ground_state(vp_b, vn_b, vp_a, vn_a));
        kani::assert(
            calculate_total_energy(vp_a, vn_a) == calculate_total_energy(vp_b, vn_b),
            "Mutual ground states must have equal energy",
        );
    }

    // Energy monotonicity in V_nuc: increasing attraction lowers energy.
    #[kani::proof]
    fn verify_nuc_monotonicity() {
        let vp: u64 = kani::any();
        let vn1: u64 = kani::any();
        let vn2: u64 = kani::any();
        kani::assume(vp <= i64::MAX as u64);
        kani::assume(vn1 <= i64::MAX as u64);
        kani::assume(vn2 <= i64::MAX as u64);
        kani::assume(vn1 <= vn2);
        kani::assert(
            calculate_total_energy(vp, vn2) <= calculate_total_energy(vp, vn1),
            "Higher V_nuc must not raise energy",
        );
    }

    // Energy monotonicity in V_pair: increasing friction raises energy.
    #[kani::proof]
    fn verify_pair_monotonicity() {
        let vn: u64 = kani::any();
        let vp1: u64 = kani::any();
        let vp2: u64 = kani::any();
        kani::assume(vn <= i64::MAX as u64);
        kani::assume(vp1 <= i64::MAX as u64);
        kani::assume(vp2 <= i64::MAX as u64);
        kani::assume(vp1 <= vp2);
        kani::assert(
            calculate_total_energy(vp1, vn) <= calculate_total_energy(vp2, vn),
            "Higher V_pair must not lower energy",
        );
    }

    // Min-pair selector never increases energy vs either input.
    #[kani::proof]
    fn verify_min_pair_le_either() {
        let vp_a: u64 = kani::any();
        let vn_a: u64 = kani::any();
        let vp_b: u64 = kani::any();
        let vn_b: u64 = kani::any();
        kani::assume(vp_a <= i64::MAX as u64);
        kani::assume(vn_a <= i64::MAX as u64);
        kani::assume(vp_b <= i64::MAX as u64);
        kani::assume(vn_b <= i64::MAX as u64);
        let (mp, mn) = min_energy_pair(vp_a, vn_a, vp_b, vn_b);
        kani::assert(
            calculate_total_energy(mp, mn) <= calculate_total_energy(vp_a, vn_a),
            "Min selector energy <= A",
        );
        kani::assert(
            calculate_total_energy(mp, mn) <= calculate_total_energy(vp_b, vn_b),
            "Min selector energy <= B",
        );
    }

    // Decision 3: ground state is independent of raw multiplicity M. Two
    // occupancies with equal ledger energy — but arbitrary raw multiplicities —
    // are mutually ground states.
    #[kani::proof]
    fn verify_ground_state_ignores_multiplicity() {
        let vp_a: u64 = kani::any();
        let vn_a: u64 = kani::any();
        let vp_b: u64 = kani::any();
        let vn_b: u64 = kani::any();
        // multiplicity is symbolic and unconstrained
        let m_a: u64 = kani::any();
        let m_b: u64 = kani::any();
        kani::assume(vp_a <= i64::MAX as u64);
        kani::assume(vn_a <= i64::MAX as u64);
        kani::assume(vp_b <= i64::MAX as u64);
        kani::assume(vn_b <= i64::MAX as u64);
        kani::assume(calculate_total_energy(vp_a, vn_a) == calculate_total_energy(vp_b, vn_b));
        let a = Occupancy::new(vp_a, vn_a, m_a);
        let b = Occupancy::new(vp_b, vn_b, m_b);
        // energy equality forces a mutually ground-state independent of M
        kani::assert(is_ground_state(a.v_pair, a.v_nuc, b.v_pair, b.v_nuc), "a GS over b (M-blind)");
        kani::assert(is_ground_state(b.v_pair, b.v_nuc, a.v_pair, a.v_nuc), "b GS over a (M-blind)");
    }

    // Decision 3: the ground-state selector chooses the lower-energy ledger
    // and never lets the recorded multiplicity overturn that decision.
    #[kani::proof]
    fn verify_adopt_ground_state_energy_min() {
        let vp_a: u64 = kani::any();
        let vn_a: u64 = kani::any();
        let vp_b: u64 = kani::any();
        let vn_b: u64 = kani::any();
        let m_a: u64 = kani::any();
        let m_b: u64 = kani::any();
        kani::assume(vp_a <= i64::MAX as u64);
        kani::assume(vn_a <= i64::MAX as u64);
        kani::assume(vp_b <= i64::MAX as u64);
        kani::assume(vn_b <= i64::MAX as u64);
        let a = Occupancy::new(vp_a, vn_a, m_a);
        let b = Occupancy::new(vp_b, vn_b, m_b);
        let g = adopt_ground_state(&a, &b);
        kani::assert(
            g.energy() <= calculate_total_energy(vp_a, vn_a),
            "adopted ground state no higher energy than A",
        );
        kani::assert(
            g.energy() <= calculate_total_energy(vp_b, vn_b),
            "adopted ground state no higher energy than B",
        );
    }

    // Decision 3: energy is a total, multiplicity-blind function — for the
    // same ledger the same energy is returned for every multiplicity.
    #[kani::proof]
    fn verify_energy_multiplicity_invariant() {
        let vp: u64 = kani::any();
        let vn: u64 = kani::any();
        let m1: u64 = kani::any();
        let m2: u64 = kani::any();
        kani::assume(vp <= i64::MAX as u64);
        kani::assume(vn <= i64::MAX as u64);
        let occ1 = Occupancy::new(vp, vn, m1);
        let occ2 = Occupancy::new(vp, vn, m2);
        kani::assert(occ1.energy() == occ2.energy(), "energy ignores multiplicity M");
    }
}
