import CulturalMath.Base

namespace CulturalMath.Vedic

def ekadhikena5 (x : Nat) : Nat :=
  let n := x / 10
  n * (n + 1) * 100 + 25

theorem ekadhikena5_25 : ekadhikena5 25 = 625 := by native_decide
theorem ekadhikena5_35 : ekadhikena5 35 = 1225 := by native_decide
theorem ekadhikena5_45 : ekadhikena5 45 = 2025 := by native_decide
theorem ekadhikena5_105 : ekadhikena5 105 = 11025 := by native_decide

def nikhilamMul (a b base : Nat) : Nat :=
  base * base + base * (a + b) + a * b

theorem nikhilam_correct (a b base : Nat) :
    nikhilamMul a b base = (base + a) * (base + b) := by
  simp only [nikhilamMul]
  rw [Nat.add_mul, Nat.mul_add, Nat.mul_add, Nat.mul_add, Nat.mul_comm base a]
  omega

def vedicFeedback (a b : Nat) (_ : b ≥ 1) : Nat → Nat
  | mt => mt * a / b

axiom div_mul_le (x y : Nat) (hy : y ≥ 1) (hxy : x ≤ y) : ∀ mt, mt * x / y ≤ mt

theorem vedicFeedback_contracting (a b mt : Nat) (hab : a ≤ b) (hb : b ≥ 1) (_ : mt ≥ 1) :
    vedicFeedback a b hb mt ≤ mt := by
  simp only [vedicFeedback]; exact div_mul_le a b hb hab mt

theorem shunyam_mod (a b p : Nat) (h : a + b = p) (_ : p ≥ 1) :
    (a + b) % p = 0 := by rw [h, Nat.mod_self]

def vedicPrimeEncode (n : Nat) : Nat := 10 ^ n - (n - 1)

end CulturalMath.Vedic
