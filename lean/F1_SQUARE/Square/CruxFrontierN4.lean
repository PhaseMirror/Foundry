/-
F1 square — crux frontier `n = 4`: the next coefficient of the prime–archimedean coupling, pinned to
the concrete closed form `λ₄` (`LambdaFour.lean`), built on the constructive `γ₃` (`Rgamma3`).

`atlas_crux_localization` reduced closing the crux in the Atlas to the coupling sign
`arith(n) + arch(n) > 0` for all `n` — conquered at `n = 1, 2, 3`
(`coupling_head_positive`, `Rlambda2_pos`, `coupling_n3_positive`). The NEXT coefficient is `n = 4`,
and this brick pins it exactly: for η-data anchored through `η₃` (the `γ₃`-bearing fourth anchor), the
coupling at `n = 4` is positive iff the concrete closed form `Rlambda4` is positive
(`coupling_n4_iff_pos_lambda4`, via `genuineLam_four`). So the `n = 4` conquest IS `Pos Rlambda4`.

WHAT REMAINS (the open numeric frontier, honestly). `Rlambda4 ≈ 0.36998` (the standard Li value),
with `λ₄^{arith} ≈ +1.3755` and `λ₄^{∞} ≈ −1.0067` — an absolute margin ≈ 0.37, not razor-thin, but
the closed form carries the SAME heavy cancellation as `λ₃` (the archimedean block collapses
`Θ(3.8)` constants to `Θ(1)`), so a `Pos Rlambda4` certificate needs `γ, γ₁, γ₂, γ₃, ζ(2), ζ(3),
ζ(4), log 4π` placed at sufficient precision at once. The new constant is `γ₃`: it enters λ₄ ONLY via
`η₃` with coefficient `+2/3`, contributing `−(2/3)γ₃ ≈ −0.00137` to `λ₄^{arith}` — TINY (since
`γ₃ ≈ +0.00205`). So `Pos Rlambda4` needs only a LOOSE UPPER bound on `γ₃` (the side controlling the
negative term), which the `GammaThree` Euler–Maclaurin bracket is being built to supply; `ζ(4) ∈
[1.082, 1.097]` (`zeta4_lower`/`zeta4_upper`) is already in place. STILL MISSING for `Pos λ₄`: the
`γ₃` upper bracket, then the multi-constant assembly (cf. `LambdaThreePos.lean`).

This is genuine progress (the `n = 4` target is now a single concrete `Pos Rlambda4`), and it is
HONEST about the boundary: extending `n` one coefficient at a time conquers more ground but never
closes the crux, which is `∀ n` (= RH); that uniform bound is the irreducible content. The crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.LefschetzCoupling
import F1Square.Analysis.LambdaFour

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

/-- **The `n = 4` coupling is exactly `Pos Rlambda4`** (for η-data anchored through `η₃`): through
    `genuineLam_four` (the closed form meets the ladder at `n = 4`), the coupling
    `arith(4) + arch(4)` is positive iff the concrete closed form `Rlambda4` is. So the next
    coefficient of the crux is the single concrete object `Rlambda4`. -/
theorem coupling_n4_iff_pos_lambda4 (E : StieltjesEta4) :
    Pos (Radd (genuineArithSeq E.toStieltjesEta.eta 4) (genuineArchSeq 4)) ↔ Pos Rlambda4 := by
  constructor
  · intro h; exact Pos_congr (genuineLam_four E) h
  · intro h; exact Pos_congr (Req_symm (genuineLam_four E)) h

/-- **The crux's open content, pinned at `n = 4`**: for η₃-anchored data, the crux holds iff the
    coupling is positive at every `n`, and its `n = 4` instance is `Pos Rlambda4` — the concrete
    closed form in `γ, γ₁, γ₂, γ₃, ζ(2), ζ(3), ζ(4), log 4π`. Closing `n = 4` is `Pos Rlambda4` (the
    open numeric frontier); closing all `n` is RH. Never asserted. -/
theorem crux_frontier_n4 (E : StieltjesEta4) :
    (SpectralCrux (genuineSpectralSquare E.toStieltjesEta) ↔
        ∀ n, 0 < n → Pos (Radd (genuineArithSeq E.toStieltjesEta.eta n) (genuineArchSeq n)))
    ∧ (Pos (Radd (genuineArithSeq E.toStieltjesEta.eta 4) (genuineArchSeq 4)) ↔ Pos Rlambda4) :=
  ⟨genuine_crux_arch_coupling E.toStieltjesEta, coupling_n4_iff_pos_lambda4 E⟩

end UOR.Bridge.F1Square.Square
