/-! # Finite Decidable Model for the Ṛta Re-Fitting Operator

This module defines a minimal, fully computable model of states, viability,
contraction, and the `Fit` operator. It is intended for use in the test harness
(`#guard`, `#eval`, SlimCheck) and does *not* depend on the full CRMF/Phase Mirror
proof stack.
-/

open List

/- -----------------------------------------------------------------
   Miniature type for prime-indexed words (MOC words).
   For the test we use a simple finite enumeration.
----------------------------------------------------------------- -/
inductive MOC_Word : Type where
  | p2  : MOC_Word
  | p3  : MOC_Word
  | p5  : MOC_Word
  | p7  : MOC_Word
deriving BEq, DecidableEq, Repr, Inhabited

/- -----------------------------------------------------------------
   A small finite state record.
   - `id`        : unique identifier for debugging
   - `primeSig`  : the prime-indexed signature (MOC word)
   - `coherence` : resonance score (normalised between 0 and 1)
   - `norm`      : operator norm (must be ≤ 1)
   - `noiseLevel` : bounded noise (set to 0 for tests)
   - `memory`    : a list of past MOC words (simplified history)
----------------------------------------------------------------- -/
structure FState where
  id         : Nat
  primeSig   : MOC_Word
  coherence  : Float       -- resonance score, 0 ≤ c ≤ 1
  norm       : Float       -- operator norm, 0 ≤ n ≤ 1
  noiseLevel : Float
  memory     : List MOC_Word
deriving Inhabited, Repr, BEq

/- -----------------------------------------------------------------
   Constants (tunable for the sandbox).
----------------------------------------------------------------- -/
def ε : Float := 0.1
def maxNoise : Float := 0.05
def R_max : Float := 1.0

/- -----------------------------------------------------------------
   Viability and contraction predicates.
----------------------------------------------------------------- -/
def viable (s : FState) : Bool :=
  s.coherence ≥ 0.5 && s.norm ≤ 1.0 - ε / 2.0

def contraction_holds (s : FState) : Bool :=
  s.norm ≤ 1.0 - ε

def satisfies_c1_c2_c3 (s : FState) : Bool :=
  viable s && contraction_holds s && s.noiseLevel ≤ maxNoise

/- -----------------------------------------------------------------
   Canonical witness and restoration (simplified).
----------------------------------------------------------------- -/
def canonical_witness (s : FState) : MOC_Word :=
  s.primeSig

def restore (w : MOC_Word) (s : FState) : FState :=
  if w == s.primeSig then
    let newCoh := min (s.coherence + 0.1) R_max
    { s with coherence := newCoh,
             norm := max (s.norm - 0.05) (1.0 - ε),
             noiseLevel := 0.0 }
  else
    s

/- -----------------------------------------------------------------
   The Fit operator – composition of canonical_witness and restore.
----------------------------------------------------------------- -/
def Fit (s : FState) : FState :=
  let w := canonical_witness s
  restore w s

/- -----------------------------------------------------------------
   FittingCheck gate (Gate 0.5).
----------------------------------------------------------------- -/
def contractionMargin (s : FState) : Float :=
  (1.0 - ε) - s.norm

def FittingCheck (current : FState) (newState : FState) : Bool :=
  let Δ_fit := newState.coherence - current.coherence + contractionMargin current
  Δ_fit ≥ 0.0

/- -----------------------------------------------------------------
   Helper to iterate Fit exactly n times.
----------------------------------------------------------------- -/
def FitIter (s : FState) : Nat → FState
  | 0     => s
  | n + 1 => FitIter (Fit s) n

/- -----------------------------------------------------------------
   Test fixtures.
----------------------------------------------------------------- -/
def lowResState : FState :=
  { id := 1,
    primeSig := MOC_Word.p2,
    coherence := 0.6,
    norm := 0.95,
    noiseLevel := 0.02,
    memory := []
  }

def mediumResState : FState :=
  { id := 2,
    primeSig := MOC_Word.p3,
    coherence := 0.85,
    norm := 0.92,
    noiseLevel := 0.01,
    memory := []
  }

def fullyFittedState : FState :=
  { id := 3,
    primeSig := MOC_Word.p5,
    coherence := 1.0,
    norm := 1.0 - ε,
    noiseLevel := 0.0,
    memory := []
  }

/- -----------------------------------------------------------------
   Computable tests (run via `#eval` or `#eval`).
----------------------------------------------------------------- -/

-- 1. Fit increases resonance on a state that is not yet fully fitted.
#eval (Fit lowResState).coherence > lowResState.coherence

-- 2. Fit is idempotent on a state that is already fully fitted.
#eval Fit fullyFittedState == fullyFittedState

-- 3. Fit reaches a fixed point within 5 iterations from a medium state.
--    Since the step is +0.1, it should hit 1.0 quickly.
#eval (FitIter mediumResState 5).coherence ≥ 0.99

-- 4. FittingCheck passes when moving from lower to higher resonance.
#eval FittingCheck lowResState (Fit lowResState)

-- 5. FittingCheck fails when the update reduces coherence without improving margin.
#eval ! (FittingCheck fullyFittedState { fullyFittedState with coherence := fullyFittedState.coherence - 0.1 })
