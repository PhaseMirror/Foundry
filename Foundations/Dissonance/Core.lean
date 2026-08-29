import Foundations.ADR.Core

/-!
# Foundations.Dissonance.Core — Phase Mirror Dissonance & Circuit Breaker Tracking

Formalizes dissonance severity levels, conflict log entries, circuit-breaker state machines,
and ADR immutability preservation theorems under dissonance attachments (ADR-402).
-/

namespace Foundations.Dissonance

open Foundations.ADR

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

/-- Circuit-breaker state machine. -/
inductive CircuitBreakerState where
  | Closed
  | Open
  | HalfOpen
  deriving Repr, DecidableEq

/-- Conflict log entry recording a dissonance event. -/
structure ConflictLogEntry where
  receipt_hash : String
  r_sc : Nat
  l_eff : Nat
  tau_r : Nat
  breach_type : String
  timestamp : Nat
  deriving Repr, DecidableEq

/-- An ADR with attached dissonance metadata. -/
structure DissonantADR where
  adr : ADR
  max_severity : Severity := Severity.Low
  conflict_logs : List ConflictLogEntry := []
  breaker_state : CircuitBreakerState := CircuitBreakerState.Closed
  deriving Repr

/-- Create a dissonant ADR from a plain ADR with no dissonance history. -/
def mkDissonantADR (a : ADR) : DissonantADR :=
  { adr := a, max_severity := Severity.Low, conflict_logs := [], breaker_state := CircuitBreakerState.Closed }

/-- Attach a conflict log entry to a dissonant ADR, updating max severity. -/
def attach_conflict (da : DissonantADR) (entry : ConflictLogEntry) (sev : Severity) : DissonantADR :=
  let new_max :=
    match da.max_severity, sev with
    | Severity.Critical, _ => Severity.Critical
    | Severity.High, Severity.Critical => Severity.Critical
    | Severity.High, _ => Severity.High
    | Severity.Medium, Severity.Critical => Severity.Critical
    | Severity.Medium, Severity.High => Severity.High
    | Severity.Medium, _ => Severity.Medium
    | Severity.Low, Severity.Critical => Severity.Critical
    | Severity.Low, Severity.High => Severity.High
    | Severity.Low, Severity.Medium => Severity.Medium
    | Severity.Low, Severity.Low => Severity.Low
  { da with max_severity := new_max, conflict_logs := da.conflict_logs ++ [entry] }

/-- Trip the circuit breaker on a dissonant ADR. -/
def trip_breaker (da : DissonantADR) : DissonantADR :=
  { da with breaker_state := CircuitBreakerState.Open }

/-- Theorem: Attaching a conflict log does not change the underlying ADR identity. -/
theorem attach_preserves_adr_id (da : DissonantADR) (entry : ConflictLogEntry) (sev : Severity) :
    (attach_conflict da entry sev).adr.id = da.adr.id := rfl

/-- Theorem: Tripping the breaker does not change the underlying ADR. -/
theorem trip_preserves_adr (da : DissonantADR) :
    (trip_breaker da).adr = da.adr := rfl

/-- Theorem: Accepted ADRs remain immutable even when dissonance is attached. -/
theorem accepted_immutable_with_dissonance (da : DissonantADR) (entry : ConflictLogEntry) (sev : Severity)
    (h_acc : da.adr.status = ADRStatus.Accepted) :
    (attach_conflict da entry sev).adr.status = ADRStatus.Accepted := by
  dsimp [attach_conflict]
  cases da.max_severity with
  | Critical => exact h_acc
  | High =>
    cases sev with
    | Critical => exact h_acc
    | _ => exact h_acc
  | Medium =>
    cases sev with
    | Critical => exact h_acc
    | High => exact h_acc
    | _ => exact h_acc
  | Low =>
    cases sev with
    | Critical => exact h_acc
    | High => exact h_acc
    | Medium => exact h_acc
    | Low => exact h_acc

/-- The conflict log of a dissonant ADR is traceable to non-empty receipt hashes. -/
def conflict_log_traceable (da : DissonantADR) : Prop :=
  ∀ entry ∈ da.conflict_logs, entry.receipt_hash ≠ ""

/-- Theorem: Initial dissonant ADRs have traceable empty logs. -/
theorem initial_traceable (a : ADR) :
    conflict_log_traceable (mkDissonantADR a) := by
  intro entry h_entry
  dsimp [mkDissonantADR] at h_entry
  simp at h_entry

end Foundations.Dissonance
