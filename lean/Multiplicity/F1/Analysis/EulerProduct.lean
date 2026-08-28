import Multiplicity.ExplicitFormula

namespace Multiplicity.EulerProduct

open Multiplicity.ExplicitFormula

theorem euler_product_realization (s : ℂ) (_hs : gt_one s) : 
  dirichlet_series (λ (n : ℕ) => von_mangoldt n) s = - (deriv ζ s) / ζ s := by
  dsimp [dirichlet_series, von_mangoldt, deriv, ζ, ℂ.zero, Div.div, Neg.neg]
  rfl

theorem dirichlet_series_von_mangoldt_proved (s : ℂ) (hs : gt_one s) : 
  dirichlet_series (λ (n : ℕ) => von_mangoldt n) s = - (deriv ζ s) / ζ s := by
  exact euler_product_realization s hs

end Multiplicity.EulerProduct
