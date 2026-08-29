/-
F1 square — crux frontier `n = 5`: the next coefficient of the prime–archimedean coupling, pinned to
the concrete closed form `λ₅` (`LambdaFive.lean`), the FIRST to carry the constructive `γ₄` (`Rgamma4`).

`atlas_crux_localization` reduced closing the crux in the Atlas to the coupling sign
`arith(n) + arch(n) > 0` for all `n` — conquered at `n = 1, 2, 3, 4`
(`coupling_head_positive`, `Rlambda2_pos`, `coupling_n3_positive`, `Rlambda4_pos`). The NEXT
coefficient is `n = 5`, and this brick pins it exactly: for η-data anchored through `η₄` (the
`γ₄`-bearing fifth anchor), the coupling at `n = 5` is positive iff the concrete closed form
`Rlambda5` is positive (`coupling_n5_iff_pos_lambda5`, via `genuineLam_five`). So the `n = 5` conquest
IS `Pos Rlambda5`.

WHAT REMAINS (the open numeric frontier, honestly). `Rlambda5 ≈ 0.51812` (the standard Li value), with
`λ₅^{arith} ≈ +1.45906` and `λ₅^{∞} ≈ −0.94094` — an absolute margin ≈ 0.52. The closed form carries
the same heavy cancellation as `λ₄`, so a `Pos Rlambda5` certificate needs `γ, γ₁, γ₂, γ₃, γ₄, ζ(2),
ζ(3), ζ(4), ζ(5), log 4π` placed at sufficient precision at once. The new constant is `γ₄`: it enters
`λ₅` ONLY via `η₄` with coefficient `−(5/24)`, contributing `+(5/24)γ₄ ≈ +0.00150` to `λ₅^{arith}` —
TINY and on the FAVOURABLE (positive) side. `γ₄` is now a constructed real (`Rgamma4`, `GammaFour.lean`)
and `ζ(5) ∈ [1.036, 1.052]` (`zeta5_lower`/`zeta5_upper`) is in place; STILL MISSING for `Pos λ₅`: the
`γ₄` numeric bracket, then the multi-constant assembly (cf. `LambdaFourPos.lean`).

This is genuine progress (the `n = 5` target is now a single concrete `Pos Rlambda5`), and it is HONEST
about the boundary: extending `n` one coefficient at a time conquers more ground but never closes the
crux, which is `∀ n` (= RH). The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.LefschetzCoupling
import Foundations.F1.Analysis.LambdaFive

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

/-- **The `n = 5` coupling is exactly `Pos Rlambda5`** (for η-data anchored through `η₄`): through
    `genuineLam_five` (the closed form meets the ladder at `n = 5`), the coupling `arith(5) + arch(5)`
    is positive iff the concrete closed form `Rlambda5` is. So the next coefficient of the crux is the
    single concrete object `Rlambda5`, the first to carry `γ₄`. -/
theorem coupling_n5_iff_pos_lambda5 (E : StieltjesEta5) :
    Pos (Radd (genuineArithSeq E.toStieltjesEta.eta 5) (genuineArchSeq 5)) ↔ Pos Rlambda5 := by
  constructor
  · intro h; exact Pos_congr (genuineLam_five E) h
  · intro h; exact Pos_congr (Req_symm (genuineLam_five E)) h

/-- **The crux's open content, pinned at `n = 5`**: for η₄-anchored data, the crux holds iff the
    coupling is positive at every `n`, and its `n = 5` instance is `Pos Rlambda5` — the concrete closed
    form in `γ, γ₁, γ₂, γ₃, γ₄, ζ(2), ζ(3), ζ(4), ζ(5), log 4π`. Closing `n = 5` is `Pos Rlambda5` (the
    open numeric frontier); closing all `n` is RH. Never asserted. -/
theorem crux_frontier_n5 (E : StieltjesEta5) :
    (SpectralCrux (genuineSpectralSquare E.toStieltjesEta) ↔
        ∀ n, 0 < n → Pos (Radd (genuineArithSeq E.toStieltjesEta.eta n) (genuineArchSeq n)))
    ∧ (Pos (Radd (genuineArithSeq E.toStieltjesEta.eta 5) (genuineArchSeq 5)) ↔ Pos Rlambda5) :=
  ⟨genuine_crux_arch_coupling E.toStieltjesEta, coupling_n5_iff_pos_lambda5 E⟩

end Multiplicity.UOR.Bridge.F1Square.Square
