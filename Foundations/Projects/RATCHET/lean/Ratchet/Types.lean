/-!
# Ratchet.Types — Operational Data Structures for ADR-0038

Formalizes core operational data structures from ADR-0038 §3.1 & §3.3:
- PlantState: plant state variables and monotonic identifiers
- WritePath & WriteManifest: self-edit transparency binding artifacts
- SafetyBarrier: barrier certificates and constraint linearizations
- Snapshot: cryptographically bound state snapshots
-/

namespace Ratchet

/-- Operational modes for the external controller C_ext. -/
inductive Mode : Type where
  | IDLE    : Mode
  | BURST   : Mode
  | CAPTURE : Mode
  | GROUND  : Mode
  | HALT    : Mode
  deriving Repr, DecidableEq

/-- Access permission for a write path. -/
inductive AccessMode : Type where
  | Read    : AccessMode
  | Write   : AccessMode
  | Execute : AccessMode
  deriving Repr, DecidableEq

/-- Write path into learner parameter theta. -/
structure WritePath where
  handle : String
  access : AccessMode
  deriving Repr, DecidableEq

/-- Complete write manifest for learner parameter theta (Binding artifact for C2). -/
structure WriteManifest where
  paths    : List WritePath
  complete : Bool
  deriving Repr, DecidableEq

/-- Plant state record. -/
structure PlantState where
  x           : List Nat
  u           : List Nat
  y           : List Nat
  theta       : List Nat
  t           : Nat
  burst_id    : Nat
  snapshot_id : Nat
  deriving Repr, DecidableEq

/-- Safety barrier function phi and gradient metadata. -/
structure SafetyBarrier where
  margin  : Nat
  horizon : Nat
  deriving Repr, DecidableEq

/-- Cryptographic state snapshot for rollback operations. -/
structure Snapshot where
  id           : Nat
  burst_id     : Nat
  t            : Nat
  theta_snap   : List Nat
  x_snap       : List Nat
  y_hist       : List (List Nat)
  content_hash : String
  signature    : String
  deriving Repr, DecidableEq

/-- Invariant: Manifest is valid only when complete flag is strictly true. -/
def is_manifest_valid (m : WriteManifest) : Prop :=
  m.complete = true

/-- Invariant: Snapshot signature is non-empty and non-pending. -/
def is_snapshot_verified (s : Snapshot) : Bool :=
  s.signature != "" && s.signature != "PENDING" && s.content_hash != ""

end Ratchet
