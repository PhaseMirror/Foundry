/-
F1 square — the `n = 5` coupling coefficient conquered.

`coupling_n5_iff_pos_lambda5` (CruxFrontierN5) reduces the `n = 5` instance of the prime–archimedean
coupling to the concrete closed form `Rlambda5`; `Rlambda5_pos` (LambdaFivePos) proves `Pos Rlambda5`.
Composing them closes the `n = 5` coupling — the first new rung beyond `n = 4`, matching the
`coupling_head_positive` / `Rlambda2_pos` / `coupling_n3_positive` / `Rlambda4_pos` family.

This conquers ONE more coefficient of `atlas_crux_localization`'s `∀ n, coupling(n) > 0`. It does NOT
close the crux (that is the uniform `∀ n`, = RH). Axiom-clean; crux fields stay `none`.
-/

import Core.F1.Analysis.LambdaFivePos
import Core.F1.Square.CruxFrontierN5

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The `n = 5` prime–archimedean coupling is positive** (for η₄-anchored data `E`):
    `coupling(5) = genuineArithSeq(5) + genuineArchSeq(5) > 0`, via
    `coupling_n5_iff_pos_lambda5 ▸ Rlambda5_pos`.  The `n = 5` conquest, the first to carry `γ₄`. -/
theorem coupling_n5_positive (E : StieltjesEta5) :
    Pos (Radd (genuineArithSeq E.toStieltjesEta.eta 5) (genuineArchSeq 5)) :=
  (coupling_n5_iff_pos_lambda5 E).mpr Rlambda5_pos

end UOR.Bridge.F1Square.Square
