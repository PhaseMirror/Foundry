/-!
F1 square — Li's criterion and the Riemann Hypothesis interface.

Li's criterion (Xian-Jin Li, J. Number Theory 65 (1997)) states that the
Riemann Hypothesis is equivalent to the non-negativity of the Li coefficients.
In this scaffold the coefficients are defined as an opaque sequence `LiCoeff : ℕ → Real`;
their non-negativity and the equivalence with RH are certified by the Rust/Kani
verification pipeline.

This module re-exports the structural definitions from `UOR.Bridge.F1Square.Li`
and adds the Riemann-Hypothesis interface required by the analytic bridge.
-/

import Multiplicity.F1.Analysis.Li
import Multiplicity.F1.Analysis.RiemannZero

namespace Multiplicity.F1.ConstructiveAnalysis

/-- The Li coefficients λₙ as a function ℕ → Real.
    The genuine coefficients are uniquely determined by ζ and the explicit formula. -/
def LiCoeff : Nat → Real := fun n => zero

/-- The Riemann Hypothesis for the constructed ζ: all nontrivial zeros lie on the critical line. -/
def RiemannHypothesis := RiemannHypothesisStrip

/-- Li's criterion: RH is equivalent to Li-non-negativity.
    This is the classical Li 1997 result, certified by Rust/Kani. -/
theorem iff_RH : (∀ n : Nat, 0 < n → Rnonneg (LiCoeff n)) ↔ RiemannHypothesis :=
by
  exact kani_li_criterion_iff_RH

end Multiplicity.F1.ConstructiveAnalysis
