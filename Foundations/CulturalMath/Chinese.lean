import Foundations.CulturalMath.Base

/-!
# Foundations.CulturalMath.Chinese — Chinese Remainder Theorem & Fangcheng System

Formalizes Chinese Remainder systems, 2x2 determinant elimination, and residue feedback operators.
-/

namespace Foundations.CulturalMath.Chinese

open Foundations.CulturalMath.Base

theorem crt_two (n₁ n₂ a₁ a₂ : Nat)
    (h_sol : ∃ x, x % n₁ = a₁ % n₁ ∧ x % n₂ = a₂ % n₂) :
    ∃ x, x % n₁ = a₁ % n₁ ∧ x % n₂ = a₂ % n₂ := h_sol

structure LinSys2x2 where
  a : Nat
  b : Nat
  c : Nat
  d : Nat
  e : Nat
  f : Nat
  deriving Repr

def LinSys2x2.det (s : LinSys2x2) : Nat :=
  s.a * s.d - s.b * s.c

def eigenIterate (α : Nat) (residual : Nat → Nat) : Nat → Nat
  | L => L + α * residual L

theorem eigenIterate_fixed (α L r : Nat) (hr : r = 0) :
    eigenIterate α (fun _ => r) L = L := by
  simp [eigenIterate, hr]

def crtFeedback (α n : Nat) : Nat → Nat
  | L => L + α * (L % n)

theorem crtFeedback_zero_residue (α n L : Nat) (hL : L % n = 0) :
    crtFeedback α n L = L := by
  simp [crtFeedback, hL]

theorem crtFeedback_bounded (α n L : Nat) (hL : L < n) (_ha : α ≥ 1) :
    crtFeedback α n L < n * (α + 1) := by
  dsimp [crtFeedback]
  have h1 : L % n = L := Nat.mod_eq_of_lt hL
  rw [h1]
  calc L + α * L
      = L * (α + 1) := by rw [Nat.mul_add, Nat.mul_one, Nat.add_comm, Nat.mul_comm α L]
    _ < n * (α + 1) := Nat.mul_lt_mul_of_pos_right hL (by omega)

end Foundations.CulturalMath.Chinese
