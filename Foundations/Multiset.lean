-- lean/Core/Multiset.lean
-- Multiplicity Theory – Core Prime‑Encoded Multisets
-- No imports from Mathlib; only core Lean definitions.

namespace Multiplicity.Core

def Prime (p : Nat) : Prop := 2 ≤ p ∧ ∀ m, m ∣ p → m = 1 ∨ m = p

/-! ### Prime‑encoded multiset definition
We represent a multiset as a function `f : Nat → Nat` that is non‑zero only on primes
and is zero for all but finitely many naturals. -/

/-- `is_prime_encoding f` states that any index with a non‑zero value is a prime. -/
def is_prime_encoding (f : Nat → Nat) : Prop :=
  ∀ n, f n ≠ 0 → Prime n

/-- `FiniteSupport f` asserts that `f` is zero beyond some bound `N`. -/
structure FiniteSupport where
  f : Nat → Nat
  prime_enc : is_prime_encoding f
  bound : ∃ N, ∀ n ≥ N, f n = 0

/-- The type of prime‑encoded multisets. -/
abbrev Multiset := FiniteSupport

/-- Empty multiset. -/
def empty : Multiset :=
  { f := fun _ => 0,
    prime_enc := by intro n h; contradiction,
    bound := ⟨0, by intro n _; rfl⟩ }

/-- Singleton multiset containing one occurrence of a prime `p`. -/
def singleton (p : Nat) (hp : Prime p) : Multiset :=
  { f := fun q => if q = p then 1 else 0,
    prime_enc := by
      intro q hq
      dsimp at hq
      split at hq
      · next heq =>
        subst heq
        exact hp
      · contradiction,
    bound := ⟨p + 1, by
      intro n hn
      by_cases hne : n = p
      · have hp_absurd : p ≥ p + 1 := by rw [hne] at hn; exact hn
        have h_absurd : p < p := Nat.lt_of_lt_of_le (Nat.lt_succ_self p) hp_absurd
        exact False.elim (Nat.lt_irrefl p h_absurd)
      · have : (if n = p then 1 else 0) = 0 := if_neg hne
        exact this⟩ }

/-- Union of two multisets corresponds to pointwise addition of exponents. -/
def union (M N : Multiset) : Multiset :=
  { f := fun p => M.f p + N.f p,
    prime_enc := by
      intro p hp
      dsimp at hp
      by_cases h : M.f p = 0
      · have hn_nz : N.f p ≠ 0 := by
          intro hN
          rw [h, hN] at hp
          contradiction
        exact N.prime_enc p hn_nz
      · exact M.prime_enc p h,
    bound := by
      rcases M.bound with ⟨NM, hM⟩
      rcases N.bound with ⟨NN, hN⟩
      refine ⟨max NM NN, ?_⟩
      intro n hn
      have hMzero : M.f n = 0 := hM n (Nat.le_trans (Nat.le_max_left _ _) hn)
      have hNzero : N.f n = 0 := hN n (Nat.le_trans (Nat.le_max_right _ _) hn)
      have hSum : M.f n + N.f n = 0 := by rw [hMzero, hNzero]
      exact hSum }

/-- The exponent of a prime `p` in the union is the sum of exponents. -/
theorem interaction_exponent_add (M N : Multiset) (p : Nat) :
  (union M N).f p = M.f p + N.f p := rfl

end Multiplicity.Core
