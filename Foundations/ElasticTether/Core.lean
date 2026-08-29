/-!
# Foundations.ElasticTether.Core — Elastic Tether Potential & Discrete Stability
-/

namespace Foundations.ElasticTether
open Std

structure TetherState where
  length   : Nat
  restLen  : Nat
  kSpring  : Nat
  damping  : Nat
  deriving Repr, DecidableEq

deriving instance Repr for ByteArray

def tension (s : TetherState) : Nat :=
  if s.length ≥ s.restLen then
    s.kSpring * (s.length - s.restLen)
  else
    0

def potentialEnergy (s : TetherState) : Nat :=
  if s.length ≥ s.restLen then
    let delta := s.length - s.restLen
    (s.kSpring * delta * delta) / 2
  else
    0

theorem tension_zero_at_rest (s : TetherState) (h : s.length ≤ s.restLen) :
    tension s = 0 := by
  unfold tension
  by_cases heq : s.length = s.restLen
  · subst heq
    simp
  · have hlt : s.length < s.restLen := Nat.lt_of_le_of_ne h heq
    have : ¬ (s.length ≥ s.restLen) := by
      have : ¬ (s.restLen ≤ s.length) := Nat.not_le.mpr hlt
      simpa [Nat.ge_iff_le] using this
    simp [this]

end Foundations.ElasticTether
