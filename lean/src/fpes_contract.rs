//! ADR-0029 FPES runtime assertions — `#[contract]`-style debug_assert! injection.
//!
//! When `CONTRACT_FPES=1` is set (by `build.rs`), every function in this
//! module injects `debug_assert!` checks that verify FPES invariants at
//! runtime.  In release builds without the env var, the assertions are
//! compiled out (zero cost).
//!
//! # Design
//!
//! This is the production-quality subset of a full `#[contract]` proc macro.
//! Instead of a macro, we provide a set of wrapper functions that:
//!
//! 1. Check the `CONTRACT_FPES` environment variable at init time
//! 2. Inject `debug_assert!` at every call site
//! 3. Delegate to the actual implementation
//!
//! To adopt this pattern, wrap production functions:
//!
//! ```rust
//! use crate::fpes_contract::FpesContract;
//!
//! fn prune_hypotheses(space: &mut HypothesisSpace, policy: &SelectionPolicy) {
//!     FpesContract::check_prune_invariants(space, policy);
//!     // ... actual implementation ...
//! }
//! ```
//!
//! # Contract obligations (from `contracts/fpes.yaml`)
//!
//! | Function | Assertion | Obligation |
//! |----------|-----------|------------|
//! | `check_prune_invariants` | `space.paths.len() > 0` | FPES-MULTIPLICITY-001 |
//! | `check_prune_invariants` | `multiplicity_survives(space, policy)` | FPES-SURVIVAL-002 |
//! | `check_contraction` | `classes_nonempty(space)` | FPES-SURVIVAL-002 |
//! | `check_viable` | `viable(space)` | FPES-CERTIFICATE-006 |

use std::sync::Once;

static INIT: Once = Once::new();
static mut FPES_CONTRACTS_ENABLED: bool = false;

/// Initialize the FPES contract system.  Called once at startup.
/// Reads `CONTRACT_FPES` env var; if set to "1", enables runtime assertions.
pub fn init_fpes_contracts() {
    INIT.call_once(|| {
        let enabled = std::env::var("CONTRACT_FPES")
            .map(|v| v == "1")
            .unwrap_or(false);
        // SAFETY: Once ensures single initialization
        unsafe {
            FPES_CONTRACTS_ENABLED = enabled;
        }
        if enabled {
            eprintln!("[FPES CONTRACT] Runtime assertions ENABLED (CONTRACT_FPES=1)");
        }
    });
}

/// Check whether FPES contracts are enabled.
pub fn fpes_contracts_enabled() -> bool {
    // Ensure initialized
    init_fpes_contracts();
    unsafe { FPES_CONTRACTS_ENABLED }
}

/// FPES contract checker — injects `debug_assert!` at call sites.
///
/// Each method corresponds to a production function that needs invariant
/// checking.  The assertions verify the proof obligations from
/// `contracts/fpes.yaml` at runtime.
pub struct FpesContract;

impl FpesContract {
    /// Check invariants for hypothesis space pruning.
    ///
    /// # Contract (FPES-MULTIPLICITY-001 + FPES-SURVIVAL-002)
    /// - `space.paths.len() > 0`: non-empty path pool
    /// - Every registered class has ≥ 1 path after pruning
    pub fn check_prune_invariants(path_count: usize, class_multiplicities: &[u32]) {
        if !fpes_contracts_enabled() {
            return;
        }
        debug_assert!(
            path_count > 0,
            "[FPES CONTRACT] prune_hypotheses: path pool must be non-empty \
             (FPES-MULTIPLICITY-001)"
        );
        for (i, &mult) in class_multiplicities.iter().enumerate() {
            debug_assert!(
                mult >= 1,
                "[FPES CONTRACT] prune_hypotheses: class {} has multiplicity {} < 1 \
                 after pruning (FPES-SURVIVAL-002)",
                i,
                mult
            );
        }
    }

    /// Check invariants for contraction to representatives.
    ///
    /// # Contract (FPES-SURVIVAL-002)
    /// - All classes were nonempty before contraction
    /// - All classes remain nonempty after contraction
    pub fn check_contraction(
        classes_before: &[u32],
        multiplicities_before: &[u32],
        multiplicities_after: &[u32],
    ) {
        if !fpes_contracts_enabled() {
            return;
        }
        assert_eq!(
            classes_before.len(),
            multiplicities_before.len(),
            "[FPES CONTRACT] class/multiplicity array length mismatch"
        );
        assert_eq!(
            multiplicities_before.len(),
            multiplicities_after.len(),
            "[FPES CONTRACT] before/after multiplicity array length mismatch"
        );
        for (i, (&before, &after)) in multiplicities_before
            .iter()
            .zip(multiplicities_after.iter())
            .enumerate()
        {
            debug_assert!(
                before >= 1,
                "[FPES CONTRACT] contraction: class {} was already empty before contraction",
                classes_before[i]
            );
            debug_assert!(
                after >= 1,
                "[FPES CONTRACT] contraction: class {} lost all paths after contraction \
                 (FPES-SURVIVAL-002 violation)",
                classes_before[i]
            );
        }
    }

    /// Check the viability gate.
    ///
    /// # Contract (FPES-CERTIFICATE-006)
    /// - `NoDupClasses`: class ids are unique
    /// - `Registered`: every path's class is registered
    /// - `ClassesNonempty`: every class has ≥ 1 path
    pub fn check_viable(
        nodup_classes: bool,
        registered: bool,
        classes_nonempty: bool,
        path_count: usize,
        class_count: usize,
    ) {
        if !fpes_contracts_enabled() {
            return;
        }
        debug_assert!(
            nodup_classes,
            "[FPES CONTRACT] Viable: NoDupClasses violated — duplicate class ids"
        );
        debug_assert!(
            registered,
            "[FPES CONTRACT] Viable: Registered violated — unregistered path class"
        );
        debug_assert!(
            classes_nonempty,
            "[FPES CONTRACT] Viable: ClassesNonempty violated — empty class"
        );
        debug_assert!(
            path_count > 0 || class_count == 0,
            "[FPES CONTRACT] Viable: non-empty class list but empty path list"
        );
    }

    /// Check conflict detection for concurrent proposals.
    ///
    /// # Contract (FPES-CONFLICT-005)
    /// If two proposals both select a path for a class and are not flagged
    /// as conflicting, their selections must agree.
    pub fn check_proposal_agreement(
        proposal_agrees: bool,
        class_id: u32,
        p1_name: &str,
        p2_name: &str,
    ) {
        if !fpes_contracts_enabled() {
            return;
        }
        debug_assert!(
            proposal_agrees,
            "[FPES CONTRACT] concurrent proposals '{}' and '{}' disagree on class {} \
             but are not flagged as conflicting (FPES-CONFLICT-005)",
            p1_name,
            p2_name,
            class_id
        );
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_contracts_disabled_by_default() {
        std::env::remove_var("CONTRACT_FPES");
        // Re-init won't run (Once), but the default is false
        assert!(!fpes_contracts_enabled());
    }

    #[test]
    fn test_check_prune_no_panic_when_disabled() {
        std::env::remove_var("CONTRACT_FPES");
        // Should not panic even with invalid data when contracts are disabled
        FpesContract::check_prune_invariants(0, &[0, 0, 0]);
    }

    #[test]
    fn test_check_contraction_valid() {
        std::env::remove_var("CONTRACT_FPES");
        // When disabled, no assertion fires
        FpesContract::check_contraction(&[0, 1, 2], &[3, 2, 3], &[1, 1, 1]);
    }

    #[test]
    fn test_check_viable_valid() {
        std::env::remove_var("CONTRACT_FPES");
        FpesContract::check_viable(true, true, true, 8, 3);
    }
}
