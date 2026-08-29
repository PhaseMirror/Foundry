import Init

/-! # Exotic Spheres — Core Types

Formalizes foundational types for prime-indexed multiplicity invariants:
prime generation, p-adic valuation, basic matrix types over ℚ and 𝔽ₚ,
and the star-shaped plumbing graph structure.
-/

namespace ExoticSpheres.Core

open Nat

/-- Simple prime sieve up to n. -/
def sievePrimes (n : Nat) : List Nat :=
  if n < 2 then []
  else
    let candidates := List.range (n + 1)
    let isPrime (m : Nat) : Bool :=
      m >= 2 && (List.range (m/2 + 1)).all (fun d => d < 2 || d >= m || m % d != 0)
    candidates.filter isPrime

/-- p-adic valuation v_p(x) for positive integer x. -/
def padicValuationInt (p x : Nat) : Nat :=
  if x = 0 then 0
  else
    let rec count (fuel k acc : Nat) : Nat :=
      match fuel with
      | 0 => acc
      | fuel + 1 =>
        if k > x then acc
        else if x % k == 0 then count fuel (k*p) (acc + 1)
        else count fuel (k*p) acc
    count x p 0

/-- p-adic valuation for rational num/den. -/
def padicValuation (p : Nat) (num den : Nat) : Int :=
  Int.ofNat (padicValuationInt p num) - Int.ofNat (padicValuationInt p den)

/-- p-adic valuation v_p(0) = ∞ represented as 9999. -/
def padicValuationZero : Int := 9999

/-- Star-shaped plumbing graph: center vertex + legs. -/
structure StarPlumbing where
  centerWeight : Int
  legs : List (List Int)
  deriving Repr

/-- Vertex label after canonicalization (Mode A). -/
structure CanonicalPlumbing where
  vertexWeights : List Int
  adjacency : List (List Nat)
  deriving Repr

/-- Brieskorn sphere Σ(p,q,r) parameters. -/
structure BrieskornParams where
  p : Nat
  q : Nat
  r : Nat
  deriving Repr

/-- Smooth-sensitive kernel block type. -/
structure SmoothKernel where
  matrixSize : Nat
  intersectionBlock : List (List Rat)
  smoothScalar : Rat
  deriving Repr

/-- Prime-weighted multiplicity matrix. -/
structure MultiplicityMatrix where
  size : Nat
  primeLabels : List Nat
  depthLabels : List Nat
  entries : List (List Rat)
  deriving Repr

/-- Verified core properties. -/
theorem sieve_2_included : (sievePrimes 2).contains 2 := by decide
theorem sieve_3_included : (sievePrimes 3).contains 3 := by decide
theorem sieve_4_excludes : ¬(sievePrimes 4).contains 4 := by decide

theorem padic_v2_two : padicValuationInt 2 2 = 1 := by decide
theorem padic_v2_three : padicValuationInt 2 3 = 0 := by decide

end ExoticSpheres.Core
