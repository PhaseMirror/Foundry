/-
F1 square — **the convolution's Mellin MOMENT factors as the g-weighted dilated moment of `f`**
(`MomentMulConvDilated.lean`): the moment-window (`[0,1]`) analog of `twTerm_mulConv_dilated`. The
compact `[0,1]` piece of the convolution's Mellin transform is the `t`-integral of the `g`-weighted
`[0,1]` moment of the *dilated* `f`:

    `mellinMoment (mulConvRTest f g 1) n  ≈  ∫_t (g(t)·(1/max(t,a))) · mellinMoment (dilateTestR (1/max(t,a)) f) n  dt`.

Crucially — unlike the tail terms — this is a **single** `∫_t` (no sum over windows), so it factors with
NO interchange. Together with `twTerm_mulConv_dilated` (the tail windows), it supplies the per-window
factored form for BOTH pieces of `convMellinHat = moment + tail`; assembling them into
`∫_t W·mellinHat(dilateTestR c_t f)` is the remaining `Σ_m`/`∫_t` interchange.

Same shape as `twTerm_mulConv_dilated`: `mellinConv_fubini` (outer `∫_t`) composed with `riemannIntegralI_congr`
rewriting the inner integral via `dilMellinF_eq_mellinMoment`, plus a `riemannIntegralI_unit` bridge from
`mellinMoment` (a `[0,1]` `riemannIntegral`) to the `[0,1]` `riemannIntegralI` the fubini form uses.

HONEST SCOPE. The moment-window factorization. It builds NO tail assembly, NO `Σ_m`/`∫_t` interchange, NO
covariance application, NO factorization `M[f⋆g]=M[f]·M[g]`, NO positivity, NO crux. The dilated test is
clamped at `1/a`; `f`-decay is not needed here (the moment is a finite `[0,1]` integral). Step 4
(band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MellinConv
import Multiplicity.F1.Square.DilMellinFEval
import Multiplicity.F1.Square.IntervalMinorant

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- **The dilated-moment integrand** `t ↦ (g(t)·(1/max(t,a)))·mellinMoment (dilateTestR (1/max(t,a)) f) n` —
    the moment-window analog of `dilTailIntegrand`. -/
def momIntegrand (f g : L2Test) (n : Nat) (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (t : Real) : Real :=
  Rmul (Rmul (g.f t) (clampedInv a han had t))
    (mellinMoment (dilateTestR (clampedInv a han had t) (Qinv a) (Qinv_den_pos han)
      (Int.le_of_lt (Qinv_num_pos had)) ((recipTest a han had).hbd t) f) n)

/-- **The swapped outer test's value equals the dilated-moment integrand at each `t`** — the `g`-pullout
    `coupOuterTestSwap_gpull` (at the moment weight `powTest n`, window `[0,1]`) composed with
    `dilMellinF_eq_mellinMoment` (the inner `[0,1]` integral is the dilated test's Mellin moment). -/
theorem mom_ptw (f g : L2Test) (n : Nat) (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) (t : Real) :
    Req ((coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).f t)
        (momIntegrand f g n a han had t) :=
  Req_trans
    (coupOuterTestSwap_gpull f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
      (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) t)
    (Rmul_congr (Req_refl _)
      (dilMellinF_eq_mellinMoment f n (⟨1, 1⟩ : Q) Nat.one_pos a han had t (by decide)
        (Qinv a) (Qinv_den_pos han) (Int.le_of_lt (Qinv_num_pos had)) ((recipTest a han had).hbd t)))

/-- **The convolution's Mellin moment factors as the g-weighted dilated moment of `f`.**
    `mellinMoment (mulConvRTest f g 1) n = ∫_t (g(t)·(1/max(t,a)))·mellinMoment (dilateTestR (1/max(t,a)) f) n dt`.
    Composes the `riemannIntegralI_unit` bridge (`mellinMoment` ↔ the `[0,1]` interval integral),
    `mellinConv_fubini` (the outer `∫_t` form), and `riemannIntegralI_congr` rewriting the inner integral
    via `mom_ptw`. A single `∫_t` — the moment piece factors with no window sum. -/
theorem mellinMoment_mulConv_dilated (f g : L2Test) (n : Nat) (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Req (mellinMoment (mulConvRTest f g (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
          lo w hlo hw hwn) n)
        (riemannIntegralI
          (coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLd
          (coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLn
          (fun t t' => Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr
            (Req_symm (mom_ptw f g n a han had lo w hlo hw hwn t))
            (Req_symm (mom_ptw f g n a han had lo w hlo hw hwn t')))))
            ((coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
              (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hlip t t'))
          (fun t t' h => Req_trans
            (Req_symm (mom_ptw f g n a han had lo w hlo hw hwn t))
            (Req_trans ((coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
                (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hfc t t' h)
              (mom_ptw f g n a han had lo w hlo hw hwn t')))
          lo w hlo hw hwn) := by
  refine Req_trans (Req_symm (riemannIntegralI_unit
    (l2L_den (mulConvRTest f g (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had lo w hlo hw hwn)
      (powTest n))
    (l2L_num (mulConvRTest f g (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had lo w hlo hw hwn)
      (powTest n))
    (l2lip (mulConvRTest f g (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had lo w hlo hw hwn)
      (powTest n))
    (l2fc (mulConvRTest f g (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had lo w hlo hw hwn)
      (powTest n)))) ?_
  refine Req_trans
    (mellinConv_fubini f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had lo w hlo hw hwn
      (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)) ?_
  exact riemannIntegralI_congr
    (coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
      (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLd
    (coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
      (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLn
    (coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
      (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hlip
    (coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
      (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hfc
    _ _
    lo w hlo hw hwn
    (fun t => mom_ptw f g n a han had lo w hlo hw hwn t)

end Multiplicity.UOR.Bridge.F1Square.Square
