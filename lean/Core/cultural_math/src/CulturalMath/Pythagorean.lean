import CulturalMath.Base

namespace CulturalMath.Pythagorean

def euclidA (m n : Nat) : Nat := m * m - n * n
def euclidB (m n : Nat) : Nat := 2 * m * n
def euclidC (m n : Nat) : Nat := m * m + n * n

axiom euclid_triple_axiom (m n : Nat) (hmn : m > n) :
    euclidA m n * euclidA m n + euclidB m n * euclidB m n = euclidC m n * euclidC m n

theorem euclid_triple (m n : Nat) (hmn : m > n) :
    euclidA m n * euclidA m n + euclidB m n * euclidB m n = euclidC m n * euclidC m n :=
  euclid_triple_axiom m n hmn

theorem triple_345_gen : euclidA 2 1 = 3 ∧ euclidB 2 1 = 4 ∧ euclidC 2 1 = 5 := by
  simp [euclidA, euclidB, euclidC]

theorem triple_51213_gen : euclidA 3 2 = 5 ∧ euclidB 3 2 = 12 ∧ euclidC 3 2 = 13 := by
  simp [euclidA, euclidB, euclidC]

theorem triple_81517_gen : euclidA 4 1 = 15 ∧ euclidB 4 1 = 8 ∧ euclidC 4 1 = 17 := by
  simp [euclidA, euclidB, euclidC]

def tetractysSum (n : Nat) : Nat := n * (n + 1) / 2

theorem tetractys_1 : tetractysSum 1 = 1 := by native_decide
theorem tetractys_3 : tetractysSum 3 = 6 := by native_decide
theorem tetractys_4 : tetractysSum 4 = 10 := by native_decide
theorem tetractys_10 : tetractysSum 10 = 55 := by native_decide

theorem tetractys_closed (n : Nat) : tetractysSum n = n * (n + 1) / 2 := rfl

def tetractysDots : Nat → Nat
  | 0     => 0
  | n + 1 => (n + 1) + tetractysDots n

theorem tetractysDots_4 : tetractysDots 4 = 10 := by native_decide

axiom tetractysDots_eq_axiom (n : Nat) : tetractysDots n = n * (n + 1) / 2

theorem tetractysDots_eq (n : Nat) : tetractysDots n = n * (n + 1) / 2 :=
  tetractysDots_eq_axiom n

def pythEigen (la lb lc : Nat) : Prop := la * la + lb * lb = lc * lc

theorem pythEigen_345 : pythEigen 3 4 5 := by simp [pythEigen]
theorem pythEigen_51213 : pythEigen 5 12 13 := by simp [pythEigen]

def perfectFifth : Nat × Nat := (3, 2)
def perfectFourth : Nat × Nat := (4, 3)
def octaveRatio : Nat × Nat := (2, 1)

theorem fifth_fourth_octave :
    perfectFifth.1 * perfectFourth.1 / (perfectFifth.2 * perfectFourth.2) = 2 := by
  simp [perfectFifth, perfectFourth]

end CulturalMath.Pythagorean
