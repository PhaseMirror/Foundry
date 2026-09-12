/-
F1 square — **the `g`-pullout of the swapped convolution–Mellin inner integral**
(`MellinConvGPull.lean`): the Fubini-swapped object `coupOuterTestSwap.f t = ∫ₓ coupIntegrand(x,t) dx`
has an `x`-constant weight buried in its integrand. This file factors that weight out.

The swapped coupled integrand at fixed `t` splits into an `x`-constant part and an `x`-dependent part:

    `coupIntegrand(x,t) = f(clamp x·clampedInv(a,t))·g(t)·clampedInv(a,t)·ψ(x)`
                        = W(t) · D(x,t),
    `W(t) := g(t)·clampedInv(a,t)`            (constant in `x`),
    `D(x,t) := f(clamp x·clampedInv(a,t))·ψ(x)` (the dilated-Mellin-of-`f` integrand).

`coupOuterTestSwap_gpull` regroups `coupIntegrand` by scalar `Rmul` associativity/commutativity
(`gpull_regroup`), then pulls the real constant `W(t)` out of the `x`-window integral with the
interval real-scalar law `riemannIntegralI_Rsmul` — reconciling the working modulus by
`lip_weaken`/`riemannIntegralI_certif_irrel`, exactly the mirror of the per-`x` weight pullout in
`MellinConvFubini`. The isolated inner integral is bundled as `dilMellinF`, the dilated Mellin of `f`
at scale `clampedInv(a,t)` (its own `x`-Lipschitz certificate is the product bound `Rmul_lipschitz`
of the `1`-Lipschitz band clamp against `ψ`). `mellinConv_gpull` composes this with
`mellinConv_fubini` to rewrite the whole double integral in the pulled-out form.

HONEST SCOPE. The `g`-pullout — factoring the `x`-constant weight `g(t)·clampedInv(a,t)` out of the
swapped inner `x`-integral, isolating the dilated-Mellin-of-`f` object `dilMellinF`. A scalar-linearity
regrouping inheriting from `mellinConv_fubini`; it evaluates NO integral, proves NO dilation
covariance, builds NO limit, NO positivity, NO determinacy, NO crux. The inner `∫ₓ` is left as `dilMellinF`
(the later half-line dilation-covariance step evaluates it as a multiple of `M[f]`). Step 4
(band-coupling positivity) is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MellinConvFubini
import Foundations.F1.Analysis.RmulLipschitz
import Foundations.F1.Analysis.IntervalRsmul

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- **The four-factor regroup** `((A·G)·c)·d ≈ (G·c)·(A·d)` — a pure real-`Rmul`
    associativity/commutativity rearrangement (both sides are the product of `A,G,c,d`). It moves the
    `x`-constant weight `G·c` to the front of the swapped coupled integrand. -/
private theorem gpull_regroup (A G c d : Real) :
    Req (Rmul (Rmul (Rmul A G) c) d) (Rmul (Rmul G c) (Rmul A d)) :=
  Req_trans
    (Req_trans (Rmul_assoc (Rmul A G) c d) (Rmul_assoc A G (Rmul c d)))
    (Req_trans
      (Rmul_congr (Req_refl A)
        (Req_trans (Req_symm (Rmul_assoc G c d)) (Rmul_comm (Rmul G c) d)))
      (Req_trans (Req_symm (Rmul_assoc A d (Rmul G c)))
        (Rmul_comm (Rmul A d) (Rmul G c))))

/-- **The dilated-Mellin-of-`f` integrand** `D(x,t) = f(clamp x·clampedInv(a,t))·ψ(x)` — the
    `x`-dependent part of the swapped coupled integrand, once the `x`-constant weight
    `g(t)·clampedInv(a,t)` is removed. A total `Real → Real` in the integration variable `x`. -/
def dilIntegrand (f ψ : L2Test) (S : Q) (hSd : 0 < S.den)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (t : Real) : Real → Real :=
  fun x => Rmul (f.f (Rmul (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x) (clampedInv a han had t)))
    (ψ.f x)

/-- The dilated-Mellin integrand's Lipschitz modulus `f.M·ψ.L + ψ.M·(f.L·(1/a))` — the product
    constant of the `(f.L·(1/a))`-Lipschitz clamped `f`-dilation against `ψ`. -/
def dilLx (f ψ : L2Test) (a : Q) (han : 0 < a.num) (had : 0 < a.den) : Q :=
  add (mul f.M ψ.L) (mul ψ.M (mul f.L (Qinv a)))

theorem dilLx_den (f ψ : L2Test) (a : Q) (han : 0 < a.num) (had : 0 < a.den) :
    0 < (dilLx f ψ a han had).den :=
  add_den_pos (Qmul_den_pos f.hMd ψ.hLd)
    (Qmul_den_pos ψ.hMd (Qmul_den_pos f.hLd (Qinv_den_pos han)))

theorem dilLx_num (f ψ : L2Test) (a : Q) (han : 0 < a.num) (had : 0 < a.den) :
    0 ≤ (dilLx f ψ a han had).num :=
  Rmul_lip_const_nonneg (Int.mul_nonneg f.hLn (Int.le_of_lt (Qinv_num_pos had)))
    ψ.hLn f.hMn ψ.hMn

/-- **The clamped `f`-dilation is `(f.L·(1/a))`-Lipschitz in `x`** — `|f(clamp x·c) − f(clamp x'·c)| ≤
    ofQ(f.L·(1/a))·|x − x'|`, where `c = clampedInv(a,t)` is a fixed real with `|c| ≤ 1/a`: the
    `1`-Lipschitz band clamp, the `|c| ≤ 1/a` bound, and `f`'s slope `f.L`. The `x`-difference core of
    the dilated-Mellin integrand. -/
private theorem dilIntegrand_A_lipX (f : L2Test) (S : Q) (hSd : 0 < S.den)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (t : Real) (x x' : Real) :
    Rle (Rabs (Rsub
          (f.f (Rmul (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x) (clampedInv a han had t)))
          (f.f (Rmul (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x') (clampedInv a han had t)))))
        (Rmul (ofQ (mul f.L (Qinv a)) (Qmul_den_pos f.hLd (Qinv_den_pos han)))
          (Rabs (Rsub x x'))) := by
  have hc : Rle (Rabs (clampedInv a han had t)) (ofQ (Qinv a) (Qinv_den_pos han)) :=
    (recipTest a han had).hbd t
  have hinner : Rle (Rabs (Rsub
        (Rmul (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x) (clampedInv a han had t))
        (Rmul (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x') (clampedInv a han had t))))
      (Rmul (ofQ (Qinv a) (Qinv_den_pos han)) (Rabs (Rsub x x'))) := by
    refine Rle_trans (Rle_of_Req (Req_trans
      (Rabs_congr (Req_symm (Rmul_sub_distrib_right
        (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x)
        (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x') (clampedInv a han had t))))
      (Rabs_Rmul (Rsub (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x)
        (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x')) (clampedInv a han had t)))) ?_
    refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs (clampedInv a han had t))
      (qBandQ_lipschitz (⟨0, 1⟩ : Q) S (by decide) hSd x x')) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_Rabs (Rsub x x')) hc) ?_
    exact Rle_of_Req (Rmul_comm (Rabs (Rsub x x')) (ofQ (Qinv a) (Qinv_den_pos han)))
  refine Rle_trans (f.hlip (Rmul (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x) (clampedInv a han had t))
    (Rmul (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x') (clampedInv a han had t))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ f.hLd f.hLn) hinner) ?_
  exact Rle_of_Req (Req_trans
    (Req_symm (Rmul_assoc (ofQ f.L f.hLd) (ofQ (Qinv a) (Qinv_den_pos han)) (Rabs (Rsub x x'))))
    (Rmul_congr (Rmul_ofQ_ofQ f.hLd (Qinv_den_pos han)) (Req_refl _)))

/-- **The dilated-Mellin integrand is `dilLx`-Lipschitz in `x`** — the product-Lipschitz estimate
    (`Rmul_lipschitz`) of the clamped `f`-dilation (`dilIntegrand_A_lipX`) against `ψ`. -/
theorem dilIntegrand_lipX (f ψ : L2Test) (S : Q) (hSd : 0 < S.den)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (t : Real) :
    ∀ x x', Rle (Rabs (Rsub (dilIntegrand f ψ S hSd a han had t x)
        (dilIntegrand f ψ S hSd a han had t x')))
      (Rmul (ofQ (dilLx f ψ a han had) (dilLx_den f ψ a han had)) (Rabs (Rsub x x'))) :=
  fun x x' =>
    Rmul_lipschitz
      (f := fun x => f.f (Rmul (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x) (clampedInv a han had t)))
      (g := ψ.f) (Lf := mul f.L (Qinv a)) (Lg := ψ.L) (Mf := f.M) (Mg := ψ.M)
      (Qmul_den_pos f.hLd (Qinv_den_pos han)) ψ.hLd f.hMd ψ.hMd
      (Int.mul_nonneg f.hLn (Int.le_of_lt (Qinv_num_pos had))) ψ.hLn f.hMn ψ.hMn
      (fun x x' => dilIntegrand_A_lipX f S hSd a han had t x x')
      (fun x x' => ψ.hlip x x')
      (fun x => f.hbd (Rmul (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x) (clampedInv a han had t)))
      (fun x => ψ.hbd x) x x'

/-- **The dilated-Mellin integrand's `x`-congruence** — `x ≈ x' ⟹ D(x,t) ≈ D(x',t)`: `f`'s
    congruence through the `1`-Lipschitz band clamp, times `ψ`'s own congruence. -/
theorem dilIntegrand_fcX (f ψ : L2Test) (S : Q) (hSd : 0 < S.den)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (t : Real) (x x' : Real) (h : Req x x') :
    Req (dilIntegrand f ψ S hSd a han had t x) (dilIntegrand f ψ S hSd a han had t x') :=
  Rmul_congr
    (f.hfc _ _ (Rmul_congr (qBandQ_congr (⟨0, 1⟩ : Q) S (by decide) hSd h)
      (Req_refl (clampedInv a han had t)))) (ψ.hfc x x' h)

/-- **The dilated Mellin of `f` at scale `clampedInv(a,t)`** `dilMellinF f ψ S a t =
    ∫ₓ f(clamp x·clampedInv(a,t))·ψ(x) dx` over `[xlo, xlo+xw]` — the isolated `x`-dependent inner
    integral produced by the `g`-pullout. NOT yet evaluated as a multiple of `M[f]`; that is the
    separate half-line dilation-covariance step. -/
def dilMellinF (f ψ : L2Test) (S : Q) (hSd : 0 < S.den)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (t : Real)
    (xlo xw : Q) (hxlo : 0 < xlo.den) (hxw : 0 < xw.den) (hxwn : 0 ≤ xw.num) : Real :=
  riemannIntegralI (dilLx_den f ψ a han had) (dilLx_num f ψ a han had)
    (dilIntegrand_lipX f ψ S hSd a han had t)
    (fun x x' h => dilIntegrand_fcX f ψ S hSd a han had t x x' h)
    xlo xw hxlo hxw hxwn

/-- **The swapped coupled integrand factors** `coupIntegrand(x,t) ≈ (g(t)·clampedInv(a,t))·D(x,t)` —
    the pointwise `g`-pullout at fixed `(x,t)`, the four-factor regroup `gpull_regroup` on the
    definitional product `f(clamp x·c)·g(t)·c·ψ(x)`. -/
private theorem coupIntegrand_gpull (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (t x : Real) :
    Req (coupIntegrand f g ψ S hSd hSn a han had x t)
      (Rmul (Rmul (g.f t) (clampedInv a han had t)) (dilIntegrand f ψ S hSd a han had t x)) :=
  gpull_regroup
    (f.f (Rmul (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x) (clampedInv a han had t)))
    (g.f t) (clampedInv a han had t) (ψ.f x)

/-- **The `g`-pullout of the swapped inner `x`-integral** —
    `coupOuterTestSwap.f t ≈ (g(t)·clampedInv(a,t)) · dilMellinF f ψ S a t`. The `x`-constant weight
    `W(t) = g(t)·clampedInv(a,t)` is pulled out of `∫ₓ coupIntegrand(x,t) dx` by the interval
    real-scalar law `riemannIntegralI_Rsmul`: regroup the integrand to `W(t)·D(x,t)`
    (`coupIntegrand_gpull`), reconcile onto the working modulus `couLx + dilLx`
    (`lip_weaken`/`riemannIntegralI_certif_irrel`), pull `W(t)` out, and return `D`'s integral to its
    own certificate as `dilMellinF`. A scalar-linearity regrouping: no integral evaluation, no
    dilation covariance, no crux. -/
theorem coupOuterTestSwap_gpull (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (xlo xw : Q) (hxlo : 0 < xlo.den)
    (hxw : 0 < xw.den) (hxwn : 0 ≤ xw.num) (t : Real) :
    Req ((coupOuterTestSwap f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn).f t)
        (Rmul (Rmul (g.f t) (clampedInv a han had t))
          (dilMellinF f ψ S hSd a han had t xlo xw hxlo hxw hxwn)) := by
  have Ld : 0 < (add (couLx f g ψ S hSd hSn a han had) (dilLx f ψ a han had)).den :=
    add_den_pos (couLx_den f g ψ S hSd hSn a han had) (dilLx_den f ψ a han had)
  have Ln : 0 ≤ (add (couLx f g ψ S hSd hSn a han had) (dilLx f ψ a han had)).num :=
    Qadd_num_nonneg_loc (couLx_num f g ψ S hSd hSn a han had) (dilLx_num f ψ a han had)
  have hcoup_fc : ∀ (y y' : Real), Req y y' →
      Req (coupIntegrand f g ψ S hSd hSn a han had y t)
          (coupIntegrand f g ψ S hSd hSn a han had y' t) :=
    fun y y' h => coup_fcX f g ψ S hSd hSn a han had y y' t h
  have hcoup_star := lip_weaken (couLx_den f g ψ S hSd hSn a han had) Ld
    (Qle_self_add (dilLx_num f ψ a han had))
    (fun y y' => coup_lipX f g ψ S hSd hSn a han had y y' t)
  have hDfun_star := lip_weaken (dilLx_den f ψ a han had) Ld
    (Qle_self_add_l (couLx_num f g ψ S hSd hSn a han had))
    (dilIntegrand_lipX f ψ S hSd a han had t)
  have hscaled_star : ∀ x x',
      Rle (Rabs (Rsub
          (Rmul (Rmul (g.f t) (clampedInv a han had t)) (dilIntegrand f ψ S hSd a han had t x))
          (Rmul (Rmul (g.f t) (clampedInv a han had t)) (dilIntegrand f ψ S hSd a han had t x'))))
        (Rmul (ofQ (add (couLx f g ψ S hSd hSn a han had) (dilLx f ψ a han had)) Ld)
          (Rabs (Rsub x x'))) :=
    fun x x' => Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr
      (Req_symm (coupIntegrand_gpull f g ψ S hSd hSn a han had t x))
      (Req_symm (coupIntegrand_gpull f g ψ S hSd hSn a han had t x')))))
      (hcoup_star x x')
  have hscaled_fc : ∀ (x x' : Real), Req x x' →
      Req (Rmul (Rmul (g.f t) (clampedInv a han had t)) (dilIntegrand f ψ S hSd a han had t x))
          (Rmul (Rmul (g.f t) (clampedInv a han had t)) (dilIntegrand f ψ S hSd a han had t x')) :=
    fun x x' h => Rmul_congr (Req_refl (Rmul (g.f t) (clampedInv a han had t)))
      (dilIntegrand_fcX f ψ S hSd a han had t x x' h)
  have s1 := riemannIntegralI_certif_irrel (couLx_den f g ψ S hSd hSn a han had)
    (couLx_num f g ψ S hSd hSn a han had)
    (fun y y' => coup_lipX f g ψ S hSd hSn a han had y y' t) hcoup_fc
    Ld Ln hcoup_star hcoup_fc xlo xw hxlo hxw hxwn
  have s2 := riemannIntegralI_congr Ld Ln hcoup_star hcoup_fc hscaled_star hscaled_fc
    xlo xw hxlo hxw hxwn
    (fun x => coupIntegrand_gpull f g ψ S hSd hSn a han had t x)
  have s3 := riemannIntegralI_Rsmul (Rmul (g.f t) (clampedInv a han had t)) Ld Ln
    hDfun_star (fun x x' h => dilIntegrand_fcX f ψ S hSd a han had t x x' h)
    hscaled_star hscaled_fc xlo xw hxlo hxw hxwn
  have s4 := riemannIntegralI_certif_irrel Ld Ln hDfun_star
    (fun x x' h => dilIntegrand_fcX f ψ S hSd a han had t x x' h)
    (dilLx_den f ψ a han had) (dilLx_num f ψ a han had)
    (dilIntegrand_lipX f ψ S hSd a han had t)
    (fun x x' h => dilIntegrand_fcX f ψ S hSd a han had t x x' h)
    xlo xw hxlo hxw hxwn
  exact Req_trans s1 (Req_trans s2 (Req_trans s3
    (Rmul_congr (Req_refl (Rmul (g.f t) (clampedInv a han had t))) s4)))

/-- **The pulled-out convolution–Mellin double integral** — `mellinConv f g ψ ≈ ∫ₜ (g(t)·clampedInv(a,t))·
    dilMellinF f ψ S a t dt`. Composes `mellinConv_fubini` (the `t`-outer form) with the per-`t` weight
    pullout `coupOuterTestSwap_gpull`, transported to the `t`-window integral by `riemannIntegralI_congr`
    (the target integrand inherits its `t`-Lipschitz / congruence certificate from `coupOuterTestSwap`).
    No integral evaluation, no dilation covariance, no crux. -/
theorem mellinConv_gpull (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den)
    (hwn : 0 ≤ w.num) (xlo xw : Q) (hxlo : 0 < xlo.den) (hxw : 0 < xw.den) (hxwn : 0 ≤ xw.num) :
    Req (mellinConv f g ψ S hSd hSn a han had lo w hlo hw hwn xlo xw hxlo hxw hxwn)
        (riemannIntegralI
          (coupOuterTestSwap f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn).hLd
          (coupOuterTestSwap f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn).hLn
          (fun t t' => Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr
            (Req_symm (coupOuterTestSwap_gpull f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn t))
            (Req_symm (coupOuterTestSwap_gpull f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn t')))))
            ((coupOuterTestSwap f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn).hlip t t'))
          (fun t t' h => Req_trans
            (Req_symm (coupOuterTestSwap_gpull f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn t))
            (Req_trans ((coupOuterTestSwap f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn).hfc t t' h)
              (coupOuterTestSwap_gpull f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn t')))
          lo w hlo hw hwn) :=
  Req_trans
    (mellinConv_fubini f g ψ S hSd hSn a han had lo w hlo hw hwn xlo xw hxlo hxw hxwn)
    (riemannIntegralI_congr
      (coupOuterTestSwap f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn).hLd
      (coupOuterTestSwap f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn).hLn
      (coupOuterTestSwap f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn).hlip
      (coupOuterTestSwap f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn).hfc
      (fun t t' => Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr
        (Req_symm (coupOuterTestSwap_gpull f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn t))
        (Req_symm (coupOuterTestSwap_gpull f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn t')))))
        ((coupOuterTestSwap f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn).hlip t t'))
      (fun t t' h => Req_trans
        (Req_symm (coupOuterTestSwap_gpull f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn t))
        (Req_trans ((coupOuterTestSwap f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn).hfc t t' h)
          (coupOuterTestSwap_gpull f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn t')))
      lo w hlo hw hwn
      (fun t => coupOuterTestSwap_gpull f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn t))

end Multiplicity.UOR.Bridge.F1Square.Square
