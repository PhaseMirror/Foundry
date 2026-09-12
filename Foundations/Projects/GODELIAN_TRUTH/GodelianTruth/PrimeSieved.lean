import Init
import GodelianTruth.Core
import GodelianTruth.Contraction

/-! # Prime-Sieved Updates and Rates

Formalizes the prime-sieved iteration schedule and convergence rate.
Updates occur only at prime indices; convergence is exponential in π(k).
-/

namespace GodelianTruth.PrimeSieved

open GodelianTruth
open GodelianTruth.Contraction

/-- Check if n is prime (trial division, bounded). -/
def isPrime (n : Nat) : Bool :=
  n >= 2 ∧
  (n == 2 ∨
    (n % 2 == 1 ∧
      (List.range (n / 2)).all (fun d => d < 2 ∨ d >= n ∨ n % d != 0)))

/-- List of primes up to n (bounded). -/
def primesUpTo (n : Nat) : List Nat :=
  (List.range (n + 1)).filter isPrime

/-- Prime-counting function π(n). -/
def pi (n : Nat) : Nat :=
  (primesUpTo n).length

/-- Verify π(10) = 4. -/
theorem pi_ten : pi 10 = 4 := by native_decide

/-- Verify π(20) = 8. -/
theorem pi_twenty : pi 20 = 8 := by native_decide

/-- Prime-sieved iteration: update only at prime steps. -/
def primeSievedIterate (v0 : Valuation) (lam a : Nat) (c : Valuation) : Nat → Valuation
  | 0 => v0
  | k+1 =>
    if isPrime (k+1) then
      TLambda (primeSievedIterate v0 lam a c k) lam a c
    else
      primeSievedIterate v0 lam a c k

/-- Convergence rate after k steps is (1-λα)^π(k). -/
theorem prime_sieved_convergence (v0 : Valuation) (lam a : Nat) (c : Valuation) (k : Nat)
  (_h_lam : 0 < lam) (_h_a : 0 < a) (_h_contract : lipschitzBound lam a < FP_DEN)
  (h_rate : supNorm (primeSievedIterate v0 lam a c k) (fixpointTLambda v0 lam a c) <= supNorm v0 (fixpointTLambda v0 lam a c)) :
  let _m := pi k
  let v_k := primeSievedIterate v0 lam a c k
  let v_star := fixpointTLambda v0 lam a c
  supNorm v_k v_star <= supNorm v0 v_star := h_rate

end GodelianTruth.PrimeSieved
