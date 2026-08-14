import UOR

def sq_nonneg_int (a : Int) : 0 ≤ a * a := by
  rcases Int.le_total 0 a with h | h
  · exact Int.mul_nonneg h h
  · have h1 : 0 ≤ -a := by omega
    have h2 : 0 ≤ (-a) * (-a) := Int.mul_nonneg h1 h1
    have h3 : (-a) * (-a) = a * a := by ring_uor
    rw [←h3]
    exact h2
