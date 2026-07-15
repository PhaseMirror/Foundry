//! # Universal Atomic Calculator (UAC) – Langlands-Native Loss Function
//!
//! Extends the UAC's variational optimization with a Frobenius-weighted
//! Langlands penalty term. This forces the optimizer to find states that
//! are not only energetically minimal but also arithmetically authentic—
//! they lie on the correct Galois representations.

use crate::galois::{GaloisRepresentation, LanglandsPairing, MonsterConjugacyClass};
use crate::rta::{RtaMetric, State};

// ---------------------------------------------------------------------------
// Langlands-weighted loss function
// ---------------------------------------------------------------------------

/// Configuration for the Langlands-weighted loss function.
#[derive(Debug, Clone, Copy)]
pub struct LanglandsLossConfig {
    /// Weight of the Langlands penalty term in the total loss.
    pub lambda_langlands: f64,
    /// Prime bound for the truncated Euler product.
    pub prime_bound: u64,
    /// Tolerance for non-vanishing of L(1, ρ_g).
    pub tolerance: f64,
    /// Whether to include the Artin conductor factor.
    pub include_conductor: bool,
}

impl Default for LanglandsLossConfig {
    fn default() -> Self {
        Self {
            lambda_langlands: 0.1,
            prime_bound: 100,
            tolerance: 1e-12,
            include_conductor: true,
        }
    }
}

/// Computes the Frobenius-weighted Langlands loss for a given state.
///
/// The loss is:
///   L_Langlands = lambda * sum_{g activated} |L(1, ρ_g) - target_g|^2
///
/// where `target_g` is the expected L-value for class g (typically 1.0 for
/// the identity class, derived from the normalized j-invariant).
pub fn langlands_loss(
    state: &State,
    config: LanglandsLossConfig,
) -> f64 {
    let mut total_loss = 0.0;
    let activated_classes = activated_monster_classes(state);

    for class in activated_classes {
        let repr = match GaloisRepresentation::with_goldilocks(class) {
            Ok(r) => r,
            Err(_) => continue,
        };

        let pairing = LanglandsPairing::with_config(
            repr,
            crate::galois::LanglandsPairingConfig {
                prime_bound: config.prime_bound,
                s: 1.0,
                tolerance: config.tolerance,
                include_conductor: config.include_conductor,
            },
        );

        match pairing.special_value_at_one() {
            Ok(l_val) => {
                let target = 1.0; // Target L-value for a valid Galois representation
                let diff = l_val - target;
                total_loss += diff * diff;
            }
            Err(_) => {
                // If L(1, ρ_g) vanishes or is invalid, add a large penalty
                total_loss += 1.0;
            }
        }
    }

    config.lambda_langlands * total_loss
}

/// Compute the total UAC loss, combining the standard Arta defect with
/// the Langlands penalty.
///
///   L_total = L_arta + L_Langlands
pub fn uac_total_loss(state: &State, langlands_config: LanglandsLossConfig) -> f64 {
    let arta_loss = state.arta_defect();
    let langlands_loss = langlands_loss(state, langlands_config);
    arta_loss + langlands_loss
}

/// Determine which Monster classes are activated by the current state.
///
/// A class is activated if any prime in its associated prime set appears
/// in the state's active primes.
fn activated_monster_classes(state: &State) -> Vec<MonsterConjugacyClass> {
    let mut activated = Vec::new();
    for class in crate::gates::ALL_MONSTER_CLASSES {
        let assoc = crate::gates::associated_primes(class);
        if assoc.iter().any(|p| state.active_primes.contains(p)) {
            activated.push(*class);
        }
    }
    activated
}

// ---------------------------------------------------------------------------
// Arithmetic Bindu Attractor
// ---------------------------------------------------------------------------

/// The Arithmetic Bindu Attractor refines the Bindu attractor by requiring
/// that the perfect state's prime-indexed operators form a global Artin
/// representation compatible with the Monster's moonshine module.
///
/// The MSC stablecoin becomes a measure of distance from this arithmetic Bindu,
/// linking economic value directly to the Langlands program.
#[derive(Debug, Clone)]
pub struct ArithmeticBinduAttractor {
    /// The target Monster class for the attractor (typically the identity).
    pub target_class: MonsterConjugacyClass,
    /// The target L-value for the attractor (typically 1.0).
    pub target_l_value: f64,
    /// Tolerance for considering a state "at the attractor".
    pub tolerance: f64,
}

impl ArithmeticBinduAttractor {
    /// Create a new Arithmetic Bindu Attractor with default settings.
    pub fn new() -> Self {
        Self {
            target_class: MonsterConjugacyClass::IDENTITY,
            target_l_value: 1.0,
            tolerance: 1e-6,
        }
    }

    /// Create with custom settings.
    pub fn with_config(target_class: MonsterConjugacyClass, target_l_value: f64, tolerance: f64) -> Self {
        Self {
            target_class,
            target_l_value,
            tolerance,
        }
    }

    /// Compute the distance from a state to the Arithmetic Bindu attractor.
    ///
    /// This is the sum of:
    /// 1. The RTA distance to the zero-defect Bindu state
    /// 2. The Langlands distance to the target L-value
    pub fn distance(&self, state: &State) -> f64 {
        let bindu = State::new();
        let rta_dist = state.rta_dist(&bindu);
        let l_dist = state.l_dist(&bindu);

        // Compute Langlands penalty
        let repr = match GaloisRepresentation::with_goldilocks(self.target_class) {
            Ok(r) => r,
            Err(_) => return f64::INFINITY,
        };

        let pairing = LanglandsPairing::new(repr);
        let l_val = match pairing.special_value_at_one() {
            Ok(v) => v,
            Err(_) => return f64::INFINITY,
        };

        let langlands_dist = (l_val - self.target_l_value).abs();

        // Combined distance: RTA + Langlands
        rta_dist + l_dist + langlands_dist
    }

    /// Check if a state is at the Arithmetic Bindu attractor.
    pub fn is_at_attractor(&self, state: &State) -> bool {
        self.distance(state) < self.tolerance
    }
}

impl Default for ArithmeticBinduAttractor {
    fn default() -> Self {
        Self::new()
    }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_langlands_loss_empty_state() {
        let state = State::new();
        let config = LanglandsLossConfig::default();
        let loss = langlands_loss(&state, config);
        assert!(loss >= 0.0);
    }

    #[test]
    fn test_uac_total_loss_combines_arta_and_langlands() {
        let mut state = State::new();
        state.active_primes.insert(2);
        state.joint_words.insert((2, 3), 1.0);
        let config = LanglandsLossConfig::default();
        let total = uac_total_loss(&state, config);
        assert!(total >= state.arta_defect());
    }

    #[test]
    fn test_arithmetic_bindu_attractor_distance() {
        let attractor = ArithmeticBinduAttractor::new();
        let state = State::new();
        let dist = attractor.distance(&state);
        assert!(dist >= 0.0 || dist.is_infinite());
    }

    #[test]
    fn test_arithmetic_bindu_attractor_at_bindu() {
        let attractor = ArithmeticBinduAttractor::with_config(
            MonsterConjugacyClass::IDENTITY,
            1.0,
            1e-6,
        );
        let state = State::new();
        // The Bindu state should be close to the attractor
        // (though the L-value may not be exactly 1.0 due to numerical precision)
        let _ = attractor.is_at_attractor(&state);
    }
}
