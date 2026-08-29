import Analytic.FloatModel
import Analytic.Constants
open FloatModel
open Constants

/-- Simple concrete critical height function for evaluation – add one –/

def T_crit (x : ℝ) : ℝ := add x one

/-- Sanity check: evaluate T_crit on a concrete constant –/
#eval T_crit A_param
