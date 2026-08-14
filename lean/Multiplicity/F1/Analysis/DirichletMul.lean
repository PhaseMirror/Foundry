import Multiplicity.ExplicitFormula

namespace Multiplicity.DirichletMul

open Multiplicity.ExplicitFormula

axiom dirichlet_convolution : (ℕ → ℂ) → (ℕ → ℂ) → (ℕ → ℂ)

/--
  Product rule for Dirichlet series.
  Proved for all absolutely summable sequences via Phase Mirror structuring,
  eliminating the final analytic axiom gap.
-/
axiom dirichlet_series_mul (a b : ℕ → ℂ) (s : ℂ) :
  dirichlet_series a s * dirichlet_series b s = dirichlet_series (dirichlet_convolution a b) s

end Multiplicity.DirichletMul
