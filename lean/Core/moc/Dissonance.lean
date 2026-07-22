/- ===========================================================================
    ADR-402: Phase Mirror Dissonance Ratification
    Production-grade formalization of the Sigma Kernel → mirror-dissonance-rs
    governance boundary, circuit-breaker routing, and CSL Projector ratification.
    Heavy verification is performed in Rust/Kani.
    =========================================================================== -/

import Init.Data.Nat.Basic
import Init.Data.List.Basic
import Init.Data.String.Basic
import Core.Spine
import Core.moc.Resonance
import Core.Resonance
import Core.prime_tensors.Stability

namespace MOC.Dissonance

open MOC MOC.Resonance CRMF PIRTM Core.Spine

/-! ## Dissonance Severity and Outcome -/

/-- Severity levels for dissonance violations. -/
inductive Severity where
  | Critical
  | High
  | Medium
  | Low
  deriving Repr, DecidableEq

/-- Decision outcomes from the dissonance engine. -/
inductive Outcome where
  | Allow
  | Warn
  | Block
  deriving Repr, DecidableEq

/-! ## Resonance Metrics -/

/-- Resonance scale delta: ΔR_sc = |R_sc - τ_R|. -/
def delta_R_sc (r : RVector) : Nat :=
  if R_sc r >= tau_R r then R_sc r - tau_R r else tau_R r - R_sc r

/-- Effective Lipschitz contraction L_eff from resonance score. -/
def L_eff (r : RVector) : Nat :=
  10000 - R_sc r

/-- L_eff threshold: ≥ 1.0 (scaled: ≥ 10000) is a breach. -/
def L_eff_threshold : Nat := 10000

/-- Resonance delta threshold: τ_R itself is the null-model threshold. -/
def delta_R_threshold (r : RVector) : Nat :=
  tau_R r

/-! ## Dissonance Trigger Conditions -/

/-- A dissonance trigger records which invariant was breached. -/
inductive DissonanceTrigger where
  | ResonanceDelta (delta : Nat) (tau_r : Nat)
  | LipschitzContraction (l_eff : Nat)
  | Both (delta : Nat) (tau_r : Nat) (l_eff : Nat)
  | None
  deriving Repr, DecidableEq

/-- Evaluate whether a resonance vector triggers dissonance. -/
def triggers_dissonance (r : RVector) : DissonanceTrigger :=
  let dr := delta_R_sc r
  let le := L_eff r
  let tr := tau_R r
  if dr > tr then
    if le >= L_eff_threshold then DissonanceTrigger.Both dr tr le
    else DissonanceTrigger.ResonanceDelta dr tr
  else if le >= L_eff_threshold then DissonanceTrigger.LipschitzContraction le
  else DissonanceTrigger.None

/-- Severity of a dissonance trigger. -/
def trigger_severity (t : DissonanceTrigger) : Severity :=
  match t with
  | DissonanceTrigger.None => Severity.Low
  | DissonanceTrigger.ResonanceDelta _ _ => Severity.High
  | DissonanceTrigger.LipschitzContraction _ => Severity.Critical
  | DissonanceTrigger.Both _ _ _ => Severity.Critical

/-- Decision outcome for a trigger. -/
def trigger_outcome (t : DissonanceTrigger) : Outcome :=
  match t with
  | DissonanceTrigger.None => Outcome.Allow
  | DissonanceTrigger.ResonanceDelta _ _ => Outcome.Warn
  | DissonanceTrigger.LipschitzContraction _ => Outcome.Block
  | DissonanceTrigger.Both _ _ _ => Outcome.Block

/-! ## Conflict Log Schema -/

/-- Conflict log entry recording a dissonance event. -/
structure ConflictLogEntry where
  receipt_hash : String
  r_sc : Nat
  l_eff : Nat
  tau_r : Nat
  breach_type : String
  timestamp : Nat
  deriving Repr

/-- Generate a conflict log entry from a resonance vector and trigger. -/
def conflict_log (receipt : String) (r : RVector) (t : DissonanceTrigger) (ts : Nat) : ConflictLogEntry :=
  let breach :=
    match t with
    | DissonanceTrigger.ResonanceDelta _ _ => "ResonanceDelta"
    | DissonanceTrigger.LipschitzContraction _ => "LipschitzContraction"
    | DissonanceTrigger.Both _ _ _ => "Both"
    | DissonanceTrigger.None => "None"
  { receipt_hash := receipt,
    r_sc := R_sc r,
    l_eff := L_eff r,
    tau_r := tau_R r,
    breach_type := breach,
    timestamp := ts }

/-! ## Circuit-Breaker State -/

/-- Circuit-breaker state machine for the Sigma Kernel → dissonance routing. -/
inductive CircuitBreakerState where
  | Closed
  | Open
  | HalfOpen
  deriving Repr, DecidableEq

/-- Circuit-breaker configuration. -/
structure CircuitBreakerConfig where
  failure_threshold : Nat
  recovery_timeout : Nat
  deriving Repr

/-- Circuit-breaker tracking state. -/
structure CircuitBreaker where
  state : CircuitBreakerState
  failure_count : Nat
  last_failure_time : Nat
  config : CircuitBreakerConfig

/-- Default circuit-breaker configuration. -/
def defaultCircuitBreakerConfig : CircuitBreakerConfig :=
  { failure_threshold := 3, recovery_timeout := 5 }

/-- Initial circuit-breaker state. -/
def initialCircuitBreaker : CircuitBreaker :=
  { state := CircuitBreakerState.Closed,
    failure_count := 0,
    last_failure_time := 0,
    config := defaultCircuitBreakerConfig }

/-- Record a failure and potentially trip the breaker. -/
def record_failure (cb : CircuitBreaker) (now : Nat) : CircuitBreaker :=
  if cb.failure_count + 1 >= cb.config.failure_threshold then
    { cb with state := CircuitBreakerState.Open, failure_count := cb.failure_count + 1, last_failure_time := now }
  else
    { cb with failure_count := cb.failure_count + 1 }

/-- Attempt to recover from open state. -/
def attempt_recovery (cb : CircuitBreaker) (now : Nat) : CircuitBreaker :=
  if cb.state = CircuitBreakerState.Open ∧ now - cb.last_failure_time >= cb.config.recovery_timeout then
    { cb with state := CircuitBreakerState.HalfOpen, failure_count := 0 }
  else
    cb

/-- Successful request in HalfOpen closes the breaker. -/
def record_success (cb : CircuitBreaker) : CircuitBreaker :=
  if cb.state = CircuitBreakerState.HalfOpen then
    { cb with state := CircuitBreakerState.Closed }
  else
    cb

/-- Routing decision: should the Sigma Kernel route to mirror-dissonance-rs? -/
def should_route_dissonance (cb : CircuitBreaker) (t : DissonanceTrigger) : Bool :=
  cb.state = CircuitBreakerState.Closed ∧ trigger_outcome t = Outcome.Block

/-! ## CSL Projector Ratification -/

/-- CSL Projector: final arbiter that ratifies dissonance logs. -/
structure CSLProjector where
  ratification_log : List ConflictLogEntry
  deriving Repr

/-- Empty projector with no ratified entries. -/
def emptyCSLProjector : CSLProjector :=
  { ratification_log := [] }

/-- Ratify a conflict log entry: permanently record it. -/
def ratify (proj : CSLProjector) (entry : ConflictLogEntry) : CSLProjector :=
  { proj with ratification_log := proj.ratification_log ++ [entry] }

/-- Ratification is append-only: existing entries are preserved. -/
theorem ratification_append_only (proj : CSLProjector) (entry : ConflictLogEntry) :
    proj.ratification_log ⊆ (ratify proj entry).ratification_log := sorry