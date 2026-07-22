import CulturalMath.Base

namespace CulturalMath.Chinese

axiom crt_two_axiom (n₁ n₂ a₁ a₂ : Nat)
    (hn₁ : n₁ ≥ 2) (hn₂ : n₂ ≥ 2) :
    ∃ x, x % n₁ = a₁ % n₁ ∧ x % n₂ = a₂ % n₂

structure LinSys2x2 where
  a : Nat
  b : Nat
  c : Nat
  d : Nat
  e : Nat
  f : Nat

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

axiom crtFeedback_bounded (α n L : Nat) (hL : L < n) (ha : α ≥ 1) :
    crtFeedback α n L < n * (α + 1)

end CulturalMath.Chinese
