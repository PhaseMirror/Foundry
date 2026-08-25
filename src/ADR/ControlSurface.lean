/-!
# ADR.ControlSurface — cross-layer control-surface contract (Lean side)

Mirror of the Rust contract in `rust/src/control_surface.rs`. Both sides
define the same `ADRStatus` / `CircuitBreakerState` vocabulary and the same
refinement predicate (`contract_valid` / `is_valid`), so a certification
dossier minted on either layer is rejected or accepted identically.

Consistency between the two files is enforced in CI by
`scripts/check_control_surface_schema.py`.

Refinement rule (the enforcement teeth)
---------------------------------------
`contract_valid c` holds iff the contract carries the current schema version
**and** an accepted contract can only ride an armed circuit breaker. A tripped
breaker therefore blocks any accepted-status contract — the machine-level
statement of the documented circuit-breaker / veto control surface.
-/

namespace ADR.ControlSurface

/-- Current cross-layer schema version. Must match
`CONTROL_SURFACE_SCHEMA_VERSION` in `rust/src/control_surface.rs`. -/
def SCHEMA_VERSION : Nat := 2

/-- Lifecycle status of an Architecture Decision Record. -/
inductive ADRStatus where
  | proposed   : ADRStatus
  | accepted   : ADRStatus
  | deprecated : ADRStatus
  | superseded : ADRStatus
  deriving DecidableEq, Repr

/-- State of the release circuit breaker. -/
inductive CircuitBreakerState where
  | armed    : CircuitBreakerState
  | tripped  : CircuitBreakerState
  | disabled : CircuitBreakerState
  deriving DecidableEq, Repr

/-- The control-surface contract carried by every certification dossier. -/
structure ControlSurfaceContract where
  schemaVersion : Nat
  status        : ADRStatus
  breaker       : CircuitBreakerState
  deriving Repr

/-- Refinement predicate shared with the Rust layer:
current schema version ∧ accepted contracts require an armed breaker. -/
def contract_valid (c : ControlSurfaceContract) : Prop :=
  c.schemaVersion = SCHEMA_VERSION ∧
    (c.status = .accepted → c.breaker = .armed)

/-- **No bypass**: an accepted contract behind a tripped breaker is invalid.
This is the cross-layer analogue of
`CertificationGate.no_bypass_triple_lock`. -/
theorem no_bypass_tripped_breaker (c : ControlSurfaceContract)
    (hs : c.status = .accepted) (ht : c.breaker = .tripped) :
    ¬ contract_valid c := by
  intro ⟨_, hb⟩
  rw [hb hs] at ht
  exact CircuitBreakerState.noConfusion ht

/-- Version pinning: any other schema version is invalid regardless of state. -/
theorem wrong_version_invalid (c : ControlSurfaceContract)
    (hv : c.schemaVersion ≠ SCHEMA_VERSION) :
    ¬ contract_valid c := by
  intro h
  exact hv h.1

end ADR.ControlSurface
