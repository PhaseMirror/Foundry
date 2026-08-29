/-!
# Foundations.UniversalAtomic.Core — Sovereign Policy & Universal Atomic Multiplicity

Formalizes sovereign policy contexts, evidence schemas, and verdict arbitration.
-/

namespace Foundations.UniversalAtomic

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

def Verdict.isFinal : Verdict → Bool
  | .approve _ | .reject _ => true
  | _                      => false

def Verdict.requiresHuman : Verdict → Bool
  | .human_required _ => true
  | _                 => false

end Foundations.UniversalAtomic
