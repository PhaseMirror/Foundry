namespace Sovereign.Policy

abbrev PolicyId     := String
abbrev Role         := String
abbrev CorrelationId := String
abbrev HashURI      := String
abbrev DID          := String
abbrev Subject      := String

structure Evidence where
  refs       : List HashURI
  hashes     : List ByteArray
  signatures : List (DID × ByteArray)

structure Context where
  correlation_id : CorrelationId
  actor          : DID
  task_type      : String
  evidence       : Evidence
  timestamp      : UInt64
  nonce          : ByteArray

inductive Verdict where
  | approve       (policy_id : PolicyId) : Verdict
  | reject        (policy_id : PolicyId) : Verdict
  | defer         (reason    : String)   : Verdict
  | escalate      (target    : Role)     : Verdict
  | human_required (policy_ids : List PolicyId) : Verdict
  deriving BEq

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
        match acc, cur with
        | .human_required ps, .human_required qs => .human_required (ps ++ qs)
        | _,                   _                  => cur
      else
        match acc, cur with
        | .human_required ps, .human_required qs => .human_required (ps ++ qs)
        | _,                   _                  => acc
    ) v

class Policy (π : PolicyId) where
  eval : Context → Verdict

def Verdict.isFinal : Verdict → Bool
  | .approve _ | .reject _ => true
  | _                      => false

def Verdict.requiresHuman : Verdict → Bool
  | .human_required _ => true
  | _                 => false

def Verdict.toNatsSubject : Verdict → Subject
  | .approve _        => "sovereign.audit.bifrost.commit.v1"
  | .reject _         => "sovereign.audit.bifrost.commit.v1"
  | .defer _          => "sovereign.governance.decision.pending.v1"
  | .escalate _       => "sovereign.governance.decision.pending.v1"
  | .human_required _ => "sovereign.governance.decision.pending.v1"

end Sovereign.Policy


