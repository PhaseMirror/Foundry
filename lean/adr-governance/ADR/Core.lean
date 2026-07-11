/-!
# Core ADR Definitions
This module defines the basic data structures for Architecture Decision Records,
including provenance tracking for source artifacts and layout specifications.
-/
namespace ADR

inductive ADRStatus
  | Proposed
  | Accepted
  | Deprecated
  | Superseded
  deriving Repr, BEq

/-- Provenance record for an ADR, tracking original source locations. -/
structure Provenance where
  source_path : String
  source_type : String  -- "rust" | "ts" | "py" | "lean" | "doc"
  commit_hash : Option String
  deriving Repr

/-- Layout specification describing the monorepo structure. -/
structure LayoutSpec where
  root_name : String
  lean_dir : String
  impl_dirs : List String
  defensive_dir : Option String
  plans_dir : Option String
  sources_dir : Option String
  deriving Repr

/-- An artifact link with optional provenance. -/
structure ArtifactLink where
  url : String
  description : String
  provenance : Option Provenance
  deriving Repr

structure ADR where
  id : Nat
  title : String
  status : ADRStatus
  context : String
  decision : String
  consequences : List String
  supersedes : Option Nat
  links : List ArtifactLink
  deriving Repr

/-- Represents a collection of ADRs in the system -/
abbrev ADRRegistry := List ADR

/-- Provenanced registry with a global invariant ensuring every ADR link carries provenance. -/
structure ProvenancedRegistry where
  registry : ADRRegistry
  valid : ∀ (a : ADR), a ∈ registry → ∀ (l : ArtifactLink), l ∈ a.links → l.provenance.isSome

/-- Default materia_commons layout specification. -/
def defaultLayout : LayoutSpec := {
  root_name := "materia_commons",
  lean_dir := "lean",
  impl_dirs := ["impl/rust", "impl/ts", "impl/py"],
  defensive_dir := some "defensive",
  plans_dir := some "plans",
  sources_dir := some "sources"
}

end ADR
