theorem t1 (e f : Int) : e + (f - e) = f := by
  omega

theorem t2 (e f : Int) : e + (f - e) = f := by
  simp_arith

theorem t3 (e f : Int) : e + (f - e) = f := by
  rw [Int.add_comm, Int.sub_add_cancel]
