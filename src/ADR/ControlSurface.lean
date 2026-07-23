import ADR.Core
import ADR.Governance

open ADR
open ADR.Governance

/-!
# ADR.ControlSurface
Lean counterparts to the Rust shared control-surface contract.

This module mirrors the types and predicates defined in
`rust/src/control_surface.rs` so that both layers share a common
contract vocabulary. The cross-layer CI gate (`verify.yml`) checks that
the Lean and Rust schemas stay aligned.
-/

namespace ADR.ControlSurface

/-- Mirror of Rust `CircuitBreakerState`. -/
inductive CircuitBreakerState where
  | Closed
  | Open
  | HalfOpen
deriving Repr, DecidableEq

/-- Mirror of Rust `ControlSurfaceContract`.
    The Lean side proves the same invariants as the Rust side. -/
structure ControlSurfaceContract where
  adr_id : Nat
  status : ADRStatus
  supersedes : Option ADRId
  links : List String
  allowed_transitions : List (ADRStatus × ADRStatus)
  circuit_breaker : CircuitBreakerState
deriving Repr

/-- Reject a re-entrant Accepted → Proposed transition.
    This mirrors `ControlSurfaceContract::reject_reentrant_acceptance` in Rust. -/
def reject_reentrant_acceptance (c : ControlSurfaceContract) : Prop :=
  ¬(c.status = ADRStatus.Accepted ∧
    c.allowed_transitions.any (fun t => t.1 = ADRStatus.Accepted ∧ t.2 = ADRStatus.Proposed))

/-- Supersession must be acyclic: supersedes ID < current ID. -/
def supersession_acyclic (c : ControlSurfaceContract) : Prop :=
  match c.supersedes with
  | none => True
  | some sid => sid.value < c.adr_id

/-- Accepted ADRs must have at least one artifact link. -/
def accepted_has_links (c : ControlSurfaceContract) : Prop :=
  c.status = ADRStatus.Accepted → c.links.length > 0

/-- Full contract validity check (mirrors `ControlSurfaceContract::is_valid` in Rust). -/
def contract_valid (c : ControlSurfaceContract) : Prop :=
  c.adr_id > 0 ∧
  reject_reentrant_acceptance c ∧
  supersession_acyclic c ∧
  accepted_has_links c

/-- A minimal verified contract mirrors the Rust witness. -/
def sample_contract : ControlSurfaceContract := {
  adr_id := 1,
  status := ADRStatus.Accepted,
  supersedes := none,
  links := ["docs/adr/ADR-PML-001.md"],
  allowed_transitions := [
    (ADRStatus.Proposed, ADRStatus.Accepted),
    (ADRStatus.Proposed, ADRStatus.Deprecated),
    (ADRStatus.Accepted, ADRStatus.Deprecated),
    (ADRStatus.Accepted, ADRStatus.Superseded),
    (ADRStatus.Deprecated, ADRStatus.Superseded),
  ],
  circuit_breaker := CircuitBreakerState.Closed
}

/-- The sample contract satisfies all invariants. -/
theorem sample_contract_valid : contract_valid sample_contract := by
  unfold contract_valid reject_reentrant_acceptance supersession_acyclic accepted_has_links
  constructor <;>
    (simp [sample_contract] <;> trivial) <;>
    (simp [sample_contract])

end ADR.ControlSurface
