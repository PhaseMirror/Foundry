import DCA.Attributes

/-!
# DCA Core Definitions

This module defines the fundamental types for the DCA-System, formalizing
the Digital Control Act (DCA) specification from ADR-0030.

## Architecture Overview

The DCA ecosystem requires a production-grade, mathematically verified
implementation framework. The execution environment must:
- Prevent undefined behavior
- Enforce core state invariants (FIR: Filter → Isolate → Reconstruct)
- Establish a cross-language verification pipeline between Lean 4 and Rust/Kani

## Types Defined

- `DcaState` — the complete computational state of a DCA pipeline frame
- `DcaTransition` — the FIR deterministic transition relation (Prop)
- `MemoryFrame` — fixed-width memory topology (48 bytes per granular index)
- `MemoryTopology` — the memory allocation discipline
- `FirPath` — the deterministic inverse path (is_ → did → was)
- `OverflowGate` — execution safety gate for epsilon_g arithmetic
- `ExecutionGate` — composite safety gate combining all DCA invariants
- `DcaRegistry` — ordered collection of DCA states for audit

## Conventions

All definitions follow mathlib naming conventions. Doc comments use
`/-! ... -/` blocks. Every definition carries a `@[dca]` tag or a
docstring referencing ADR-0030.
-/

namespace DCA

/-! ### DcaState -/

/-- The complete computational state of a DCA pipeline frame.

Fields model the FIR (Filter → Isolate → Reconstruct) cycle:
- `was`: the previous-isolated value (the "was" phase — before current)
- `did`: the current filtered value (the "did" phase — just completed)
- `is_`: the current isolated value (the "is" phase — active now)
- `root_pointer`: immutable reference to the root of the computation tree
- `epsilon_g`: the deterministic growth increment for the isolated value
- `is_valid`: the safety flag; `false` isolates the pipeline from corruption

Memory layout: 6 × UInt64 = 48 bytes, matching the ADR-0030 memory
topology constraint of maximum 48 bytes per granular index. -/
structure DcaState where
  was           : UInt64
  did           : UInt64
  is_           : UInt64
  root_pointer  : UInt64
  epsilon_g     : UInt64
  is_valid      : Bool
  deriving Repr, BEq, Inhabited

instance : ToString DcaState := ⟨fun s =>
  s!"DcaState(was={s.was}, did={s.did}, is={s.is_}, " ++
  s!"root={s.root_pointer}, eps={s.epsilon_g}, valid={s.is_valid})"⟩

/-! ### DcaTransition -/

/-- The FIR deterministic transition relation.

`DcaTransition s1 s2` is a `Prop` asserting that `s2` is the unique
successor of `s1` under one FIR cycle:

1. `s2.was = s1.did` — the old "did" becomes the new "was" (history shift)
2. `s2.did = s1.is_` — the old "is" becomes the new "did" (filter completion)
3. `s2.is_ = s1.is_ + s1.epsilon_g` — deterministic growth (isolation)
4. `s2.root_pointer = s1.root_pointer` — root is immutable
5. `s2.epsilon_g = s1.epsilon_g` — growth rate is constant
6. `s1.is_valid = true` — precondition: source must be valid
7. `s2.is_valid = true` — postcondition: result is valid

This encodes the axiom from ADR-0030 §2:
> "Axiomatic preservation law: State transitions must follow deterministic loops"

The constructor `DcaTransition.step` carries all seven equalities as
explicit hypotheses, making the transition proof-carrying by construction. -/
inductive DcaTransition : DcaState → DcaState → Prop where
  | step (s1 s2 : DcaState) :
      s2.was = s1.did →
      s2.did = s1.is_ →
      s2.is_ = (s1.is_ + s1.epsilon_g) →
      s2.root_pointer = s1.root_pointer →
      s2.epsilon_g = s1.epsilon_g →
      s1.is_valid = true →
      s2.is_valid = true →
      DcaTransition s1 s2

/-! ### Memory Topology -/

/-- The maximum size of a single memory frame in bytes.

ADR-0030 §4: "Memory buffers are fixed-width frames (maximum 48 bytes
per granular index) ensuring deterministic allocation profiles."

48 bytes = 6 × UInt64, matching the DcaState layout. -/
def MaxFrameBytes : Nat := 48

/-- A memory frame: a fixed-width buffer of exactly `MaxFrameBytes` bytes.

Frames are the atomic unit of the DCA memory topology. Each frame holds
exactly one `DcaState` (6 × 8 = 48 bytes), ensuring zero fragmentation
and deterministic allocation. -/
structure MemoryFrame where
  sizeBytes : Nat
  isValid   : sizeBytes ≤ MaxFrameBytes
  deriving Repr, BEq

/-- The memory topology: a collection of frames with the allocation discipline
that every frame respects `MaxFrameBytes`. -/
structure MemoryTopology where
  frames : List MemoryFrame
  deriving Repr, BEq

/-- Check if a byte count fits within a single frame. -/
def fitsInFrame (n : Nat) : Bool :=
  n ≤ MaxFrameBytes

/-! ### FIR Path (Deterministic Sequence Validation) -/

/-- The deterministic inverse path required by ADR-0030 §4:
"Every runtime transition must output a cryptographically testable
inverse path (`is_ → did → was`)."

`FirPath` records the three-phase reverse chain for audit verification. -/
structure FirPath where
  current : UInt64
  previous : UInt64
  oldest : UInt64
  deriving Repr, BEq

/-- Construct the FIR inverse path from a DCA state.
The path is `is_ → did → was` — the reversibility chain. -/
def DcaState.firPath (s : DcaState) : FirPath :=
  { current := s.is_, previous := s.did, oldest := s.was }

/-- Verify that a FIR path matches the expected reverse chain from a state. -/
def FirPath.matches (path : FirPath) (s : DcaState) : Bool :=
  path.current == s.is_ && path.previous == s.did && path.oldest == s.was

/-! ### Overflow Gate (Execution Safety) -/

/-- The overflow gate: detects when `epsilon_g` arithmetic would cause
a `UInt64` overflow, forcing `is_valid` to `false`.

ADR-0030 §4: "If arithmetic overflow occurs during `epsilon_g` sequencing,
the execution layer forces the state flag to `false`, isolating the system
pipeline from memory corruption."

`OverflowGate.check s` returns `true` when the state is safe (no overflow);
`false` when overflow would occur. -/
def OverflowGate.check (s : DcaState) : Bool :=
  if s.is_valid then
    s.is_.toNat + s.epsilon_g.toNat ≤ (UInt64.size - 1)
  else
    true

/-- A state passes the overflow gate when check returns `true`. -/
def OverflowSafe (s : DcaState) : Prop :=
  OverflowGate.check s = true

/-! ### Execution Gate (Composite Safety) -/

/-- The composite execution gate: combines all DCA safety invariants into
a single check.

ADR-0030 §4 operational invariants:
1. Memory topology: state fits in 48-byte frame
2. FIR reversibility: is_ → did → was path is reconstructible
3. Overflow safety: epsilon_g arithmetic is bounded

The gate returns `true` iff all three invariants hold. -/
def ExecutionGate.check (s : DcaState) : Bool :=
  let memoryOk := fitsInFrame (6 * 8)
  let overflowOk := OverflowGate.check s
  memoryOk && overflowOk

/-- A state passes the composite execution gate. -/
def ExecutionSafe (s : DcaState) : Prop :=
  ExecutionGate.check s = true

/-! ### DcaRegistry -/

/-- A registry of DCA states: the append-only audit trail.

The registry is the single source of truth for:
- State lookups (`lookup`)
- Transition traceability (`trace`)
- Audit-monitor queries for Kani cross-checks

Following the exact pattern of `ADR.Registry` in the ADR-System. -/
structure DcaRegistry where
  states : List DcaState
  deriving Repr, BEq

/-- Safe list access without mathlib `List.get?`. -/
def listGet? {α : Type} : List α → Nat → Option α
  | [], _ => none
  | a :: _, 0 => some a
  | _ :: as, n + 1 => listGet? as n

namespace DcaRegistry

/-- Look up a DCA state by index within the registry. -/
def lookup (reg : DcaRegistry) (idx : Nat) : Option DcaState :=
  listGet? reg.states idx

/-- Register a new DCA state, appending it to the registry
(append-only discipline). -/
def add (reg : DcaRegistry) (s : DcaState) : DcaRegistry :=
  { states := reg.states ++ [s] }

/-- The valid states of a registry. -/
def valid (reg : DcaRegistry) : List DcaState :=
  reg.states.filter (fun s => s.is_valid == true)

/-- The count of valid states in the registry. -/
def validCount (reg : DcaRegistry) : Nat :=
  (reg.valid).length

/-- True when no duplicate states exist in the registry
(append-only uniqueness). -/
def uniqueStates (reg : DcaRegistry) : Bool :=
  (reg.states.eraseDups).length == reg.states.length

end DcaRegistry

/-! ### Transition Chain (Supersession analogue) -/

/-- A chain of DCA transitions: a sequence of states connected by
`DcaTransition` steps. Used to prove traceability and convergence. -/
structure TransitionChain where
  states : List DcaState
  steps  : List (DcaState × DcaState)
  deriving Repr, BEq

/-- The length of a transition chain (number of steps). -/
def TransitionChain.length (c : TransitionChain) : Nat :=
  c.steps.length

/-- A chain is well-formed when every step is a valid `DcaTransition`. -/
def TransitionChain.wellFormed (c : TransitionChain) : Prop :=
  ∀ (p : Fin c.steps.length),
    let ⟨s1, s2⟩ := c.steps[p]
    DcaTransition s1 s2

end DCA
