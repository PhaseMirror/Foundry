namespace ADR

structure ADRId where
  sequence : Nat
  hash : Option String := none
  deriving Repr, DecidableEq, BEq, Inhabited

def ADRId.new (seq : Nat) (h? : Option String := none) : Option ADRId :=
  if seq > 0 then some { sequence := seq, hash := h? } else none

instance : ToString ADRId where
  toString id := match id.hash with
    | some h => s!"ADR-{id.sequence}:{h}"
    | none => s!"ADR-{id.sequence}"

instance : Ord ADRId where
  compare a b := match compare a.sequence b.sequence with
    | Ordering.eq => compare (a.hash.getD "") (b.hash.getD "")
    | ord => ord

inductive ArtifactType where
  | docs : ArtifactType
  | repo : ArtifactType
  | paper : ArtifactType
  | commit : ArtifactType
  | contract : ArtifactType
  | other : (s : String) → ArtifactType
  deriving Repr, DecidableEq

instance : ToString ArtifactType where
  toString
    | .docs => "docs"
    | .repo => "repo"
    | .paper => "paper"
    | .commit => "commit"
    | .contract => "contract"
    | .other s => s

structure ArtifactLink where
  url : String
  artifactType : ArtifactType
  description : String
  deriving Repr, DecidableEq

inductive ADRStatus where
  | Proposed
  | Accepted
  | Deprecated
  | Superseded
  deriving Repr, DecidableEq, Inhabited

instance : ToString ADRStatus where
  toString
    | .Accepted => "Accepted"
    | .Proposed => "Proposed"
    | .Deprecated => "Deprecated"
    | .Superseded => "Superseded"

structure ADR where
  id : ADRId
  title : String
  status : ADRStatus
  context : String
  decision : String
  consequences : List String
  supersedes : Option ADRId
  links : List ArtifactLink
  deriving Repr, DecidableEq, BEq, Inhabited

def ADR.mkProposed
    (seq : Nat)
    (title context decision : String)
    (consequences : List String)
    (supersedes? : Option ADRId := none)
    (links? : List ArtifactLink := []) : Option ADR :=
  match ADRId.new seq with
  | none => none
  | some adrId => pure { id := adrId, title, status := .Proposed, context, decision, consequences, supersedes := supersedes?, links := links? }

structure ADRRegistry where
  entries : List ADR
  deriving Repr

def ADRRegistry.empty : ADRRegistry := { entries := [] }

def ADRRegistry.insert (reg : ADRRegistry) (adr : ADR) : ADRRegistry :=
  { reg with entries :=
      let rest := reg.entries.filter (·.id ≠ adr.id)
      rest ++ [adr]
  }

def ADRRegistry.lookup (reg : ADRRegistry) (id : ADRId) : Option ADR :=
  reg.entries.find? (·.id = id)

def ADRRegistry.accepted (reg : ADRRegistry) : List ADR :=
  reg.entries.filter (·.status = .Accepted)

def ADRRegistry.deprecate (reg : ADRRegistry) (id : ADRId) : Option ADRRegistry :=
  match reg.lookup id with
  | some adr =>
    if adr.status = .Accepted ∨ adr.status = .Proposed then
      some { reg with entries :=
              let rest := reg.entries.filter (·.id ≠ id)
              let updated := { adr with status := .Deprecated }
              rest ++ [updated]
            }
    else none
  | none => none

def ADRRegistry.supersede (reg : ADRRegistry) (oldId newId : ADRId) : Option ADRRegistry :=
  match reg.lookup oldId with
  | some adr =>
    if adr.status = .Accepted then
      let rest := reg.entries.filter (·.id ≠ oldId)
      let updated := { adr with status := .Superseded, supersedes := some newId }
      some { reg with entries := rest ++ [updated] }
    else none
  | none => none

structure StatusTransition where
  adrId : ADRId
  fromStatus : ADRStatus
  toStatus : ADRStatus
  timestamp : String
  deriving Repr, BEq

structure AuditTrail where
  transitions : List StatusTransition
  deriving Repr

def AuditTrail.empty : AuditTrail := { transitions := [] }

def AuditTrail.record (trail : AuditTrail) (tr : StatusTransition) : AuditTrail :=
  { trail with transitions := tr :: trail.transitions }

def isAccepted (adr : ADR) : Prop := adr.status = ADRStatus.Accepted

def isSuperseded (adr : ADR) : Prop := adr.status = ADRStatus.Superseded

def isImmutable (adr : ADR) : Prop :=
  adr.status = .Accepted ∨ adr.status = .Deprecated

end ADR
