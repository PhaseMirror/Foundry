/-- 
  DISCLAIMER: This is a research program. RH remains open. The 𝔽₁-square 
  with Hodge index is unconstructed. Numerical experiments and admitted 
  bounds are exploratory and do not constitute proof.
--/

import F1Square.Interval

namespace Data.PrimeLogs

/-- List of (pk, p, k, log_p_interval) for prime powers ≤ 10^5 --/
def prime_power_logs_list : List (Nat × Nat × ℕ × Interval) := [
  (2, 2, 1, { low := 693147180559945 / 1000000000000000, high := 693147180559946 / 1000000000000000, inv := by norm_num }),
  (3, 3, 1, { low := 1098612288668109 / 1000000000000000, high := 1098612288668110 / 1000000000000000, inv := by norm_num }),
  (4, 2, 2, { low := 693147180559945 / 1000000000000000, high := 693147180559946 / 1000000000000000, inv := by norm_num }),
  (5, 5, 1, { low := 1609437912434100 / 1000000000000000, high := 1609437912434101 / 1000000000000000, inv := by norm_num })
  -- ... thousands more entries would be added here
]

end Data.PrimeLogs
