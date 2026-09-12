/-
F1 square — **the twisted-tail term is Lipschitz in the real dilation scale**
(`TwTermScaleLip.lean`): the per-window twisted-tail term
`twTerm (dilateTestR c φ) n m = ∫_{[m+1, m+2]}(φ(c·x)·powWinTest m n)` is Lipschitz in the REAL scale
`c`, with the rational constant `φ.L·(m+2)·(powWinTest m n).M`.

WHY (rung 6, the tail's atomic continuity fact). `twTail (dilate_c φ) n` is the `Rlim` of finite sums
of these `twTerm` terms. This file records the atomic per-window continuity: each term is a direct
instance of the general-window primitive `window_moment_scale_lipschitz` at the weight
`ψ = powWinTest m n` and the integer window `[m+1, m+2]` (`lo = m+1`, `w = 1`). It is the finite-head
ingredient of the tail's scale-continuity — the whole-tail continuity additionally needs a
UNIFORM-in-scale decay bound across the infinitely many windows (the per-window constant here grows
with `m`, so it is NOT summable): that uniform bound is the unbuilt wall, not supplied here.

HONEST SCOPE. Lipschitz-in-scale of ONE twisted-tail window term only — a direct instance of the
committed `window_moment_scale_lipschitz`, with the constant simplified (`w = 1`,
`(m+1)+1 = m+2`). It builds NO whole-tail continuity (needs uniform-in-scale decay, unbuilt), NO
half-line real-scale covariance, NO factorization, NO positivity, NO determinacy, NO crux. Step 4
(band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.WindowMomentScaleLip
import Foundations.F1.Square.MellinHat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The twisted-tail term is Lipschitz in the real dilation scale.** For real scales `c, c'` each
    bounded by the rational `S`,

      `|twTerm (dilateTestR c φ) n m − twTerm (dilateTestR c' φ) n m| ≤ (φ.L·(m+2)·(powWinTest m n).M)·|c − c'|`.

    A direct instance of `window_moment_scale_lipschitz` at the weight `ψ = powWinTest m n` and the
    integer window `[m+1, m+2]` (`lo = m+1`, `w = 1`), with the constant simplified: the `w = 1` factor
    drops and `(m+1)+1 = m+2`. The atomic per-window continuity of the twisted tail; the whole-tail
    continuity additionally needs a uniform-in-scale decay bound across the windows, not built here. -/
theorem twTerm_scale_lipschitz (φ : L2Test) (n m : Nat)
    (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (c c' : Real) (hcS : Rle (Rabs c) (ofQ S hSd)) (hc'S : Rle (Rabs c') (ofQ S hSd)) :
    Rle (Rabs (Rsub (twTerm (dilateTestR c S hSd hSn hcS φ) n m)
                    (twTerm (dilateTestR c' S hSd hSn hc'S φ) n m)))
        (Rmul (ofQ (mul (mul φ.L (⟨(m : Int) + 2, 1⟩ : Q)) (powWinTest m n).M)
                (Qmul_den_pos (Qmul_den_pos φ.hLd Nat.one_pos) (powWinTest m n).hMd))
          (Rabs (Rsub c c'))) := by
  have hlon : (0 : Int) ≤ (m : Int) + 1 := by omega
  refine Rle_trans
    (window_moment_scale_lipschitz φ (powWinTest m n) S hSd hSn c c' hcS hc'S
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) hlon (by decide)) ?_
  refine Rle_of_Req (Rmul_congr (ofQ_congr _ _ ?_) (Req_refl _))
  simp only [Qeq, mul, add]
  push_cast
  ring_uor

end Multiplicity.UOR.Bridge.F1Square.Square
