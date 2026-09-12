import Foundations.PeanoN.Order

/-!
# PeanoN: Divisibility, Division, and Modulo

Extends the from-scratch reconstruction of `ℕ` (see `Foundations.PeanoN.Nat`
and `Foundations.PeanoN.Order`) with the supporting order / subtraction /
multiplication lemmas and then a specification of division and modulo
derived entirely from the custom `Nat` datatype. No built-in `Nat`
arithmetic and no mathlib: every theorem follows from the inductive
structure of `Nat` by induction or from the well-ordering principle.

## Contents
- `pred` (truncated predecessor) and its laws.
- Order and trichotomy lemmas.
- `sub`-cancellation laws (`sub_add`, `le_sub_eq`, `sub_add_cancel`).
- Divisibility `dvd` and its basic laws.
- A division/modulo specification `divMod_spec` proved by strong
  induction, from which `div`, `mod`, `div_mod` and `mod_lt` follow.
-/

set_option autoImplicit false
set_option relaxedAutoImplicit false

namespace Foundations.PeanoN

namespace Nat

/-! ## `pred` — truncated predecessor -/

/-- Truncated predecessor: `pred 0 = 0`, `pred (succ n) = n`. -/
def pred : Nat → Nat
  | .zero => .zero
  | .succ n => n

theorem pred_zero : pred Nat.zero = Nat.zero := rfl

theorem pred_succ (n : Nat) : pred (succ n) = n := rfl

theorem succ_pred_of_pos {a : Nat} (h : a ≠ Nat.zero) : succ (pred a) = a := by
  cases a with
  | zero => exact absurd rfl h
  | succ a => rfl

theorem pred_le (a : Nat) : Le (pred a) a := by
  cases a with
  | zero => exact le_refl Nat.zero
  | succ a => exact le_succ_self a

/-! ## Order and arithmetic support -/

/-- `a + 1 = succ a`. -/
theorem add_one (a : Nat) : add a one = succ a := by
  change add a (succ zero) = succ a
  rw [add_succ, add_zero]

/-- Multiplication is monotone on the right. -/
theorem mul_le_mul_right {a b c : Nat} (h : Le a b) : Le (mul a c) (mul b c) := by
  rcases h with ⟨k, hk⟩
  refine ⟨mul k c, ?_⟩
  calc
    add (mul a c) (mul k c) = mul (add a k) c := by rw [add_mul]
    _ = mul b c := by rw [hk]

/-- Multiplication is monotone on the left. -/
theorem mul_le_mul_left {a b c : Nat} (h : Le a b) : Le (mul c a) (mul c b) := by
  rw [mul_comm c a, mul_comm c b]
  exact mul_le_mul_right h

/-- From `¬ Le a b` obtain `Le b a` (classical totality). -/
theorem le_of_not_le {a b : Nat} (h : ¬ Le a b) : Le b a := by
  rcases le_total a b with hab | hba
  · exact absurd hab h
  · exact hba

/-- Trichotomy: exactly one of `a < b`, `a = b`, `b < a`. -/
theorem trichotomy (a b : Nat) : Lt a b ∨ a = b ∨ Lt b a := by
  cases Classical.em (Le a b) with
  | inl hab =>
      rcases le_lt_or_eq hab with heq | hlt
      · exact Or.inr (Or.inl heq)
      · exact Or.inl hlt
  | inr hnle =>
      have hba : Le b a := le_of_not_le hnle
      rcases le_lt_or_eq hba with heq | hlt
      · exfalso
        apply hnle
        rw [heq]
        exact le_refl a
      · exact Or.inr (Or.inr hlt)

/-! ## Subtraction cancellation -/

/-- `(a + b) - a = b`: subtraction cancels a preceding addend. -/
theorem sub_add (a b : Nat) : sub (add a b) a = b := by
  induction a with
  | zero =>
      rw [zero_add, sub_zero]
  | succ a ih =>
      calc
        sub (add (succ a) b) (succ a) = sub (succ (add a b)) (succ a) := by rw [succ_add]
        _ = sub (add a b) a := by rfl
        _ = b := ih

/-- If `Le b a` then `a = (a - b) + b`. -/
theorem sub_add_cancel {a b : Nat} (h : Le b a) : a = add (sub a b) b := by
  rcases h with ⟨k, hk⟩
  have hs : sub a b = k := by
    calc
      sub a b = sub (add b k) b := by rw [hk]
      _ = k := sub_add b k
  calc
    a = add b k := by rw [hk]
    _ = add k b := by rw [add_comm]
    _ = add (sub a b) b := by rw [hs]

/-- Truncated subtraction never exceeds its input: `a - b ≤ a`. -/
theorem sub_le (a : Nat) : ∀ b : Nat, Le (sub a b) a := by
  induction a with
  | zero =>
      intro b
      rw [zero_sub]
      exact le_refl Nat.zero
  | succ a ih =>
      intro b
      cases b with
      | zero =>
          rw [sub_zero]
          exact le_refl (succ a)
      | succ b' =>
          change Le (sub a b') (succ a)
          exact le_succ_of_le (ih b')

/-- If `b > 0` and `a ≥ b + 1` then `a - b < a`. -/
theorem sub_lt_of_le_succ (a b : Nat) (hb : b ≠ Nat.zero) (h : Le (succ b) a) :
    Lt (sub a b) a := by
  cases b with
  | zero => exact absurd rfl hb
  | succ c =>
      cases a with
      | zero => exact absurd h (not_succ_le_zero (succ c))
      | succ a' =>
          exact le_succ_succ (sub_le a' c)

/-! ## Divisibility -/

/-- `a ∣ b` means `∃ k, a * k = b`. -/
def dvd (a b : Nat) : Prop := ∃ k, mul a k = b

infix:50 " ∣ " => dvd

/-- `a * 1 = a`: `1` is a right multiplicative identity. -/
theorem mul_one (a : Nat) : mul a one = a := by
  rw [mul_comm, one_mul]

theorem dvd_refl (a : Nat) : dvd a a := ⟨one, by rw [mul_one]⟩

theorem dvd_trans {a b c : Nat} (hab : dvd a b) (hbc : dvd b c) : dvd a c := by
  rcases hab with ⟨k, hk⟩
  rcases hbc with ⟨l, hl⟩
  refine ⟨mul k l, ?_⟩
  calc
    mul a (mul k l) = mul (mul a k) l := by rw [mul_assoc]
    _ = mul b l := by rw [hk]
    _ = c := hl

/-! ## Division and Modulo -/

/-- Division-and-modulo specification: for `0 < b` there is a quotient
`q` and remainder `r` with `a = b * q + r` and `r < b`. -/
theorem divMod_spec (a b : Nat) (hb : b ≠ Nat.zero) :
    ∃ q r : Nat, a = add (mul b q) r ∧ Lt r b := by
  refine strong_induction (P := fun a => ∃ q r : Nat, a = add (mul b q) r ∧ Lt r b) ?_ a
  intro a ih
  rcases trichotomy a b with hlt | heq | hblt
  · -- `a < b`: quotient 0, remainder a.
    refine ⟨zero, a, ?_, hlt⟩
    rw [mul_zero, zero_add]
  · -- `a = b`: quotient 1, remainder 0.
    refine ⟨one, zero, ?_, ?_⟩
    · calc
        a = b := heq
        _ = add b zero := by rw [add_zero]
        _ = add (mul b one) zero := by rw [mul_one]
    · -- remainder `0 < b`, since `b ≠ 0`.
      have hbc : b = succ (pred b) := (succ_pred_of_pos hb).symm
      rw [hbc]
      refine ⟨pred b, ?_⟩
      calc
        add (succ zero) (pred b) = succ (add zero (pred b)) := by rw [succ_add]
        _ = succ (pred b) := by rw [zero_add]
  · -- `b < a`: recurse at `a - b`, quotient `q₀ + 1`, remainder `r₀`.
    have hle_b_a : Le b a := le_trans (le_succ_self' b) hblt
    have hac : a = add (sub a b) b := sub_add_cancel hle_b_a
    have hma : Lt (sub a b) a := sub_lt_of_le_succ a b hb hblt
    have ⟨q0, r0, hq0, hr0⟩ := ih (sub a b) hma
    refine ⟨succ q0, r0, ?_, hr0⟩
    calc
      a = add (sub a b) b := hac
      _ = add (add (mul b q0) r0) b := by rw [hq0]
      _ = add (mul b q0) (add r0 b) := by rw [add_assoc]
      _ = add (mul b q0) (add b r0) := by rw [add_comm r0 b]
      _ = add (add (mul b q0) b) r0 := by rw [add_assoc]
      _ = add (mul b (succ q0)) r0 := by rw [mul_succ]

/-- The quotient of `a` by `b` (0 when `b = 0`). -/
noncomputable def div : Nat → Nat → Nat
  | a, zero => zero
  | a, succ b' => Classical.choose
      (p := fun q => ∃ r, a = add (mul (succ b') q) r ∧ Lt r (succ b'))
      (divMod_spec a (succ b') (by intro h; cases h))

/-- The remainder of `a` by `b` (`a` when `b = 0`). -/
noncomputable def mod : Nat → Nat → Nat
  | a, zero => a
  | a, succ b' => Classical.choose
      (p := fun r => a = add (mul (succ b') (div a (succ b'))) r ∧ Lt r (succ b'))
      (Classical.choose_spec
        (p := fun q => ∃ r, a = add (mul (succ b') q) r ∧ Lt r (succ b'))
        (divMod_spec a (succ b') (by intro h; cases h)))

private theorem divMod_spec_all (a b' : Nat) :
    a = add (mul (succ b') (div a (succ b'))) (mod a (succ b')) ∧
    Lt (mod a (succ b')) (succ b') := by
  let exq : ∃ q : Nat, ∃ r : Nat, a = add (mul (succ b') q) r ∧ Lt r (succ b') :=
    divMod_spec a (succ b') (by intro h; cases h)
  have hdiv : div a (succ b') =
      Classical.choose (p := fun q => ∃ r, a = add (mul (succ b') q) r ∧ Lt r (succ b')) exq := by
    rfl
  have exr : ∃ r, a = add (mul (succ b') (div a (succ b'))) r ∧ Lt r (succ b') := by
    rw [hdiv]
    exact Classical.choose_spec (p := fun q => ∃ r, a = add (mul (succ b') q) r ∧ Lt r (succ b')) exq
  have hmod : mod a (succ b') =
      Classical.choose (p := fun r => a = add (mul (succ b') (div a (succ b'))) r ∧ Lt r (succ b')) exr := by
    rfl
  have hfull : a = add (mul (succ b') (div a (succ b')))
      (Classical.choose (p := fun r => a = add (mul (succ b') (div a (succ b'))) r ∧ Lt r (succ b')) exr) ∧
      Lt (Classical.choose (p := fun r => a = add (mul (succ b') (div a (succ b'))) r ∧ Lt r (succ b')) exr) (succ b') :=
    Classical.choose_spec (p := fun r => a = add (mul (succ b') (div a (succ b'))) r ∧ Lt r (succ b')) exr
  rw [← hmod] at hfull
  exact hfull

/-- Division algorithm: `a = (a / b) * b + a % b` for `0 < b`. -/
theorem div_mod (a b : Nat) (hb : b ≠ Nat.zero) :
    a = add (mul b (div a b)) (mod a b) := by
  cases b with
  | zero => exact absurd rfl hb
  | succ b' => exact (divMod_spec_all a b').1

/-- The remainder is bounded: `a % b < b` for `0 < b`. -/
theorem mod_lt (a b : Nat) (hb : b ≠ Nat.zero) : Lt (mod a b) b := by
  cases b with
  | zero => exact absurd rfl hb
  | succ b' => exact (divMod_spec_all a b').2

/-! ## Divisibility: basic laws -/

/-- Every number is divisible by itself. -/
theorem dvd_refl' (a : Nat) : dvd a a := dvd_refl a

/-- Anything divides a multiple of itself: `a ∣ a * b`. -/
theorem dvd_mul_right (a b : Nat) : dvd a (mul a b) := ⟨b, rfl⟩

/-- `a ∣ 0` for every `a`. -/
theorem dvd_zero (a : Nat) : dvd a Nat.zero := ⟨zero, mul_zero a⟩

/-- `1 ∣ a` for every `a`. -/
theorem one_dvd (a : Nat) : dvd one a := ⟨a, one_mul a⟩

/-- Divisibility is closed under addition of the multiples. -/
theorem dvd_add {a b c : Nat} (h1 : dvd a b) (h2 : dvd a c) : dvd a (add b c) := by
  rcases h1 with ⟨k, hk⟩
  rcases h2 with ⟨l, hl⟩
  refine ⟨add k l, ?_⟩
  calc
    mul a (add k l) = add (mul a k) (mul a l) := by rw [mul_add]
    _ = add b c := by rw [hk, hl]

end Nat

end Foundations.PeanoN
