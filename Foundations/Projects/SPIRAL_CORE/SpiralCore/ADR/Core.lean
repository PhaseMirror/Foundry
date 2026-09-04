import Init
import SpiralCore.Core

namespace SpiralCore.ADR

open SpiralCore (ClaimClass)

abbrev ADRId := String

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

/-- Extract all unique variable atom names from a PropExpr. -/
def getAtoms : PropExpr → List String
  | .var s => [s]
  | .not p => getAtoms p
  | .and p1 p2 => (getAtoms p1 ++ getAtoms p2).eraseDups
  | .or p1 p2 => (getAtoms p1 ++ getAtoms p2).eraseDups
  | .implies p1 p2 => (getAtoms p1 ++ getAtoms p2).eraseDups

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

/-- Unique IDs invariant across the registry. -/
def uniqueIds (r : Registry) : Bool :=
  r.all (fun adr => (r.filter (fun a => a.id == adr.id)).length == 1)

/-- No ADR directly supersedes itself. -/
def noSelfSupersede (r : Registry) : Bool :=
  r.all (fun adr => match adr.supersedes with
    | some target => target != adr.id
    | none => true)

/-- Supersession target invariant: If replacement ADR carries `supersedes = some targetId`,
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

/-- Generate all 2^k Boolean valuation environments over a finite list of atom names. -/
def allEnvironments (atoms : List String) : List (String → Bool) :=
  match atoms with
  | [] => [fun _ => false]
  | a :: as =>
    let subEnvs := allEnvironments as
    let trueEnvs := subEnvs.map (fun env => fun s => if s == a then true else env s)
    let falseEnvs := subEnvs.map (fun env => fun s => if s == a then false else env s)
    trueEnvs ++ falseEnvs

/-- Sound Consequence Entailment: Evaluates consequence soundness across ALL 2^k truth assignments
    for the atom set of the ADR. Premises (context ++ decision) => consequence. -/
def adrConsequencesEntailed (adr : ADR) : Bool :=
  let allExprs := adr.context ++ adr.decision ++ adr.consequences
  let atoms := (allExprs.flatMap getAtoms).eraseDups
  let envs := allEnvironments atoms
  envs.all (fun env =>
    let premisesHold := (adr.context ++ adr.decision).all (fun p => evalProp env p)
    if premisesHold then
      adr.consequences.all (fun c => evalProp env c)
    else
      true)

def consequencesEntailed (r : Registry) : Bool :=
  r.all adrConsequencesEntailed

/-- Well-formedness specification predicate for ADR Registry. -/
def WellFormed (r : Registry) : Prop :=
  uniqueIds r = true ∧
  noSelfSupersede r = true ∧
  validSupersedeTargets r = true ∧
  isAcyclic r = true ∧
  consequencesEntailed r = true

def checkWellFormed (r : Registry) : Bool :=
  uniqueIds r && noSelfSupersede r && validSupersedeTargets r && isAcyclic r && consequencesEntailed r

/-- Dependently typed subtype of Machine-Checked Valid Registries. -/
def ValidRegistry := { r : Registry // WellFormed r }

/-- State Transition action on ADR Registry. -/
inductive TransitionAction where
  | propose (adr : ADR)
  | markAccepted (id : ADRId)
  | markDeprecated (id : ADRId)
  | supersede (newAdr : ADR) (oldId : ADRId)
deriving Repr, DecidableEq

/-- Helper to convert Boolean WellFormed validation into ValidRegistry. -/
def validateRegistry (r : Registry) : Except String ValidRegistry :=
  if h : checkWellFormed r = true then
    have h_wf : WellFormed r := by
      dsimp [checkWellFormed] at h
      cases h_u : uniqueIds r with
      | false => simp [h_u] at h
      | true =>
        cases h_n : noSelfSupersede r with
        | false => simp [h_u, h_n] at h
        | true =>
          cases h_v : validSupersedeTargets r with
          | false => simp [h_u, h_n, h_v] at h
          | true =>
            cases h_a : isAcyclic r with
            | false => simp [h_u, h_n, h_v, h_a] at h
            | true =>
              cases h_c : consequencesEntailed r with
              | false => simp [h_u, h_n, h_v, h_a, h_c] at h
              | true => exact ⟨h_u, h_n, h_v, h_a, h_c⟩
    Except.ok ⟨r, h_wf⟩
  else
    Except.error "Registry fails WellFormed invariants after transition"

/-- Controlled State Transition disallowing invalid transitions and ensuring post-state ValidRegistry subtype. -/
def applyTransition (r : Registry) (action : TransitionAction) : Except String ValidRegistry :=
  let rawRes : Except String Registry :=
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
      else if (r.map ADR.id).contains newAdr.id then
        Except.error "Replacement ADR ID must be fresh"
      else
        match r.find? (fun a => a.id == oldId) with
        | some oldAdr =>
          if oldAdr.status != .Accepted then
            Except.error "Target ADR to supersede must be Accepted"
          else
            let updatedOld := r.map (fun a => if a.id == oldId then { a with status := .Superseded } else a)
            Except.ok (newAdr :: updatedOld)
        | none => Except.error "Target ADR to supersede not found"
  match rawRes with
  | Except.ok updatedReg => validateRegistry updatedReg
  | Except.error err => Except.error err

end SpiralCore.ADR
