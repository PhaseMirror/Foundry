/-!
# EchoBraid.Core

Core types and discrete representations for the Echo Braid formalism:
- Prime-indexed tint-bundle representations
- Discrete phase angles and harmonic eigenmemory
- Fixed-point arithmetic constants (denominator = 100)
- Metric norm definitions for braid state spaces
-/

namespace EchoBraid

/-- Fixed-point denominator: 100 represents 1.00 -/
def FP_DEN : Nat := 100

/-- Fixed-point multiplication: (a * b) / 100 -/
def fpMul (a b : Nat) : Nat :=
  (a * b) / FP_DEN

/-- Fixed-point scaling by fraction num/den -/
def fpScale (x num den : Nat) : Nat :=
  if den == 0 then 0 else (x * num) / den

/-- Maximum phase in degrees for modular arithmetic -/
def MAX_PHASE_DEG : Nat := 360

/-- Normalize phase angle to [0, 360) -/
def normPhase (deg : Nat) : Nat :=
  deg % MAX_PHASE_DEG

/--
TintBundle: Represents a perceptual / sensory resonance channel.
- `tintId`: Unique channel index
- `phaseDeg`: Current phase angle in degrees [0, 360)
- `intensity`: Normalized energy intensity (0 to 100)
-/
structure TintBundle where
  tintId    : Nat
  phaseDeg  : Nat
  intensity : Nat
  deriving Repr, DecidableEq, Inhabited

/--
EigenMemory: Represents historical phase traceability and emotional/cognitive eigenstate.
- `traceId`: Provenance identifier
- `amplitude`: Harmonic amplitude (fixed-point, 0 to 100)
- `phase`: Associated harmonic phase angle [0, 360)
-/
structure EigenMemory where
  traceId   : Nat
  amplitude : Nat
  phase     : Nat
  deriving Repr, DecidableEq, Inhabited

/--
Strand: A single prime-indexed trajectory in the Echo Braid.
- `prime`: The prime factor indexing this strand (e.g. 2, 3, 5, 7, 11)
- `tint`: Associated perceptual tint-bundle
- `eigen`: Historical eigenmemory trace
- `position`: Permutation position in the braid bundle (0-indexed)
-/
structure Strand where
  prime    : Nat
  tint     : TintBundle
  eigen    : EigenMemory
  position : Nat
  deriving Repr, DecidableEq, Inhabited

/--
EchoBraidState: Complete state of an N-strand Echo Braid at time step `t`.
- `time`: Discrete time index
- `strands`: Ordered list of active strands
- `lambdaM`: Adaptive multiplicity scaling factor (fixed point, e.g. 60 = 0.60)
- `spectralCoherence`: Coherence metric (0 to 100)
-/
structure EchoBraidState where
  time              : Nat
  strands           : List Strand
  lambdaM           : Nat
  spectralCoherence : Nat
  deriving Repr, DecidableEq, Inhabited

/-- Energy of a single strand: intensity * amplitude / 100 -/
def strandEnergy (s : Strand) : Nat :=
  fpMul s.tint.intensity s.eigen.amplitude

/-- Total energy of an Echo Braid state -/
def totalEnergy (st : EchoBraidState) : Nat :=
  st.strands.foldl (fun acc s => acc + strandEnergy s) 0

/-- Discrete distance between two strands on the same prime -/
def strandDist (s1 s2 : Strand) : Nat :=
  let dInt := if s1.tint.intensity >= s2.tint.intensity
              then s1.tint.intensity - s2.tint.intensity
              else s2.tint.intensity - s1.tint.intensity
  let dAmp := if s1.eigen.amplitude >= s2.eigen.amplitude
              then s1.eigen.amplitude - s2.eigen.amplitude
              else s2.eigen.amplitude - s1.eigen.amplitude
  dInt + dAmp

/-- Discrete sup-norm over list of strands -/
def strandListSupNorm (l1 l2 : List Strand) : Nat :=
  match l1, l2 with
  | [], _ => 0
  | _, [] => 0
  | s1 :: rest1, s2 :: rest2 =>
    let d := strandDist s1 s2
    let dRest := strandListSupNorm rest1 rest2
    if d >= dRest then d else dRest

/-- Discrete sup-norm between two Echo Braid states with identical strand counts -/
def supNorm (st1 st2 : EchoBraidState) : Nat :=
  strandListSupNorm st1.strands st2.strands

end EchoBraid
