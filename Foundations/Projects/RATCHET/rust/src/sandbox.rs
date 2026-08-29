//! BURST Actuation Sandbox and Hardware Safety Interlock (ADR-0038 §5.2)

use crate::types::PlantState;

pub const DEFAULT_MAX_ACTUATION: f64 = 100.0;

/// Sandbox state tracker enforcing isolation during BURST.
pub struct Sandbox {
    pub max_actuation: f64,
    pub network_disabled: bool,
    pub ephemeral_only: bool,
    pub killed: bool,
}

impl Sandbox {
    pub fn new(max_actuation: f64) -> Self {
        Self {
            max_actuation,
            network_disabled: true,
            ephemeral_only: true,
            killed: false,
        }
    }

    /// Map real actuator commands into safe bounded sandbox space.
    pub fn map_actuation(&self, u: &[f64]) -> Vec<f64> {
        u.iter()
            .map(|&val| {
                if val > self.max_actuation {
                    self.max_actuation
                } else if val < -self.max_actuation {
                    -self.max_actuation
                } else {
                    val
                }
            })
            .collect()
    }

    /// Check sandbox invariant: network disabled, ephemeral storage only, actuation within range, unkilled.
    pub fn check_invariant(&self, state: &PlantState) -> bool {
        if self.killed || !self.network_disabled || !self.ephemeral_only {
            return false;
        }

        for &val in &state.u {
            if val.abs() > self.max_actuation + 1e-6 {
                return false;
            }
        }

        true
    }

    /// Emergency kill-switch triggerable only by C_ext.
    pub fn kill(&mut self) {
        self.killed = true;
    }

    /// Reset sandbox for a new burst session.
    pub fn reset(&mut self) {
        self.killed = false;
        self.network_disabled = true;
        self.ephemeral_only = true;
    }
}
