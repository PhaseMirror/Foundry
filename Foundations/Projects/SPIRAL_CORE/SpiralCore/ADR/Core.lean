import Init
import SpiralCore.Core

namespace SpiralCore.ADR

abbrev ADRId := String

inductive ClaimClass where
  | observerNote
  | systemAssumption
  | analogy
  | computationalSurrogate
  | definition
  | policy
  | implementationRequirement
  | testableHypothesis
deriving Repr, DecidableEq

inductive ADRStatus where
  | Proposed
  | Accepted
  | Deprecated
  | Superseded
deriving Repr, DecidableEq

inductive PropExpr where
  | var (name : String)
  | not (p : PropExpr)
  | and (p1 p2 : PropExpr)
  | or (p1 p2 : PropExpr)
  | implies (p1 p2 : PropExpr)
deriving Repr, DecidableEq

def evalProp (env : String → Bool) : PropExpr → Bool
  | .var s => env s
  | .not p => !(evalProp env p)
  | .and p1 p2 => evalProp env p1 && evalProp env p2
  | .or p1 p2 => evalProp env p1 || evalProp env p2
  | .implies p1 p2 => !(evalProp env p1) || evalProp env p2

structure ADR where
  id : ADRId
  title : String
  status : ADRStatus
  claimClass : ClaimClass
  context : List PropExpr
  decision : List PropExpr
  consequences : List PropExpr
  supersedes : Option ADRId
deriving Repr, DecidableEq

abbrev Registry := List ADR

/-- Unique IDs invariant across the registry (every ID appears exactly once). -/
def uniqueIds (r : Registry) : Bool :=
  r.all (fun adr => (r.filter (fun a => a.id == adr.id)).length == 1)

/-- No ADR directly supersedes itself. -/
def noSelfSupersede (r : Registry) : Bool :=
  r.all (fun adr => match adr.supersedes with
    | some target => target != adr.id
    | none => true)

/-- Supersession target invariant: If an ADR carries `supersedes = some targetId`,
    targetId must exist in registry, targetId != adr.id, and target's status must be Superseded or Deprecated. -/
def validSupersedeTargets (r : Registry) : Bool :=
  r.all (fun adr =>
    match adr.supersedes with
    | some targetId =>
      match r.find? (fun a => a.id == targetId) with
      | some target => (targetId != adr.id) && (target.status == .Superseded || target.status == .Deprecated)
      | none => false
    | none => true)

/-- Single-step supersession parent resolution. -/
def stepSupersedes (r : Registry) (id : ADRId) : Option ADRId :=
  match r.find? (fun a => a.id == id) with
  | some adr => adr.supersedes
  | none => none

/-- Bounded reachability walk to check acyclicity up to bound. -/
def checkAcyclicBounded (r : Registry) (curr : ADRId) (visited : List ADRId) (bound : Nat) : Bool :=
  match bound with
  | 0 => false
  | bound' + 1 =>
    match stepSupersedes r curr with
    | none => true
    | some parent =>
      if visited.contains parent then
        false
      else
        checkAcyclicBounded r parent (parent :: visited) bound'

/-- Global acyclicity verification over registry. -/
def isAcyclic (r : Registry) : Bool :=
  r.all (fun adr => checkAcyclicBounded r adr.id [adr.id] r.length)

/-- Consequence Entailment: Every consequence in every ADR must be satisfied in every Boolean environment
    where the context and decisions are satisfied (checked over default valuation environment). -/
def adrConsequencesEntailed (adr : ADR) : Bool :=
  adr.consequences.all (fun cons =>
    let env := fun _ => true
    let premisesHold := (adr.context ++ adr.decision).all (fun p => evalProp env p)
    if premisesHold then evalProp env cons else true)

def consequencesEntailed (r : Registry) : Bool :=
  r.all adrConsequencesEntailed

/-- Well-formedness specification predicate for ADR Registry. -/
def WellFormed (r : Registry) : Prop :=
  uniqueIds r = true ∧
  noSelfSupersede r = true ∧
  validSupersedeTargets r = true ∧
  isAcyclic r = true ∧
  consequencesEntailed r = true

/-- Dependently typed subtype of Machine-Checked Valid Registries. -/
def ValidRegistry := { r : Registry // WellFormed r }

/-- State Transition action on ADR Registry. -/
inductive TransitionAction where
  | propose (adr : ADR)
  | markAccepted (id : ADRId)
  | markDeprecated (id : ADRId)
  | supersede (newAdr : ADR) (oldId : ADRId)
deriving Repr, DecidableEq

/-- Controlled State Transition application function disallowing invalid transitions (e.g. Accepted -> Proposed). -/
def applyTransition (r : Registry) (action : TransitionAction) : Except String Registry :=
  match action with
  | .propose adr =>
    if adr.status != .Proposed then
      Except.error "New proposal must have status Proposed"
    else if (r.map ADR.id).contains adr.id then
      Except.error "ADR ID already exists"
    else
      Except.ok (adr :: r)
  | .markAccepted id =>
    match r.find? (fun a => a.id == id) with
    | some adr =>
      if adr.status == .Proposed then
        let updated := r.map (fun a => if a.id == id then { a with status := .Accepted } else a)
        Except.ok updated
      else
        Except.error "Only Proposed ADRs can be marked Accepted"
    | none => Except.error "ADR not found"
  | .markDeprecated id =>
    match r.find? (fun a => a.id == id) with
    | some adr =>
      if adr.status == .Proposed || adr.status == .Accepted then
        let updated := r.map (fun a => if a.id == id then { a with status := .Deprecated } else a)
        Except.ok updated
      else
        Except.error "Invalid state for deprecation"
    | none => Except.error "ADR not found"
  | .supersede newAdr oldId =>
    if newAdr.status != .Accepted then
      Except.error "Replacement ADR must be Accepted"
    else if newAdr.supersedes != some oldId then
      Except.error "Replacement ADR must set supersedes pointer to oldId"
    else
      match r.find? (fun a => a.id == oldId) with
      | some oldAdr =>
        if oldAdr.status != .Accepted then
          Except.error "Target ADR to supersede must be Accepted"
        else
          let updatedOld := r.map (fun a => if a.id == oldId then { a with status := .Superseded } else a)
          Except.ok (newAdr :: updatedOld)
      | none => Except.error "Target ADR to supersede not found"

end SpiralCore.ADR
