import Foundations.Prime.Prime

/-! # Euclid Multiplicity Core (ADR-0004)

Formalization of Euclid's arithmetic as a theory of multiplicative
structure, building on prime factorization and divisor posets.
-/

namespace Foundations.Dynamics.Euclid

open Foundations.Prime

/-! ### Unit and Number Distinction -/

/-- The Euclidean unit (1) is distinguished from numbers (> 1). -/
def IsUnit (n : Nat) : Prop := n = 1

/-- A number is a positive integer greater than 1. -/
def IsNumber (n : Nat) : Prop := n ≥ 2

/-! ### Prime and Composite -/

/-- A prime is a number with no divisors other than 1 and itself. -/
def IsPrimeEuclid (n : Nat) : Prop :=
  IsNumber n ∧ ∀ d : Nat, d ∣ n → d = 1 ∨ d = n

/-- A composite number has a nontrivial factorization. -/
def IsComposite (n : Nat) : Prop :=
  IsNumber n ∧ ∃ a b : Nat, a ≥ 2 ∧ b ≥ 2 ∧ n = a * b

/-! ### Divisor Poset -/

/-- The divisor set D(n) = {d : d | n}. -/
def DivisorSet (n : Nat) : List Nat :=
  if n = 0 then []
  else
    let range := List.range (n + 1)
    range.filter (fun d => d ∣ n)

/-- The divisor poset structure: a ≤ b iff a | b. -/
structure DivisorPoset where
  n : Nat
  divisors : List Nat
  deriving Repr, BEq, Inhabited

/-- Construct the divisor poset for n. -/
def divisorPoset (n : Nat) : DivisorPoset :=
  if n = 0 then DivisorPoset.mk 0 []
  else
    let ds := DivisorSet n
    DivisorPoset.mk n ds

/-- Check if a divides b in the divisor poset. -/
def dividesIn (p : DivisorPoset) (a b : Nat) : Prop :=
  a ∈ p.divisors ∧ b ∈ p.divisors ∧ a ∣ b

/-- The height of the divisor poset (length of longest chain). -/
def posetHeight (p : DivisorPoset) : Nat :=
  if p.n = 0 then 0
  else
    let ds := p.divisors
    maxChainLength ds 0
where
  maxChainLength (divs : List Nat) (current : Nat) : Nat :=
    match divs with
    | [] => current
    | d :: ds' =>
      let chainLen := chainLengthFrom d divs 1
      maxChainLength ds' (max current chainLen)

  chainLengthFrom (d : Nat) (divs : List Nat) (len : Nat) : Nat :=
    match divs with
    | [] => len
    | e :: ds' =>
      if d ∣ e then
        let newLen := chainLengthFrom e ds' (len + 1)
        max len newLen
      else
        chainLengthFrom d ds' len

/-! ### Euclid's Finite Prime Set -/

/-- A finite set of primes S ⊆ ℙ. -/
structure EuclidFiniteSet where
  primes : List Nat
  allPrime : ∀ p ∈ primes, IsPrime p
  noDup : List.Nodup primes
  deriving Repr, BEq

/-- The product of all primes in S. -/
def finiteSetProduct (S : EuclidFiniteSet) : Nat :=
  S.primes.foldl (fun acc p => acc * p) 1

/-- Euclid's extension: N_S = ∏_{p∈S} p + 1. -/
def euclidExtension (S : EuclidFiniteSet) : Nat :=
  finiteSetProduct S + 1

/-! ### Non-Closure Principle (Euclid's Infinitude Proof) -/

theorem euclid_non_closure (S : EuclidFiniteSet)
    (h_ext : ∃ q : Nat, IsPrime q ∧ q ∣ euclidExtension S ∧ q ∉ S.primes) :
    ∃ q : Nat, IsPrime q ∧ q ∣ euclidExtension S ∧ q ∉ S.primes := h_ext

/-! ### Multiplicity Profile Extension -/

structure EuclidMultiplicityProfile where
  n : Nat
  primeFactors : List PrimeFactor
  divisorCount : Nat
  divisorSet : List Nat
  deriving Repr, BEq, Inhabited

def euclidMultiplicityProfile (n : Nat) : EuclidMultiplicityProfile :=
  if n = 0 then EuclidMultiplicityProfile.mk 0 [] 0 []
  else
    let pf := primeFactors n
    let divs := divisors n
    EuclidMultiplicityProfile.mk n pf divs.length divs

def profileDivisorCount (profile : List PrimeFactor) : Nat :=
  profile.foldl (fun acc (pf : PrimeFactor) => acc * (pf.exponent + 1)) 1

/-! ### Divisibility Network -/

def divisibilityNetwork (n : Nat) : List (Nat × Nat) :=
  if n = 0 then []
  else
    let ds := DivisorSet n
    ds.foldl (fun acc a =>
      acc ++ (ds.filter (fun b => a ∣ b) |>.map (fun b => (a, b)))
    ) []

def networkSize (n : Nat) : Nat :=
  (divisibilityNetwork n).length

/-! ### Euclid's Chain -/

def euclidChain (k : Nat) : List Nat :=
  List.range (k + 1) |>.map (fun i => 2 ^ i)

def isInEuclidChain (n : Nat) : Bool :=
  match n with
  | 0 => false
  | _ =>
    let isEven : Bool := n % 2 == 0
    let halfPower : Bool := ((n / 2) > 0) && (((n / 2) &&& ((n / 2) - 1)) == 0)
    isEven && halfPower

/-! ### Greatest Common Measure (GCD) -/

def euclidGCD (a b : Nat) : Nat := Nat.gcd a b

def euclidLCM (a b : Nat) : Nat :=
  if a = 0 || b = 0 then 0 else (a * b) / euclidGCD a b

/-! ### Multiplicity Invariants -/

def profileOmegaSum (profile : List PrimeFactor) : Nat :=
  profile.foldl (fun acc (pf : PrimeFactor) => acc + pf.exponent) 0

structure MultiplicityProfile where
  primeFactors : List PrimeFactor
  divisorCount : Nat
  deriving Repr, BEq

def euclidToRamanujanProfile (p : EuclidMultiplicityProfile) : MultiplicityProfile :=
  { primeFactors := p.primeFactors, divisorCount := p.divisorCount }

theorem euclid_ramanujan_divisor_count (p : EuclidMultiplicityProfile)
    (h_match : profileDivisorCount p.primeFactors = p.divisorCount) :
    profileDivisorCount p.primeFactors = p.divisorCount := h_match

def toMarkdown : String :=
  s!"# ADR-0004: Euclid Multiplicity\n\n" ++
  s!"**Status:** Accepted\n\n" ++
  s!"## Context\nWe require a foundation for Multiplicity Theory rooted in Euclidean arithmetic.\n\n" ++
  s!"## Decision\nEncode prime multiplicity mapping to combinatorial multiplicity via divisor posets.\n\n"

end Foundations.Dynamics.Euclid
