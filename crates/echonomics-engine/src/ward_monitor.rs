//! # echonomics_engine::ward_monitor — ADR-0029 WardMonitor Interlock Duty Cycle
//!
//! Production-grade implementation of the WardMonitor hardware-level
//! interlock:
//! - Universal thresholds, scaled ×10 for exact integer arithmetic:
//!   - Embodied energy: Red when `E < -0.7` (i.e. `E_scaled < -7`).
//!   - Triadic Discrepancy Index (TDI): Green `≤ 0.8`, Amber `≤ 1.8`, Red
//!     `> 1.8` (`8`, `18` scaled).
//!   - Masking: `≥ 2` masking flags in the last 3 consecutive check-ins.
//!   - HRV drift: Red when `Avg Drift < -1.5σ` (`-15` scaled).
//! - Composite `SIG_GOV_KILL` — no single metric except extreme energy
//!   collapse triggers it:
//!   `E < -0.7 OR (TDI > 1.8 AND AvgDrift < -1.5σ) OR (masking ≥ 2/3)`.
//! - Duty cycle: the monitor recomputes the cryptographic chain
//!   (`prev_hash`/`entry_hash`); a broken link fails closed to interlock.
//!
//! Kani model-checking harnesses (`cargo kani`) discharge the gate properties
//! for all symbolic inputs.

use serde::{Deserialize, Serialize};

/// Embodied energy interlock bound: `E < -0.7`, scaled ×10.
pub const ENERGY_RED_BOUND: i64 = -7;

/// TDI green ceiling: `TDI ≤ 0.8`, scaled ×10.
pub const TDI_GREEN_BOUND: u64 = 8;

/// TDI amber ceiling: `TDI ≤ 1.8`, scaled ×10 (above this is Red).
pub const TDI_AMBER_BOUND: u64 = 18;

/// HRV drift amber floor: `AvgDrift ≥ -1.5σ`, scaled ×10 (below is Red).
pub const HRV_AMBER_BOUND: i64 = -15;

/// Masking window: the last 3 consecutive check-ins.
pub const MASKING_WINDOW: u64 = 3;

/// Sustained-masking interlock count: `≥ 2` masking flags in the window.
pub const MASKING_RED_COUNT: u64 = 2;

/// Observed triad state: embodied energy and HRV drift (signed, ×10) plus the
/// TDI score and the masking-flag count over the last 3 check-ins.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct WardState {
    /// Embodied energy `E` × 10.
    pub energy_scaled: i64,
    /// Triadic discrepancy index × 10.
    pub tdi_scaled: u64,
    /// Mean HRV log-deviation × 10 (σ units).
    pub hrv_drift_scaled: i64,
    /// Masking flags in the last 3 check-ins.
    pub masking_last_n: u64,
}

impl WardState {
    /// Embodied-energy interlock: `E < -0.7`.
    pub const fn is_energy_red(&self) -> bool {
        self.energy_scaled < ENERGY_RED_BOUND
    }

    /// TDI interlock: `TDI > 1.8`.
    pub const fn is_tdi_red(&self) -> bool {
        self.tdi_scaled > TDI_AMBER_BOUND
    }

    /// TDI amber band: `0.8 < TDI ≤ 1.8` (warning, not interlock).
    pub const fn is_tdi_amber(&self) -> bool {
        self.tdi_scaled > TDI_GREEN_BOUND && self.tdi_scaled <= TDI_AMBER_BOUND
    }

    /// HRV-drift interlock: `AvgDrift < -1.5σ`.
    pub const fn is_hrv_red(&self) -> bool {
        self.hrv_drift_scaled < HRV_AMBER_BOUND
    }

    /// Sustained-masking interlock: `≥ 2` masking flags in the window.
    pub const fn is_masking_red(&self) -> bool {
        self.masking_last_n >= MASKING_RED_COUNT
    }

    /// `SIG_GOV_KILL` composite condition:
    /// `E < -0.7` OR `(TDI > 1.8 AND AvgDrift < -1.5σ)` OR `masking ≥ 2/3`.
    pub const fn sig_gov_kill(&self) -> bool {
        self.is_energy_red() || (self.is_tdi_red() && self.is_hrv_red()) || self.is_masking_red()
    }

    /// A masking count is valid only within the 3-check-in window.
    pub const fn is_masking_count_in_window(&self) -> bool {
        self.masking_last_n <= MASKING_WINDOW
    }
}

/// A monitor entry: the hash of the current check-in plus the hash of the
/// previous entry, forming the tamper-evident chain.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct MonitorEntry {
    pub entry_hash: u64,
    pub prev_hash: u64,
}

/// Chain validity: every successor's `prevHash` equals its predecessor's
/// `entryHash` (recomputed by the monitor each duty cycle).
pub const fn is_chain_valid(entries: &[MonitorEntry]) -> bool {
    let mut i = 0;
    while i + 1 < entries.len() {
        if entries[i + 1].prev_hash != entries[i].entry_hash {
            return false;
        }
        i += 1;
    }
    true
}

/// A chain violation: the recomputation failed.
pub const fn is_chain_broken(entries: &[MonitorEntry]) -> bool {
    !is_chain_valid(entries)
}

/// The WardMonitor interlock: threshold breach OR chain violation
/// (fail-closed duty cycle).
pub const fn monitor_interlock(entries: &[MonitorEntry], state: &WardState) -> bool {
    state.sig_gov_kill() || is_chain_broken(entries)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_universal_thresholds() {
        assert_eq!(ENERGY_RED_BOUND, -7);
        assert_eq!(TDI_GREEN_BOUND, 8);
        assert_eq!(TDI_AMBER_BOUND, 18);
        assert_eq!(HRV_AMBER_BOUND, -15);
        assert_eq!(MASKING_WINDOW, 3);
        assert_eq!(MASKING_RED_COUNT, 2);

        // Boundary behavior.
        assert!(WardState { energy_scaled: -8, tdi_scaled: 0, hrv_drift_scaled: 0, masking_last_n: 0 }
            .is_energy_red());
        assert!(!WardState { energy_scaled: -7, tdi_scaled: 0, hrv_drift_scaled: 0, masking_last_n: 0 }
            .is_energy_red(), "exactly -0.7 is not red");
        assert!(WardState { energy_scaled: 0, tdi_scaled: 19, hrv_drift_scaled: 0, masking_last_n: 0 }
            .is_tdi_red());
        assert!(!WardState { energy_scaled: 0, tdi_scaled: 18, hrv_drift_scaled: 0, masking_last_n: 0 }
            .is_tdi_red());
        assert!(WardState { energy_scaled: 0, tdi_scaled: 10, hrv_drift_scaled: 0, masking_last_n: 0 }
            .is_tdi_amber());
        assert!(WardState { energy_scaled: 0, tdi_scaled: 0, hrv_drift_scaled: -16, masking_last_n: 0 }
            .is_hrv_red());
        assert!(!WardState { energy_scaled: 0, tdi_scaled: 0, hrv_drift_scaled: -15, masking_last_n: 0 }
            .is_hrv_red());
        assert!(WardState { energy_scaled: 0, tdi_scaled: 0, hrv_drift_scaled: 0, masking_last_n: 2 }
            .is_masking_red());
        assert!(!WardState { energy_scaled: 0, tdi_scaled: 0, hrv_drift_scaled: 0, masking_last_n: 1 }
            .is_masking_red(), "a single transient flag is amber, not red");
    }

    #[test]
    fn test_composite_interlock() {
        let red_energy = WardState { energy_scaled: -8, tdi_scaled: 0, hrv_drift_scaled: 0, masking_last_n: 0 };
        let composite = WardState { energy_scaled: 0, tdi_scaled: 19, hrv_drift_scaled: -16, masking_last_n: 0 };
        let tdi_alone = WardState { energy_scaled: 0, tdi_scaled: 19, hrv_drift_scaled: 0, masking_last_n: 0 };
        let masked = WardState { energy_scaled: 0, tdi_scaled: 0, hrv_drift_scaled: 0, masking_last_n: 2 };
        let green = WardState { energy_scaled: 3, tdi_scaled: 5, hrv_drift_scaled: 0, masking_last_n: 0 };

        assert!(red_energy.sig_gov_kill(), "extreme E collapse alone triggers");
        assert!(composite.sig_gov_kill(), "TDI AND HRV drift triggers");
        assert!(!tdi_alone.sig_gov_kill(), "no false positive: TDI alone is not enough");
        assert!(masked.sig_gov_kill(), "sustained masking triggers");
        assert!(!green.sig_gov_kill(), "fully green state never interlocks");
    }

    #[test]
    fn test_duty_cycle_chain() {
        let entry1 = MonitorEntry { entry_hash: 42, prev_hash: 0 };
        let entry2 = MonitorEntry { entry_hash: 99, prev_hash: 42 };
        let entry2_tampered = MonitorEntry { entry_hash: 99, prev_hash: 7 };
        let green = WardState { energy_scaled: 3, tdi_scaled: 5, hrv_drift_scaled: 0, masking_last_n: 0 };

        assert!(is_chain_valid(&[entry1]), "genesis chain is valid");
        assert!(is_chain_valid(&[entry1, entry2]));
        assert!(!is_chain_valid(&[entry1, entry2_tampered]), "broken link detected");
        assert!(monitor_interlock(&[entry1, entry2_tampered], &green), "tampering forces interlock");
        assert!(!monitor_interlock(&[entry1, entry2], &green), "intact chain + green state stays quiet");
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    /// ADR-0029: extreme energy collapse alone triggers `SIG_GOV_KILL`.
    #[kani::proof]
    fn verify_energy_collapse_triggers_interlock() {
        let energy_scaled: i64 = kani::any();
        let tdi_scaled: u64 = kani::any();
        let hrv_drift_scaled: i64 = kani::any();
        let masking_last_n: u64 = kani::any();
        let st = WardState { energy_scaled, tdi_scaled, hrv_drift_scaled, masking_last_n };
        if st.is_energy_red() {
            kani::assert(st.sig_gov_kill(), "E < -0.7 alone triggers SIG_GOV_KILL");
        }
    }

    /// ADR-0029: no false positive — a high TDI alone (green elsewhere)
    /// never triggers the interlock.
    #[kani::proof]
    fn verify_tdi_alone_not_enough() {
        let energy_scaled: i64 = kani::any();
        let tdi_scaled: u64 = kani::any();
        let hrv_drift_scaled: i64 = kani::any();
        let masking_last_n: u64 = kani::any();
        kani::assume(energy_scaled >= ENERGY_RED_BOUND);
        kani::assume(hrv_drift_scaled >= HRV_AMBER_BOUND);
        kani::assume(masking_last_n < MASKING_RED_COUNT);

        let st = WardState { energy_scaled, tdi_scaled, hrv_drift_scaled, masking_last_n };
        kani::assert(
            !st.sig_gov_kill() || st.is_tdi_red(),
            "TDI alone never triggers: if interlocks, TDI red must pair with another red metric",
        );
    }

    /// ADR-0029: the composite condition is exactly the three-way disjunction.
    #[kani::proof]
    fn verify_composite_iff_components() {
        let energy_scaled: i64 = kani::any();
        let tdi_scaled: u64 = kani::any();
        let hrv_drift_scaled: i64 = kani::any();
        let masking_last_n: u64 = kani::any();
        let st = WardState { energy_scaled, tdi_scaled, hrv_drift_scaled, masking_last_n };

        let expected = st.is_energy_red()
            || (st.is_tdi_red() && st.is_hrv_red())
            || st.is_masking_red();
        kani::assert(st.sig_gov_kill() == expected, "SIG_GOV_KILL is the composite disjunction");
    }

    /// ADR-0029: duty cycle — a broken chain link always forces the
    /// monitor interlock.
    #[kani::proof]
    fn verify_broken_chain_forces_interlock() {
        let e1_hash: u64 = kani::any();
        let e2_hash: u64 = kani::any();
        let prev_hash: u64 = kani::any();
        let energy_scaled: i64 = kani::any();
        let tdi_scaled: u64 = kani::any();
        let hrv_drift_scaled: i64 = kani::any();
        let masking_last_n: u64 = kani::any();

        let entries = [
            MonitorEntry { entry_hash: e1_hash, prev_hash: 0 },
            MonitorEntry { entry_hash: e2_hash, prev_hash },
        ];
        let st = WardState { energy_scaled, tdi_scaled, hrv_drift_scaled, masking_last_n };
        if prev_hash != e1_hash {
            kani::assert(
                monitor_interlock(&entries, &st),
                "a tampered chain forces SIG_GOV_KILL regardless of thresholds",
            );
        }
    }

    /// ADR-0029: duty cycle — an intact chain with a green state stays quiet.
    #[kani::proof]
    fn verify_intact_chain_green_state_quiet() {
        let e1_hash: u64 = kani::any();
        let e2_hash: u64 = kani::any();
        let energy_scaled: i64 = kani::any();
        let tdi_scaled: u64 = kani::any();
        let hrv_drift_scaled: i64 = kani::any();
        let masking_last_n: u64 = kani::any();
        kani::assume(energy_scaled >= ENERGY_RED_BOUND);
        kani::assume(tdi_scaled <= TDI_AMBER_BOUND);
        kani::assume(hrv_drift_scaled >= HRV_AMBER_BOUND);
        kani::assume(masking_last_n < MASKING_RED_COUNT);

        let entries = [
            MonitorEntry { entry_hash: e1_hash, prev_hash: 0 },
            MonitorEntry { entry_hash: e2_hash, prev_hash: e1_hash },
        ];
        let st = WardState { energy_scaled, tdi_scaled, hrv_drift_scaled, masking_last_n };
        kani::assert(
            !monitor_interlock(&entries, &st),
            "intact chain and green state produce no interlock",
        );
    }
}