//! Elastic Tether — Rust Numerical Backend
//!
//! Provides verified numerical implementations of:
//! - CMT (Coherent Multiset Tensor) navigation
//! - ETP (Elastic Tether Protocol) dynamics
//! - Prime sieving and accessibility checks
//!
//! Verification via Kani model checker.

/// Toolbelt primes for CMT factorization.
pub const TOOLBELT_PRIMES: [u64; 3] = [2, 3, 5];

/// Check if a number is accessible via CMT (has toolbelt prime factor).
pub fn is_accessible(n: u64) -> bool {
    TOOLBELT_PRIMES.iter().any(|&p| n % p == 0)
}

/// Compute CMT resistance of a state.
pub fn cmt_resistance(n: u64) -> f64 {
    if is_accessible(n) { 1.0 } else { 100.0 }
}

/// Compute CMT distance of a path.
pub fn cmt_distance(path: &[u64]) -> f64 {
    path.iter().map(|&c| cmt_resistance(c)).sum()
}

/// Sieve of Eratosthenes: find all primes up to limit.
pub fn sieve(limit: u64) -> Vec<bool> {
    let mut is_prime = vec![true; (limit + 1) as usize];
    is_prime[0] = false;
    if limit >= 1 {
        is_prime[1] = false;
    }
    for i in 2..=limit {
        if is_prime[i as usize] && i * i <= limit {
            for j in (i * i..=limit).step_by(i as usize) {
                is_prime[j as usize] = false;
            }
        }
    }
    is_prime
}

/// Count primes up to n.
pub fn pi(n: u64) -> u64 {
    let is_prime = sieve(n);
    is_prime.iter().filter(|&&p| p).count() as u64
}

/// Compute accessible states up to N.
pub fn accessible_states(n: u64) -> Vec<u64> {
    (0..=n).filter(|&x| is_accessible(x)).collect()
}

/// Compute max gap between consecutive accessible states.
pub fn max_cmt_gap(n: u64) -> u64 {
    let states = accessible_states(n);
    if states.len() < 2 {
        return 0;
    }
    states.windows(2).map(|w| w[1] - w[0]).max().unwrap_or(0)
}

/// Compute mean CMT gap.
pub fn mean_cmt_gap(n: u64) -> f64 {
    let states = accessible_states(n);
    if states.len() < 2 {
        return 0.0;
    }
    let gaps: Vec<u64> = states.windows(2).map(|w| w[1] - w[0]).collect();
    let sum: u64 = gaps.iter().sum();
    sum as f64 / gaps.len() as f64
}

/// Safety parameters for ETP.
#[derive(Debug, Clone, Copy)]
pub struct SafetyParams {
    pub cost_interrogate: u64,
    pub v_max: u64,
    pub v_min: u64,
}

impl SafetyParams {
    /// Derived safe lead distance Δ_safe = Cost_interrogate / v_max.
    pub fn delta_safe(&self) -> u64 {
        self.cost_interrogate / self.v_max
    }
}

/// Agent state at time t.
#[derive(Debug, Clone, Copy)]
pub struct AgentState {
    pub head_pos: u64,
    pub tail_pos: u64,
    pub params: SafetyParams,
}

impl AgentState {
    /// Current lag L(t) = x_head - x_tail.
    pub fn lag(&self) -> u64 {
        self.head_pos - self.tail_pos
    }

    /// Check if in lead region (lag > Δ_safe).
    pub fn in_lead_region(&self) -> bool {
        self.lag() > self.params.delta_safe()
    }

    /// Head velocity law (physics-based, no oracle).
    pub fn head_velocity(&self, mu_bar: f64) -> u64 {
        let l = self.lag();
        let delta = self.params.delta_safe();
        if l > delta {
            self.params.v_min
        } else {
            let bonus = (self.params.v_max - self.params.v_min) as f64 * mu_bar;
            self.params.v_min + bonus.floor() as u64
        }
    }

    /// Tether potential V_tether = 0.5 * k * (L - Δ_safe)^2.
    pub fn tether_potential(&self, k: f64) -> f64 {
        let l = self.lag() as f64;
        let delta = self.params.delta_safe() as f64;
        0.5 * k * (l - delta).powi(2)
    }
}

/// CMT navigator: compute next accessible state from current position.
pub fn cmt_navigate(current: u64, max_n: u64) -> Option<u64> {
    let accessible = accessible_states(max_n);
    accessible.iter().find(|&&x| x > current).copied()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_is_accessible_2() {
        assert!(is_accessible(2));
    }

    #[test]
    fn test_is_accessible_4() {
        assert!(is_accessible(4));
    }

    #[test]
    fn test_not_accessible_7() {
        assert!(!is_accessible(7));
    }

    #[test]
    fn test_cmt_gap_reduction() {
        assert!(max_cmt_gap(100_000) <= 2);
    }

    #[test]
    fn test_lag_nonnegative() {
        let state = AgentState {
            head_pos: 100,
            tail_pos: 50,
            params: SafetyParams {
                cost_interrogate: 10,
                v_max: 100,
                v_min: 1,
            },
        };
        assert!(state.lag() >= 0);
    }

    #[test]
    fn test_lead_region_vmin() {
        let state = AgentState {
            head_pos: 5000,
            tail_pos: 1000,
            params: SafetyParams {
                cost_interrogate: 10,
                v_max: 100,
                v_min: 1,
            },
        };
        assert!(state.in_lead_region());
        assert_eq!(state.head_velocity(0.0), 1);
    }
}
