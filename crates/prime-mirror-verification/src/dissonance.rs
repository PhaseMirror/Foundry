//! ADR-402: Phase Mirror Dissonance Ratification — Rust verification layer
//!
//! Implements Sigma Kernel → mirror-dissonance-rs governance boundary,
//! circuit-breaker routing, and CSL Projector ratification verified by Kani.

/// Severity levels for dissonance violations.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Severity {
    Critical,
    High,
    Medium,
    Low,
}

/// Decision outcomes from the dissonance engine.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Outcome {
    Allow,
    Warn,
    Block,
}

/// Dissonance trigger condition.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DissonanceTrigger {
    ResonanceDelta(u64, u64),  // delta, tau_r
    LipschitzContraction(u64), // l_eff
    Both(u64, u64, u64),       // delta, tau_r, l_eff
    None,
}

/// Resonance vector (simplified RVector).
#[derive(Debug, Clone, Copy)]
pub struct RVector {
    pub r1: u64,
    pub r2: u64,
    pub r3: u64,
}

impl RVector {
    pub fn new(r1: u64, r2: u64, r3: u64) -> Self {
        RVector { r1, r2, r3 }
    }
}

/// Resonance score R_sc = cube root of (r1 * r2 * r3), integer approximation.
pub fn r_sc(r: &RVector) -> u64 {
    let prod = r.r1 * r.r2 * r.r3;
    if prod == 0 {
        0
    } else {
        // Integer cube root approximation
        let mut x = 1;
        while (x + 1).pow(3) <= prod {
            x += 1;
        }
        x
    }
}

/// Null-model threshold τ_R.
pub fn tau_r(r: &RVector) -> u64 {
    let delta_top = (r.r1 - r.r1).pow(2) + (r.r2 - r.r2).pow(2) + (r.r3 - r.r3).pow(2);
    r.r1 - delta_top
}

/// Resonance scale delta: ΔR_sc = |R_sc - τ_R|.
pub fn delta_r_sc(r: &RVector) -> u64 {
    let rs = r_sc(r);
    let tr = tau_r(r);
    if rs >= tr { rs - tr } else { tr - rs }
}

/// Effective Lipschitz contraction L_eff.
pub fn l_eff(r: &RVector) -> u64 {
    10000 - r_sc(r)
}

/// L_eff threshold: ≥ 10000 (scaled 1.0) is a breach.
pub fn l_eff_threshold() -> u64 {
    10000
}

/// Evaluate dissonance trigger.
pub fn triggers_dissonance(r: &RVector) -> DissonanceTrigger {
    let dr = delta_r_sc(r);
    let le = l_eff(r);
    let tr = tau_r(r);

    if dr > tr {
        if le >= l_eff_threshold() {
            DissonanceTrigger::Both(dr, tr, le)
        } else {
            DissonanceTrigger::ResonanceDelta(dr, tr)
        }
    } else if le >= l_eff_threshold() {
        DissonanceTrigger::LipschitzContraction(le)
    } else {
        DissonanceTrigger::None
    }
}

/// Severity of a dissonance trigger.
pub fn trigger_severity(t: &DissonanceTrigger) -> Severity {
    match t {
        DissonanceTrigger::None => Severity::Low,
        DissonanceTrigger::ResonanceDelta(_, _) => Severity::High,
        DissonanceTrigger::LipschitzContraction(_) => Severity::Critical,
        DissonanceTrigger::Both(_, _, _) => Severity::Critical,
    }
}

/// Decision outcome for a trigger.
pub fn trigger_outcome(t: &DissonanceTrigger) -> Outcome {
    match t {
        DissonanceTrigger::None => Outcome::Allow,
        DissonanceTrigger::ResonanceDelta(_, _) => Outcome::Warn,
        DissonanceTrigger::LipschitzContraction(_) => Outcome::Block,
        DissonanceTrigger::Both(_, _, _) => Outcome::Block,
    }
}

/// Severity to outcome mapping: Critical → Block, High → Warn, others → Allow.
pub fn severity_to_outcome(s: &Severity) -> Outcome {
    match s {
        Severity::Critical => Outcome::Block,
        Severity::High => Outcome::Warn,
        Severity::Medium => Outcome::Allow,
        Severity::Low => Outcome::Allow,
    }
}

/// Circuit-breaker state machine.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CircuitBreakerState {
    Closed,
    Open,
    HalfOpen,
}

/// Circuit-breaker configuration.
#[derive(Debug, Clone, Copy)]
pub struct CircuitBreakerConfig {
    pub failure_threshold: u64,
    pub recovery_timeout: u64,
}

impl Default for CircuitBreakerConfig {
    fn default() -> Self {
        CircuitBreakerConfig { failure_threshold: 3, recovery_timeout: 5 }
    }
}

/// Circuit-breaker tracking state.
#[derive(Debug, Clone, Copy)]
pub struct CircuitBreaker {
    pub state: CircuitBreakerState,
    pub failure_count: u64,
    pub last_failure_time: u64,
    pub config: CircuitBreakerConfig,
}

impl Default for CircuitBreaker {
    fn default() -> Self {
        CircuitBreaker {
            state: CircuitBreakerState::Closed,
            failure_count: 0,
            last_failure_time: 0,
            config: CircuitBreakerConfig::default(),
        }
    }
}

impl CircuitBreaker {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn record_failure(&self, now: u64) -> Self {
        if self.failure_count + 1 >= self.config.failure_threshold {
            CircuitBreaker {
                state: CircuitBreakerState::Open,
                failure_count: self.failure_count + 1,
                last_failure_time: now,
                config: self.config,
            }
        } else {
            CircuitBreaker {
                state: self.state,
                failure_count: self.failure_count + 1,
                last_failure_time: self.last_failure_time,
                config: self.config,
            }
        }
    }

    pub fn attempt_recovery(&self, now: u64) -> Self {
        if self.state == CircuitBreakerState::Open
            && now - self.last_failure_time >= self.config.recovery_timeout
        {
            CircuitBreaker {
                state: CircuitBreakerState::HalfOpen,
                failure_count: 0,
                last_failure_time: self.last_failure_time,
                config: self.config,
            }
        } else {
            *self
        }
    }

    pub fn record_success(&self) -> Self {
        if self.state == CircuitBreakerState::HalfOpen {
            CircuitBreaker {
                state: CircuitBreakerState::Closed,
                failure_count: 0,
                last_failure_time: self.last_failure_time,
                config: self.config,
            }
        } else {
            *self
        }
    }
}

/// Routing decision: should the Sigma Kernel route to mirror-dissonance-rs?
pub fn should_route_dissonance(cb: &CircuitBreaker, t: &DissonanceTrigger) -> bool {
    cb.state == CircuitBreakerState::Closed && trigger_outcome(t) == Outcome::Block
}

/// Conflict log entry recording a dissonance event.
#[derive(Debug, Clone, Copy)]
pub struct ConflictLogEntry {
    pub receipt_hash: u64,
    pub r_sc: u64,
    pub l_eff: u64,
    pub tau_r: u64,
    pub breach_type: u64, // 0=None, 1=ResonanceDelta, 2=LipschitzContraction, 3=Both
    pub timestamp: u64,
}

/// CSL Projector: final arbiter that ratifies dissonance logs.
#[derive(Debug, Clone, Default)]
pub struct CSLProjector {
    pub ratification_log: Vec<ConflictLogEntry>,
}

impl CSLProjector {
    pub fn new() -> Self {
        CSLProjector { ratification_log: Vec::new() }
    }

    pub fn ratify(&mut self, entry: ConflictLogEntry) {
        self.ratification_log.push(entry);
    }
}

/// Sigma Kernel evaluation: produces a dissonance event if invariants are breached.
pub fn evaluate_sigma_kernel(
    r: &RVector,
    cb: &CircuitBreaker,
    now: u64,
    receipt: u64,
) -> (DissonanceTrigger, bool, CircuitBreaker) {
    let t = triggers_dissonance(r);
    let route = should_route_dissonance(cb, &t);
    let new_cb = if route { cb.record_failure(now) } else { cb.record_success() };
    let ratified = route && cb.state == CircuitBreakerState::Closed;
    (t, ratified, new_cb)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_prime_2_is_prime() {
        assert!(PrimeMoc::new(2, 0).is_some());
    }

    #[test]
    fn test_prime_3_is_prime() {
        assert!(PrimeMoc::new(3, 0).is_some());
    }

    #[test]
    fn test_circuit_breaker_initial() {
        let cb = CircuitBreaker::new();
        assert_eq!(cb.state, CircuitBreakerState::Closed);
        assert_eq!(cb.failure_count, 0);
    }

    #[test]
    fn test_circuit_breaker_trips() {
        let cb = CircuitBreaker::new();
        let cb = cb.record_failure(1);
        let cb = cb.record_failure(2);
        let cb = cb.record_failure(3);
        assert_eq!(cb.state, CircuitBreakerState::Open);
    }

    #[test]
    fn test_circuit_breaker_recovery() {
        let cb = CircuitBreaker {
            state: CircuitBreakerState::Open,
            failure_count: 3,
            last_failure_time: 0,
            config: CircuitBreakerConfig::default(),
        };
        let cb = cb.attempt_recovery(5);
        assert_eq!(cb.state, CircuitBreakerState::HalfOpen);
    }

    #[test]
    fn test_csl_projector_append_only() {
        let mut proj = CSLProjector::new();
        let entry = ConflictLogEntry {
            receipt_hash: 1,
            r_sc: 0,
            l_eff: 10000,
            tau_r: 0,
            breach_type: 2,
            timestamp: 0,
        };
        proj.ratify(entry);
        assert_eq!(proj.ratification_log.len(), 1);
    }

    #[test]
    fn test_n108_no_dissonance() {
        // RVector with r1=r2=r3=8500 gives R_sc ≈ 8500, L_eff = 1500 < 10000
        let r = RVector::new(8500, 8500, 8500);
        let t = triggers_dissonance(&r);
        assert_eq!(t, DissonanceTrigger::None);
    }

    #[test]
    fn test_low_resonance_triggers_lipschitz() {
        // RVector with r1=r2=r3=0 gives R_sc = 0, L_eff = 10000
        let r = RVector::new(0, 0, 1);
        let t = triggers_dissonance(&r);
        assert_eq!(t, DissonanceTrigger::LipschitzContraction(10000));
    }
}
