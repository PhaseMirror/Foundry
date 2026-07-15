import ADR.Core
import ADR.Proofs
import ADR.PhaseMirror
import ADR.Resonance
import ADR.Export

/-!
# Dissonance Module

Integrates the Phase Mirror Dissonance formalization (ADR-402) with the ADR
governance model. Provides:
- Dissonance severity levels aligned with ADR risk levels
- Conflict log entries as attachable ADR metadata
- Proofs that dissonance events preserve ADR invariants
- Circuit-breaker state tracking across ADR transitions

NOTE: The heavy verification of trigger conditions, circuit-breaker state machine,
and CSL projector is performed in Rust/Kani (crates/prime-mirror-verification).
This module provides the type-level integration with the ADR governance model.
-/

open ADR

open ADR.Export

namespace ADR.Dissonance

/-! ## Local Dissonance Types -/

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

/-- Conflict log entry recording a dissonance event. -/
structure ConflictLogEntry where
  receipt_hash : String
  r_sc : Nat
  l_eff : Nat
  tau_r : Nat
  breach_type : String
  timestamp : Nat
  deriving Repr

/-! ## Dissonance-Attached ADR -/

/-- An ADR with attached dissonance metadata records the maximum observed
    dissonance severity and any conflict log entries. -/
structure DissonantADR where
  adr : ADR
  max_severity : Severity := Severity.Low
  conflict_logs : List ConflictLogEntry := []
  breaker_state : CircuitBreakerState := CircuitBreakerState.Closed

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
def trip_breaker (da : DissonantADR) (_now : Nat) : DissonantADR :=
  { da with breaker_state := CircuitBreakerState.Open }

/-! ## Dissonance Preserves ADR Immutability -/

/-- Attaching a conflict log does not change the underlying ADR identity. -/
theorem attach_preserves_adr_id (da : DissonantADR) (entry : ConflictLogEntry) (sev : Severity) :
    (attach_conflict da entry sev).adr.id = da.adr.id := by rfl

/-- Tripping the breaker does not change the underlying ADR. -/
theorem trip_preserves_adr (da : DissonantADR) (now : Nat) :
    (trip_breaker da now).adr = da.adr := by rfl

/-- Accepted ADRs remain immutable even when dissonance is attached. -/
theorem accepted_immutable_with_dissonance (da : DissonantADR) (entry : ConflictLogEntry) (sev : Severity)
    (h_acc : da.adr.status = ADRStatus.Accepted) :
    (attach_conflict da entry sev).adr.status = ADRStatus.Accepted := by
  unfold attach_conflict
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

/-! ## PhaseMirror Involution Preserves Dissonance -/

/-- Applying the PhaseMirror to a dissonant ADR preserves the dissonance record. -/
def apply_phase_mirror (pm : PhaseMirror) (da : DissonantADR) : DissonantADR :=
  { da with adr := ADR.apply pm da.adr }

/-- PhaseMirror involution preserves the dissonant ADR structure. -/
theorem phase_mirror_dissonance_involutive (pm : PhaseMirror) (da : DissonantADR) :
    apply_phase_mirror pm (apply_phase_mirror pm da) = da := by
  unfold apply_phase_mirror
  cases da with
  | mk adr max_severity conflict_logs breaker_state =>
    simp [ADR.apply_involutive]

/-- A superseding ADR points to a strictly smaller id.
    This follows from the supersedes_lt well-formedness condition. -/
theorem no_critical_escalation_loop (a1 a2 : ADR)
    (h_sup : a1.supersedes = some a2.id)
    (h_wf : supersedes_lt a1) :
    a1.id ≠ a2.id := by
  have h_lt : a2.id.value < a1.id.value := by
    unfold supersedes_lt at h_wf
    simp [h_sup] at h_wf
    exact h_wf
  intro h
  have : a2.id.value = a1.id.value := by simp [h]
  rw [this] at h_lt
  exact Nat.lt_irrefl _ h_lt

/-! ## Traceability Through Dissonance -/

/-- The conflict log of a dissonant ADR is traceable to its ADR id. -/
def conflict_log_traceable (da : DissonantADR) : Prop :=
  ∀ entry ∈ da.conflict_logs, entry.receipt_hash ≠ ""

/-- Initial dissonant ADRs have traceable empty logs. -/
theorem initial_traceable (a : ADR) :
    conflict_log_traceable (mkDissonantADR a) := by
  intro entry h_entry
  unfold mkDissonantADR at h_entry
  simp at h_entry

/-! ## Export Dissonance Metadata -/

/-- Render dissonance metadata as markdown. -/
def renderDissonanceMarkdown (da : DissonantADR) : String :=
  "**Dissonance Severity**: " ++
  match da.max_severity with
  | Severity.Critical => "Critical"
  | Severity.High => "High"
  | Severity.Medium => "Medium"
  | Severity.Low => "Low"
  ++ "\n**Circuit Breaker**: " ++
  match da.breaker_state with
  | CircuitBreakerState.Closed => "Closed"
  | CircuitBreakerState.Open => "Open"
  | CircuitBreakerState.HalfOpen => "HalfOpen"
  ++ "\n**Conflict Logs**: " ++ (toString da.conflict_logs.length) ++ "\n" ++
  String.intercalate "\n" (da.conflict_logs.map (fun e =>
    "- `" ++ e.breach_type ++ "` @ " ++ (toString e.timestamp) ++ ": R_sc=" ++ (toString e.r_sc) ++ ", L_eff=" ++ (toString e.l_eff) ++ ", τ_R=" ++ (toString e.tau_r)))

/-- Full markdown export for a dissonant ADR. -/
def renderMarkdownWithDissonance (da : DissonantADR) : String :=
  renderMarkdown da.adr ++ "\n" ++ renderDissonanceMarkdown da

end ADR.Dissonance
