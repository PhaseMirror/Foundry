import Init
theorem sq_nonneg (a : Int) : 0 ≤ a * a := by
  rcases Int.le_total 0 a with h | h
  · exact Int.mul_nonneg h h
  · have h' : 0 ≤ -a := by omega
    have hh : 0 ≤ (-a) * (-a) := Int.mul_nonneg h' h'
    rw [Int.neg_mul_neg] at hh
    exact hh
