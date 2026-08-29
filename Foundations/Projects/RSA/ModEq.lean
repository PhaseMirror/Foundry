/-!
# Modular equivalence over `Nat`

A minimal, axiom-free toolkit of modular congruence facts used by the RSA
formalization. Following the project design contract, we deliberately avoid
Mathlib: `ModEq a b n` is simply `a % n = b % n`, and every lemma is proved
from the `Nat` remainder identities available in the core Lean library.

Notation: `a ≡ b [MOD n]`.

## Design notes

* The predicate is the *reflexive* `Prop` `a % n = b % n` (not a quotient).
* Congruence of `+`, `*`, `^` is established in the obvious way via the
  corresponding `Nat.*_mod` lemmas.
* The final lemmas reduce `a ≡ b [MOD n]` to a divisibility statement in the
  form `n ∣ a - b` or `n ∣ b - a`; these are the stepping stones used by the
  CRT lemma and by the RSA correctness proof.
-/

namespace Multiplicity.RSA

/-- `a` is congruent to `b` modulo `n`, i.e. `a % n = b % n`. -/
def ModEq (a b n : Nat) : Prop := a % n = b % n

notation:50 a " ≡ " b " [MOD " n "]" => ModEq a b n

theorem modEq_iff (a b n : Nat) : a ≡ b [MOD n] ↔ a % n = b % n := Iff.rfl

theorem modEq_refl (a n : Nat) : a ≡ a [MOD n] := rfl

/-- An exact equality is a congruence. -/
theorem modEq_of_eq {a b n : Nat} (h : a = b) : a ≡ b [MOD n] := by
  unfold ModEq
  rw [h]

/-- Divisibility implies congruence to zero. -/
theorem modEq_of_dvd {a n : Nat} (h : n ∣ a) : a ≡ 0 [MOD n] := by
  unfold ModEq
  rw [Nat.dvd_iff_mod_eq_zero.mp h]
  simp

/-- A divisor of `b` divides every positive power of `b`. -/
theorem dvd_pow_of_dvd {a b n : Nat} (h : a ∣ b) (hn : 1 ≤ n) : a ∣ b ^ n := by
  rcases h with ⟨c, hc⟩
  refine ⟨c * b ^ (n - 1), ?_⟩
  calc
    b ^ n = b ^ ((n - 1) + 1) := congrArg (fun m => b ^ m) (by omega)
    _ = b ^ (n - 1) * b ^ 1 := by rw [Nat.pow_add]
    _ = b ^ (n - 1) * b := by rw [Nat.pow_one]
    _ = b * b ^ (n - 1) := by rw [Nat.mul_comm]
    _ = (a * c) * b ^ (n - 1) := by rw [hc]
    _ = a * (c * b ^ (n - 1)) := by rw [Nat.mul_assoc]

theorem modEq_symm {a b n : Nat} (h : a ≡ b [MOD n]) : b ≡ a [MOD n] := h.symm

theorem modEq_trans {a b c n : Nat} (h₁ : a ≡ b [MOD n]) (h₂ : b ≡ c [MOD n]) :
    a ≡ c [MOD n] := h₁.trans h₂

@[simp] theorem modEq_mod_self (a n : Nat) : a ≡ a % n [MOD n] := by
  unfold ModEq
  rw [Nat.mod_mod]

@[simp] theorem modEq_mod_eq (a n : Nat) : a % n ≡ a [MOD n] := by
  unfold ModEq
  rw [Nat.mod_mod]

/-- Congruence of addition. -/
theorem modEq_add {a b c d n : Nat} (h₁ : a ≡ b [MOD n]) (h₂ : c ≡ d [MOD n]) :
    a + c ≡ b + d [MOD n] := by
  unfold ModEq
  rw [Nat.add_mod, h₁, h₂, ← Nat.add_mod]

theorem modEq_add_left {a b c n : Nat} (h : a ≡ b [MOD n]) : c + a ≡ c + b [MOD n] := by
  simpa using modEq_add (modEq_refl c n) h

theorem modEq_add_right {a b c n : Nat} (h : a ≡ b [MOD n]) : a + c ≡ b + c [MOD n] := by
  simpa using modEq_add h (modEq_refl c n)

/-- Congruence of multiplication. -/
theorem modEq_mul {a b c d n : Nat} (h₁ : a ≡ b [MOD n]) (h₂ : c ≡ d [MOD n]) :
    a * c ≡ b * d [MOD n] := by
  unfold ModEq
  rw [Nat.mul_mod, h₁, h₂, ← Nat.mul_mod]

theorem modEq_mul_left {a b c n : Nat} (h : a ≡ b [MOD n]) : c * a ≡ c * b [MOD n] := by
  simpa using modEq_mul (modEq_refl c n) h

theorem modEq_mul_right {a b c n : Nat} (h : a ≡ b [MOD n]) : a * c ≡ b * c [MOD n] := by
  simpa using modEq_mul h (modEq_refl c n)

/-- Congruence of powers. -/
theorem modEq_pow {a b n : Nat} (k : Nat) (h : a ≡ b [MOD n]) : a ^ k ≡ b ^ k [MOD n] := by
  induction k with
  | zero => simp [ModEq]
  | succ k ih => simpa [Nat.pow_succ] using modEq_mul ih h

theorem modEq_pow_self (a k n : Nat) : a ^ k ≡ (a % n) ^ k [MOD n] := by
  simpa [ModEq] using (modEq_pow k (modEq_mod_eq a n)).symm

/-- Adding a multiple of the modulus does not change the residue. -/
theorem modEq_add_mul_left (a k n : Nat) : a ≡ a + k * n [MOD n] := by
  unfold ModEq
  rw [Nat.mul_comm]
  exact (Nat.add_mul_mod_self_left a n k).symm

theorem modEq_add_mul_right (a k n : Nat) : a ≡ k * n + a [MOD n] := by
  unfold ModEq
  rw [Nat.mul_comm]
  rw [Nat.add_comm]
  exact (Nat.add_mul_mod_self_left a n k).symm

/-- A congruence together with a size bound yields an exact equality. -/
theorem eq_of_modEq_of_lt {a b n : Nat} (ha : a < n) (hb : b < n) (h : a ≡ b [MOD n]) :
    a = b := by
  unfold ModEq at h
  have ha' : a % n = a := Nat.mod_eq_of_lt ha
  have hb' : b % n = b := Nat.mod_eq_of_lt hb
  rwa [ha', hb'] at h

/-- `a ≡ b [MOD n]` implies `n ∣ a - b` when `b ≤ a`. -/
theorem dvd_sub_of_modEq {a b n : Nat} (h : a ≡ b [MOD n]) (hge : b ≤ a) : n ∣ a - b := by
  by_cases hn0 : n = 0
  · subst n
    have : a = b := by
      unfold ModEq at h
      have ha : a % 0 = a := Nat.mod_zero a
      have hb : b % 0 = b := Nat.mod_zero b
      rwa [ha, hb] at h
    rw [this]
    rw [Nat.sub_self]
    exact ⟨0, rfl⟩
  · have hn : 0 < n := Nat.pos_of_ne_zero hn0
    have hq : b / n ≤ a / n := Nat.div_le_div hge (Nat.le_refl n) hn0
    let X : Nat := (a / n) * n
    let Y : Nat := (b / n) * n
    let r : Nat := a % n
    have hXY : Y ≤ X := by simpa [X, Y] using Nat.mul_le_mul_right n hq
    have hsplit : a = X + r := by
      change a = (a / n) * n + a % n
      rw [Nat.mul_comm]
      exact (Nat.div_add_mod a n).symm
    have hb' : b = (b / n) * n + a % n := by
      calc
        b = (b / n) * n + b % n := by rw [Nat.mul_comm]; exact (Nat.div_add_mod b n).symm
        _ = (b / n) * n + a % n := by rw [h]
    have hb'' : b = Y + r := by simpa [Y, r] using hb'
    have hres : a - b = X - Y := by
      have hsub : (X + r) - (Y + r) = X - Y := by omega
      calc
        a - b = (X + r) - (Y + r) := by rw [hsplit, hb'']
        _ = X - Y := hsub
    rw [hres]
    simp [X, Y]
    rw [← Nat.mul_sub_right_distrib]
    rw [Nat.mul_comm]
    exact Nat.dvd_mul_right n (a / n - b / n)

/-- If `a ≡ b [MOD n]` then `n ∣ a - b` or `n ∣ b - a`. -/
theorem dvd_or_dvd_of_modEq {a b n : Nat} (h : a ≡ b [MOD n]) : n ∣ a - b ∨ n ∣ b - a := by
  cases Nat.le_total a b with
  | inl hab =>
      right
      exact dvd_sub_of_modEq h.symm hab
  | inr hba =>
      left
      exact dvd_sub_of_modEq h hba

end Multiplicity.RSA
