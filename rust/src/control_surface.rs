//! Cross-layer control-surface contract (Rust side).
//!
//! Mirror of `src/ADR/ControlSurface.lean`. Both sides define the same
//! `AdrStatus` / `CircuitBreakerState` vocabulary and the same refinement
//! predicate (`is_valid` / `contract_valid`), so a certification dossier
//! minted on either layer is accepted or rejected identically.
//!
//! Consistency between the two files is enforced in CI by
//! `scripts/check_control_surface_schema.py`.
//!
//! Refinement rule (the enforcement teeth):
//! `is_valid` holds iff the contract carries the current schema version and
//! an accepted-status contract rides an armed circuit breaker. A tripped
//! breaker therefore blocks any accepted-status contract — the machine-level
//! statement of the documented circuit-breaker / veto control surface.

/// Current cross-layer schema version.
/// Must match `ADR.ControlSurface.SCHEMA_VERSION` on the Lean side.
pub const CONTROL_SURFACE_SCHEMA_VERSION: u32 = 2;

/// Lifecycle status of an Architecture Decision Record.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AdrStatus {
    Proposed,
    Accepted,
    Deprecated,
    Superseded,
}

/// State of the release circuit breaker.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CircuitBreakerState {
    Armed,
    Tripped,
    Disabled,
}

/// The control-surface contract carried by every certification dossier.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ControlSurfaceContract {
    pub schema_version: u32,
    pub status: AdrStatus,
    pub breaker: CircuitBreakerState,
}

impl ControlSurfaceContract {
    /// Refinement predicate shared with the Lean layer:
    /// current schema version AND accepted contracts require an armed breaker.
    pub fn is_valid(&self) -> bool {
        self.schema_version == CONTROL_SURFACE_SCHEMA_VERSION
            && (self.status != AdrStatus::Accepted || self.breaker == CircuitBreakerState::Armed)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn contract(status: AdrStatus, breaker: CircuitBreakerState) -> ControlSurfaceContract {
        ControlSurfaceContract { schema_version: CONTROL_SURFACE_SCHEMA_VERSION, status, breaker }
    }

    /// Lean twin of `no_bypass_tripped_breaker`: an accepted contract behind a
    /// tripped breaker is invalid — there is no bypass around the breaker.
    #[test]
    fn no_bypass_tripped_breaker() {
        let c = contract(AdrStatus::Accepted, CircuitBreakerState::Tripped);
        assert!(!c.is_valid());
    }

    /// Accepted + armed + current schema is the only valid accepted shape.
    #[test]
    fn accepted_requires_armed_breaker() {
        assert!(contract(AdrStatus::Accepted, CircuitBreakerState::Armed).is_valid());
        assert!(!contract(AdrStatus::Accepted, CircuitBreakerState::Disabled).is_valid());
    }

    /// Non-accepted statuses are unconstrained by the breaker.
    #[test]
    fn non_accepted_unconstrained() {
        for status in [AdrStatus::Proposed, AdrStatus::Deprecated, AdrStatus::Superseded] {
            for breaker in [
                CircuitBreakerState::Armed,
                CircuitBreakerState::Tripped,
                CircuitBreakerState::Disabled,
            ] {
                assert!(contract(status, breaker).is_valid());
            }
        }
    }

    /// Version pinning mirrors `wrong_version_invalid` on the Lean side.
    #[test]
    fn wrong_version_invalid() {
        let mut c = contract(AdrStatus::Accepted, CircuitBreakerState::Armed);
        c.schema_version += 1;
        assert!(!c.is_valid());
    }
}
