/-
F1 square — **the covConnect at the genuine reconstruction scale** (`CovConnectClampedInv.lean`): the
covConnect algebra `covConnect_pure` instantiated at `c = clampedInv(a,t)`, `T = qClampQ a t = max(t,a)`,
so the tail commute's per-`t` integrand is EXACTLY the head/moment difference of two window tests:

    `g(t)·clampedInv(a,t)·twTail(dilateTestR (clampedInv a t) f)
        ≈  g(t)·max(t,a)ⁿ·mellinHat f  −  g(t)·clampedInv(a,t)·mellinMoment(dilateTestR (clampedInv a t) f)`.

WHY (grounding `v = ĝ`). This is the covConnect the tail commute's `hU` needs: the LHS is `hU`'s target
integrand verbatim, and the RHS is `Whead − Tmom` — the head `Whead.f t = g·max(t,a)ⁿ·mellinHat f` (the
`M[f]` factor pulled out) and the moment `Tmom.f t = g·clampedInv·mellinMoment(dilate f)`. Both inputs are
already discharged: `hcov` is `covariance_at_clampedInv` (matching `hU`'s Mellin term), and the reciprocal
`T·c = 1` is `Rmul_Rinv_self (qClampQ_witness …)` (`clampedInv = Rinv(qClampQ …)` by definition).

HONEST SCOPE. Object-grounding substrate — the per-`t` head/moment split at the genuine scale. It builds
the tests `Whead`/`Tmom` as OBJECTS nowhere yet (that assembles `U` and feeds the tail commute), builds
NO factorization `M[f⋆g]=M[f]·M[g]`, grounds NO `v = ĝ`, and — emphatically — applies NO step-4
band-coupling positivity (`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.CovarianceAtClampedInv
import Foundations.F1.Square.CovConnectPure
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The covConnect at `c = clampedInv(a,t)`.** For a window point `t = affineMap lo w s`, the tail
    commute's per-`t` integrand `g·clampedInv·twTail(dilate clampedInv f)` equals the head/moment
    difference `g·max(t,a)ⁿ·mellinHat f  −  g·clampedInv·mellinMoment(dilate clampedInv f)`. Built from
    `covConnect_pure` with `hcov = covariance_at_clampedInv` and the reciprocal
    `T·c = Rmul_Rinv_self (qClampQ_witness …)`. -/
theorem covConnect_at_clampedInv (f g : L2Test) (n : Nat) {Cf : Q}
    (hCfd : 0 < Cf.den) (hCfn : 0 ≤ Cf.num)
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
      Rle (Rabs (f.f y)) (ofQ (mul Cf (⟨1, (k + 1) ^ (n + 2)⟩ : Q))
        (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos k)))))
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (ha1 : Qle a (⟨1, 1⟩ : Q))
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hw1 : Qle (add lo w) (⟨1, 1⟩ : Q))
    (s : Real) (h1 : Rle s one) :
    Req (Rmul (Rmul (g.f (affineMap lo w hlo hw s))
                (clampedInv a han had (affineMap lo w hlo hw s)))
              (twTail (dilateTestR (clampedInv a han had (affineMap lo w hlo hw s)) (Qinv a)
                  (Qinv_den_pos han) (Int.le_of_lt (Qinv_num_pos had))
                  ((recipTest a han had).hbd (affineMap lo w hlo hw s)) f)
                n hCfd hCfn
                (dilateTestR_window_hdec f n hCfd hCfn hfdec
                  (clampedInv a han had (affineMap lo w hlo hw s)) (Qinv a)
                  (Qinv_den_pos han) (Int.le_of_lt (Qinv_num_pos had))
                  ((recipTest a han had).hbd (affineMap lo w hlo hw s))
                  (window_clampedInv_ge_one a han had ha1 lo w hlo hw hwn hw1 s h1))))
        (Rsub
          (Rmul (Rmul (g.f (affineMap lo w hlo hw s))
                  (Rpow (qClampQ a had (affineMap lo w hlo hw s)) n))
                (mellinHat f n hCfd hCfn (hdec_window_of_hfdec f n hCfd hCfn hfdec)))
          (Rmul (Rmul (g.f (affineMap lo w hlo hw s))
                  (clampedInv a han had (affineMap lo w hlo hw s)))
                (mellinMoment (dilateTestR (clampedInv a han had (affineMap lo w hlo hw s)) (Qinv a)
                    (Qinv_den_pos han) (Int.le_of_lt (Qinv_num_pos had))
                    ((recipTest a han had).hbd (affineMap lo w hlo hw s)) f) n))) :=
  covConnect_pure n
    (covariance_at_clampedInv f n hCfd hCfn hfdec a han had ha1 lo w hlo hw hwn hw1 s h1)
    (Rmul_Rinv_self (qClampQ_witness a han had (affineMap lo w hlo hw s)))

end Multiplicity.UOR.Bridge.F1Square.Square
