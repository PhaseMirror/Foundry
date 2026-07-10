// lean/Core/Matrix.lean
-- Multiplicity Theory – Core Prime‑Based Interaction Matrices
-- No imports from Mathlib; only core Lean definitions.

namespace Multiplicity.Core

open Nat
open Finset

/-! ### Matrix definition
We model a matrix of size `n` as a function `Fin n → Fin n → Nat`.
-/

def Matrix (n : Nat) : Type := Fin n → Fin n → Nat

/-- Identity matrix (1 on the diagonal, 0 elsewhere). -/
def identity (n : Nat) : Matrix n :=
  fun i j => if i = j then 1 else 0

/-- Diagonal matrix given a vector of prime entries. -/
def diag {n : Nat} (primes : Fin n → Nat) (hp : ∀ i, Prime (primes i)) : Matrix n :=
  fun i j => if i = j then primes i else 0

/-- Matrix multiplication (using natural number arithmetic). -/
def mul {n : Nat} (A B : Matrix n) : Matrix n :=
  fun i j =>
    ∑ k : Fin n, A i k * B k j

notation A " ⬝ " B => mul A B

/-- Matrix exponentiation by natural numbers. -/
def matPow {n : Nat} (M : Matrix n) : Nat → Matrix n
| 0 => identity n
| (k+1) => M ⬝ (matPow k)

/-- Helper lemma: multiplication of two diagonal matrices yields a diagonal matrix whose
    entries are pointwise products. -/
theorem mul_diag_diag {n : Nat} (a b : Fin n → Nat)
    (ha : ∀ i, Prime (a i)) (hb : ∀ i, Prime (b i)) :
    (diag a ha) ⬝ (diag b hb) =
      diag (fun i => a i * b i) (by
        intro i; exact (Nat.prime_mul (ha i) (hb i))) := by
  funext i j
  have hsum : (∑ k : Fin n, (if i = k then a i else 0) * (if k = j then b k else 0)) =
      (if i = j then a i * b i else 0) := by
    classical
    by_cases hij : i = j
    · subst hij
      -- only k = i contributes
      have : (∑ k : Fin n, (if i = k then a i else 0) * (if k = i then b k else 0)) =
          a i * b i := by
        have hsingle : (∑ k : Fin n,
            (if i = k then a i else 0) * (if k = i then b k else 0)) =
            (if i = i then a i else 0) * (if i = i then b i else 0) := by
          -- sum over Fin n where only k = i is non‑zero
          apply sum_eq_single i
          · intro x hx hxne
            simp [hxne] at *
          · intro hx
            simp [hx]
        simpa using hsingle
      simpa [hij] using this
    · have hne : i ≠ j := hij
      -- for any k, either i ≠ k or k ≠ j, making a factor zero
      have : (∑ k : Fin n,
            (if i = k then a i else 0) * (if k = j then b k else 0)) = 0 := by
        apply sum_eq_zero_iff_of_forall
        intro k hk
        have : (if i = k then a i else 0) = 0 ∨ (if k = j then b k else 0) = 0 := by
          by_cases hik : i = k
          · left; simp [hik]
          · right; by_cases kj : k = j
            · have : i = j := by simpa [hik] using kj.symm
              exact (hne this).elim
            · right; simp [kj]
        cases this with
        | inl hzero => simp [hzero]
        | inr hzero => simp [hzero]
      simpa [hne] using this
    
  simp [diag, mul, hsum]

/-- Power of a diagonal matrix: each diagonal entry is raised to the exponent. -/
theorem diag_pow {n : Nat} (primes : Fin n → Nat) (hp : ∀ i, Prime (primes i)) (k : Nat) :
    matPow (diag primes hp) k =
      diag (fun i => (primes i) ^ k) (by
        intro i; exact (Nat.prime_pow (hp i) k)) := by
  induction k with
  | zero =>
    funext i j
    simp [matPow, identity, diag]
  | succ k ih =>
    have : matPow (diag primes hp) (k+1) = (diag primes hp) ⬝ matPow (diag primes hp) k := rfl
    simp [matPow, this, ih, mul_diag_diag] 
    -- after rewriting, both sides are diagonal with entry (primes i) * (primes i)^k = (primes i)^(k+1)
    funext i j
    by_cases h : i = j
    · subst h
      simp [diag, Nat.pow_succ]
    · simp [diag, h]

end Multiplicity.Core
