// lean/Core/Multiset.lean
-- Multiplicity Theory – Core Prime‑Encoded Multisets
-- No imports from Mathlib; only core Lean definitions.

namespace Multiplicity.Core

open Nat

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

instance : DecidableEq FiniteSupport := by
  unfold FiniteSupport
  infer_instance

/-- The type of prime‑encoded multisets. -/
abbrev Multiset := FiniteSupport

/-- Empty multiset. -/
def empty : Multiset :=
  { f := fun _ => 0,
    prime_enc := by intro n h; cases h,
    bound := ⟨0, by intro n _; rfl⟩ }

/-- Singleton multiset containing one occurrence of a prime `p`. -/
def singleton (p : Nat) (hp : Prime p) : Multiset :=
  { f := fun q => if q = p then 1 else 0,
    prime_enc := by
      intro q hq
      have : q = p := by
        have : (if q = p then 1 else 0) = 1 := by
          simpa [hq] using hq
        simpa [if_pos, if_neg] using this
      subst this; exact hp,
    bound := ⟨p + 1, by intro n hn; simp [Nat.not_le_of_gt hn]⟩ }

/-- Union of two multisets corresponds to pointwise addition of exponents. -/
def union (M N : Multiset) : Multiset :=
  { f := fun p => M.f p + N.f p,
    prime_enc := by
      intro p hp
      have hM : M.f p = 0 ∨ M.f p ≠ 0 := em (M.f p = 0)
      have hN : N.f p = 0 ∨ N.f p ≠ 0 := em (N.f p = 0)
      cases hM with
      | inl hM0 =>
        have : N.f p ≠ 0 := by
          intro h0; have : M.f p + N.f p = 0 := by simpa [hM0, h0] using hp
          exact Nat.succ_ne_zero _ (by simpa using this)
        exact N.prime_enc p this
      | inr hMne0 =>
        exact M.prime_enc p hMne0,
    bound := by
      rcases M.bound with ⟨NM, hM⟩
      rcases N.bound with ⟨NN, hN⟩
      refine ⟨max NM NN, ?_⟩
      intro n hn
      have hMzero : M.f n = 0 := hM n (le_of_max_le_left hn)
      have hNzero : N.f n = 0 := hN n (le_of_max_le_right hn)
      simpa [hMzero, hNzero] }

/-- The exponent of a prime `p` in the union is the sum of exponents. -/
theorem interaction_exponent_add (M N : Multiset) (p : Nat) :
  (union M N).f p = M.f p + N.f p := rfl

end Multiplicity.Core
