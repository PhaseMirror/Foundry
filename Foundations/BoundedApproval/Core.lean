/-!
# Foundations.BoundedApproval.Core — Bounded Approval Policy & Suspension Invariants

Formalizes the link between operational outcome metrics, Archivum suspension state,
and the MCP admission gate (Phase 2 Closure).
-/

namespace Foundations.BoundedApproval

/-- Recommendation envelope schema. -/
structure RecommendationEnvelope where
  proposal_id : String
  owner : String
  metric : String
  horizon : Nat
  artifacts : List String
  confidence : Nat -- Scaled fixed-point percentage (85 = 85%)
  deriving Repr, DecidableEq

/-- Decidable predicate for schema validity: confidence >= 85%. -/
def is_valid_schema (env : RecommendationEnvelope) : Bool :=
  env.proposal_id.length > 0 &&
  env.artifacts.length > 0 &&
  env.confidence >= 85

/-- Archivum receipt types. -/
inductive ReceiptKind where
  | auto_approval_suspension
  | auto_approval_suspension_cleared
  | other
  deriving Repr, DecidableEq

/-- Archivum receipt record. -/
structure Receipt where
  kind : ReceiptKind
  unique_key : String
  actor : String
  deriving Repr, DecidableEq

abbrev ArchivumLog := List Receipt

/-- Authorized policy team authority. -/
def PolicyAuthority (actor : String) : Prop :=
  actor = "@PhaseMirror/mcp-policy-team"

instance (a : String) : Decidable (PolicyAuthority a) :=
  if h : a = "@PhaseMirror/mcp-policy-team" then isTrue h else isFalse h

/-- Computes the current suspension state from the append-only ledger. -/
def get_suspension_state (log : ArchivumLog) : Option String :=
  log.foldl (fun acc r =>
    match r.kind with
    | .auto_approval_suspension => some r.unique_key
    | .auto_approval_suspension_cleared =>
      if some r.unique_key == acc ∧ (decide (PolicyAuthority r.actor)) then none else acc
    | .other => acc
  ) none

/-- Admission gate logic: strictly rejects if suspension is active. -/
def admit (env : RecommendationEnvelope) (log : ArchivumLog) : Bool :=
  match get_suspension_state log with
  | some _ => false
  | none => is_valid_schema env

/-- Theorem: Admission strictly respects active suspension. -/
theorem admit_respects_suspension
    (env : RecommendationEnvelope)
    (log : ArchivumLog) :
    (get_suspension_state log).isSome → admit env log = false := by
  intro h
  dsimp [admit]
  match h_state : get_suspension_state log with
  | some key => rfl
  | none =>
    simp [h_state] at h

/-- Final BoundedApproval invariant: admission implies no active suspension. -/
theorem final_bounded_approval_invariant
    (env : RecommendationEnvelope)
    (log : ArchivumLog) :
    admit env log = true → (get_suspension_state log).isNone := by
  intro h
  match h_state : get_suspension_state log with
  | some key =>
    have h_false := admit_respects_suspension env log (by simp [h_state])
    rw [h] at h_false
    contradiction
  | none => simp

end Foundations.BoundedApproval
