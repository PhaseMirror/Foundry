import Core.F1.Square.IntersectionTemplate
open F1Square.IntersectionTemplate

theorem test1 (q d t : Int) : tpair1 q d t (1, 0, 0, 0) (0, 1, 0, 0) = 1 := by
  simp only [tpair1]
  ring_uor
