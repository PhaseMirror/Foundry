
namespace ADR

/-! ## ADR Identity -/

/--
A globally unique identifier for an ADR.
Formally, ADR IDs form a decidable equality type to support set membership
and history traversal proofs.
-/
structure ADRId where
  value : Nat
  deriving Repr, DecidableEq, Inhabited

namespace ADRId

/--
Successor ID generator.  Used when constructing a new ADR in sequence.
-/
def next (id : ADRId) : ADRId :=
  ⟨id.value + 1⟩

instance : ToString ADRId where
  toString id := s!"ADR-{id.value}"

end ADRId

/-! ## ADR Status -/

/--
The lifecycle status of an ADR.

- `Proposed`    — under discussion, not yet accepted.
- `Accepted`    — formally approved; immutable unless superseded.
- `Deprecated`  — no longer recommended; may still be in use.
- `Superseded`  — replaced by another ADR; original retained for traceability.
-/
inductive ADRStatus where
  | Proposed
  | Accepted
  | Deprecated
  | Superseded
  deriving Repr, DecidableEq, Inhabited

namespace ADRStatus

/--
Whether the status is terminal (no further transitions allowed except
via supersession).
-/
def isTerminal : ADRStatus → Bool
  | Accepted => true
  | Superseded => true
  | Deprecated => true
  | Proposed => false

/--
Whether the status is mutable (can transition without supersession).
-/
def isMutable : ADRStatus → Bool := fun s => !isTerminal s

end ADRStatus

/-! ## Artifact Links -/

/--
A typed link from an ADR to an external artifact (commit, module, test, etc.).
-/
structure ArtifactLink where
  artifactType : String
  identifier : String
  deriving Repr, Inhabited

namespace ArtifactLink

/--
Create a link to a Lean declaration.
-/
def leanDecl (declName : String) : ArtifactLink :=
  ⟨"Lean", declName⟩

/--
Create a link to a Git commit.
-/
def gitCommit (hash : String) : ArtifactLink :=
  ⟨"Git", hash⟩

/--
Create a link to a test file.
-/
def testFile (path : String) : ArtifactLink :=
  ⟨"Test", path⟩

end ArtifactLink

/-! ## ADR Structure -/

/--
The canonical ADR record.

Fields:
- `id` — unique identifier.
- `title` — short human-readable title.
- `status` — current lifecycle status.
- `context` — motivating forces and constraints.
- `decision` — the chosen direction.
- `consequences` — list of concrete outcomes (textual for now;
  a future enhancement replaces this with a formally checked logic).
- `supersedes` — if `some id`, this ADR replaces `id`.
- `links` — references to external artifacts.
-/
structure ADR where
  id : ADRId
  title : String
  status : ADRStatus
  context : String
  decision : String
  consequences : List String
  supersedes : Option ADRId
  links : List ArtifactLink
  deriving Repr, Inhabited

namespace ADR

/--
A readable ADR identifier string.
-/
def adrIdStr (a : ADR) : String := toString a.id

/--
Set the status of an ADR, returning a modified copy.
-/
def setStatus (a : ADR) (s : ADRStatus) : ADR :=
  { a with status := s }

/--
Set the supersedes field of an ADR.
-/
def setSupersedes (a : ADR) (target : Option ADRId) : ADR :=
  { a with supersedes := target }

/--
Add a link to an ADR.
-/
def addLink (a : ADR) (link : ArtifactLink) : ADR :=
  { a with links := a.links ++ [link] }

end ADR

/-! ## Valid Transitions -/

/--
Whether transitioning from `old` to `new` is allowed under ADR governance.

Accepted ADRs are immutable unless they are superseded by a valid target ADR.
Proposed ADRs may be accepted or deprecated without supersession.
-/
def validTransition (old new : ADRStatus) (supersedes : Option ADRId) : Bool :=
  if old = new then true
  else if old = ADRStatus.Accepted then
    new = ADRStatus.Superseded && supersedes.isSome
  else if old = ADRStatus.Proposed then
    new = ADRStatus.Accepted || new = ADRStatus.Deprecated
  else false

/-! ## Supersession Chain -/

def followSupersessionLoop (lookup : ADRId → Option ADR) (current : ADR) (acc : List ADRId) (fuel : Nat) : List ADRId :=
  match fuel with
  | 0 => acc
  | fuel + 1 =>
      match current.supersedes with
      | none => acc
      | some targetId =>
          match lookup targetId with
          | none => acc
          | some target =>
              followSupersessionLoop lookup target (targetId :: acc) fuel

/--
`followSupersession lookup a` returns the full chain of ADR IDs superseded by `a`,
given a lookup function `lookup : ADRId → Option ADR`.

The function is bounded by `fuel` iterations to guarantee termination in the
absence of structural decrease proofs.  A `fuel` of 1024 exceeds any realistic
ADR chain and is treated as unbounded for practical purposes.
-/
def followSupersession (lookup : ADRId → Option ADR) (a : ADR) (fuel : Nat := 1024) : List ADRId :=
  followSupersessionLoop lookup a [] fuel

end ADR
