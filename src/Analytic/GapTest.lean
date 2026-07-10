import Analytic.FloatModel
import Analytic.Constants
import Analytic.CriticalHeight
open FloatModel
open Constants

/-
  Test that the concrete critical height is computed correctly and that the
  analytic gap inequality holds for the *real* extracted constants.
-/

-- Compute the critical height with the current constants
def criticalHeight : ℝ := T_crit A_param

#eval criticalHeight   -- you should see a concrete Float (≈1.086… with dummy data)

/-
  Gap inequality:
    η_min * log ( N ( criticalHeight + 1 ) )  >  C_bound * |τ_star| + K₀
  where:
    N T = exp ( A_param * log T )
-/
def lhs : ℝ := mul η_min (log (N (add criticalHeight one)))
def rhs : ℝ := add (mul C_bound (abs τ_star)) K₀

#eval lhs   -- left‑hand side (a Float)
#eval rhs   -- right‑hand side (a Float)

-- Boolean check – should reduce to  when the real constants are used
#eval lt rhs lhs   -- true ⇔ gap is open
