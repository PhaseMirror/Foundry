import CulturalMath.Base

namespace CulturalMath.Japanese

-- Incircle radius of right triangle
def incircleRadius (a b c : Nat) : Nat := (a + b - c) / 2

theorem incircle_345 :
    incircleRadius 3 4 5 = 1 := by native_decide

theorem incircle_51213 :
    incircleRadius 5 12 13 = 2 := by native_decide

-- Newton iteration
def newtonIterate (α : Nat) (residual : Nat → Nat) : Nat → Nat
  | xn => xn + α * residual xn

theorem newton_fixed (α x res : Nat) (hres : res = 0) :
    newtonIterate α (fun _ => res) x = x := by
  simp [newtonIterate, hres]

-- Circle packing
def sangakuCircleRadius (s n : Nat) : Nat := s / (2 * n)

-- Modular calendar
def jpYear := 360
def jpMonth := 30
def dayOfMonth (t : Nat) : Nat := t % jpMonth
def monthNum (t : Nat) : Nat := (t / jpMonth) % 12

theorem dayOfMonth_periodic (t : Nat) : dayOfMonth (t + jpMonth) = dayOfMonth t := by
  simp [dayOfMonth, jpMonth]

theorem monthNum_periodic (t : Nat) : monthNum (t + jpYear) = monthNum t := by
  simp only [monthNum, jpYear, jpMonth]
  rw [show (360 : Nat) = 12 * 30 from by omega]
  rw [Nat.add_mul_div_right _ _ (by omega : 0 < 30)]
  rw [Nat.add_mod, show (12 : Nat) % 12 = 0 from by omega, Nat.add_zero]
  exact Nat.mod_eq_of_lt (Nat.mod_lt _ (by omega : 0 < 12))

-- Fractal
def sangakuFractal (T0 : Nat) : Nat → Nat
  | 0     => T0
  | n + 1 => sangakuFractal T0 n / 2

theorem sangakuFractal_decreasing (T0 n : Nat) (_hT0 : T0 ≥ 1) :
    sangakuFractal T0 (n + 1) ≤ sangakuFractal T0 n := by
  simp [sangakuFractal]; omega

end CulturalMath.Japanese
