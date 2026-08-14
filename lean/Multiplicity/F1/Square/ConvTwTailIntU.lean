/-
F1 square — **the tail commute discharged: `convTwTail = ∫_t (Whead − Tmom)`** (`ConvTwTailIntU.lean`):
the tail branch of the `∫_t` reconstruction with its covariance-connect `hU` finally SUPPLIED. The
parametric tail commute `convTwTail_eq_intTail` is instantiated at the genuine head/moment test
`U = L2Test.sub Whead Tmom` (`Whead` the head test `g·clamp01ⁿ·M[f]`, `Tmom` the existing
`coupOuterTestSwap` moment test), and `hU` is proved from `covConnect_at_clampedInv` plus the window
inertness of the clamps (`a ≤ lo` makes `clamp01(t) = max(t,a) = t` on `[lo, lo+w] ⊆ (0,1]`):

    `convTwTail f g n  =  ∫_t (Whead.f t − Tmom.f t)  dt`.

WHY (grounding `v = ĝ`). This removes the last free hypothesis from the tail branch: the tail commute
was parametric in `hU` (no `U` supplied); now `U` is the genuine `Whead − Tmom` and `hU` is discharged,
so `convTwTail` is a concrete `∫_t` of built tests. Combined with the moment side
(`mellinMoment_mulConv_dilated`: `mellinMoment(mulConv) = ∫_t Tmom`), `convMellinHat = ∫_t Whead`, whose
window evaluation is `M[f]·(compact moment of g)` — the factorization `M[f⋆g] = M[f]·M[g]` on the window.

HONEST SCOPE. The tail commute at the genuine `U`. It does NOT yet assemble the moment side into the
factorization (that composes this with `mellinMoment_mulConv_dilated` and the `∫Whead` evaluation),
builds NO factorization `M[f⋆g]=M[f]·M[g]` on its own, grounds NO `v = ĝ`, and — emphatically — applies
NO step-4 band-coupling positivity (`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.HeadTest
import Multiplicity.F1Square.Square.CovConnectClampedInv
import Multiplicity.F1Square.Square.MomentMulConvDilated
import Multiplicity.F1Square.Square.DilTailCommute

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- **The tail branch's covariance-connect discharged.** `convTwTail f g n = ∫_t (Whead − Tmom)` where
    `Whead = headTest f g n` and `Tmom = coupOuterTestSwap f g (powTest n) …` (the moment test). The
    parametric `hU` of `convTwTail_eq_intTail` is proved from `covConnect_at_clampedInv` (the per-`t`
    head/moment split) plus the clamps' window inertness (`a ≤ lo`: `clamp01(t) = max(t,a) = t` on the
    window), so the tail branch is now hypothesis-free. -/
theorem convTwTail_eq_intU (f g : L2Test) (n : Nat) {Cf : Q}
    (hCfd : 0 < Cf.den) (hCfn : 0 ≤ Cf.num)
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
      Rle (Rabs (f.f y)) (ofQ (mul Cf (⟨1, (k + 1) ^ (n + 2)⟩ : Q))
        (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos k)))))
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (ha1 : Qle a (⟨1, 1⟩ : Q))
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hw1 : Qle (add lo w) (⟨1, 1⟩ : Q)) (halo : Qle a lo) :
    Req (convTwTail f g n hCfd hCfn hfdec a han had ha1 lo w hlo hw hwn hw1)
        (riemannIntegralI
          (L2Test.sub (headTest f g n hCfd hCfn hfdec)
            (coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
              (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))).hLd
          (L2Test.sub (headTest f g n hCfd hCfn hfdec)
            (coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
              (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))).hLn
          (L2Test.sub (headTest f g n hCfd hCfn hfdec)
            (coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
              (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))).hlip
          (L2Test.sub (headTest f g n hCfd hCfn hfdec)
            (coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
              (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))).hfc
          lo w hlo hw hwn) := by
  refine convTwTail_eq_intTail f g n hCfd hCfn hfdec a han had ha1 lo w hlo hw hwn hw1
    (L2Test.sub (headTest f g n hCfd hCfn hfdec)
      (coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))) ?_
  intro s h0 h1
  -- window bounds for `t = affineMap lo w s ∈ [lo, lo+w] ⊆ [a, 1] ⊆ [0,1]`.
  have hlot : Rle (ofQ lo hlo) (affineMap lo w hlo hw s) :=
    Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ hw hwn) (Rnonneg_of_Rle_zero h0))
  have hat : Rle (ofQ a had) (affineMap lo w hlo hw s) :=
    Rle_trans (Rle_ofQ_ofQ had hlo halo) hlot
  have hQ0a : Qle (⟨0, 1⟩ : Q) a := by simp only [Qle]; omega
  have h0t : Rle (ofQ (⟨0, 1⟩ : Q) (by decide)) (affineMap lo w hlo hw s) :=
    Rle_trans (Rle_ofQ_ofQ (by decide) had hQ0a) hat
  have h1t : Rle (affineMap lo w hlo hw s) (ofQ (⟨1, 1⟩ : Q) (by decide)) := by
    have hws : Rle (Rmul (ofQ w hw) s) (ofQ w hw) :=
      Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hw hwn) h1) (Rle_of_Req (Rmul_one (ofQ w hw)))
    exact Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _)) hws)
      (Rle_trans (Rle_of_Req (Radd_ofQ_ofQ hlo hw))
        (Rle_ofQ_ofQ (add_den_pos hlo hw) (by decide) hw1))
  -- the two clamps are inert on the window, so `clamp01(t) ≈ max(t,a) ≈ t`.
  have hclampeq : Req (clamp01 (affineMap lo w hlo hw s))
      (qClampQ a had (affineMap lo w hlo hw s)) :=
    Req_trans (qBandQ_eq_of_band h0t h1t) (Req_symm (qClampQ_eq_of_ge hat))
  -- `Whead.f t ≈ g·max(t,a)ⁿ·M[f]` (the covConnect head).
  have hWhead : Req ((headTest f g n hCfd hCfn hfdec).f (affineMap lo w hlo hw s))
      (Rmul (Rmul (g.f (affineMap lo w hlo hw s))
              (Rpow (qClampQ a had (affineMap lo w hlo hw s)) n))
            (mellinHat f n hCfd hCfn (hdec_window_of_hfdec f n hCfd hCfn hfdec))) :=
    Req_trans (headTest_f_eq f g n hCfd hCfn hfdec (affineMap lo w hlo hw s))
      (Rmul_congr (Rmul_congr (Req_refl _) (Rpow_congr hclampeq n)) (Req_refl _))
  -- `Tmom.f t ≈ momIntegrand` (the covConnect moment term).
  have hTmom := mom_ptw f g n a han had lo w hlo hw hwn (affineMap lo w hlo hw s)
  -- assemble: `U.f t = Whead.f t − Tmom.f t ≈ head − mom ≈ tail integrand`.
  exact Req_trans (Rsub_congr hWhead hTmom)
    (Req_symm (covConnect_at_clampedInv f g n hCfd hCfn hfdec a han had ha1
      lo w hlo hw hwn hw1 s h1))

end Multiplicity.UOR.Bridge.F1Square.Square
