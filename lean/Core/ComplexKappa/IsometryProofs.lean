// Norm preservation for the first column of the Stinespring dilation

import Core.ComplexKappa.IsometryKani

set_option linter.unusedVariables false

namespace ComplexKappa

/-- The first column of the Stinespring dilation is an isometry, hence it preserves the norm. -/
theorem first_column_norm_eq (k k_star ε σ γ : Real) (x : ℂ) :
  ‖firstColumn (stinespring_dilation k k_star ε σ γ) x‖ = ‖x‖ :=
by
  have hIso := first_column_is_isometry k k_star ε σ γ
  exact hIso.norm_eq x

end ComplexKappa
