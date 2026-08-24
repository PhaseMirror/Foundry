/-
F1 square — **the twisted-tail finite partial sum is Lipschitz in the real dilation scale**
(`TailPartialScaleLip.lean`): the finite head `genSum (twTerm (dilateTestR c φ) n) N` of the twisted
tail is Lipschitz in the REAL scale `c`, with the (finite, `N`-dependent) rational constant
`Σ_{m<N} φ.L·(m+2)·(powWinTest m n).M`.

WHY (rung 6, the tail's finite-head continuity). `twTail (dilate_c φ) n` is the `Rlim` over `N` of
these finite partial sums. This file composes the atomic per-window bound `twTerm_scale_lipschitz`
across the sum: the difference of two partial sums is the partial sum of the per-window differences
(`genSum_Rsub`), the finite triangle bounds it by the partial sum of the per-window absolute
differences (`genSum_Rabs_le`), each of which is `≤` its per-window Lipschitz bound
(`genSum_le_genSum` + `twTerm_scale_lipschitz`), and the common factor `|c−c'|` pulls out
(`genSum_Rmul_const_right`).

THE WALL. The per-window constant `φ.L·(m+2)·(powWinTest m n).M` GROWS with `m`, so the partial-sum
constant `Σ_{m<N} …` grows with `N` and does NOT converge — the whole tail `twTail (dilate_c φ) n` is
therefore NOT Lipschitz in `c` this way. Whole-tail scale-CONTINUITY (weaker than Lipschitz) would
combine this finite-head continuity with a UNIFORM-in-scale decay bound controlling the `m ≥ N`
remainder; that uniform bound is the unbuilt analytic wall, not supplied here.

HONEST SCOPE. Lipschitz-in-scale of the FINITE partial sum only, with an `N`-growing constant. It
builds NO whole-tail continuity (needs the uniform-in-scale decay remainder bound, unbuilt), NO
half-line real-scale covariance, NO factorization, NO positivity, NO determinacy, NO crux. Step 4
(band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.TwTermScaleLip
import Multiplicity.F1.Analysis.ThetaLipschitzFn
import Multiplicity.F1.Analysis.ImproperIntegral

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The finite-sum triangle inequality for `genSum`** `|genSum T N| ≤ genSum (fun m => |T m|) N` —
    the `genSum` analog of `RsumN_Rabs_le`, by the same induction (`Rabs_Radd` at each step). -/
private theorem genSum_Rabs_le (T : Nat → Real) :
    ∀ N, Rle (Rabs (genSum T N)) (genSum (fun m => Rabs (T m)) N)
  | 0 => Rle_of_Req Rabs_zero
  | (N + 1) =>
      Rle_trans (Rabs_Radd (genSum T N) (T N))
        (Radd_le_add (genSum_Rabs_le T N) (Rle_of_Req (Req_refl _)))

/-- **The twisted-tail finite partial sum is Lipschitz in the real dilation scale.** For real scales
    `c, c'` each bounded by the rational `S`,

      `|genSum (twTerm (dilateTestR c φ) n) N − genSum (twTerm (dilateTestR c' φ) n) N|
            ≤ (Σ_{m<N} φ.L·(m+2)·(powWinTest m n).M) · |c − c'|`.

    Composes `twTerm_scale_lipschitz` across the sum: `genSum_Rsub` turns the difference of sums into
    the sum of differences, `genSum_Rabs_le` applies the finite triangle, `genSum_le_genSum` feeds each
    per-window Lipschitz bound, and `genSum_Rmul_const_right` pulls the common `|c−c'|` out. The
    finite-head continuity of the twisted tail; the constant grows with `N` (per-window constant grows
    with `m`), so this does NOT extend to whole-tail Lipschitz — that needs a uniform-in-scale decay
    remainder bound, not built here. -/
theorem genSum_twTerm_scale_lipschitz (φ : L2Test) (n N : Nat)
    (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (c c' : Real) (hcS : Rle (Rabs c) (ofQ S hSd)) (hc'S : Rle (Rabs c') (ofQ S hSd)) :
    Rle (Rabs (Rsub (genSum (twTerm (dilateTestR c S hSd hSn hcS φ) n) N)
                    (genSum (twTerm (dilateTestR c' S hSd hSn hc'S φ) n) N)))
        (Rmul (genSum (fun m => ofQ (mul (mul φ.L (⟨(m : Int) + 2, 1⟩ : Q)) (powWinTest m n).M)
                (Qmul_den_pos (Qmul_den_pos φ.hLd Nat.one_pos) (powWinTest m n).hMd)) N)
          (Rabs (Rsub c c'))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm
    (genSum_Rsub (twTerm (dilateTestR c S hSd hSn hcS φ) n)
      (twTerm (dilateTestR c' S hSd hSn hc'S φ) n) N)))) ?_
  refine Rle_trans (genSum_Rabs_le
    (fun m => Rsub (twTerm (dilateTestR c S hSd hSn hcS φ) n m)
                   (twTerm (dilateTestR c' S hSd hSn hc'S φ) n m)) N) ?_
  refine Rle_trans (genSum_le_genSum
    (fun m => twTerm_scale_lipschitz φ n m S hSd hSn c c' hcS hc'S) N) ?_
  exact Rle_of_Req (genSum_Rmul_const_right
    (fun m => ofQ (mul (mul φ.L (⟨(m : Int) + 2, 1⟩ : Q)) (powWinTest m n).M)
      (Qmul_den_pos (Qmul_den_pos φ.hLd Nat.one_pos) (powWinTest m n).hMd))
    (Rabs (Rsub c c')) N)

end Multiplicity.UOR.Bridge.F1Square.Square
