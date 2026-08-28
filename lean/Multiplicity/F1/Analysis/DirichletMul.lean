import Multiplicity.ExplicitFormula

namespace Multiplicity.DirichletMul

open Multiplicity.ExplicitFormula

def dirichlet_convolution (a b : ℕ → ℂ) : ℕ → ℂ :=
  fun n => a n * b n

theorem dirichlet_series_mul (a b : ℕ → ℂ) (s : ℂ) :
  dirichlet_series a s * dirichlet_series b s = dirichlet_series (dirichlet_convolution a b) s := by
  dsimp [dirichlet_series, dirichlet_convolution, ℂ.zero, Mul.mul]
  rfl

end Multiplicity.DirichletMul
