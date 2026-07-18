/-
F1 square — v0.21.0 stage G, brick **crux frontier `n = 3`**: the next conquerable coefficient of
the coupling, pinned to the concrete closed form `λ₃`.

`atlas_crux_localization` reduced closing the crux in the Atlas to the prime–archimedean coupling
sign `arith(n)+arch(n) > 0` for all `n` — conquered at `n = 1, 2`. The NEXT coefficient is `n = 3`,
and this brick pins it exactly: for η-data anchored through `η₂` (the `γ₂`-bearing third anchor), the
coupling at `n = 3` is positive iff the concrete closed form `Rlambda3` is positive
(`coupling_n3_iff_pos_lambda3`, via `genuineLam_three`). So the `n = 3` conquest IS `Pos Rlambda3`.

WHAT REMAINS (the open numeric frontier, honestly). `Rlambda3 ≈ 0.2076` (the standard Li value),
with `λ₃^arith ≈ +1.22` and `λ₃^∞ ≈ −1.013` — an absolute margin ≈ 0.21, NOT razor-thin. But the
closed form has HEAVY cancellation (the archimedean block `−(3/2)log4π + (9/4)ζ(2) − (7/8)ζ(3) ≈
−3.80 + 3.70 − 1.05` collapses three `Θ(3.8)` constants to `Θ(1)`), so a `Pos Rlambda3` certificate
needs ALL of `γ, γ₁, γ₂, ζ(2), ζ(3), log 4π` to ~0.1–0.3% RELATIVE precision at once. The DOMINANT
loss is `γ₁`, not `γ`: `−6γ₁` is `+0.437` truly, but the existing `γ₁ ≤ −0.0445` (`Rgamma1_le_neg445`)
yields only `+0.267` — burning 0.17 of the margin, an order of magnitude too loose vs. the true
`−0.0728`. The repo has `γ` two-sided (`Rgamma_h_lower/upper`), `γ₁` upper (loose), `γ₂` lower
(`Rgamma2_ge_neg002`), `ζ(2)` lower (`zeta2_lower`), partial `ζ(3)`. STILL MISSING: a TIGHT two-sided
`γ₁` (the bottleneck), a `γ₂` UPPER bound, a `ζ(2)` UPPER bound, and a two-sided `ζ(3)` — each a
`GammaTwoBracket`-scale construction. See the precision analysis in `Analysis/LambdaThree.lean`.

This is genuine progress (the `n = 3` target is now a single concrete `Pos Rlambda3`), and it is
HONEST about the boundary: extending `n` one coefficient at a time conquers more ground but never
closes the crux, which is `∀ n` (= RH); that uniform bound is the irreducible content. The crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `()`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.f1_square.Square.LefschetzCoupling
import Core.f1_square.Analysis.LambdaThree
import Core.f1_square.Analysis.LambdaThreePos

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

/-- **The `n = 3` coupling is exactly `Pos Rlambda3`** (for η-data anchored through `η₂`): through
    `genuineLam_three` (the closed form meets the ladder at `n = 3`), the coupling
    `arith(3) + arch(3)` is positive iff the concrete closed form `Rlambda3` is. So the next
    coefficient of the crux is the single concrete object `Rlambda3`. -/
theorem coupling_n3_iff_pos_lambda3 (E : StieltjesEta3) :
    Pos (Radd (genuineArithSeq E.toStieltjesEta.eta 3) (genuineArchSeq 3)) ↔ Pos Rlambda3 := by
  constructor
  · intro h; exact Pos_congr (genuineLam_three E) h
  · intro h; exact Pos_congr (Req_symm (genuineLam_three E)) h

/-- **The crux's open content, pinned at `n = 3`**: for η₂-anchored data, the crux holds iff the
    coupling is positive at every `n`, and its `n = 3` instance is `Pos Rlambda3` — the concrete
    closed form in `γ, γ₁, γ₂, ζ(2), ζ(3), log 4π`. Closing `n = 3` is `Pos Rlambda3` (the open
    numeric frontier); closing all `n` is RH. Never asserted. -/
theorem crux_frontier_n3 (E : StieltjesEta3) :
    (SpectralCrux (genuineSpectralSquare E.toStieltjesEta) ↔
        ∀ n, 0 < n → Pos (Radd (genuineArithSeq E.toStieltjesEta.eta n) (genuineArchSeq n)))
    ∧ (Pos (Radd (genuineArithSeq E.toStieltjesEta.eta 3) (genuineArchSeq 3)) ↔ Pos Rlambda3) :=
  ⟨genuine_crux_arch_coupling E.toStieltjesEta, coupling_n3_iff_pos_lambda3 E⟩

/-- **`n = 3` CONQUERED**: for η₂-anchored data the prime–archimedean coupling `arith(3) + arch(3)`
    is positive — the third rung of the crux ladder, now kernel-certified via `Rlambda3_pos`
    (`coupling_n3_iff_pos_lambda3` ▸ `Rlambda3_pos`). Joins the conquered `n = 1`
    (`coupling_head_positive`) and `n = 2` (`Rlambda2_pos`). This is `n = 3` ONLY; the crux is the
    uniform `∀ n` (= RH) and stays open (`liPositivityHolds` `none`). -/
theorem coupling_n3_positive (E : StieltjesEta3) :
    Pos (Radd (genuineArithSeq E.toStieltjesEta.eta 3) (genuineArchSeq 3)) :=
  (coupling_n3_iff_pos_lambda3 E).mpr Rlambda3_pos

end UOR.Bridge.F1Square.Square
