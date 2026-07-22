import Lean
import Core.F1.RiemannZeta
/-! Test suite for RiemannZeta axioms -/

open RiemannZeta

#check zeta_at_2_equals_pi_squared_over_6
#check first_zero_at_14_134725
#check gram_points_monotone

def main : IO Unit := pure ()
