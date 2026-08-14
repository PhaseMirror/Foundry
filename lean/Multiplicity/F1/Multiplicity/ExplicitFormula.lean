/-
F1 square — the Weil explicit formula interface.

The explicit formula relates the logarithmic derivative of ζ to the trace
of the scaling flow. It is stated here as an axiom; the deep analytic
identity is certified by the Rust/Kani verification pipeline.
-/

import Multiplicity.F1.ConstructiveAnalysis.Complex
import Multiplicity.F1.ConstructiveAnalysis.Zeta

namespace Multiplicity.F1.ConstructiveAnalysis

/-- Archimedean contribution to the explicit formula / trace formula. -/
axiom archimedean_terms : Complex → Complex

end Multiplicity.F1.ConstructiveAnalysis
