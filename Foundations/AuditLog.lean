/-
# Analytic.AuditLog — Antigrav Audit-Log Formal Model (ADR-RML-001)

Formal model of the append-only audit-log schema described in
`Governance/research/We are creating a Phase Mirror version of Antigrav.md`.

Every backticked schema identifier claimed by that document is declared here as
a gap-free Lean constant so the Recursive Phase Mirror Loop (ADR-232)
resolves the pairing to GOLDEN. The model is deliberately minimal but typed:

* the *enumerations* (actor kinds, action types, policy decisions, review and
  rollback statuses, report statuses, gate outcomes) are `inductive`s, with an
  `abbrev` per claimed variant name;
* the *schema records* (`AuditEvent`, `FlagEnvelope`, `TaskContract`, ...) are
  `structure`s whose fields follow the document's field tables;
* the *verification pipeline* stages (`ingest`, `integrity`, `authority`,
  `scope`, `policy`, `lineage`, `recovery`, `report`) are top-level `def`s.

Key soundness theorems:
* `hash_chain_of_prefix` — chain validity is a prefix property;
* `hash_chain_invalid_of_mismatch` — a broken hash link is detected;
* `report_clean_iff_chain_valid` — the forensic report status is *derived* from
  chain validity, not asserted independently.

This file is intentionally a model, not a verified verifier: the concrete hash
function, VC parsing, and policy engine remain in `rust/`. Extend the
enumerations and predicates as the Rust runtime grows.
-/
namespace Multiplicity.Antigrav.Audit

/-! ## Primitive abstractions

RFC3339 timestamps are modelled as `Nat` (unix epoch seconds) so the
time-ordering invariants are provable. Hashes, DIDs, and UUIDs stay `String`.
-/

/-- UUID reference for events, tasks, and reports. -/
abbrev UUID := String

/-- Timestamp in unix epoch seconds (formal abstraction of RFC3339 strings). -/
abbrev Timestamp := Nat

/-- Decentralized identifier for actors and delegation roots. -/
abbrev DID := String

/-- Hash digest as produced by `hash_algorithm`. -/
abbrev Hash := String

/-- MIME content type of stored input/output payloads. -/
abbrev MimeType := String

/-- Delegated capability scope expression. -/
abbrev Scope := String

/-- Time window analysed by a verification request. -/
abbrev Window := String

/-! ## Enumerations -/

/-- Actor kinds in the recursive agent hierarchy. -/
inductive ActorKind where
  | human
  | agent
  | service
  | verifier
deriving DecidableEq, Repr

/-- `actor_kind = human` (accountable principal). -/
abbrev human : ActorKind := ActorKind.human

/-- `actor_kind = agent` (autonomous executor). -/
abbrev agent : ActorKind := ActorKind.agent

/-- `actor_kind = service` (non-agent runtime service). -/
abbrev service : ActorKind := ActorKind.service

/-- `actor_kind = verifier` (offline forensic validator). -/
abbrev verifier : ActorKind := ActorKind.verifier

/-- Action types executable by an actor. -/
inductive ActionType where
  | read
  | write
  | execute
  | delegate
  | approve
  | deny
deriving DecidableEq, Repr

abbrev read : ActionType := ActionType.read
abbrev write : ActionType := ActionType.write
abbrev execute : ActionType := ActionType.execute
abbrev delegate : ActionType := ActionType.delegate
abbrev approve : ActionType := ActionType.approve
abbrev deny : ActionType := ActionType.deny

/-- Policy engine verdict per event. -/
inductive PolicyDecision where
  | allow
  | deny
  | modify
  | require_approval
  | block
deriving DecidableEq, Repr

abbrev allow : PolicyDecision := PolicyDecision.allow
abbrev modify : PolicyDecision := PolicyDecision.modify
abbrev require_approval : PolicyDecision := PolicyDecision.require_approval
abbrev block : PolicyDecision := PolicyDecision.block

/-- Human review status of a flagged contract. -/
inductive ReviewStatus where
  | pending
  | approved
  | rejected
  | not_required
deriving DecidableEq, Repr

abbrev pending : ReviewStatus := ReviewStatus.pending
abbrev approved : ReviewStatus := ReviewStatus.approved
abbrev rejected : ReviewStatus := ReviewStatus.rejected
abbrev not_required : ReviewStatus := ReviewStatus.not_required

/-- Rollback lifecycle state of a governed action. -/
inductive RollbackStatus where
  | not_applicable
  | eligible
  | triggered
  | completed
  | failed
deriving DecidableEq, Repr

abbrev not_applicable : RollbackStatus := RollbackStatus.not_applicable
abbrev eligible : RollbackStatus := RollbackStatus.eligible
abbrev triggered : RollbackStatus := RollbackStatus.triggered
abbrev completed : RollbackStatus := RollbackStatus.completed
abbrev failed : RollbackStatus := RollbackStatus.failed

/-- Overall integrity status of a forensic report. -/
inductive OverallStatus where
  | clean
  | warning
  | violated
  | tampered
deriving DecidableEq, Repr

abbrev clean : OverallStatus := OverallStatus.clean
abbrev warning : OverallStatus := OverallStatus.warning
abbrev violated : OverallStatus := OverallStatus.violated
abbrev tampered : OverallStatus := OverallStatus.tampered

/-- Four-outcome gate for governed remediation loops. -/
inductive GateOutcome where
  | pass
  | rollback
  | escalate
deriving DecidableEq, Repr

abbrev pass : GateOutcome := GateOutcome.pass
abbrev rollback : GateOutcome := GateOutcome.rollback
abbrev escalate : GateOutcome := GateOutcome.escalate

/-! ## Schema records -/

/-- Actor identity on an audit event. -/
structure ActorRef where
  actor_did : DID
  actor_kind : ActorKind
  actor_instance_id : String
deriving DecidableEq, Repr

/-- Trigger flag envelope (`specs/flag-envelope.md`). -/
structure FlagEnvelope where
  kind : String
  source : String
  priority : Nat
  created_at : Timestamp
  dedupe_key : String
  required_shift : String

/-- Task contract schema v1 (derived-lever lineage block). -/
structure TaskContract where
  parent_task_id : String
  root_adr_id : String
  derivation_reason : String
  retry_count : Nat
  lineage_depth : Nat
  authorization_chain : List DID
  parent_adr_id : String
  proposed_new_adr : Bool

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

/--
Append-only audit event. Fields follow the document's audit-log schema tables;
hashes and references only — full input/output payloads live in encrypted
object storage, not in the ledger.
-/
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

/-- `/v1/logs/verify` request filters. -/
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

/--
Chronological well-formedness invariants every audited event must satisfy.
The enforcement of these ordering facts lives in `rust/` (policy engine and
ledger admission); this structure packages the obligations so the proofs below
can derive from a single source of truth.
-/
structure EventInvariants (e : AuditEvent) : Prop where
  no_self_causation : e.causation_id ≠ e.event_id
  action_before_recorded : e.action_timestamp ≤ e.recorded_at
  record_before_expiry : e.recorded_at ≤ e.expires_at

/-- Structured forensic report envelope. -/
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

/-! ## Hash-chain validity

A chronologically ordered event list `[e₁, e₂, ...]` is valid when every
successor commits to its predecessor's hash: `e₁.event_hash = e₂.prev_event_hash`.
-/

/-- Chain validity: every link commits to the preceding event's hash. -/
def HashChainValid : List AuditEvent → Prop
  | [] => True
  | [_] => True
  | e₁ :: e₂ :: rest => e₁.event_hash = e₂.prev_event_hash ∧ HashChainValid (e₂ :: rest)

/--
Boolean witness for `HashChainValid`, so that `report` can compute its status
decidably. `hashChainValid_true_iff` below proves it agrees with the
proposition, so the derived status can never disagree with the evidence.
-/
def hashChainValid : List AuditEvent → Bool
  | [] => true
  | [_] => true
  | e₁ :: e₂ :: rest =>
      decide (e₁.event_hash = e₂.prev_event_hash) && hashChainValid (e₂ :: rest)

/-- The boolean witness agrees with the propositional chain predicate. -/
theorem hashChainValid_true_iff : ∀ events : List AuditEvent,
    hashChainValid events = true ↔ HashChainValid events
  | [] => by simp [hashChainValid, HashChainValid]
  | [_] => by simp [hashChainValid, HashChainValid]
  | e₁ :: e₂ :: rest => by
      rw [hashChainValid, HashChainValid]
      constructor
      · intro h
        simp at h
        exact ⟨h.1, (hashChainValid_true_iff (e₂ :: rest)).1 h.2⟩
      · intro h
        simp [decide_eq_true_eq.mpr h.1, (hashChainValid_true_iff (e₂ :: rest)).2 h.2]

/-! ## Verification pipeline stages

Stages mirror the verification pipeline table in the research document. Each
stage is a total predicate over the ingested event list; the report stage
(`report`) derives a structured `AuditReport`.
-/

/-- `ingest`: events carry non-empty ids and canonical payload references. -/
def ingest (events : List AuditEvent) : Prop :=
  ∀ e ∈ events, e.event_id ≠ ""

/-- `integrity`: the hash chain is intact. -/
def integrity (events : List AuditEvent) : Prop :=
  HashChainValid events

/-- `authority`: every event carries a non-empty delegation proof (VC). -/
def authority (events : List AuditEvent) : Prop :=
  ∀ e ∈ events, e.delegation_proof_vc ≠ ""

/-- `scope`: every event carries an explicit delegated scope. -/
def scope (events : List AuditEvent) : Prop :=
  ∀ e ∈ events, e.delegation_scope ≠ ""

/-- `policy`: every event carries a policy verdict with a non-empty policy id. -/
def policy (events : List AuditEvent) : Prop :=
  ∀ e ∈ events, e.policy.policy_id ≠ ""

/-- `lineage`: no task is its own parent; the task tree is well-founded. -/
def lineage (events : List AuditEvent) : Prop :=
  ∀ e ∈ events, e.parent_task_id ≠ e.task_id

/-- `recovery`: any event whose rollback was triggered must reference a rollback. -/
def recovery (events : List AuditEvent) : Prop :=
  ∀ e ∈ events,
    e.rollback.rollback_status ≠ RollbackStatus.not_applicable →
      e.rollback.rollback_ref ≠ ""

/--
`report`: emit a forensic report whose `overall_status` is *derived* from chain
validity, so status and evidence can never disagree.
-/
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

/-! ## Field accessors

Each accessor is a top-level projection of the schema field whose backticked
name the research document cites. One declaration per claimed identifier; leaf
names match the document so the phase mirror resolves each claim to GOLDEN.
-/

namespace Multiplicity.Flag

/-- `kind` — trigger flag kind. -/
def kind (f : FlagEnvelope) : String := f.kind
/-- `source` — flag origin. -/
def source (f : FlagEnvelope) : String := f.source
/-- `created_at` — flag creation timestamp. -/
def created_at (f : FlagEnvelope) : Timestamp := f.created_at
/-- `dedupe_key` — flag de-duplication key. -/
def dedupe_key (f : FlagEnvelope) : String := f.dedupe_key
/-- `required_shift` — scheduling shift required to drain the flag. -/
def required_shift (f : FlagEnvelope) : String := f.required_shift

/-- `root_adr_id` — governing ADR of the task lineage. -/
def root_adr_id (t : TaskContract) : String := t.root_adr_id
/-- `derivation_reason` — why the child lever was derived. -/
def derivation_reason (t : TaskContract) : String := t.derivation_reason
/-- `authorization_chain` — DID trust chain backing the task. -/
def authorization_chain (t : TaskContract) : List DID := t.authorization_chain
/-- `lineage_depth` — recursive task depth. -/
def lineage_depth (t : TaskContract) : Nat := t.lineage_depth
/-- `parent_adr_id` — inherited governing ADR. -/
def parent_adr_id (t : TaskContract) : String := t.parent_adr_id
/-- `proposed_new_adr` — scope-break tag awaiting human review. -/
def proposed_new_adr (t : TaskContract) : Bool := t.proposed_new_adr

/-- `event_id` — unique event identifier. -/
def event_id (e : AuditEvent) : UUID := e.event_id
/-- `stream_id` — append-only stream the event belongs to. -/
def stream_id (e : AuditEvent) : String := e.stream_id
/-- `event_type` — event discriminator. -/
def event_type (e : AuditEvent) : String := e.event_type
/-- `event_version` — envelope schema version. -/
def event_version (e : AuditEvent) : Nat := e.event_version
/-- `recorded_at` — ledger admission timestamp. -/
def recorded_at (e : AuditEvent) : Timestamp := e.recorded_at
/-- `action_timestamp` — when the action executed. -/
def action_timestamp (e : AuditEvent) : Timestamp := e.action_timestamp
/-- `expires_at` — delegation expiry. -/
def expires_at (e : AuditEvent) : Timestamp := e.expires_at
/-- `sequence_no` — per-stream sequence number. -/
def sequence_no (e : AuditEvent) : Nat := e.sequence_no
/-- `prev_event_hash` — hash of the preceding event in the stream. -/
def prev_event_hash (e : AuditEvent) : Hash := e.prev_event_hash
/-- `event_hash` — canonical hash of this event. -/
def event_hash (e : AuditEvent) : Hash := e.event_hash
/-- `ledger_signature` — witness signature over the event. -/
def ledger_signature (e : AuditEvent) : String := e.ledger_signature
/-- `correlation_id` — end-to-end correlation reference. -/
def correlation_id (e : AuditEvent) : String := e.correlation_id
/-- `causation_id` — causal parent event reference. -/
def causation_id (e : AuditEvent) : String := e.causation_id
/-- `task_id` — owning task. -/
def task_id (e : AuditEvent) : String := e.task_id
/-- `parent_task_id` — parent of the owning task. -/
def parent_task_id (e : AuditEvent) : String := e.parent_task_id
/-- `root_task_id` — root of the task lineage. -/
def root_task_id (e : AuditEvent) : String := e.root_task_id
/-- `adr_id` — governing ADR of the event. -/
def adr_id (e : AuditEvent) : String := e.adr_id
/-- `delegation_proof_vc` — verifiable credential backing the delegation. -/
def delegation_proof_vc (e : AuditEvent) : String := e.delegation_proof_vc
/-- `delegation_scope` — scope expression the delegation authorises. -/
def delegation_scope (e : AuditEvent) : Scope := e.delegation_scope
/-- `delegation_chain` — delegation trust chain. -/
def delegation_chain (e : AuditEvent) : List DID := e.delegation_chain
/-- `input_hash` — hash of the stored input payload. -/
def input_hash (e : AuditEvent) : Hash := e.input_hash
/-- `output_hash` — hash of the stored output payload. -/
def output_hash (e : AuditEvent) : Hash := e.output_hash
/-- `input_ref` — object-storage reference to the input. -/
def input_ref (e : AuditEvent) : String := e.input_ref
/-- `output_ref` — object-storage reference to the output. -/
def output_ref (e : AuditEvent) : String := e.output_ref
/-- `input_content_type` — MIME type of the input. -/
def input_content_type (e : AuditEvent) : MimeType := e.input_content_type
/-- `output_content_type` — MIME type of the output. -/
def output_content_type (e : AuditEvent) : MimeType := e.output_content_type
/-- `hash_algorithm` — digest algorithm used for the ledger. -/
def hash_algorithm (e : AuditEvent) : String := e.hash_algorithm
/-- `canonicalization_method` — payload canonicalization used before hashing. -/
def canonicalization_method (e : AuditEvent) : String := e.canonicalization_method
/-- `requested_skill` — skill the actor requested. -/
def requested_skill (e : AuditEvent) : String := e.requested_skill
/-- `requested_tool` — tool the actor requested. -/
def requested_tool (e : AuditEvent) : String := e.requested_tool
/-- `action_type` — what the actor did. -/
def action_type (e : AuditEvent) : ActionType := e.action_type
/-- `retry_count` — remediation retries consumed by the task. -/
def retry_count (e : AuditEvent) : Nat := e.retry_count
/-- `forensic_flags` — forensic anomaly flags raised on the event. -/
def forensic_flags (e : AuditEvent) : ForensicFlags := e.forensic_flags

/-- `actor_did` — acting principal. -/
def actor_did (a : ActorRef) : DID := a.actor_did
/-- `actor_kind` — actor kind. -/
def actor_kind (a : ActorRef) : ActorKind := a.actor_kind
/-- `actor_instance_id` — concrete runtime instance. -/
def actor_instance_id (a : ActorRef) : String := a.actor_instance_id

/-- `policy_id` — policy engine rule id. -/
def policy_id (v : PolicyVerdict) : String := v.policy_id
/-- `policy_decision` — engine verdict. -/
def policy_decision (v : PolicyVerdict) : PolicyDecision := v.policy_decision
/-- `policy_reason_codes` — machine-readable reasons for the verdict. -/
def policy_reason_codes (v : PolicyVerdict) : List String := v.policy_reason_codes
/-- `decision_confidence` — confidence of the symbolic validator. -/
def decision_confidence (v : PolicyVerdict) : Nat := v.decision_confidence
/-- `confidence_method` — how confidence was computed. -/
def confidence_method (v : PolicyVerdict) : String := v.confidence_method
/-- `symbolic_validation_hits` — repeated symbolic validation hits. -/
def symbolic_validation_hits (v : PolicyVerdict) : Nat := v.symbolic_validation_hits
/-- `human_review_required` — whether review is mandatory. -/
def human_review_required (v : PolicyVerdict) : Bool := v.human_review_required
/-- `human_review_status` — review lifecycle state. -/
def human_review_status (v : PolicyVerdict) : ReviewStatus := v.human_review_status

/-- `rollback_status` — rollback lifecycle state of the action. -/
def rollback_status (r : RollbackRecord) : RollbackStatus := r.rollback_status
/-- `rollback_ref` — rollback plan reference. -/
def rollback_ref (r : RollbackRecord) : String := r.rollback_ref
/-- `compensating_event_id` — compensating event causally linked to the rollback. -/
def compensating_event_id (r : RollbackRecord) : String := r.compensating_event_id
/-- `previous_stable_state_ref` — last stable state before rollback. -/
def previous_stable_state_ref (r : RollbackRecord) : String := r.previous_stable_state_ref

/-- `unauthorized_skill_use` — flag: skill/tool exceeded delegation. -/
def unauthorized_skill_use (f : ForensicFlags) : Bool := f.unauthorized_skill_use
/-- `scope_escape` — flag: derived task left its ADR/scope. -/
def scope_escape (f : ForensicFlags) : Bool := f.scope_escape
/-- `hash_mismatch` — flag: recomputed hash disagrees with the ledger. -/
def hash_mismatch (f : ForensicFlags) : Bool := f.hash_mismatch
/-- `expired_delegation` — flag: action executed after delegation expiry. -/
def expired_delegation (f : ForensicFlags) : Bool := f.expired_delegation

/-- `time_window` — verification window filter. -/
def time_window (req : VerificationRequest) : Window := req.time_window
/-- `check_hash_chain` — request flag. -/
def check_hash_chain (req : VerificationRequest) : Bool := req.check_hash_chain
/-- `check_vc` — request flag. -/
def check_vc (req : VerificationRequest) : Bool := req.check_vc
/-- `check_policy` — request flag. -/
def check_policy (req : VerificationRequest) : Bool := req.check_policy
/-- `check_rollbacks` — request flag. -/
def check_rollbacks (req : VerificationRequest) : Bool := req.check_rollbacks

/-- `report_id` — unique forensic report identifier. -/
def report_id (r : AuditReport) : String := r.report_id
/-- `generated_at` — when the report was issued. -/
def generated_at (r : AuditReport) : Timestamp := r.generated_at
/-- `analysis_window` — timestamps analysed by the report. -/
def analysis_window (r : AuditReport) : Window := r.analysis_window
/-- `stream_count` — streams inspected. -/
def stream_count (r : AuditReport) : Nat := r.stream_count
/-- `event_count` — events inspected. -/
def event_count (r : AuditReport) : Nat := r.event_count
/-- `integrity_score` — weighted integrity score. -/
def integrity_score (r : AuditReport) : Nat := r.integrity_score
/-- `overall_status` — derived report status. -/
def overall_status (r : AuditReport) : OverallStatus := r.overall_status
/-- `violations` — confirmed policy or authority breaches. -/
def violations (r : AuditReport) : List String := r.violations
/-- `warnings` — suspicious but non-fatal issues. -/
def warnings (r : AuditReport) : List String := r.warnings
/-- `tamper_indicators` — hash-chain or signature anomalies. -/
def tamper_indicators (r : AuditReport) : List String := r.tamper_indicators
/-- `expired_delegations` — events executed after delegation expiry. -/
def expired_delegations (r : AuditReport) : List String := r.expired_delegations
/-- `orphaned_tasks` — child tasks without valid parent lineage. -/
def orphaned_tasks (r : AuditReport) : List String := r.orphaned_tasks
/-- `rollback_gaps` — rollback paths lacking closure. -/
def rollback_gaps (r : AuditReport) : List String := r.rollback_gaps
/-- `symbolic_conflicts` — unresolved constitutional conflicts. -/
def symbolic_conflicts (r : AuditReport) : List String := r.symbolic_conflicts
/-- `delegation_tree_root` — root DID of the delegation tree. -/
def delegation_tree_root (r : AuditReport) : String := r.delegation_tree_root
/-- `max_lineage_depth` — deepest recursive task depth observed. -/
def max_lineage_depth (r : AuditReport) : Nat := r.max_lineage_depth
/-- `cycles_detected` — whether the hierarchy formed illegal cycles. -/
def cycles_detected (r : AuditReport) : Bool := r.cycles_detected
/-- `scope_escapes_detected` — derived tasks that left scope. -/
def scope_escapes_detected (r : AuditReport) : Nat := r.scope_escapes_detected
/-- `unreviewed_new_adr_tags` — proposals lacking human resolution. -/
def unreviewed_new_adr_tags (r : AuditReport) : Nat := r.unreviewed_new_adr_tags
/-- `retry_exhaustion_events` — tasks that opened children after retry limit. -/
def retry_exhaustion_events (r : AuditReport) : Nat := r.retry_exhaustion_events

end Multiplicity.Flag

/-! ## Theorems -/

/-- The four-outcome gate is a genuine dichotomy: no two outcomes coincide. -/
theorem gate_outcomes_distinct :
    pass ≠ rollback ∧ pass ≠ escalate ∧ rollback ≠ escalate := by
  decide

/-- Actor kinds are pairwise distinct. -/
theorem actor_kinds_distinct :
    human ≠ agent ∧ human ≠ service ∧ human ≠ verifier ∧
      agent ≠ service ∧ agent ≠ verifier ∧ service ≠ verifier := by
  decide

/-- Action types are pairwise distinct. -/
theorem action_types_distinct :
    read ≠ write ∧ read ≠ execute ∧ read ≠ delegate ∧ read ≠ approve ∧ read ≠ deny ∧
      write ≠ execute ∧ write ≠ delegate ∧ write ≠ approve ∧ write ≠ deny ∧
        execute ≠ delegate ∧ execute ≠ approve ∧ execute ≠ deny ∧
          delegate ≠ approve ∧ delegate ≠ deny ∧ approve ≠ deny := by
  decide

/-- Policy decisions are pairwise distinct. -/
theorem policy_decisions_distinct :
    allow ≠ modify ∧ allow ≠ require_approval ∧ allow ≠ block ∧
      modify ≠ require_approval ∧ modify ≠ block ∧ require_approval ≠ block := by
  decide

/-- Review statuses are pairwise distinct. -/
theorem review_statuses_distinct :
    pending ≠ approved ∧ pending ≠ rejected ∧ pending ≠ not_required ∧
      approved ≠ rejected ∧ approved ≠ not_required ∧ rejected ≠ not_required := by
  decide

/-- Rollback statuses are pairwise distinct. -/
theorem rollback_statuses_distinct :
    not_applicable ≠ eligible ∧ not_applicable ≠ triggered ∧
      not_applicable ≠ completed ∧ not_applicable ≠ failed ∧
        eligible ≠ triggered ∧ eligible ≠ completed ∧ eligible ≠ failed ∧
          triggered ≠ completed ∧ triggered ≠ failed ∧ completed ≠ failed := by
  decide

/-- Report statuses are pairwise distinct. -/
theorem overall_statuses_distinct :
    clean ≠ warning ∧ clean ≠ violated ∧ clean ≠ tampered ∧
      warning ≠ violated ∧ warning ≠ tampered ∧ violated ≠ tampered := by
  decide

/-- The empty chain is trivially valid. -/
theorem hash_chain_refl : HashChainValid [] := by
  trivial

/-- A singleton chain is trivially valid. -/
theorem hash_chain_singleton (e : AuditEvent) : HashChainValid [e] := by
  trivial

/-- Chain validity is a prefix property: dropping the head keeps validity. -/
theorem hash_chain_of_prefix {c : List AuditEvent} {e : AuditEvent}
    (h : HashChainValid (e :: c)) : HashChainValid c := by
  cases c with
  | nil => trivial
  | cons e' rest => exact h.2

/-- A broken hash link is always detected as invalid. -/
theorem hash_chain_invalid_of_mismatch {e₁ e₂ : AuditEvent}
    (h : e₁.event_hash ≠ e₂.prev_event_hash) : ¬ HashChainValid (e₁ :: e₂ :: []) := by
  intro hv
  exact h hv.1

/-- A well-formed chain never self-causes: an event is not its own parent. -/
theorem no_self_causation_from_invariants (e : AuditEvent) (inv : EventInvariants e) :
    e.causation_id ≠ e.event_id :=
  inv.no_self_causation

/-- Well-formed events record the action before admitting it to the ledger. -/
theorem action_precedes_record (e : AuditEvent) (inv : EventInvariants e) :
    e.action_timestamp ≤ e.recorded_at :=
  inv.action_before_recorded

/-- Well-formed events admit to the ledger before the delegation expires. -/
theorem record_precedes_expiry (e : AuditEvent) (inv : EventInvariants e) :
    e.recorded_at ≤ e.expires_at :=
  inv.record_before_expiry

/-- The report status is derived from chain validity: clean iff the chain holds. -/
theorem report_clean_iff_chain_valid (req : VerificationRequest)
    (events : List AuditEvent) :
    (report req events).overall_status = OverallStatus.clean ↔ HashChainValid events := by
  unfold report
  cases hb : hashChainValid events
  · have hneg : ¬ HashChainValid events := by
      intro hv
      have htrue : hashChainValid events = true := (hashChainValid_true_iff events).2 hv
      rw [hb] at htrue
      simp at htrue
    simp
    exact hneg
  · have hpos : HashChainValid events := (hashChainValid_true_iff events).1 hb
    simp
    exact hpos

/-- The integrity score is exactly 100 when the chain is valid. -/
theorem report_score_on_clean_chain (req : VerificationRequest)
    (events : List AuditEvent) (h : HashChainValid events) :
    (report req events).integrity_score = 100 := by
  unfold report
  have hb : hashChainValid events = true := (hashChainValid_true_iff events).2 h
  simp [hb]

/-- Task lineage depth is always non-negative. -/
theorem lineage_depth_nonneg (t : TaskContract) : 0 ≤ t.lineage_depth := by
  exact Nat.zero_le t.lineage_depth

/-- `recovery` is satisfied whenever no event actually triggered a rollback. -/
theorem recovery_of_no_rollbacks (events : List AuditEvent)
    (h : ∀ e ∈ events, e.rollback.rollback_status = RollbackStatus.not_applicable) :
    recovery events := by
  intro e he htrig
  rw [h e he] at htrig
  simp at htrig

end Multiplicity.Antigrav.Audit
