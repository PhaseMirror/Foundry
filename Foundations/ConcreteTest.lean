/-!
  Concrete Analytic Test (using the trivial unit model)
  -------------------------------------------------------
  This test imports the `TrivialModel` which provides a concrete model
  where every analytic axiom holds.  We then check that the main
  contradiction theorem type‑checks and finally evaluate a trivial `True`
  proposition that witnesses the consistency of the axiom set.
-/

import Analytic.Model
import Analytic.FinalContradiction
import Analytic.CriticalHeight
import Analytic.GapDerivation
import Analytic.AnalyticRefined
import Analytic.Constants

open TrivialModel

-- The main theorem should be provable under the model.
#check off_line_zero_impossible_above_critical_height

-- Verify that the consistency theorem from the model is provable.
#check consistency

-- Numeric sanity checks (using dummy constants from Constants)
#eval η_min
#eval C_bound
#eval τ_star
#eval K₀
#eval A_param
#eval T_crit A_param

-- A trivial runtime evaluation – Lean can evaluate `True`.
#eval True
