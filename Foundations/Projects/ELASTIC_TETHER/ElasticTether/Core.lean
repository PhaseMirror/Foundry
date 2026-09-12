import Init

/-! # Elastic Tether — Core Types

Formalizes the foundational types for the Physics-Based Elastic Tether Protocol:
prime-encoded state spaces, CMT navigation, bifurcated Head/Tail agents,
tether lag, and safety parameters.
-/

namespace ElasticTether.Core

open Nat

/-- Toolbelt primes for CMT factorization. -/
def toolbeltPrimes : List Nat := [2, 3, 5]

/-- Check if a number is accessible via CMT (has toolbelt prime factor). -/
def isAccessible (n : Nat) : Bool :=
  toolbeltPrimes.any (fun p => n % p == 0)

/-- Trial division primality test. -/
def isPrime (n : Nat) : Bool :=
  n >= 2 ∧ (n == 2 ∨ (n % 2 == 1 ∧ (List.range (n / 2 + 1)).all (fun d => d < 2 ∨ d >= n ∨ n % d != 0)))

/-- Prime-counting function π(n). -/
def pi (n : Nat) : Nat :=
  (List.range (n + 1)).filter isPrime |> fun lst => lst.length

/-- Compute accessible states up to N. -/
def accessibleStates (N : Nat) : List Nat :=
  (List.range (N + 1)).filter isAccessible

/-- Prime density at N. -/
def primeDensity (N : Nat) : Float :=
  if N = 0 then 0.0 else (pi N).toFloat / N.toFloat

/-- CMT resistance of a state. -/
def cmtResistance (n : Nat) : Float :=
  if isAccessible n then 1.0 else 100.0

/-- CMT distance of a path. -/
def cmtDistance (path : List Nat) : Float :=
  path.foldl (fun acc c => acc + cmtResistance c) 0.0

/-- Verified set S_verified(t). -/
structure VerifiedSet where
  maxPrime : Nat
  computed : List Nat
  deriving Repr

/-- Lag L(t) = x_head - x_tail. -/
structure Lag where
  headPos : Nat
  tailPos : Nat
  deriving Repr

def lagValue (l : Lag) : Nat := l.headPos - l.tailPos

/-- Safety parameters. -/
structure SafetyParams where
  costInterrogate : Nat
  vMax : Nat
  vMin : Nat
  deriving Repr

/-- Derived safe lead distance Δ_safe = Cost_interrogate / v_max. -/
def deltaSafe (params : SafetyParams) : Nat :=
  params.costInterrogate / params.vMax

/-- Head velocity law. -/
def headVelocity (headPos tailPos : Nat) (params : SafetyParams) (muBar : Float) : Nat :=
  let L := headPos - tailPos
  let delta := deltaSafe params
  if L > delta then
    params.vMin
  else
    let bonus := (params.vMax - params.vMin).toFloat * muBar
    params.vMin + bonus.floor.toUInt64.toNat

/-- Verified core properties. -/
theorem accessible_2 : isAccessible 2 = true := rfl
theorem accessible_4 : isAccessible 4 = true := rfl
theorem not_accessible_7 : isAccessible 7 = false := rfl
theorem lag_value_nonnegative (l : Lag) : lagValue l >= 0 := Nat.zero_le _

end ElasticTether.Core
