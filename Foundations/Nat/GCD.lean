import Foundations.Peano.Peano
import Foundations.Nat.Order
import Foundations.Nat.Arith
import Foundations.Nat.Div

namespace Foundations.NatGCD

open Foundations.Peano
open Foundations.NatOrder
open Foundations.NatArith
open Foundations.NatDiv

/-! ## GCD and LCM (using core definitions) -/

/-- GCD is commutative. -/
theorem gcd_comm (a b : Nat) : Nat.gcd a b = Nat.gcd b a := Nat.gcd_comm a b

/-- GCD is associative. -/
theorem gcd_assoc (a b c : Nat) : Nat.gcd (Nat.gcd a b) c = Nat.gcd a (Nat.gcd b c) :=
  Nat.gcd_assoc a b c

/-- `gcd a b` divides `a`. -/
theorem gcd_dvd_left (a b : Nat) : Nat.gcd a b ∣ a := Nat.gcd_dvd_left a b

/-- `gcd a b` divides `b`. -/
theorem gcd_dvd_right (a b : Nat) : Nat.gcd a b ∣ b := Nat.gcd_dvd_right a b

/-- If `d ∣ a` and `d ∣ b` then `d ∣ gcd a b`. -/
theorem dvd_gcd {a b d : Nat} (ha : d ∣ a) (hb : d ∣ b) : d ∣ Nat.gcd a b :=
  Nat.dvd_gcd ha hb

/-- GCD is positive when either argument is positive. -/
theorem gcd_pos {a b : Nat} (ha : 0 < a) : 0 < Nat.gcd a b :=
  Nat.gcd_pos_of_pos_left b ha

/-- GCD is idempotent. -/
theorem gcd_self (a : Nat) : Nat.gcd a a = a := Nat.gcd_self a

/-- `gcd 0 a = a`. -/
theorem gcd_zero_left (a : Nat) : Nat.gcd 0 a = a := Nat.gcd_zero_left a

/-- `gcd a 0 = a`. -/
theorem gcd_zero_right (a : Nat) : Nat.gcd a 0 = a := Nat.gcd_zero_right a

/-! ## LCM -/

/-- `lcm a b` is a multiple of `a`. -/
theorem lcm_dvd_left (a b : Nat) : a ∣ Nat.lcm a b := Nat.dvd_lcm_left a b

/-- `lcm a b` is a multiple of `b`. -/
theorem lcm_dvd_right (a b : Nat) : b ∣ Nat.lcm a b := Nat.dvd_lcm_right a b

/-- The product of GCD and LCM equals the product. -/
theorem gcd_mul_lcm (a b : Nat) : Nat.gcd a b * Nat.lcm a b = a * b :=
  Nat.gcd_mul_lcm a b

/-- LCM is commutative. -/
theorem lcm_comm (a b : Nat) : Nat.lcm a b = Nat.lcm b a := Nat.lcm_comm a b

/-! ## Extended GCD (Subtraction-based Euclidean Algorithm) -/

/-- Subtraction-based extended Euclidean auxiliary. Returns `(s, t, g)` with `s·↑a + t·↑b = ↑g`. -/
def extgcdAux : Nat → Nat → Int × Int × Nat :=
  fun a b =>
  if a = 0 then (0, 1, b)
  else if b = 0 then (1, 0, a)
  else if a < b then
    let ⟨s, t, g⟩ := extgcdAux (b - a) a
    (t - s, s, g)
  else
    let ⟨s, t, g⟩ := extgcdAux (a - b) b
    (s, t - s, g)
termination_by a b => a + b
decreasing_by all_goals omega

theorem extgcdAux_eq_lt (a b : Nat) (h : a < b) (ha : a ≠ 0) :
    extgcdAux a b = let ⟨s, t, g⟩ := extgcdAux (b - a) a; (t - s, s, g) := by
  have hbne : b ≠ 0 := by omega
  rw [extgcdAux.eq_def, if_neg ha, if_neg hbne, if_pos h]

theorem extgcdAux_eq_ge (a b : Nat) (h : ¬ a < b) (hb : b ≠ 0) :
    extgcdAux a b = let ⟨s, t, g⟩ := extgcdAux (a - b) b; (s, t - s, g) := by
  have hane : a ≠ 0 := by omega
  rw [extgcdAux.eq_def, if_neg hane, if_neg hb, if_neg h]

theorem lt_bezout_step (a b : Nat) (_ : a < b) (s t : Int) (g : Nat)
    (ih : s * ↑(b - a) + t * ↑a = ↑g) :
    (t - s) * ↑a + s * ↑b = ↑g := by
  have hba : (↑b : Int) - ↑a = ↑(b - a) := by omega
  rw [← hba] at ih; rw [Int.mul_sub s] at ih; rw [Int.sub_mul t s ↑a]; omega

theorem ge_bezout_step (a b : Nat) (_ : ¬ a < b) (s t : Int) (g : Nat)
    (ih : s * ↑(a - b) + t * ↑b = ↑g) :
    s * ↑a + (t - s) * ↑b = ↑g := by
  have hab : (↑a : Int) - ↑b = ↑(a - b) := by omega
  rw [← hab] at ih; rw [Int.mul_sub s] at ih; rw [Int.sub_mul t s ↑b]; omega

/-- Bézout identity: `extgcdAux a b` returns `(s, t, g)` with `s·↑a + t·↑b = ↑g`. -/
theorem extgcdAux_bezout :
    ∀ a b : Nat, let ⟨s, t, g⟩ := extgcdAux a b; s * ↑a + t * ↑b = ↑g
  | 0, b => by simp [extgcdAux.eq_def]
  | a + 1, 0 => by simp [extgcdAux.eq_def]
  | a' + 1, b' + 1 => by
    have hc : a' < b' ∨ ¬ a' < b' := Classical.em (a' < b')
    cases hc with
    | inl hlt =>
      rw [extgcdAux_eq_lt (a' + 1) (b' + 1) (by omega) (by omega)]
      have ih1 := extgcdAux_bezout (b' + 1 - (a' + 1)) (a' + 1)
      change (match extgcdAux (b' + 1 - (a' + 1)) (a' + 1) with
        | (s, t, g) => s * ↑(b' + 1 - (a' + 1)) + t * ↑(a' + 1) = ↑g) at ih1
      dsimp only; dsimp only at ih1
      exact lt_bezout_step (a' + 1) (b' + 1) (by omega) _ _ _ ih1
    | inr hge =>
      rw [extgcdAux_eq_ge (a' + 1) (b' + 1) (by omega) (by omega)]
      have ih1 := extgcdAux_bezout (a' + 1 - (b' + 1)) (b' + 1)
      change (match extgcdAux (a' + 1 - (b' + 1)) (b' + 1) with
        | (s, t, g) => s * ↑(a' + 1 - (b' + 1)) + t * ↑(b' + 1) = ↑g) at ih1
      dsimp only; dsimp only at ih1
      exact ge_bezout_step (a' + 1) (b' + 1) (by omega) _ _ _ ih1

/-! ## GCD Subtraction Identities -/

private theorem gcd_sub_left (a b : Nat) (_ : a ≥ b) : Nat.gcd a b = Nat.gcd (a - b) b := by
  have hsub : (a - b) + b = a := by omega
  have key := Nat.gcd_add_self_left b (a - b)
  rw [hsub] at key
  exact key

private theorem gcd_sub_right (a b : Nat) (_ : a ≤ b) : Nat.gcd a b = Nat.gcd (b - a) a := by
  have hsub : (b - a) + a = b := by omega
  have key := Nat.gcd_add_self_left a (b - a)
  rw [hsub] at key
  rw [Nat.gcd_comm a b, key]

/-! ## GCD Correctness -/

private theorem extgcdAux_gcd_aux :
    ∀ a b : Nat, (extgcdAux a b).2.2 = Nat.gcd a b
  | 0, b => by simp [extgcdAux.eq_def]
  | a + 1, 0 => by simp [extgcdAux.eq_def]
  | a' + 1, b' + 1 => by
    have hc : a' < b' ∨ ¬ a' < b' := Classical.em (a' < b')
    cases hc with
    | inl hlt =>
      rw [extgcdAux_eq_lt (a' + 1) (b' + 1) (by omega) (by omega)]
      have ih1 := extgcdAux_gcd_aux (b' + 1 - (a' + 1)) (a' + 1)
      change (match extgcdAux (b' + 1 - (a' + 1)) (a' + 1) with
        | (s, t, g) => g = Nat.gcd (b' + 1 - (a' + 1)) (a' + 1)) at ih1
      dsimp only; dsimp only at ih1
      rw [ih1, gcd_sub_right (a' + 1) (b' + 1) (by omega)]
    | inr hge =>
      rw [extgcdAux_eq_ge (a' + 1) (b' + 1) (by omega) (by omega)]
      have ih1 := extgcdAux_gcd_aux (a' + 1 - (b' + 1)) (b' + 1)
      change (match extgcdAux (a' + 1 - (b' + 1)) (b' + 1) with
        | (s, t, g) => g = Nat.gcd (a' + 1 - (b' + 1)) (b' + 1)) at ih1
      dsimp only; dsimp only at ih1
      rw [ih1, gcd_sub_left (a' + 1) (b' + 1) (by omega)]

/-! ## Bézout's Identity -/

/-- Bézout's identity: `gcd a b` is an integer linear combination of `a` and `b`. -/
theorem gcd_eq_gcd_ab (a b : Nat) :
    ∃ s t : Int, s * ↑a + t * ↑b = ↑(Nat.gcd a b) := by
  have hbez := extgcdAux_bezout a b
  have hgcd := extgcdAux_gcd_aux a b
  dsimp only at hbez hgcd
  match extgcdAux a b, hbez, hgcd with
  | (s, t, g), hbez, hgcd =>
    exact ⟨s, t, hgcd ▸ hbez⟩

end Foundations.NatGCD
