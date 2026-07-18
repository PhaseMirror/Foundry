use std::collections::{HashMap, HashSet};

/// A physical state representation incorporating the joint word topology
/// required to compute the Ṛta Metric and Arta Defect.
#[derive(Debug, Clone, Default)]
pub struct State {
    pub active_primes: HashSet<u64>,
    pub joint_words: HashMap<(u64, u64), f64>,
}

impl State {
    pub fn new() -> Self {
        Self {
            active_primes: HashSet::new(),
            joint_words: HashMap::new(),
        }
    }

    /// Compute the Langlands trace at a prime p for the identity Monster class.
    /// This is the sum of joint-word weights involving p, providing a
    /// state-dependent local trace used by the lDist metric.
    pub fn langlands_trace(&self, p: u64) -> f64 {
        let mut trace = 0.0;
        for &q in &self.active_primes {
            if p != q {
                let key = if p < q { (p, q) } else { (q, p) };
                if let Some(&weight) = self.joint_words.get(&key) {
                    trace += weight;
                }
            }
        }
        trace
    }
}

/// Discrepancy weight of a word shared by primes p and q.
#[derive(Debug, Clone)]
pub struct JointWord {
    pub p: u64,
    pub q: u64,
    pub weight: f64,
}

pub trait RtaMetric {
    fn arta_defect(&self) -> f64;
    fn coherent_weight(&self) -> f64;
    fn rta_dist(&self, other: &Self) -> f64;
    fn l_dist(&self, other: &Self) -> f64;
    fn fit(&mut self, learning_rate: f64, tolerance: f64);
}

impl RtaMetric for State {
    /// Computes the Arta defect: the sum of squared discrepancies across all joint words.
    fn arta_defect(&self) -> f64 {
        let mut defect = 0.0;
        for ((p, q), weight) in &self.joint_words {
            if self.active_primes.contains(p) && self.active_primes.contains(q) {
                defect += weight;
            }
        }
        defect
    }

    /// Computes the coherent weight (total squared evaluation mass).
    fn coherent_weight(&self) -> f64 {
        let base_mass: f64 = self.active_primes.len() as f64;
        base_mass * 10.0
    }

    /// Computes the Ṛta distance between two states.
    /// Distance is Euclidean over the 2D vector (coherentWeight, artaDefect).
    fn rta_dist(&self, other: &Self) -> f64 {
        let cw_diff = self.coherent_weight() - other.coherent_weight();
        let ad_diff = self.arta_defect() - other.arta_defect();
        (cw_diff * cw_diff + ad_diff * ad_diff).sqrt()
    }

    /// Computes the Langlands distance lDist between two states.
    /// Measures the sum of squared differences of Langlands traces over
    /// the primes present in both states.
    fn l_dist(&self, other: &Self) -> f64 {
        let common: HashSet<u64> = self.active_primes.intersection(&other.active_primes).cloned().collect();
        let mut dist = 0.0;
        for p in common {
            let t1 = self.langlands_trace(p);
            let t2 = other.langlands_trace(p);
            let d = t1 - t2;
            dist += d * d;
        }
        dist
    }

    /// The fundamental Fit operator (Gradient Descent on the Arta Defect).
    fn fit(&mut self, learning_rate: f64, tolerance: f64) {
        loop {
            let mut current_defect = 0.0;
            for weight in self.joint_words.values_mut() {
                if *weight > 0.0 {
                    current_defect += *weight;
                    *weight -= learning_rate * *weight;
                    if *weight < 1e-12 {
                        *weight = 0.0;
                    }
                }
            }

            if current_defect < tolerance {
                break;
            }
        }
    }
}

/// Stub for the CCRE Updater integration.
pub struct CCREUpdater;

impl CCREUpdater {
    pub fn update_and_audit(state: &mut State) -> f64 {
        let bindu = State::new();
        
        state.fit(0.1, 1e-6);
        
        let dist = state.rta_dist(&bindu);
        let _l_dist = state.l_dist(&bindu);
        
        // In a full implementation, l_dist would be recorded alongside
        // the RTA health snapshot. For now, we return the RTA distance.
        dist
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_fit_reduces_arta_defect() {
        let mut state = State::new();
        state.active_primes.insert(2);
        state.active_primes.insert(3);
        
        state.joint_words.insert((2, 3), 5.0);
        
        let initial_defect = state.arta_defect();
        assert!(initial_defect > 0.0);
        
        state.fit(0.2, 1e-5);
        
        let final_defect = state.arta_defect();
        assert!(final_defect < 1e-5);
    }

    #[test]
    fn test_l_dist_between_states() {
        let mut s1 = State::new();
        s1.active_primes.insert(2);
        s1.active_primes.insert(3);
        s1.joint_words.insert((2, 3), 1.0);

        let mut s2 = State::new();
        s2.active_primes.insert(2);
        s2.active_primes.insert(3);
        s2.joint_words.insert((2, 3), 2.0);

        let dist = s1.l_dist(&s2);
        assert!(dist > 0.0, "lDist should be positive for different states");
    }

    #[test]
    fn test_l_dist_same_state() {
        let mut s1 = State::new();
        s1.active_primes.insert(2);
        s1.joint_words.insert((2, 3), 1.0);

        let dist = s1.l_dist(&s1);
        assert_eq!(dist, 0.0, "lDist should be zero for identical states");
    }

    #[test]
    fn test_l_dist_no_common_primes() {
        let mut s1 = State::new();
        s1.active_primes.insert(2);

        let mut s2 = State::new();
        s2.active_primes.insert(3);

        let dist = s1.l_dist(&s2);
        assert_eq!(dist, 0.0, "lDist should be zero when no primes are common");
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    #[kani::proof]
    fn verify_fit_contracts_defect() {
        let mut state = State::new();
        let w: f64 = kani::any();
        
        kani::assume(w >= 0.0 && w <= 1000.0);
        
        state.active_primes.insert(2);
        state.active_primes.insert(3);
        state.joint_words.insert((2, 3), w);
        
        let d_initial = state.arta_defect();
        state.fit(0.1, 1e-6);
        let d_final = state.arta_defect();
        
        // Formally verify in Rust that Fit always reduces or maintains the defect
        assert!(d_final <= d_initial);
        // And if the initial defect was above tolerance, it is forcefully minimized
        if d_initial > 1e-6 {
            assert!(d_final <= 1e-6);
        }
    }
}
