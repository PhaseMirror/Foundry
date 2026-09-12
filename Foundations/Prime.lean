/-!
# Multiplicity Prime Number Infrastructure

Shared prime number definitions and predicates used across all ADR
formalizations. This module provides computable, axiom-clean definitions
for primality testing, factorization, and divisor structures.

## Modules that import this

- `Multiplicity.dynamics.Euclid`
- `Multiplicity.dynamics.Gauss`
- `Multiplicity.dynamics.Dirichlet`
- `Multiplicity.dynamics.Riemann`
- `Multiplicity.dynamics.Kummer`
- `Multiplicity.dynamics.HardyLittlewood`
- `Multiplicity.dynamics.Selberg`
- `Multiplicity.dynamics.Erdos`
- `Multiplicity.dynamics.Serre`
- `Multiplicity.dynamics.Grothendieck`
- `Multiplicity.dynamics.Hund`
- `Multiplicity.dynamics.Dedekind`
- `Multiplicity.dynamics.Ramanujan`
- `Multiplicity.dynamics.TerenceTao`
- `Multiplicity.dynamics.Quantum`

## Design Notes

All definitions are computable and axiom-clean. For performance on large
numbers, bounded versions (up to a given limit) are provided. The full
prime factorization uses trial division; for production use with large
numbers, replace with a more efficient algorithm.
-/

namespace Multiplicity.Prime

def List.bind {α β : Type u} (l : List α) (f : α → List β) : List β :=
  l.foldr (fun a acc => f a ++ acc) []

def List.eraseDuplicates [BEq α] : List α → List α
  | [] => []
  | a::as => a :: ((List.eraseDuplicates as).filter (fun x => !(x == a)))


/-! ### Basic Prime Predicates -/

/-- A prime number: greater than 1 with no divisors other than 1 and itself. -/
def IsPrime (n : Nat) : Bool :=
  if n < 2 then false
  else (List.range n).all (fun d => if d < 2 then true else n % d ≠ 0)

/-- A composite number: greater than 1 with a nontrivial factorization. -/
def IsComposite (n : Nat) : Bool :=
  n > 1 ∧ (List.range n).any (fun d => d > 1 ∧ d < n ∧ n % d = 0)

/-- A squarefree number: not divisible by any perfect square > 1. -/
def IsSquarefree (n : Nat) : Bool :=
  n = 0 ∨ n = 1 ∨ (List.range (n + 1)).all (fun d => if d < 2 then true else if d * d > n then true else n % (d * d) ≠ 0)

/-! ### Prime Factors -/

/-- A prime factor and its multiplicity exponent. -/
structure PrimeFactor where
  prime : Nat
  exponent : Nat
    deriving Repr, BEq, Inhabited

/-- Compute the prime factorization of n using trial division.
    Returns a list of (prime, exponent) pairs. -/
def primeFactors (n : Nat) : List PrimeFactor :=
  if n < 2 then []
  else
    let rec count (p m acc fuel : Nat) : Nat :=
      match fuel with
      | 0 => acc
      | f + 1 =>
        if m % p = 0 then count p (m / p) (acc + 1) f else acc
    let rec factorize (m p fuel : Nat) (acc : List PrimeFactor) : List PrimeFactor :=
      match fuel with
      | 0 => acc
      | f + 1 =>
        if m = 1 then acc
        else if p * p > m then
          if m > 1 then acc ++ [PrimeFactor.mk m 1 ] else acc
        else if m % p = 0 then
          let exp := count p m 0 (m + 10)
          factorize (m / (p ^ exp)) (p + 1) f (acc ++ [PrimeFactor.mk p exp ])
        else
          factorize m (p + 1) f acc
    factorize n 2 (n + 10) []

/-- The number of distinct prime factors ω(n). -/
def omega (n : Nat) : Nat :=
  (primeFactors n).length

/-- The total number of prime factors counted with multiplicity Ω(n). -/
def Omega (n : Nat) : Nat :=
  (primeFactors n).foldl (fun acc pf => acc + pf.exponent) 0

/-- The divisor count τ(n) = ∏ (e_i + 1). -/
def divisorCount (n : Nat) : Nat :=
  (primeFactors n).foldl (fun acc pf => acc * (pf.exponent + 1)) 1

/-- The sum of divisors σ(n). -/
def divisorSum (n : Nat) : Nat :=
  (primeFactors n).foldl (fun acc pf => acc * ((pf.prime ^ (pf.exponent + 1) - 1) / (pf.prime - 1))) 1

/-! ### Divisor Structures -/

/-- The set of divisors of n. -/
def divisors (n : Nat) : List Nat :=
  if n = 0 then []
  else
    let pf := primeFactors n
    let rec expand (factors : List PrimeFactor) : List Nat :=
      match factors with
      | [] => [1]
      | pf :: pfs =>
        let rest := expand pfs
        let multiples := (List.range (pf.exponent + 1)).map (fun e => pf.prime ^ e)
        List.bind rest (fun r => multiples.map (fun m => r * m))
    List.eraseDuplicates (expand pf)

/-- The divisor poset structure for n. -/
structure DivisorPoset where
  n : Nat
  divisors : List Nat
  deriving Repr, BEq, Inhabited, Inhabited

/-- Construct the divisor poset for n. -/
def divisorPoset (n : Nat) : DivisorPoset :=
  DivisorPoset.mk n (divisors n)

/-! ### Arithmetic Functions -/

/-- The Möbius function μ(n).
    μ(1) = 1, μ(n) = (-1)^k if n is squarefree with k prime factors, 0 otherwise. -/
def mobius (n : Nat) : Int :=
  if n = 0 then 0
  else if n = 1 then 1
  else if !IsSquarefree n then 0
  else
    let pf := primeFactors n
    if pf.length % 2 = 0 then 1 else -1

/-- The von Mangoldt function Λ(n).
    Λ(n) = log p if n = p^k, else 0. -/
def vonMangoldt (n : Nat) : Float :=
  if n = 1 then 0.0
  else
    let pf := primeFactors n
    if pf.length = 1 ∧ pf.head!.exponent > 0 then
      Float.log (Float.ofNat pf.head!.prime)
    else 0.0

/-- The Liouville function λ(n) = (-1)^Ω(n). -/
def liouville (n : Nat) : Int :=
  if n = 0 then 0
  else if Omega n % 2 = 0 then 1 else -1

/-! ### Totient and Carmichael -/

/-- Euler's totient function φ(n): count of integers 1 ≤ k ≤ n coprime to n. -/
def eulerTotient (n : Nat) : Nat :=
  if n = 0 then 0
  else (List.range (n + 1)).foldl (fun acc k => if Nat.gcd k n = 1 then acc + 1 else acc) 0

/-! ### Prime Generation -/

/-- Generate the first n primes. -/
def firstNPrimes (n : Nat) : List Nat :=
  let rec generate (count : Nat) (found : List Nat) (current fuel : Nat) : List Nat :=
    match fuel with
    | 0 => found.reverse
    | f + 1 =>
      if count = n then found.reverse
    else if IsPrime current then
      generate (count + 1) (current :: found) (current + 1) f
    else
      generate count found (current + 1) f
  generate 0 [] 2 (n * n * 2 + 10)

/-- The nth prime number (1-indexed). -/
def nthPrime (n : Nat) : Nat :=
  (firstNPrimes n).getLast! 

/-! ### Theorems -/

/-- 2 is prime. -/
theorem two_prime : IsPrime 2 := by decide

/-- 3 is prime. -/
theorem three_prime : IsPrime 3 := by decide

/-- 4 is composite. -/
theorem four_composite : IsComposite 4 := by decide

/-- The prime factorization of 12. -/
theorem primeFactors_12 : primeFactors 12 = [PrimeFactor.mk 2 2 , PrimeFactor.mk 3 1 ] := by
  rfl

/-- The divisor count of 12 is 6. -/
theorem divisorCount_12 : divisorCount 12 = 6 := by decide

/-- The Möbius function of 6. -/
theorem mobius_6 : mobius 6 = 1 := by decide

/-- The Liouville function of 6. -/
theorem liouville_6 : liouville 6 = 1 := by decide

/-- Euler's totient of 6. -/
theorem totient_6 : eulerTotient 6 = 2 := by decide

end Multiplicity.Prime
