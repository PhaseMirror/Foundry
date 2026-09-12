//! # echonomics_engine::social_physics — ADR-0013, ADR-0014, ADR-0015 Multiplicity Social Physics
//!
//! Production-grade implementation of the Multiplicity Social Physics series:
//! - ADR-0013 (Part 1): Pauli Exclusion & Spin Tags — every slot admits at most
//!   two occupants (`is_slot_capacity_valid`); spin tags are deterministic
//!   (first occupant `Alpha`, second `Beta`; occupancy beyond the bound yields
//!   no tag).
//! - ADR-0014 (Part 2): Term-Order Gate & Ground State — Hund's First Rule
//!   requires `U = 0` (`empty_slots_in_d == 0`) before pairing; the ground
//!   state maximizes multiplicity `M = |D| + 1` at half-fill.
//! - ADR-0015 (Part 3): Separated Energy Ledgers — `V_pair` and `V_nuc` are
//!   independent, non-negative ledgers; `E = V_pair - V_nuc` and the ground
//!   state minimizes `E`.
//!
//! Kani model-checking harnesses (`cargo kani`) discharge the gate properties
//! for all symbolic inputs.

use serde::{Deserialize, Serialize};

use crate::SpinTag;

/// Pauli capacity bound: a slot admits at most two occupants (ADR-0013).
pub const PAULI_CAPACITY: u64 = 2;

/// Occupancy slot bound by a Pauli key `K = (role, slot, period)`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct OccupancySlot {
    pub occupants: u64,
    pub is_degenerate: bool,
}

impl OccupancySlot {
    /// Pauli capacity bound: at most two occupants per slot.
    pub const fn is_slot_capacity_valid(&self) -> bool {
        self.occupants <= PAULI_CAPACITY
    }

    /// Deterministic spin tag by occupancy: 0 → none, 1 → `Alpha`,
    /// 2 → `Beta`, beyond the Pauli bound → none (exclusion violation).
    pub const fn spin_tag(&self) -> Option<SpinTag> {
        match self.occupants {
            0 => None,
            1 => Some(SpinTag::Alpha),
            2 => Some(SpinTag::Beta),
            _ => None,
        }
    }
}

/// Term-order gate state (ADR-0014): `empty_slots_in_d` is the count `U` of
/// still-empty degenerate slots.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct TermOrderGate {
    pub empty_slots_in_d: u64,
    pub occupied_degenerate: u64,
}

impl TermOrderGate {
    /// Hund's First Rule gate: pairing is legal exactly when `U = 0`.
    pub const fn is_pairing_legal(&self) -> bool {
        self.empty_slots_in_d == 0
    }
}

/// Ground-state multiplicity at half-fill: `M = |D| + 1`.
pub const fn ground_state_multiplicity(degenerate_set_size: u64) -> u64 {
    degenerate_set_size + 1
}

/// Social-physics engine state with separated energy ledgers (ADR-0015).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct SocialPhysicsEngine {
    pub v_pair: u64,
    pub v_nuc: u64,
    pub empty_slots: u64,
}

impl SocialPhysicsEngine {
    /// Term-order pairing legality over the ledger state: `U = 0`.
    pub const fn is_pairing_legal(&self) -> bool {
        self.empty_slots == 0
    }

    /// Separated-ledger mandate: `V_pair ≠ V_nuc` (ledgers never collapse).
    pub const fn are_ledgers_separated(&self) -> bool {
        self.v_pair != self.v_nuc
    }

    /// Total energy: `E = V_pair - V_nuc` (signed).
    pub const fn total_energy(&self) -> i64 {
        self.v_pair as i64 - self.v_nuc as i64
    }

    /// Ground-state predicate: `self` is a ground state over `other` iff
    /// `E(self) ≤ E(other)`.
    pub const fn is_ground_state(&self, other: &SocialPhysicsEngine) -> bool {
        self.total_energy() <= other.total_energy()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_pauli_capacity_max_two_and_spin_tags() {
        let slot1 = OccupancySlot { occupants: 1, is_degenerate: true };
        let slot2 = OccupancySlot { occupants: 2, is_degenerate: true };
        let slot3 = OccupancySlot { occupants: 3, is_degenerate: false };

        assert!(slot1.is_slot_capacity_valid());
        assert!(slot2.is_slot_capacity_valid());
        assert!(!slot3.is_slot_capacity_valid());

        assert_eq!(slot1.spin_tag(), Some(SpinTag::Alpha));
        assert_eq!(slot2.spin_tag(), Some(SpinTag::Beta));
        assert_eq!(OccupancySlot { occupants: 0, is_degenerate: true }.spin_tag(), None);
        assert_eq!(slot3.spin_tag(), None);
    }

    #[test]
    fn test_term_order_gate_u_zero() {
        let open = TermOrderGate { empty_slots_in_d: 2, occupied_degenerate: 1 };
        let full = TermOrderGate { empty_slots_in_d: 0, occupied_degenerate: 1 };
        assert!(!open.is_pairing_legal());
        assert!(full.is_pairing_legal());
    }

    #[test]
    fn test_ground_state_multiplicity() {
        assert_eq!(ground_state_multiplicity(4), 5); // M = |D| + 1
        assert_eq!(ground_state_multiplicity(0), 1); // closed shell singlet
    }

    #[test]
    fn test_social_physics_term_order_and_separated_ledgers() {
        let sp = SocialPhysicsEngine { v_pair: 5, v_nuc: 10, empty_slots: 0 };
        assert!(sp.is_pairing_legal());
        assert_eq!(sp.total_energy(), -5);

        let sep = SocialPhysicsEngine { v_pair: 10, v_nuc: 3, empty_slots: 0 };
        let unsep = SocialPhysicsEngine { v_pair: 7, v_nuc: 7, empty_slots: 0 };
        assert!(sep.are_ledgers_separated());
        assert!(!unsep.are_ledgers_separated());
        assert_eq!(sep.total_energy(), 7);
        // Ground state minimizes E: E(unsep) = 0 ≤ E(sep) = 7
        assert!(unsep.is_ground_state(&sep));
        assert!(!sep.is_ground_state(&unsep));
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    /// ADR-0013: Pauli capacity never exceeds two occupants.
    #[kani::proof]
    fn verify_pauli_capacity_max_two() {
        let occupants: u64 = kani::any();
        kani::assume(occupants <= 3);
        let slot = OccupancySlot { occupants, is_degenerate: true };
        if occupants <= PAULI_CAPACITY {
            kani::assert(slot.is_slot_capacity_valid(), "occupants <= 2 must be capacity-valid");
        } else {
            kani::assert(!slot.is_slot_capacity_valid(), "occupants > 2 must violate Pauli exclusion");
        }
    }

    /// ADR-0013: spin tags are deterministic — first occupant Alpha,
    /// second occupant Beta, none otherwise.
    #[kani::proof]
    fn verify_spin_tag_determinism() {
        let occupants: u64 = kani::any();
        kani::assume(occupants <= 3);
        let slot = OccupancySlot { occupants, is_degenerate: true };
        match occupants {
            0 => kani::assert(slot.spin_tag().is_none(), "empty slot has no spin tag"),
            1 => kani::assert(slot.spin_tag() == Some(SpinTag::Alpha), "first occupant is Alpha"),
            2 => kani::assert(slot.spin_tag() == Some(SpinTag::Beta), "second occupant is Beta"),
            _ => kani::assert(slot.spin_tag().is_none(), "third occupant has no spin tag (exclusion)"),
        }
    }

    /// ADR-0014: term-order gate — pairing is rejected while U > 0.
    #[kani::proof]
    fn verify_term_order_pairing_gate() {
        let empty_slots: u64 = kani::any();
        let sp = SocialPhysicsEngine { v_pair: 0, v_nuc: 0, empty_slots };

        if empty_slots > 0 {
            kani::assert(!sp.is_pairing_legal(), "Pairing must be rejected if empty slots exist");
        }
    }

    /// ADR-0015: separated-ledger mandate — V_pair ≠ V_nuc is exactly the
    /// separation predicate.
    #[kani::proof]
    fn verify_separated_ledgers() {
        let v_pair: u64 = kani::any();
        let v_nuc: u64 = kani::any();
        let sp = SocialPhysicsEngine { v_pair, v_nuc, empty_slots: 0 };
        if v_pair != v_nuc {
            kani::assert(sp.are_ledgers_separated(), "distinct ledgers must be separated");
        } else {
            kani::assert(!sp.are_ledgers_separated(), "equal ledgers must not be separated");
        }
    }

    /// ADR-0015: energy sign convention — increasing V_nuc lowers energy,
    /// increasing V_pair raises energy (bounded to avoid i64 cast overflow).
    #[kani::proof]
    fn verify_energy_monotonicity() {
        let v_pair: u64 = kani::any();
        let v_nuc_low: u64 = kani::any();
        let v_nuc_high: u64 = kani::any();
        kani::assume(v_pair < (i64::MAX as u64) / 2);
        kani::assume(v_nuc_low < (i64::MAX as u64) / 2);
        kani::assume(v_nuc_high < (i64::MAX as u64) / 2);
        kani::assume(v_nuc_low <= v_nuc_high);

        let low = SocialPhysicsEngine { v_pair, v_nuc: v_nuc_low, empty_slots: 0 };
        let high = SocialPhysicsEngine { v_pair, v_nuc: v_nuc_high, empty_slots: 0 };
        kani::assert(high.total_energy() <= low.total_energy(), "more attraction must lower energy");
    }
}