/-
F1 square — **the constructive Cayley transform** `ρ ↦ 1 − 1/ρ` and its modulus law, the object the
RH witness (`RHWitness.lean`) and the Bombieri–Lagarias pipeline (`Square/BLPipeline.lean`) have so
far handled only ABSTRACTLY (as an opaque "Cayley factor" `w` with an ASSUMED unit modulus on the
line). THIS FILE builds the genuine map and proves the unit-modulus fact, so the pipeline's
`onLine_unit` leg becomes a THEOREM, not a hypothesis.

THE MAP. For a nontrivial zero `ρ` (`ρ ≠ 0`, certified by a positivity witness `k` for `|ρ|²`), the
Li/Keiper Cayley factor is `liRatio ρ = (ρ − 1)·(1/ρ)` with `1/ρ` the constructive complex reciprocal
(`Cinv`, `ComplexInv.lean`). Its squared modulus factors through the multiplicative law:

    |liRatio ρ|² = |ρ−1|² · |1/ρ|²   (`cnormSq_mul`),   and   |ρ|² · |1/ρ|² = 1   (`cnormSq_recip`,
                                                          from `ρ·(1/ρ) = 1`, `Cmul_Cinv`).

THE PAYOFF (no `sqrt`, choice-free). On the critical line `Re ρ = ½` the Li growth-ratio identity
(`liRatio_on_line`, `ZeroGeometry`) gives `|ρ−1|² = |ρ|²`, so

    |liRatio ρ|² = |ρ−1|²·|1/ρ|² = |ρ|²·|1/ρ|² = 1   (`cnormSq_liRatio_on_line`).

This is exactly the witness's antecedent (`witnessTerm_nonneg` needs `|w|² ≤ 1`), now DERIVED from
the geometry rather than assumed: `blZeroSum_ofZeros` (`Square/BLPipeline.lean`) uses it to discharge
`onLine_unit`, shrinking the BL interface to its genuine classical core (the explicit-formula zero-sum
`bl` and its convergence `reg`). It does NOT prove WHERE the zeros are (RH); the crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.LiGrowth
import F1Square.Analysis.ComplexInv

namespace UOR.Bridge.F1Square.Analysis

/-- `cnormSq` respects complex equality `Ceq` (it is `Re² + Im²`, both `Rmul_congr`/`Radd_congr`). -/
theorem cnormSq_congr {z w : Complex} (h : Ceq z w) :
    Req (cnormSq z) (cnormSq w) :=
  Radd_congr (Rmul_congr h.1 h.1) (Rmul_congr h.2 h.2)

/-- **The reciprocal modulus law** `|ρ|² · |1/ρ|² = 1`: take `cnormSq` of the complex inverse law
    `ρ·(1/ρ) = 1` (`Cmul_Cinv`) through the multiplicative modulus (`cnormSq_mul`). No explicit
    `Rinv` algebra is needed — the inverse law carries it. -/
theorem cnormSq_recip (ρ : Complex) (k : Nat)
    (hk : Qlt (Qbound k) ((CnormSq ρ).seq k)) :
    Req (Rmul (cnormSq ρ) (cnormSq (Cinv ρ k hk))) one :=
  Req_trans (Req_symm (cnormSq_mul ρ (Cinv ρ k hk)))
    (Req_trans (cnormSq_congr (Cmul_Cinv ρ k hk)) cnormSq_one)

/-- The squared modulus of `ρ − 1` (built as `Cadd ρ (Cneg Cone)`) is the Li numerator `|ρ−1|²`
    (`csubOneNormSq`). The real parts match definitionally (`Rsub a 1 = Radd a (Rneg 1)`); the
    imaginary correction `Im ρ − 0 = Im ρ` is `Rsub_zero`. -/
theorem cnormSq_sub_one (ρ : Complex) :
    Req (cnormSq (Cadd ρ (Cneg Cone))) (csubOneNormSq ρ) :=
  Radd_congr (Req_refl _) (Rmul_congr (Rsub_zero ρ.im) (Rsub_zero ρ.im))

/-- **The constructive Cayley transform** `liRatio ρ = (ρ − 1)·(1/ρ) = 1 − 1/ρ`, with a positivity
    witness `k` for `|ρ|²` (so `1/ρ` exists). This is the genuine object behind the abstract
    "Cayley factor" of the RH witness. -/
def liRatio (ρ : Complex) (k : Nat) (hk : Qlt (Qbound k) ((CnormSq ρ).seq k)) : Complex :=
  Cmul (Cadd ρ (Cneg Cone)) (Cinv ρ k hk)

/-- **THE UNIT-MODULUS THEOREM** `Re ρ = ½ ⟹ |liRatio ρ|² = 1`. On the critical line `|ρ−1|² = |ρ|²`
    (`liRatio_on_line`), so `|liRatio ρ|² = |ρ−1|²·|1/ρ|² = |ρ|²·|1/ρ|² = 1`. This DERIVES the
    `onLine_unit` leg of the Bombieri–Lagarias interface — the witness's antecedent is a consequence
    of the geometry, not an independent assumption. It does not place the zeros (RH); crux stays
    `none`. -/
theorem cnormSq_liRatio_on_line (ρ : Complex) (k : Nat)
    (hk : Qlt (Qbound k) ((CnormSq ρ).seq k)) (hline : OnCriticalLine ρ) :
    Req (cnormSq (liRatio ρ k hk)) one := by
  refine Req_trans (cnormSq_mul (Cadd ρ (Cneg Cone)) (Cinv ρ k hk)) ?_
  have h1 : Req (cnormSq (Cadd ρ (Cneg Cone))) (cnormSq ρ) :=
    Req_trans (cnormSq_sub_one ρ) (liRatio_on_line ρ hline)
  exact Req_trans (Rmul_congr h1 (Req_refl _)) (cnormSq_recip ρ k hk)

end UOR.Bridge.F1Square.Analysis
