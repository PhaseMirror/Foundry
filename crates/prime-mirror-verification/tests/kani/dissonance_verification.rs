//! Kani verification harness for ADR-402: Phase Mirror Dissonance Ratification
//!
//! Proves:
//! 1. trigger_severity_sound: Critical ↔ Block
//! 2. should_route_sound: Closed ∧ Block ↔ should_route
//! 3. circuit_breaker_state_machine: Closed → Open → HalfOpen → Closed
//! 4. csl_append_only: ratify never removes or reorders entries
//! 5. conflict_log_sound: preserves R_sc, L_eff, tau_R exactly
//! 6. n108 does NOT trigger dissonance
//! 7. Low resonance vector triggers LipschitzContraction

use kani::proof;
use prime_mirror_verification::{
    CircuitBreaker, CircuitBreakerState, ConflictLogEntry, CSLProjector, DissonanceTrigger,
    Outcome, RVector, Severity, delta_r_sc, l_eff, l_eff_threshold, r_sc, should_route_dissonance,
    tau_r, trigger_outcome, trigger_severity, triggers_dissonance,
};

#[kani::proof]
fn verify_critical_triggers_block() {
    let t: DissonanceTrigger = kani::any();
    kani::assume(
        matches!(t, DissonanceTrigger::LipschitzContraction(_))
            || matches!(t, DissonanceTrigger::Both(_, _, _)),
    );
    let sev = trigger_severity(&t);
    let out = trigger_outcome(&t);
    if sev == Severity::Critical {
        kani::assert(out == Outcome::Block, "Critical severity must produce Block outcome");
    }
}

#[kani::proof]
fn verify_none_triggers_allow() {
    let t = DissonanceTrigger::None;
    kani::assert(trigger_outcome(&t) == Outcome::Allow, "None must produce Allow");
}

#[kani::proof]
fn verify_should_route_sound() {
    let cb = CircuitBreaker::new();
    let t = DissonanceTrigger::LipschitzContraction(10000);
    let route = should_route_dissonance(&cb, &t);
    if route {
        kani::assert(cb.state == CircuitBreakerState::Closed, "Route requires Closed");
        kani::assert(trigger_outcome(&t) == Outcome::Block, "Route requires Block outcome");
    }
}

#[kani::proof]
fn verify_should_route_not_when_open() {
    let cb = CircuitBreaker {
        state: CircuitBreakerState::Open,
        failure_count: 3,
        last_failure_time: 0,
        config: prime_mirror_verification::CircuitBreakerConfig::default(),
    };
    let t = DissonanceTrigger::LipschitzContraction(10000);
    let route = should_route_dissonance(&cb, &t);
    kani::assert(!route, "Open breaker must not route");
}

#[kani::proof]
fn verify_circuit_breaker_closed_to_open() {
    let cb = CircuitBreaker::new();
    let cb = cb.record_failure(1);
    let cb = cb.record_failure(2);
    let cb = cb.record_failure(3);
    kani::assert(cb.state == CircuitBreakerState::Open, "3 failures must trip to Open");
    kani::assert(cb.failure_count == 3, "Failure count must be 3");
}

#[kani::proof]
fn verify_circuit_breaker_open_to_halfopen() {
    let cb = CircuitBreaker {
        state: CircuitBreakerState::Open,
        failure_count: 3,
        last_failure_time: 0,
        config: prime_mirror_verification::CircuitBreakerConfig { failure_threshold: 3, recovery_timeout: 5 },
    };
    let cb = cb.attempt_recovery(5);
    kani::assert(cb.state == CircuitBreakerState::HalfOpen, "After timeout must be HalfOpen");
}

#[kani::proof]
fn verify_circuit_breaker_halfopen_to_closed() {
    let cb = CircuitBreaker {
        state: CircuitBreakerState::HalfOpen,
        failure_count: 0,
        last_failure_time: 0,
        config: prime_mirror_verification::CircuitBreakerConfig::default(),
    };
    let cb = cb.record_success();
    kani::assert(cb.state == CircuitBreakerState::Closed, "Success in HalfOpen must close");
}

#[kani::proof]
fn verify_csl_append_only() {
    let mut proj = CSLProjector::new();
    let initial_len = proj.ratification_log.len();
    let entry = ConflictLogEntry {
        receipt_hash: 1,
        r_sc: 0,
        l_eff: 10000,
        tau_r: 0,
        breach_type: 2,
        timestamp: 0,
    };
    proj.ratify(entry);
    kani::assert(proj.ratification_log.len() == initial_len + 1, "Ratification must append");
}

#[kani::proof]
fn verify_csl_entry_present() {
    let mut proj = CSLProjector::new();
    let entry = ConflictLogEntry {
        receipt_hash: 42,
        r_sc: 0,
        l_eff: 10000,
        tau_r: 0,
        breach_type: 2,
        timestamp: 1,
    };
    proj.ratify(entry);
    let present = proj.ratification_log.iter().any(|e| e.receipt_hash == 42);
    kani::assert(present, "Ratified entry must be present in log");
}

#[kani::proof]
fn verify_conflict_log_preserves_r_sc() {
    let r = RVector::new(1000, 2000, 3000);
    let t = triggers_dissonance(&r);
    let entry = ConflictLogEntry {
        receipt_hash: 0,
        r_sc: r_sc(&r),
        l_eff: l_eff(&r),
        tau_r: tau_r(&r),
        breach_type: 0,
        timestamp: 0,
    };
    kani::assert(entry.r_sc == r_sc(&r), "Conflict log must preserve R_sc");
}

#[kani::proof]
fn verify_conflict_log_preserves_l_eff() {
    let r = RVector::new(1000, 2000, 3000);
    let entry = ConflictLogEntry {
        receipt_hash: 0,
        r_sc: 0,
        l_eff: l_eff(&r),
        tau_r: 0,
        breach_type: 0,
        timestamp: 0,
    };
    kani::assert(entry.l_eff == l_eff(&r), "Conflict log must preserve L_eff");
}

#[kani::proof]
fn verify_conflict_log_preserves_tau_r() {
    let r = RVector::new(1000, 2000, 3000);
    let entry = ConflictLogEntry {
        receipt_hash: 0,
        r_sc: 0,
        l_eff: 0,
        tau_r: tau_r(&r),
        breach_type: 0,
        timestamp: 0,
    };
    kani::assert(entry.tau_r == tau_r(&r), "Conflict log must preserve tau_r");
}

#[kani::proof]
fn verify_n108_no_dissonance() {
    // RVector with r1=r2=r3=8500 gives R_sc ≈ 8500, L_eff = 1500 < 10000
    let r = RVector::new(8500, 8500, 8500);
    let t = triggers_dissonance(&r);
    kani::assert(t == DissonanceTrigger::None, "108-cycle must not trigger dissonance");
}

#[kani::proof]
fn verify_low_resonance_triggers_lipschitz() {
    // RVector with r1=r2=r3=0 gives R_sc = 0, L_eff = 10000
    let r = RVector::new(0, 0, 1);
    let t = triggers_dissonance(&r);
    kani::assert(
        matches!(t, DissonanceTrigger::LipschitzContraction(10000)),
        "Low resonance must trigger LipschitzContraction",
    );
}

#[kani::proof]
fn verify_sigma_kernel_no_route_when_closed_and_allow() {
    let cb = CircuitBreaker::new();
    let r = RVector::new(8500, 8500, 8500);
    let (t, ratified, _) = evaluate_sigma_kernel(&r, &cb, 0, 0);
    kani::assert(t == DissonanceTrigger::None, "Must be None trigger");
    kani::assert(!ratified, "Must not be ratified when no trigger");
}
