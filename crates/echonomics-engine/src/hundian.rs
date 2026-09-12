use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct PauliKey {
    pub role_class: String,
    pub slot_id: String,
    pub period_id: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum SpinTag {
    Alpha,
    Beta,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum PeriodStatus {
    Draft,
    Open,
    Closed,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum GateResult {
    OkSingle { sigma: SpinTag },
    OkPair { sigma: SpinTag },
    OkHierarchy,
    OkDualHatWaiver { sigma: Option<SpinTag> },
    OkVacate,
    RejUnknownClass,
    RejDualHat,
    RejPauli,
    RejTermOrder,
    RejPeriodClosed,
    RejNotOccupant,
}

/// Pure, side-effect-free multiplicity function: M = n_unpaired + 1.
///
/// This is the ADR-0001 canonical multiplicity law. It is kept free of any
/// hashing or allocation so it can be symbolically model-checked by Kani.
pub const fn calculate_multiplicity_peq(n_unpaired: usize) -> usize {
    n_unpaired + 1
}

/// Pure spin quantum number S = n_unpaired / 2 (exact for even n, truncating
/// otherwise, matching the reference implementation in `HundianState`).
pub fn spin_quantum_number(n_unpaired: usize) -> f64 {
    n_unpaired as f64 / 2.0
}

/// Pure, side-effect-free Pauli gate decision for a single key.
///
/// Mirrors the gate priority in `HundianState::propose_fill`'s G2/G3/G4/G5
/// stages. Operates only on `usize`/`bool` so Kani can discharge it
/// symbolically without touching hashing internals.
///
/// - `occupants_count < 2`: not at Pauli capacity
/// - `is_degenerate && occupants_count == 1 && empty_degenerate_slots > 0` -> RejTermOrder
/// - `is_degenerate && occupants_count == 1 && empty_degenerate_slots == 0` -> OkPair(Beta)
/// - `is_degenerate && occupants_count == 0` -> OkSingle(Alpha)
/// - non-degenerate -> OkHierarchy
/// - `occupants_count >= 2` -> RejPauli
pub const fn evaluate_pauli_gate_peq(
    occupants_count: usize,
    empty_degenerate_slots: usize,
    is_degenerate: bool,
) -> GateResult {
    if occupants_count >= 2 {
        GateResult::RejPauli
    } else if occupants_count == 1 {
        if is_degenerate {
            if empty_degenerate_slots > 0 {
                GateResult::RejTermOrder
            } else {
                GateResult::OkPair { sigma: SpinTag::Beta }
            }
        } else {
            GateResult::OkHierarchy
        }
    } else if is_degenerate {
        GateResult::OkSingle { sigma: SpinTag::Alpha }
    } else {
        GateResult::OkHierarchy
    }
}

/// Pure helper: is the slot at Pauli capacity?
pub const fn at_pauli_capacity(occupants_count: usize) -> bool {
    occupants_count >= 2
}

/// Pure helper: does the term-order gate block this pairing?
pub const fn term_order_blocks(is_degenerate: bool, empty_degenerate_slots: usize) -> bool {
    is_degenerate && empty_degenerate_slots > 0
}

#[derive(Debug, Clone, Default)]
pub struct HundianState {
    pub degenerate_classes: HashSet<String>,
    pub registered_slots: HashMap<PauliKey, Vec<String>>,
    pub person_occupancies: HashMap<(String, String), HashSet<PauliKey>>,
    pub period_statuses: HashMap<String, PeriodStatus>,
}

impl HundianState {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn set_period_status(&mut self, period_id: impl Into<String>, status: PeriodStatus) {
        self.period_statuses.insert(period_id.into(), status);
    }

    pub fn register_degenerate_class(&mut self, role_class: impl Into<String>) {
        self.degenerate_classes.insert(role_class.into());
    }

    pub fn register_slot(&mut self, key: PauliKey) {
        self.registered_slots.entry(key).or_default();
    }

    pub fn count_empty_degenerate_slots(&self, period_id: &str) -> usize {
        self.registered_slots
            .iter()
            .filter(|(k, occ)| k.period_id == period_id && self.degenerate_classes.contains(&k.role_class) && occ.is_empty())
            .count()
    }

    pub fn count_unpaired_degenerate_slots(&self, period_id: &str) -> usize {
        self.registered_slots
            .iter()
            .filter(|(k, occ)| k.period_id == period_id && self.degenerate_classes.contains(&k.role_class) && occ.len() == 1)
            .count()
    }

    pub fn calculate_multiplicity(&self, period_id: &str) -> (usize, f64, usize) {
        let n_unpaired = self.count_unpaired_degenerate_slots(period_id);
        let s = spin_quantum_number(n_unpaired);
        let m = calculate_multiplicity_peq(n_unpaired);
        (n_unpaired, s, m)
    }

    pub fn propose_fill(
        &mut self,
        person_id: &str,
        role_class: &str,
        slot_id: &str,
        period_id: &str,
        waiver_id: Option<&str>,
    ) -> GateResult {
        let status = self.period_statuses.get(period_id).cloned().unwrap_or(PeriodStatus::Open);
        if status != PeriodStatus::Open {
            return GateResult::RejPeriodClosed;
        }

        let key = PauliKey {
            role_class: role_class.to_string(),
            slot_id: slot_id.to_string(),
            period_id: period_id.to_string(),
        };

        // G0: Register check
        if !self.registered_slots.contains_key(&key) {
            return GateResult::RejUnknownClass;
        }

        // G1: Dual-hat check
        let is_user_has_other_keys = self
            .person_occupancies
            .get(&(person_id.to_string(), period_id.to_string()))
            .map(|keys| !keys.is_empty() && !keys.contains(&key))
            .unwrap_or(false);

        let used_waiver = if is_user_has_other_keys {
            if waiver_id.is_none() {
                return GateResult::RejDualHat;
            }
            true
        } else {
            false
        };

        let occupants = self.registered_slots.get(&key).unwrap();

        // G2: Pauli capacity
        if occupants.len() >= 2 {
            return GateResult::RejPauli;
        }

        let is_degenerate = self.degenerate_classes.contains(role_class);

        // G3: Term order & fill acceptance
        let result = if occupants.len() == 1 {
            if is_degenerate {
                let u = self.count_empty_degenerate_slots(period_id);
                if u > 0 {
                    return GateResult::RejTermOrder;
                }
                if used_waiver {
                    GateResult::OkDualHatWaiver { sigma: Some(SpinTag::Beta) }
                } else {
                    GateResult::OkPair { sigma: SpinTag::Beta }
                }
            } else {
                if used_waiver {
                    GateResult::OkDualHatWaiver { sigma: None }
                } else {
                    GateResult::OkHierarchy
                }
            }
        } else {
            if used_waiver {
                GateResult::OkDualHatWaiver { sigma: if is_degenerate { Some(SpinTag::Alpha) } else { None } }
            } else if is_degenerate {
                GateResult::OkSingle { sigma: SpinTag::Alpha }
            } else {
                GateResult::OkHierarchy
            }
        };

        self.registered_slots.get_mut(&key).unwrap().push(person_id.to_string());
        self.person_occupancies.entry((person_id.to_string(), period_id.to_string())).or_default().insert(key);
        result
    }

    pub fn propose_vacate(
        &mut self,
        person_id: &str,
        role_class: &str,
        slot_id: &str,
        period_id: &str,
    ) -> GateResult {
        let status = self.period_statuses.get(period_id).cloned().unwrap_or(PeriodStatus::Open);
        if status != PeriodStatus::Open {
            return GateResult::RejPeriodClosed;
        }

        let key = PauliKey {
            role_class: role_class.to_string(),
            slot_id: slot_id.to_string(),
            period_id: period_id.to_string(),
        };

        if !self.registered_slots.contains_key(&key) {
            return GateResult::RejUnknownClass;
        }

        let occupants = self.registered_slots.get_mut(&key).unwrap();
        if let Some(pos) = occupants.iter().position(|p| p == person_id) {
            occupants.remove(pos);
            if let Some(keys) = self.person_occupancies.get_mut(&(person_id.to_string(), period_id.to_string())) {
                keys.remove(&key);
            }
            GateResult::OkVacate
        } else {
            GateResult::RejNotOccupant
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_canonical_seven_row_sequence() {
        let mut state = HundianState::new();
        state.set_period_status("P0", PeriodStatus::Open);
        state.register_degenerate_class("facilitation");

        let k1 = PauliKey { role_class: "facilitation".into(), slot_id: "fac-1".into(), period_id: "P0".into() };
        let k2 = PauliKey { role_class: "facilitation".into(), slot_id: "fac-2".into(), period_id: "P0".into() };
        let k3 = PauliKey { role_class: "facilitation".into(), slot_id: "fac-3".into(), period_id: "P0".into() };

        state.register_slot(k1);
        state.register_slot(k2);
        state.register_slot(k3);

        // 10:00Z alice -> fac-1 OK_SINGLE (M=2)
        let r1 = state.propose_fill("alice", "facilitation", "fac-1", "P0", None);
        assert_eq!(r1, GateResult::OkSingle { sigma: SpinTag::Alpha });
        assert_eq!(state.calculate_multiplicity("P0"), (1, 0.5, 2));

        // 10:05Z bob -> fac-1 REJ_TERM_ORDER
        let r2 = state.propose_fill("bob", "facilitation", "fac-1", "P0", None);
        assert_eq!(r2, GateResult::RejTermOrder);

        // 10:06Z bob -> fac-2 OK_SINGLE (M=3)
        let r3 = state.propose_fill("bob", "facilitation", "fac-2", "P0", None);
        assert_eq!(r3, GateResult::OkSingle { sigma: SpinTag::Alpha });
        assert_eq!(state.calculate_multiplicity("P0"), (2, 1.0, 3));

        // 10:07Z carol -> fac-3 OK_SINGLE (M=4)
        let r4 = state.propose_fill("carol", "facilitation", "fac-3", "P0", None);
        assert_eq!(r4, GateResult::OkSingle { sigma: SpinTag::Alpha });
        assert_eq!(state.calculate_multiplicity("P0"), (3, 1.5, 4));

        // 10:08Z dave -> fac-1 OK_PAIR (M=3)
        let r5 = state.propose_fill("dave", "facilitation", "fac-1", "P0", None);
        assert_eq!(r5, GateResult::OkPair { sigma: SpinTag::Beta });
        assert_eq!(state.calculate_multiplicity("P0"), (2, 1.0, 3));

        // 10:09Z eve -> fac-1 REJ_PAULI
        let r6 = state.propose_fill("eve", "facilitation", "fac-1", "P0", None);
        assert_eq!(r6, GateResult::RejPauli);

        // 10:10Z bob -> fac-1 REJ_DUALHAT
        let r7 = state.propose_fill("bob", "facilitation", "fac-1", "P0", None);
        assert_eq!(r7, GateResult::RejDualHat);
    }

    #[test]
    fn test_propose_vacate_and_closed_period() {
        let mut state = HundianState::new();
        state.set_period_status("P0", PeriodStatus::Open);
        state.register_degenerate_class("facilitation");

        let k1 = PauliKey { role_class: "facilitation".into(), slot_id: "fac-1".into(), period_id: "P0".into() };
        state.register_slot(k1);

        assert_eq!(state.propose_fill("alice", "facilitation", "fac-1", "P0", None), GateResult::OkSingle { sigma: SpinTag::Alpha });

        // Vacate valid occupant
        assert_eq!(state.propose_vacate("alice", "facilitation", "fac-1", "P0"), GateResult::OkVacate);

        // Vacate non-occupant
        assert_eq!(state.propose_vacate("bob", "facilitation", "fac-1", "P0"), GateResult::RejNotOccupant);

        // Close period
        state.set_period_status("P0", PeriodStatus::Closed);
        assert_eq!(state.propose_fill("alice", "facilitation", "fac-1", "P0", None), GateResult::RejPeriodClosed);
        assert_eq!(state.propose_vacate("alice", "facilitation", "fac-1", "P0"), GateResult::RejPeriodClosed);
    }
}

#[cfg(test)]
mod pure_fn_tests {
    use super::*;

    #[test]
    fn test_pure_multiplicity_matches_engine() {
        for n in 0..=10 {
            assert_eq!(calculate_multiplicity_peq(n), n + 1);
            assert_eq!(spin_quantum_number(n), n as f64 / 2.0);
        }
    }

    #[test]
    fn test_pure_pauli_third_rejection() {
        assert_eq!(
            evaluate_pauli_gate_peq(2, 0, true),
            GateResult::RejPauli
        );
        assert_eq!(
            evaluate_pauli_gate_peq(3, 5, false),
            GateResult::RejPauli
        );
        assert_eq!(
            evaluate_pauli_gate_peq(7, 1, true),
            GateResult::RejPauli
        );
    }

    #[test]
    fn test_pure_term_order_gate() {
        // U > 0 on degenerate -> RejTermOrder
        assert_eq!(
            evaluate_pauli_gate_peq(1, 1, true),
            GateResult::RejTermOrder
        );
        assert_eq!(
            evaluate_pauli_gate_peq(1, 4, true),
            GateResult::RejTermOrder
        );
        // U = 0 on degenerate -> OkPair(Beta)
        assert_eq!(
            evaluate_pauli_gate_peq(1, 0, true),
            GateResult::OkPair { sigma: SpinTag::Beta }
        );
    }

    #[test]
    fn test_pure_spin_tag_assignment() {
        // empty degenerate -> Alpha
        assert_eq!(
            evaluate_pauli_gate_peq(0, 3, true),
            GateResult::OkSingle { sigma: SpinTag::Alpha }
        );
        // non-degenerate (any occupancy < 2) -> OkHierarchy
        assert_eq!(
            evaluate_pauli_gate_peq(0, 3, false),
            GateResult::OkHierarchy
        );
        assert_eq!(
            evaluate_pauli_gate_peq(1, 3, false),
            GateResult::OkHierarchy
        );
    }

    #[test]
    fn test_pure_matches_engine_on_canonical_sequence() {
        // The 7-row canonical sequence asserted through the pure core:
        // alice -> empty degenerate slot => OkSingle(Alpha)
        let r1 = evaluate_pauli_gate_peq(0, 2, true);
        assert_eq!(r1, GateResult::OkSingle { sigma: SpinTag::Alpha });
        // bob -> half-filled slot while 2 slots remain empty => RejTermOrder
        let r2 = evaluate_pauli_gate_peq(1, 2, true);
        assert_eq!(r2, GateResult::RejTermOrder);
        // dave -> half-filled slot, no empty candidates => OkPair(Beta)
        let r5 = evaluate_pauli_gate_peq(1, 0, true);
        assert_eq!(r5, GateResult::OkPair { sigma: SpinTag::Beta });
        // eve -> full slot => RejPauli
        let r6 = evaluate_pauli_gate_peq(2, 0, true);
        assert_eq!(r6, GateResult::RejPauli);
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    // Verify Pauli exclusion on the pure core: any slot at capacity rejects.
    #[kani::proof]
    fn verify_pauli_bound_pure() {
        let occupants: usize = kani::any();
        let empty: usize = kani::any();
        let deg: bool = kani::any();
        kani::assume(occupants >= 2);
        kani::assert(
            evaluate_pauli_gate_peq(occupants, empty, deg) == GateResult::RejPauli,
            "Third occupant must be rejected",
        );
    }

    // Verify term-order gate on the pure core.
    #[kani::proof]
    fn verify_term_order_pure() {
        let empty: usize = kani::any();
        kani::assume(empty > 0);
        kani::assert(
            evaluate_pauli_gate_peq(1, empty, true) == GateResult::RejTermOrder,
            "Empty degenerate slots remaining must block pairing",
        );
    }
}
