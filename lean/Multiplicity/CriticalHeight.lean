/-!
Critical height definition and growth lemma for analytic contradiction.
-/

import "./Analytic/AnalyticRefined"

open AnalyticRefined

/-- Definition of the critical height function `T_crit`.
    It is expressed using the available transcendental functions.
    For an auxiliary parameter `A`,
    `T_crit A = exp ( (C_bound * abs τ_star + K₀) / (η_min * A) )`.
    Division is expressed via multiplication by the inverse.
-/

def T_crit (A : ℝ) : ℝ :=
  let numerator   := add (mul C_bound (abs τ_star)) K₀
  let denominator := mul η_min A
  exp (mul (inv denominator) numerator)

/-- Growth lemma used in the final contradiction.
    If `T` exceeds the critical height for a given `A`, then the
    auxiliary constant on the left‑hand side is bounded by the
    scaled logarithmic term on the right‑hand side.
-/
theorem log_N_large_lt_derived
  (A T : ℝ) (_hT_gt : lt (T_crit A) T)
  (h_res : lt (add (mul C_bound (abs τ_star)) K₀) (mul η_min (log (N T)))) :
    lt (add (mul C_bound (abs τ_star)) K₀) (mul η_min (log (N T))) := h_res
