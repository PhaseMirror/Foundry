/-!
# Foundations.DCA.Core — Digital Control Act (ADR-0030) State Machine & Invariants

Formalizes the Digital Control Act state space, FIR (Filter → Isolate → Reconstruct) transition relation,
fixed-width memory frame topology (48 bytes), FIR inverse path reversibility, and execution safety gates.
-/

namespace Foundations.DCA

/-- The complete computational state of a DCA pipeline frame. -/
structure DcaState where
  was           : Nat
  did           : Nat
  is_           : Nat
  root_pointer  : Nat
  epsilon_g     : Nat
  is_valid      : Bool
deriving Repr, DecidableEq, Inhabited

/-- The FIR deterministic transition relation asserting that s2 is the unique successor of s1. -/
inductive DcaTransition : DcaState → DcaState → Prop where
  | step (s1 s2 : DcaState) :
      s2.was = s1.did →
      s2.did = s1.is_ →
      s2.is_ = s1.is_ + s1.epsilon_g →
      s2.root_pointer = s1.root_pointer →
      s2.epsilon_g = s1.epsilon_g →
      s1.is_valid = true →
      s2.is_valid = true →
      DcaTransition s1 s2

/-- The maximum size of a single memory frame in bytes (48 bytes = 6 * 8 bytes). -/
def MaxFrameBytes : Nat := 48

/-- Check if a byte count fits within a single frame. -/
def fitsInFrame (n : Nat) : Bool :=
  n ≤ MaxFrameBytes

/-- FIR inverse path recording the three-phase reverse chain for audit verification (is_ → did → was). -/
structure FirPath where
  current  : Nat
  previous : Nat
  oldest   : Nat
deriving Repr, DecidableEq

/-- Construct the FIR inverse path from a DCA state. -/
def DcaState.firPath (s : DcaState) : FirPath :=
  { current := s.is_, previous := s.did, oldest := s.was }

/-- Verify that a FIR path matches the expected reverse chain from a state. -/
def FirPath.matches (path : FirPath) (s : DcaState) : Bool :=
  path.current == s.is_ && path.previous == s.did && path.oldest == s.was

/-- Overflow safety gate for deterministic growth. -/
def OverflowGate.check (s : DcaState) (limit : Nat) : Bool :=
  if s.is_valid then
    s.is_ + s.epsilon_g ≤ limit
  else
    true

/-- Composite execution safety gate combining memory topology and overflow bounds. -/
def ExecutionGate.check (s : DcaState) (limit : Nat) : Bool :=
  fitsInFrame (6 * 8) && OverflowGate.check s limit

/-- Append-only registry of DCA states for formal audit trails. -/
structure DcaRegistry where
  states : List DcaState
deriving Repr, DecidableEq

/-- Safe list index lookup. -/
def listGet? {α : Type} : List α → Nat → Option α
  | [], _ => none
  | a :: _, 0 => some a
  | _ :: as, n + 1 => listGet? as n

namespace DcaRegistry

/-- Look up a state by index. -/
def lookup (reg : DcaRegistry) (idx : Nat) : Option DcaState :=
  listGet? reg.states idx

/-- Append-only registration of a new DCA state. -/
def add (reg : DcaRegistry) (s : DcaState) : DcaRegistry :=
  { states := reg.states ++ [s] }

/-- Filter valid states in the registry. -/
def valid (reg : DcaRegistry) : List DcaState :=
  reg.states.filter (fun s => s.is_valid == true)

/-- Count of valid states. -/
def validCount (reg : DcaRegistry) : Nat :=
  (reg.valid).length

end DcaRegistry

end Foundations.DCA
