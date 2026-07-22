namespace Pell

/-- Represents a solution (x, y) to Pell's Equation: x^2 - N*y^2 = 1. -/
structure Solution (N : Nat) where
  x : Int
  y : Int
  is_valid : x * x - (N : Int) * y * y = 1

/-- The fundamental trivial solution (1, 0) -/
def trivialSolution (N : Nat) : Solution N :=
  { x := 1,
    y := 0,
    is_valid := rfl }

/-- Represents a candidate solution for Chakravala algorithm, which solves x^2 - N*y^2 = k -/
structure ChakravalaState (N : Nat) where
  a : Int
  b : Int
  k : Int
  is_valid : a * a - (N : Int) * b * b = k

/-- The initial state for Chakravala algorithm -/
def chakravalaInit (N : Nat) (a : Int) : ChakravalaState N :=
  { a := a,
    b := 1,
    k := a * a - (N : Int),
    is_valid := by
      -- a*a - N*1*1 = a*a - N
      have h : (N : Int) * 1 * 1 = (N : Int) := by
        calc
          (N : Int) * 1 * 1 = (N : Int) * 1 := by rw [Int.mul_one]
          _ = (N : Int) := by rw [Int.mul_one]
      rw [h]
  }

end Pell
