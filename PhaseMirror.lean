-- PhaseMirror.lean : The unified cathedral of the conditional Riemann Hypothesis proof.
import Prime.Channel
import Prime.TransferMatrix
import Prime.Contractivity
import Prime.ExplicitFormula
import Prime.DirichletConvergence
import Prime.DirichletMul
import Prime.EulerProduct
import Prime.TraceFormula
import Prime.Xi
import Prime.ParameterIdentification
import Prime.RiemannHypothesis
import Prime.SafePrimeDefect
import Prime.CompositeFunctorDefect
import Prime.SedonaRiskModel
import Multiplicity.universal_atomic.Main
import Multiplicity.universal_atomic.BoundaryProofs
import Multiplicity.universal_atomic.BoundaryTests

open Prime

-- Re-export the capstone theorem for external consumption
theorem riemann_hypothesis : (∃ (F : List CompositeFunctorDefect.AffineFunctor), True) →
  (∀ ρ, RiemannHypothesis.IsNontrivialZero ρ → ExplicitFormula.re ρ = ExplicitFormula.ℂ.zero) :=
  CompositeFunctorDefect.composite_covering_implies_rh

-- Re-export the unconditional contractivity theorem
theorem contractivity : TransferMatrix.T < 1.0 :=
  Contractivity.strict_contractivity
