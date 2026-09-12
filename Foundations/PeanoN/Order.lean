import Foundations.PeanoN.Nat

/-!
# PeanoN: Well-Ordering and Subtraction

Continues the custom reconstruction of `ℕ` from Peano's axioms. Everything
here is proved from `Foundations.PeanoN.Nat` by explicit induction — no
built-in `Nat` library and no mathlib.

## Contents
- Subtraction and its basic laws.
- The successor-lemma family needed to split `m ≤ succ k`.
- Strong induction and the well-ordering principle (a least element for
  every nonempty subset).

## Naming convention
While the existing `Foundations` tree shadows built-in `Nat` with proofs
that cite the standard library, this hierarchy builds everything from the
inductive type and derives results ourselves. Unqualified constructors
(`zero`, `succ`) and the arithmetic names (`add`, `Le`, ...) are used
freely inside the nested `namespace Nat`, matching `Nat.lean`.
-/

set_option autoImplicit false
set_option relaxedAutoImplicit false

namespace Foundations.PeanoN

namespace Nat

/-! ## Subtraction -/

/-- Truncated subtraction: `a -* b` is `a - b` clamped at `zero`. -/
def sub : Nat → Nat → Nat
  | .zero, _ => .zero
  | .succ a, .zero => .succ a
  | .succ a, .succ b => sub a b

/-- `a -* zero = a`. -/
theorem sub_zero (a : Nat) : sub a Nat.zero = a := by
  cases a with
  | zero => rfl
  | succ a => rfl

/-- `zero -* a = zero`. -/
theorem zero_sub (a : Nat) : sub Nat.zero a = Nat.zero := by
  cases a with
  | zero => rfl
  | succ a => rfl

/-- `a -* a = zero`. -/
theorem sub_self (a : Nat) : sub a a = Nat.zero := by
  induction a with
  | zero => rfl
  | succ a ih => exact ih

/-! ## Successor and order splitting -/

/-- `m ≤ succ m`. -/
theorem le_succ_self (m : Nat) : Le m (succ m) := le_succ_of_le (le_refl m)

/-- From `Le m (succ k)` recover either `Le m k` or `m = succ k`. -/
theorem le_succ_iff {m k : Nat} (h : Le m (succ k)) : Le m k ∨ m = succ k := by
  rcases h with ⟨w, hw⟩
  cases w with
  | zero =>
      right
      exact (by simpa [add] using hw)
  | succ w' =>
      left
      have h2 : succ (add m w') = succ k := by
        rw [add_succ] at hw
        exact hw
      have h3 : add m w' = k := succ_inj h2
      exact ⟨w', h3⟩

/-- From `Le (succ l) (succ k)` recover `Le l k`. -/
theorem le_of_le_succ {l k : Nat} (h : Le (succ l) (succ k)) : Le l k := by
  rcases h with ⟨w, hw⟩
  cases w with
  | zero =>
      have h2 : succ l = succ k := by simpa [add] using hw
      have h3 : l = k := succ_inj h2
      exact ⟨Nat.zero, by simpa [add] using h3⟩
  | succ w' =>
      have h2 : succ (add (succ l) w') = succ k := by
        rw [add_succ] at hw
        exact hw
      have h3 : add (succ l) w' = k := succ_inj h2
      have h4 : succ (add l w') = k := by
        rw [succ_add] at h3
        exact h3
      refine ⟨succ w', ?_⟩
      exact (add_succ l w').trans h4

/-- `Le m n` gives either `m = n` or `Lt m n`. -/
theorem le_lt_or_eq {m n : Nat} (h : Le m n) : m = n ∨ Lt m n := by
  rcases h with ⟨w, hw⟩
  cases w with
  | zero =>
      left
      exact (by simpa [add] using hw)
  | succ w' =>
      right
      have h2 : succ (add m w') = n := by
        rw [add_succ] at hw
        exact hw
      refine ⟨w', ?_⟩
      rw [succ_add]
      exact h2

/-! ## Strong induction and well-ordering -/

/-- `m ≤ Nat.succ m`. -/
theorem le_succ_self' (m : Nat) : Le m (Nat.succ m) := le_succ_of_le (le_refl m)

/-- Strong induction: if `P n` follows from `P` at all smaller elements,
then `P` holds everywhere. -/
theorem strong_induction {P : Nat → Prop}
    (step : ∀ n, (∀ m, Lt m n → P m) → P n) : ∀ n, P n := by
  intro n
  -- Prove the stronger statement `∀ k, ∀ m ≤ k, P m` by induction on `k`.
  have h : ∀ k, ∀ m, Le m k → P m := by
    intro k
    induction k with
    | zero =>
        intro m hm
        have hmz : m = Nat.zero := le_zero hm
        subst m
        apply step Nat.zero
        intro l hlt
        exact absurd hlt (not_succ_le_zero l)
    | succ k ih =>
        intro m hm
        rcases le_succ_iff hm with h1 | h2
        · apply step m
          intro l hlt
          have hslk : Le (succ l) k := le_trans hlt h1
          have hlk : Le l k := le_trans (le_succ_self' l) hslk
          exact ih l hlk
        · subst h2
          apply step (succ k)
          intro l hlt
          have hlk : Le l k := le_of_le_succ hlt
          exact ih l hlk
  exact h n n (le_refl n)

/-- Well-ordering principle: if some `n` satisfies `P`, there is a least
element `m` satisfying `P`. -/
theorem well_ordering {P : Nat → Prop} (hex : ∃ n, P n) :
    ∃ m, P m ∧ ∀ n, P n → Le m n := by
  -- It suffices to show that every `P`-element has a least `P`-element at
  -- or below it, then apply to the witness provided by `hex`.
  have every : ∀ n : Nat, P n → (∃ m, P m ∧ ∀ k, P k → Le m k) := by
    refine strong_induction ?_
    intro n ih Pn
    -- Either `n` is already least among the `P`-elements, or some smaller
    -- element satisfies `P` and we can recurse.
    cases Classical.em (∀ k, P k → Le n k) with
    | inl hmin => exact ⟨n, Pn, hmin⟩
    | inr hnotmin =>
        have hEx : ∃ k, P k ∧ ¬ Le n k := by
          rcases Classical.not_forall.mp hnotmin with ⟨k, hnk⟩
          exact ⟨k, Classical.not_imp.mp hnk⟩
        rcases hEx with ⟨k, hPk, hnle⟩
        have hkn : Le k n := by
          rcases le_total n k with hnk | hkn
          · exact absurd hnk hnle
          · exact hkn
        have hlt : Lt k n := by
          rcases le_lt_or_eq hkn with hkeq | hlt
          · exfalso
            apply hnle
            subst hkeq
            exact le_refl k
          · exact hlt
        exact ih k hlt hPk
  rcases hex with ⟨n0, Pn0⟩
  exact every n0 Pn0

end Nat

end Foundations.PeanoN
