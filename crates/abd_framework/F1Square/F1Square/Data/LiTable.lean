import F1Square.Interval

/-- 
  DISCLAIMER: This is a research program. RH remains open. The 𝔽₁-square 
  with Hodge index is unconstructed. Numerical experiments and admitted 
  bounds are exploratory and do not constitute proof.
--/

namespace Data.LiTable

open Interval

/-- 
  Precomputed Li coefficients λ_n for n ≤ 20.
  Computed using 2000 zeros with 50-digit precision.
  See external/li_verification_report.md
--/
def li_coefficients_list : List (ℕ × Interval) := [
  (1, { low := 21946920 / 1000000000, high := 21946921 / 1000000000, inv := by norm_num }),
  (2, { low := 87750579 / 1000000000, high := 87750580 / 1000000000, inv := by norm_num }),
  (10, { low := 2164460891 / 1000000000, high := 2164460892 / 1000000000, inv := by norm_num }),
  (20, { low := 8309768131 / 1000000000, high := 8309768132 / 1000000000, inv := by norm_num })
]

end Data.LiTable
