import Foundations.ADR.Core
import Foundations.Governance.Core

/-!
# Foundations.ControlSurface.Core — Shared Control Surface Contract

Formalizes the cross-layer control-surface contract schema mirroring Rust runtime structures,
verifying non-reentrant acceptance, acyclic supersession, and link integrity.
-/

namespace Foundations.ControlSurface

open Foundations.ADR
open Foundations.Governance

/-- Mirror of Rust CircuitBreakerState. -/
inductive CircuitBreakerState where
  | Closed
  | Open
  | HalfOpen
  deriving Repr, DecidableEq

/-- Mirror of Rust ControlSurfaceContract. -/
structure ControlSurfaceContract where
  adr_id : Nat
  status : ADRStatus
  supersedes : Option Nat
  links : List String
  allowed_transitions : List (ADRStatus × ADRStatus)
  circuit_breaker : CircuitBreakerState
  deriving Repr

/-- Reject a re-entrant Accepted → Proposed transition. -/
def reject_reentrant_acceptance (c : ControlSurfaceContract) : Prop :=
  ¬(c.status = ADRStatus.Accepted ∧
    c.allowed_transitions.any (fun t => t.1 = ADRStatus.Accepted ∧ t.2 = ADRStatus.Proposed))

/-- Supersession must be acyclic: supersedes ID < current ID. -/
def supersession_acyclic (c : ControlSurfaceContract) : Prop :=
  match c.supersedes with
  | none => True
  | some sid => sid < c.adr_id

/-- Accepted ADRs must have at least one artifact link. -/
def accepted_has_links (c : ControlSurfaceContract) : Prop :=
  c.status = ADRStatus.Accepted → c.links.length > 0

/-- Full contract validity predicate. -/
def contract_valid (c : ControlSurfaceContract) : Prop :=
  c.adr_id > 0 ∧
  reject_reentrant_acceptance c ∧
  supersession_acyclic c ∧
  accepted_has_links c

/-- Verified sample contract instance. -/
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

/-- Theorem: Sample contract satisfies all validity invariants. -/
theorem sample_contract_valid : contract_valid sample_contract := by
  dsimp [contract_valid, reject_reentrant_acceptance, supersession_acyclic, accepted_has_links, sample_contract]
  refine ⟨by decide, ?_, trivial, by decide⟩
  intro h
  rcases h with ⟨h1, h2⟩
  revert h2
  decide

end Foundations.ControlSurface
