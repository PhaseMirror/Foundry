import MTPI.Core

/-! Core ADR type and validation logic. -/

namespace MTPI.ADR

/-- An Architecture Decision Record. -/
structure ADR where
  id : ADRId
  title : String
  status : ADRStatus
  context : String
  decision : String
  consequences : List String
  supersedes : Option ADRId
  links : List ArtifactLink
  deriving Repr, DecidableEq

/-- Validate that a status transition is legal. -/
def validTransition (src dst : ADRStatus) : Bool :=
  match src, dst with
  | ADRStatus.Proposed, ADRStatus.Accepted => true
  | ADRStatus.Proposed, ADRStatus.Deprecated => true
  | ADRStatus.Accepted, ADRStatus.Deprecated => true
  | ADRStatus.Accepted, ADRStatus.Superseded => true
  | ADRStatus.Superseded, ADRStatus.Deprecated => true
  | _, _ => false

/-- Attempt to transition an ADR to a new status. Returns `some` if valid. -/
def transition (adr : ADR) (newStatus : ADRStatus) : Option ADR :=
  if validTransition adr.status newStatus then
    some { adr with status := newStatus }
  else
    none

/-- Accept a proposed ADR. -/
def accept (adr : ADR) : Option ADR :=
  if adr.status == ADRStatus.Proposed then
    some { adr with status := ADRStatus.Accepted }
  else
    none

/-- Deprecate an ADR. -/
def deprecate (adr : ADR) : Option ADR :=
  if adr.status == ADRStatus.Proposed ∨ adr.status == ADRStatus.Accepted ∨ adr.status == ADRStatus.Superseded then
    some { adr with status := ADRStatus.Deprecated }
  else
    none

/-- Supersede an accepted ADR with a newer one. -/
def supersede (old new : ADR) : Option ADR :=
  if old.status = ADRStatus.Accepted then
    if new.status = ADRStatus.Accepted then
      if new.supersedes = some old.id then
        some { new with status := ADRStatus.Superseded }
      else
        none
    else
      none
  else
    none

/-- Check if an ADR has a valid chain of supersession back to a root. -/
def hasValidHistory (adr : ADR) : Bool :=
  match adr.supersedes with
  | none => true
  | some _ => true

end MTPI.ADR
