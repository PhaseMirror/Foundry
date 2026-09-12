/-!
# Foundations.AuditLog.Core — Formal Append-Only Cryptographic Audit Log Schema

Formal model of append-only audit-log schemas, hash-chain verification pipelines,
and forensic integrity report status derivation (ADR-RML-001 / ADR-232).
-/

namespace Foundations.AuditLog

abbrev UUID := String
abbrev Timestamp := Nat
abbrev DID := String
abbrev Hash := String
abbrev MimeType := String
abbrev Scope := String
abbrev Window := String

/-- Actor kinds in the recursive agent hierarchy. -/
inductive ActorKind where
  | human
  | agent
  | service
  | verifier
deriving DecidableEq, Repr

/-- Action types executable by an actor. -/
inductive ActionType where
  | read
  | write
  | execute
  | delegate
  | approve
  | deny
deriving DecidableEq, Repr

/-- Policy engine verdict per event. -/
inductive PolicyDecision where
  | allow
  | deny
  | modify
  | require_approval
  | block
deriving DecidableEq, Repr

/-- Human review status of a flagged contract. -/
inductive ReviewStatus where
  | pending
  | approved
  | rejected
  | not_required
deriving DecidableEq, Repr

/-- Rollback lifecycle state of a governed action. -/
inductive RollbackStatus where
  | not_applicable
  | eligible
  | triggered
  | completed
  | failed
deriving DecidableEq, Repr

/-- Overall integrity status of a forensic report. -/
inductive OverallStatus where
  | clean
  | warning
  | violated
  | tampered
deriving DecidableEq, Repr

/-- Four-outcome gate for governed remediation loops. -/
inductive GateOutcome where
  | pass
  | rollback
  | escalate
deriving DecidableEq, Repr

/-- Actor identity on an audit event. -/
structure ActorRef where
  actor_did : DID
  actor_kind : ActorKind
  actor_instance_id : String
deriving DecidableEq, Repr

/-- Trigger flag envelope schema. -/
structure FlagEnvelope where
  kind : String
  source : String
  priority : Nat
  created_at : Timestamp
  dedupe_key : String
  required_shift : String
deriving DecidableEq, Repr

/-- Task contract schema v1 (lineage block). -/
structure TaskContract where
  parent_task_id : String
  root_adr_id : String
  derivation_reason : String
  retry_count : Nat
  lineage_depth : Nat
  authorization_chain : List DID
  parent_adr_id : String
  proposed_new_adr : Bool
deriving DecidableEq, Repr

/-- Policy verdict attached to an event. -/
structure PolicyVerdict where
  policy_id : String
  policy_decision : PolicyDecision
  policy_reason_codes : List String
  decision_confidence : Nat
  confidence_method : String
  symbolic_validation_hits : Nat
  human_review_required : Bool
  human_review_status : ReviewStatus
deriving DecidableEq, Repr

/-- Rollback metadata for a governed action. -/
structure RollbackRecord where
  rollback_status : RollbackStatus
  rollback_ref : String
  compensating_event_id : String
  previous_stable_state_ref : String
deriving DecidableEq, Repr

/-- Forensic flags raised on an event. -/
structure ForensicFlags where
  unauthorized_skill_use : Bool
  scope_escape : Bool
  hash_mismatch : Bool
  expired_delegation : Bool
deriving DecidableEq, Repr

/-- Append-only audit event schema. -/
structure AuditEvent where
  event_id : UUID
  stream_id : String
  event_type : String
  event_version : Nat
  recorded_at : Timestamp
  action_timestamp : Timestamp
  expires_at : Timestamp
  sequence_no : Nat
  prev_event_hash : Hash
  event_hash : Hash
  ledger_signature : String
  correlation_id : String
  causation_id : String
  actor : ActorRef
  task_id : String
  parent_task_id : String
  root_task_id : String
  adr_id : String
  delegation_proof_vc : String
  delegation_scope : Scope
  delegation_chain : List DID
  input_hash : Hash
  output_hash : Hash
  input_ref : String
  output_ref : String
  input_content_type : MimeType
  output_content_type : MimeType
  hash_algorithm : String
  canonicalization_method : String
  requested_skill : String
  requested_tool : String
  action_type : ActionType
  policy : PolicyVerdict
  retry_count : Nat
  rollback : RollbackRecord
  forensic_flags : ForensicFlags
deriving DecidableEq, Repr

/-- Verification request parameters. -/
structure VerificationRequest where
  root_task_id : String
  task_id : String
  actor_did : DID
  adr_id : String
  time_window : Window
  check_hash_chain : Bool
  check_vc : Bool
  check_policy : Bool
  check_rollbacks : Bool
  report_id : String
deriving DecidableEq, Repr

/-- Chronological well-formedness invariants. -/
structure EventInvariants (e : AuditEvent) : Prop where
  no_self_causation : e.causation_id ≠ e.event_id
  action_before_recorded : e.action_timestamp ≤ e.recorded_at
  record_before_expiry : e.recorded_at ≤ e.expires_at

/-- Structured forensic report. -/
structure AuditReport where
  report_id : String
  generated_at : Timestamp
  root_task_id : String
  analysis_window : Window
  stream_count : Nat
  event_count : Nat
  integrity_score : Nat
  overall_status : OverallStatus
  violations : List String
  warnings : List String
  tamper_indicators : List String
  unauthorized_skill_use : List String
  expired_delegations : List String
  orphaned_tasks : List String
  rollback_gaps : List String
  symbolic_conflicts : List String
  delegation_tree_root : String
  max_lineage_depth : Nat
  cycles_detected : Bool
  scope_escapes_detected : Nat
  unreviewed_new_adr_tags : Nat
  retry_exhaustion_events : Nat
deriving DecidableEq, Repr

/-- Propositional chain validity: every link matches predecessor hash. -/
def HashChainValid : List AuditEvent → Prop
  | [] => True
  | [_] => True
  | e₁ :: e₂ :: rest => e₁.event_hash = e₂.prev_event_hash ∧ HashChainValid (e₂ :: rest)

/-- Computable boolean witness for HashChainValid. -/
def hashChainValid : List AuditEvent → Bool
  | [] => true
  | [_] => true
  | e₁ :: e₂ :: rest =>
      decide (e₁.event_hash = e₂.prev_event_hash) && hashChainValid (e₂ :: rest)

/-- Theorem: Boolean witness agrees with propositional chain predicate. -/
theorem hashChainValid_true_iff : ∀ events : List AuditEvent,
    hashChainValid events = true ↔ HashChainValid events
  | [] => by simp [hashChainValid, HashChainValid]
  | [_] => by simp [hashChainValid, HashChainValid]
  | e₁ :: e₂ :: rest => by
      dsimp [hashChainValid, HashChainValid]
      constructor
      · intro h
        simp at h
        exact ⟨h.1, (hashChainValid_true_iff (e₂ :: rest)).1 h.2⟩
      · intro h
        simp [decide_eq_true_eq.mpr h.1, (hashChainValid_true_iff (e₂ :: rest)).2 h.2]

/-- Generates a structured forensic report from verification requests. -/
def report (req : VerificationRequest) (events : List AuditEvent) : AuditReport :=
  { report_id := "R-" ++ req.report_id
    generated_at := 0
    root_task_id := req.root_task_id
    analysis_window := req.time_window
    stream_count := 1
    event_count := events.length
    integrity_score := if hashChainValid events then 100 else 0
    overall_status := if hashChainValid events then OverallStatus.clean else OverallStatus.violated
    violations := []
    warnings := []
    tamper_indicators := []
    unauthorized_skill_use := []
    expired_delegations := []
    orphaned_tasks := []
    rollback_gaps := []
    symbolic_conflicts := []
    delegation_tree_root := ""
    max_lineage_depth := 0
    cycles_detected := false
    scope_escapes_detected := 0
    unreviewed_new_adr_tags := 0
    retry_exhaustion_events := 0 }

theorem hash_chain_refl : HashChainValid [] := trivial

theorem hash_chain_singleton (e : AuditEvent) : HashChainValid [e] := trivial

theorem hash_chain_of_prefix {c : List AuditEvent} {e : AuditEvent}
    (h : HashChainValid (e :: c)) : HashChainValid c := by
  cases c with
  | nil => trivial
  | cons e' rest => exact h.2

theorem hash_chain_invalid_of_mismatch {e₁ e₂ : AuditEvent}
    (h : e₁.event_hash ≠ e₂.prev_event_hash) : ¬ HashChainValid (e₁ :: e₂ :: []) := by
  intro hv
  exact h hv.1

theorem report_clean_iff_chain_valid (req : VerificationRequest)
    (events : List AuditEvent) :
    (report req events).overall_status = OverallStatus.clean ↔ HashChainValid events := by
  dsimp [report]
  cases hb : hashChainValid events
  · have hneg : ¬ HashChainValid events := by
      intro hv
      have htrue : hashChainValid events = true := (hashChainValid_true_iff events).2 hv
      rw [hb] at htrue
      simp at htrue
    dsimp
    constructor
    · intro h
      cases h
    · intro h
      exact False.elim (hneg h)
  · have hpos : HashChainValid events := (hashChainValid_true_iff events).1 hb
    dsimp
    constructor
    · intro _
      exact hpos
    · intro _
      rfl

theorem report_score_on_clean_chain (req : VerificationRequest)
    (events : List AuditEvent) (h : HashChainValid events) :
    (report req events).integrity_score = 100 := by
  dsimp [report]
  have hb : hashChainValid events = true := (hashChainValid_true_iff events).2 h
  simp [hb]

end Foundations.AuditLog
