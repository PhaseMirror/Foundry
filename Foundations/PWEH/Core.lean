/-!
# Foundations.PWEH.Core — Prime-Weighted Execution Hashing

Formalizes prime enumeration, multiplicity-weighted norm evaluation, policy manifold filters,
and trace verification theorems ensuring strict rejection of uncertified primes.
-/

namespace Foundations.PWEH

/-- Prime enumeration for PWEH execution hashing. -/
inductive Prime : Type where
  | two   : Prime
  | three : Prime
  | five  : Prime
  deriving DecidableEq, Repr

/-- Tensor state with multiplicity and depth. -/
structure TensorState where
  mult  : Nat
  depth : Nat
  deriving DecidableEq, Repr

/-- Execution hashing state: tensor, hash accumulator, and step index. -/
structure PWEHState where
  tensor : TensorState
  hash   : Nat
  step   : Nat
  deriving DecidableEq, Repr

/-- Prime integer weight. -/
def prime_weight (p : Prime) : Nat :=
  match p with
  | Prime.two   => 2
  | Prime.three => 3
  | Prime.five  => 5

/-- Prime availability filter on policy manifold. -/
def is_prime_available (s : TensorState) (p : Prime) : Bool :=
  match p with
  | Prime.two   => true
  | Prime.three => decide (s.depth ≤ 2)
  | Prime.five  => false

/-- Compute multiplicity-weighted norm. -/
def compute_norm (s : TensorState) (p : Prime) : Nat :=
  s.mult * prime_weight p

/-- Verify single PWEH execution step. -/
def verify_step (prev : PWEHState) (p : Prime) : Option PWEHState :=
  if is_prime_available prev.tensor p then
    let n := compute_norm prev.tensor p
    some {
      tensor := { prev.tensor with mult := n },
      hash   := prev.hash + n,
      step   := prev.step + 1
    }
  else
    none

/-- Verify complete trace of primes. -/
def verify_trace (initial : PWEHState) (primes : List Prime) : Bool :=
  match primes with
  | [] => true
  | p :: rest =>
    match verify_step initial p with
    | none      => false
    | some next => verify_trace next rest

/-- Allowed primes under default policy manifold. -/
def PRIMES_allowed : List Prime := [Prime.two, Prime.three]

/-- Theorem: Prime 5 is strictly blocked across all tensor states. -/
theorem prime_five_blocked (s : TensorState) :
    is_prime_available s Prime.five = false := rfl

/-- Theorem: Honest execution trace over allowed primes verifies. -/
theorem honest_trace_valid :
    verify_trace { tensor := { mult := 1, depth := 0 }, hash := 0, step := 0 } [Prime.two, Prime.three] = true := rfl

/-- Theorem: Forgery execution trace containing prime 5 is blocked. -/
theorem forgery_blocked :
    verify_trace { tensor := { mult := 1, depth := 0 }, hash := 0, step := 0 } [Prime.two, Prime.five] = false := rfl

/-- Theorem: Allowed primes sequence strictly verifies on baseline state. -/
theorem pweh_allowed_trace_verifies :
    verify_trace { tensor := { mult := 1, depth := 0 }, hash := 0, step := 0 } PRIMES_allowed = true := rfl

end Foundations.PWEH
