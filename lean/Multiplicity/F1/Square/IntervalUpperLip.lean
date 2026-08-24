/-
F1 square — **the window integral is Lipschitz in its upper limit** (`IntervalUpperLip.lean`):

    `|∫_0^q φ − ∫_0^{q'} φ|  ≤  (q − q')·φ.M`   (rational `q ≥ q' > 0`).

Splitting `∫_0^q = ∫_0^{q'} + ∫_{q'}^q` (`riemannIntegralI_split_at`) leaves the difference equal to
the tail `∫_{q'}^q φ`, bounded by the window width `(q − q')` times the test's bound `φ.M`
(`riemannIntegralI_abs_le_window`).

WHY. This is the continuity of the partial integral `q ↦ ∫_0^q φ` in the upper limit — the primitive
that lets the *real*-upper-limit window integral `∫_0^c φ` (`c` a real) be constructed as the `Rlim`
of the rational partials `∫_0^{c.seq k} φ`. That real-window integral is exactly what evaluating the
factorization's inner moment `mellinMoment (dilateTestR c f) n = c^{-(n+1)}·∫_0^c (f·xⁿ)` at a real
scale needs — the wall-breaker for the real-scale dilation covariance.

HONEST SCOPE. One inequality: the partial integral is Lipschitz in its upper limit. It builds NO
real-window integral yet (that is the `Rlim` on top), NO covariance, NO factorization, NO positivity,
NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.IntervalSplitAtCap
import Multiplicity.F1.Analysis.MellinDecay

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `(A + t) − A ≈ t` — pure real-`Radd`/`Rneg` rearrangement. -/
private theorem Rsub_Radd_self_left (A t : Real) : Req (Rsub (Radd A t) A) t :=
  Req_trans (Radd_assoc A t (Rneg A))
    (Req_trans (Radd_congr (Req_refl A) (Radd_comm t (Rneg A)))
      (Req_trans (Req_symm (Radd_assoc A (Rneg A) t))
        (Req_trans (Radd_congr (Radd_neg A) (Req_refl t))
          (Req_trans (Radd_comm zero t) (Radd_zero t)))))

/-- **The window integral is Lipschitz in its upper limit**:
    `|∫_0^q φ − ∫_0^{q'} φ| ≤ (q − q')·φ.M` for rational `q ≥ q' > 0`. -/
theorem riemannIntegralI_upper_lip (φ : L2Test) (q q' : Q)
    (hqd : 0 < q.den) (hqn : 0 ≤ q.num) (hq'd : 0 < q'.den) (hq'n : 0 < q'.num)
    (hq'q : Qle q' q) :
    Rle (Rabs (Rsub
          (riemannIntegralI φ.hLd φ.hLn φ.hlip φ.hfc (⟨0, 1⟩ : Q) q (by decide) hqd hqn)
          (riemannIntegralI φ.hLd φ.hLn φ.hlip φ.hfc (⟨0, 1⟩ : Q) q' (by decide) hq'd
            (Int.le_of_lt hq'n))))
        (ofQ (mul (Qsub q q') φ.M) (Qmul_den_pos (Qsub_den_pos hqd hq'd) φ.hMd)) := by
  have hsub_nn : 0 ≤ (Qsub q q').num := Qsub_num_nonneg hq'q
  have hsplit := riemannIntegralI_split_at φ.hLd φ.hLn φ.hlip φ.hfc (⟨0, 1⟩ : Q) q q'
    (by decide) hqd hqn hq'd hq'n hq'q hsub_nn
  have hcancel : Req
      (Rsub (riemannIntegralI φ.hLd φ.hLn φ.hlip φ.hfc (⟨0, 1⟩ : Q) q (by decide) hqd hqn)
            (riemannIntegralI φ.hLd φ.hLn φ.hlip φ.hfc (⟨0, 1⟩ : Q) q' (by decide) hq'd
              (Int.le_of_lt hq'n)))
      (riemannIntegralI φ.hLd φ.hLn φ.hlip φ.hfc (add (⟨0, 1⟩ : Q) q') (Qsub q q')
          (add_den_pos (by decide) hq'd) (Qsub_den_pos hqd hq'd) hsub_nn) :=
    Req_trans (Rsub_congr hsplit (Req_refl _))
      (Rsub_Radd_self_left _ _)
  refine Rle_trans (Rle_of_Req (Rabs_congr hcancel)) ?_
  exact riemannIntegralI_abs_le_window φ.hLd φ.hLn φ.hlip φ.hfc
    (add (⟨0, 1⟩ : Q) q') (Qsub q q') φ.M
    (add_den_pos (by decide) hq'd) (Qsub_den_pos hqd hq'd) hsub_nn φ.hMd
    (fun x _ _ => φ.hbd (affineMap (add (⟨0, 1⟩ : Q) q') (Qsub q q')
      (add_den_pos (by decide) hq'd) (Qsub_den_pos hqd hq'd) x))

end Multiplicity.UOR.Bridge.F1Square.Square
