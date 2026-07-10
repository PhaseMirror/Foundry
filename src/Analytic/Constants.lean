/-!
  Analytic constant wrapper.
  Imports the generated `ExtractedValues` module and re‑exports the numerical
  constants under the names expected by the analytic scaffold.
-/

import Analytic.ExtractedValues

open ExtractedValues

/-- Minimum η required by the engine – concrete value. -/
def η_min : ℝ := ExtractedValues.η_min

/-- Upper bound on the constant C – concrete value. -/
def C_bound : ℝ := ExtractedValues.C_bound

/-- τ* (tau‑star) – concrete value. -/
def τ_star : ℝ := ExtractedValues.τ_star

/-- K₀ – concrete value. -/
def K₀ : ℝ := ExtractedValues.K₀

/-- The A‑parameter used in the exponential term – concrete value. -/
def A_param : ℝ := ExtractedValues.A_param
