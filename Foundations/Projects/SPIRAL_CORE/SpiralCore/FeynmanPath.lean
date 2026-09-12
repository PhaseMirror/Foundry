import Init
import SpiralCore.Core

namespace SpiralCore.FeynmanPath

def unitAmplitude : Nat := 1000

structure Path where
  index : Nat
  action : Int
  phase : Int
deriving Repr

def phaseOfAction (action : Int) : Int := action

def canonicalPath (i : Nat) : Path :=
  { index := i, action := Int.ofNat i, phase := phaseOfAction (Int.ofNat i) }

theorem phase_equals_phase_of_action (i : Nat) :
  (canonicalPath i).phase = phaseOfAction (canonicalPath i).action := by
  dsimp [canonicalPath, phaseOfAction]

def pathAmplitudeMagnitude (_ : Path) : Nat := unitAmplitude

theorem equal_strength_all_paths (p : Path) :
  pathAmplitudeMagnitude p = unitAmplitude := rfl

def totalAmplitude (pathCount : Nat) : Nat := pathCount * unitAmplitude

theorem total_amplitude_composition (n : Nat) :
  totalAmplitude n = n * unitAmplitude := rfl

def fidelityTolerance : Nat := 500000

def gateClosed (pathCount referenceAmplitude fidelityTolerance : Nat) : Bool :=
  let total := totalAmplitude pathCount
  ! (referenceAmplitude + fidelityTolerance < total || total + fidelityTolerance < referenceAmplitude)

theorem gate_accepts_exact_reference (pathCount tol : Nat) :
    gateClosed pathCount (totalAmplitude pathCount) tol = true := by
  dsimp [gateClosed, totalAmplitude, unitAmplitude]
  have h1 : ¬ (pathCount * 1000 + tol < pathCount * 1000) := by omega
  by_cases h : pathCount * 1000 + tol < pathCount * 1000
  · exfalso; exact h1 h
  · simp [h]

end SpiralCore.FeynmanPath