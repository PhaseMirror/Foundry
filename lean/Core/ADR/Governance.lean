import ADR.Core
import ADR.Logics
import ADR.Proofs
import ADR.History
open ADR ADR.Logics ADR.Proofs ADR.History
namespace ADR.Governance

inductive Transition where
  | propose   : ADR → Transition
  | accept    : ADR → List ADR.Proofs.ConsequenceCoverageProof → Transition
  | deprecate : ADRId → Transition
  | supersede : ADRId → ADRId → Transition
  deriving Repr

structure AcceptObligation where
  adr : ADR
  consequenceWitnesses : List ADR.Proofs.ConsequenceCoverageProof
  deriving Repr

structure SupersedeObligation where
  oldId : ADRId
  newId : ADRId
  rationale : String
  deriving Repr

def propose (reg : ADRRegistry) (adr : ADR) : Option (ADRRegistry × ADR) :=
  if reg.entries.any (·.id = adr.id) then none
  else some (reg.insert adr, adr)

def accept (reg : ADRRegistry) (adrId : ADRId) (witness : ValidADR (reg.lookup adrId).get!) : Option ADRRegistry :=
  match reg.lookup adrId with
  | some adr =>
    if adr.status = .Proposed then
      let rest := reg.entries.filter (·.id ≠ adrId)
      let updated := { adr with status := .Accepted }
      some { reg with entries := rest ++ [updated] }
    else none
  | none => none

def deprecate (reg : ADRRegistry) (adrId : ADRId) : Option ADRRegistry :=
  match reg.lookup adrId with
  | some adr =>
    if adr.status = .Accepted ∨ adr.status = .Proposed then
      let rest := reg.entries.filter (·.id ≠ adrId)
      let updated := { adr with status := .Deprecated }
      some { reg with entries := rest ++ [updated] }
    else none
  | none => none

def supersede (reg : ADRRegistry) (oldId newId : ADRId) : Option ADRRegistry :=
  match reg.lookup oldId with
  | some oldAdr =>
    if oldAdr.status = .Accepted ∧ oldId ≠ newId then
      let rest := reg.entries.filter (·.id ≠ oldId)
      let updated := { oldAdr with status := .Superseded, supersedes := some newId }
      some { reg with entries := rest ++ [updated] }
    else none
  | none => none

def reopen (reg : ADRRegistry) (adrId : ADRId) : Option ADRRegistry :=
  match reg.lookup adrId with
  | some adr =>
    if adr.status = .Superseded then
      let rest := reg.entries.filter (·.id ≠ adrId)
      let updated := { adr with status := .Proposed, supersedes := none }
      some { reg with entries := rest ++ [updated] }
    else none
  | none => none

structure ConflictSignature where
  domain : String
  decisionA : String
  decisionB : String
  deriving Repr, DecidableEq

def ConflictDetector.findConflicts (reg : ADRRegistry) : List ConflictSignature :=
  []

def ConflictDetector.conflictsWithAccepted (reg : ADRRegistry) (adr : ADR) : Option ADR :=
  let accepted := reg.accepted
  accepted.find? (fun a =>
    a.decision = adr.decision ∧ a.id ≠ adr.id
  )

def emitTransitionEvent (reg : ADRRegistry) (adrId : ADRId) (fromStatus toStatus : ADRStatus) : IO Unit := do
  let evt := s!"TRANSITION:{adrId}:{fromStatus}→{toStatus}"
  IO.println evt

def Governance.exportSnapshot (reg : ADRRegistry) : String :=
  let lines := reg.entries.map fun adr =>
    s!"{adr.id}: {adr.status}: {adr.title}"
  String.intercalate "\n" lines

structure Registrar where
  registry : ADRRegistry
  trail : AuditTrail
  deriving Repr

def Registrar.empty : Registrar :=
  { registry := ADRRegistry.empty, trail := AuditTrail.empty }

def Registrar.propose (r : Registrar) (adr : ADR) : Option (Registrar × ADR) :=
  match ADR.Governance.propose r.registry adr with
  | some (newReg, newAdr) =>
    let tr : StatusTransition :=
      { adrId := newAdr.id, fromStatus := .Proposed, toStatus := .Proposed,
        timestamp := "now" }
    some ({ r with registry := newReg, trail := r.trail.record tr }, newAdr)
  | none => none

def Registrar.accept (r : Registrar) (adrId : ADRId) (_witness : ValidADR (r.registry.lookup adrId).get!) : Option Registrar :=
  match ADR.Governance.accept r.registry adrId _witness with
  | some newReg =>
    let tr : StatusTransition :=
      { adrId := adrId, fromStatus := .Proposed, toStatus := .Accepted,
        timestamp := "now" }
    some { r with registry := newReg, trail := r.trail.record tr }
  | none => none

end ADR.Governance
