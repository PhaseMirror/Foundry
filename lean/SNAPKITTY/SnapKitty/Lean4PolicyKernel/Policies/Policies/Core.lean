-- Sovereign Policy Kernel: Core DSL
-- Defines the canonical verdict algebra, policy typeclass, context, and evidence.

namespace Sovereign.Policy

/-- Stable type aliases -/
abbrev PolicyId     := String
abbrev Role         := String
abbrev CorrelationId := String
abbrev HashURI      := String
abbrev DID          := String
abbrev Subject      := String  -- NATS subject

/-- Evidence submitted with a governance decision -/
structure Evidence where
  refs       : List HashURI
  hashes     : List ByteArray
  signatures : List (DID × ByteArray)
  deriving Repr

/-- Policy evaluation context — every executor entry carries one -/
structure Context where
  correlation_id : CorrelationId
  actor          : DID
  task_type      : String
  evidence       : Evidence
  timestamp      : UInt64
  nonce          : ByteArray
  deriving Repr

/-- Canonical verdict algebra (matches Prolog enum: approve|reject|defer|escalate|human_required) -/
inductive Verdict where
  | approve       (policy_id : PolicyId) : Verdict
  | reject        (policy_id : PolicyId) : Verdict
  | defer         (reason    : String)   : Verdict
  | escalate      (target    : Role)     : Verdict
  | human_required (policy_ids : List PolicyId) : Verdict
  deriving Repr, BEq

/-- Priority semantics for combining verdicts.
    Escalate > HumanRequired > Reject > Defer > Approve
    Rationale: a chain of policies is as strict as its strictest member. -/
def Verdict.priority : Verdict → Nat
  | .escalate _      => 4
  | .human_required _ => 3
  | .reject _        => 2
  | .defer _         => 1
  | .approve _       => 0

def Verdict.combine (vs : List Verdict) : Verdict :=
  match vs with
  | []      => Verdict.approve "SOV-DEFAULT-PASS"
  | v :: rest =>
    rest.foldl (fun acc cur =>
      if cur.priority > acc.priority then
        -- Merge human_required lists rather than overwriting
        match acc, cur with
        | .human_required ps, .human_required qs => .human_required (ps ++ qs)
        | _,                   _                  => cur
      else
        match acc, cur with
        | .human_required ps, .human_required qs => .human_required (ps ++ qs)
        | _,                   _                  => acc
    ) v

/-- A Policy is a decidable predicate on Context → Verdict.
    Every executor entry point must declare which policies it enforces. -/
class Policy (π : PolicyId) where
  eval : Context → Verdict

/-- Check that a verdict is a final (non-pending) outcome -/
def Verdict.isFinal : Verdict → Bool
  | .approve _ | .reject _ => true
  | _                      => false

def Verdict.requiresHuman : Verdict → Bool
  | .human_required _ => true
  | _                 => false

/-- The NATS subject a verdict publishes to, per sovereign.governance.* spec -/
def Verdict.toNatsSubject : Verdict → Subject
  | .approve _        => "sovereign.audit.bifrost.commit.v1"
  | .reject _         => "sovereign.audit.bifrost.commit.v1"
  | .defer _          => "sovereign.governance.decision.pending.v1"
  | .escalate _       => "sovereign.governance.decision.pending.v1"
  | .human_required _ => "sovereign.governance.decision.pending.v1"

end Sovereign.Policy
