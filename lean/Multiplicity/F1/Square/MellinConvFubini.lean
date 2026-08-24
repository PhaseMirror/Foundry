/-
F1 square — **the windowed Fubini swap of the convolution–Mellin pairing** (`MellinConvFubini.lean`):
applies the already-proven windowed 2D-Bernstein swap `bern2D_general_swap_window` to the object
`mellinConv f g ψ = ∫ₓ (f⋆g)(x)·ψ(x) dx`.

Two parts, both purely structural:

- `mellinConv_eq_paramInt` (Part A) — the **structural identity** that `mellinConv` is the `x`-outer
  double integral of the coupled `(x,t)` integrand `coupIntegrand`. Per outer point `x`, the inner
  window integral of `coupIntegrand x = (couTest x)·ψ(x)` pulls out the `t`-constant weight `ψ(x)`
  (interval real-scalar linearity, `riemannIntegralI_Rsmul`, reconciled across certificates by
  `riemannIntegralI_certif_irrel`), leaving `∫ₜ (couTest x)(t) dt = (f⋆g)(x) = mulConvRTest.f x`. So the
  parametric inner integral agrees pointwise with the `mellinConv` integrand, and integrating in `x`
  (`riemannIntegralI_congr`) gives the identity.

- `mellinConv_fubini` (Part B) — the **swap**: feeding the coupled-integrand regularity witnesses
  (`coup_lipY/coup_fcY/coup_lipX/coup_fcX/coup_lip/coup_bd`) to `bern2D_general_swap_window` at the
  outer `x`-window `[xlo, xlo+xw]` and inner `t`-window `[lo, lo+w]` turns the `x`-outer double integral
  into the `t`-outer / `x`-inner double integral of the transposed integrand.

HONEST SCOPE. The Fubini swap of the convolution–Mellin pairing `mellinConv` at the finite-window
level — the structural identity that `mellinConv` is the `x`-outer double integral of `coupIntegrand`,
plus the `t`-outer form via `bern2D_general_swap_window`. It inherits from the windowed swap and the
coupled-integrand regularity; it builds NO new limit, NO factorization, NO positivity, NO determinacy,
NO crux. It does NOT evaluate the inner `x`-integral (the later dilation-covariance step). Step 4
(band-coupling positivity) is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.ConvMellinIntegrand
import Multiplicity.F1.Square.Bern2DWindowSwap
import Multiplicity.F1.Square.MellinLinear
import Multiplicity.F1.Analysis.IntervalRsmul

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- **Pull a `t`-constant real weight out of a window integral of a scaled test** — for a test `T` in
    `t` and a real constant `c`, `∫ₜ (T.f t · c) dt = (∫ₜ T.f t dt)·c`, where the left integral runs at
    any modulus `L` carrying the certificate of the scaled integrand `t ↦ T.f t · c`. The proof pushes
    both integrands to a common modulus `L + T.L`, commutes the scalar to the left, applies the interval
    real-scalar law `riemannIntegralI_Rsmul`, and returns to `T`'s own certificate; the value is
    certificate-independent throughout. The scalar-linearity core of the per-`x` convolution identity. -/
private theorem intI_pull_right (T : L2Test) (c : Real) (L : Q) (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipH : ∀ y y', Rle (Rabs (Rsub (Rmul (T.f y) c) (Rmul (T.f y') c)))
        (Rmul (ofQ L hLd) (Rabs (Rsub y y'))))
    (hfcH : ∀ y y', Req y y' → Req (Rmul (T.f y) c) (Rmul (T.f y') c))
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Req (riemannIntegralI hLd hLn hlipH hfcH lo w hlo hw hwn)
        (Rmul (riemannIntegralI T.hLd T.hLn T.hlip T.hfc lo w hlo hw hwn) c) := by
  have Lsd : 0 < (add L T.L).den := add_den_pos hLd T.hLd
  have Lsn : 0 ≤ (add L T.L).num := Qadd_num_nonneg_loc hLn T.hLn
  have hH_star := lip_weaken hLd Lsd (Qle_self_add T.hLn) hlipH
  have hcsf_L : ∀ y y', Rle (Rabs (Rsub (Rmul c (T.f y)) (Rmul c (T.f y'))))
      (Rmul (ofQ L hLd) (Rabs (Rsub y y'))) :=
    fun y y' => Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr
      (Rmul_comm c (T.f y)) (Rmul_comm c (T.f y'))))) (hlipH y y')
  have hcsf_star := lip_weaken hLd Lsd (Qle_self_add T.hLn) hcsf_L
  have hcsf_fc : ∀ y y', Req y y' → Req (Rmul c (T.f y)) (Rmul c (T.f y')) :=
    fun y y' h => Rmul_congr (Req_refl c) (T.hfc y y' h)
  have hbase_star := lip_weaken T.hLd Lsd (Qle_self_add_l hLn) T.hlip
  have s1 := riemannIntegralI_certif_irrel hLd hLn hlipH hfcH Lsd Lsn hH_star hfcH
    lo w hlo hw hwn
  have s2 := riemannIntegralI_congr Lsd Lsn hH_star hfcH hcsf_star hcsf_fc lo w hlo hw hwn
    (fun y => Rmul_comm (T.f y) c)
  have s3 := riemannIntegralI_Rsmul c Lsd Lsn hbase_star T.hfc hcsf_star hcsf_fc lo w hlo hw hwn
  have s4 := riemannIntegralI_certif_irrel Lsd Lsn hbase_star T.hfc T.hLd T.hLn T.hlip T.hfc
    lo w hlo hw hwn
  exact Req_trans s1 (Req_trans s2 (Req_trans s3
    (Req_trans (Rmul_congr (Req_refl c) s4) (Rmul_comm c _))))

/-- **The `x`-outer parametric test of the coupled integrand** `coupOuterTest.f x = ∫ₜ coupIntegrand
    x t dt` — the inner `t`-window integral of the coupled `(x,t)` integrand, bundled as an `L2Test` in
    the outer Mellin variable `x` via `paramIntegralTest`. Its `x`-integral over `[xlo, xlo+xw]` is the
    `x`-outer double integral that `mellinConv` equals. -/
def coupOuterTest (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den)
    (hwn : 0 ≤ w.num) : L2Test :=
  paramIntegralTest (coupIntegrand f g ψ S hSd hSn a han had)
    (couLy f g ψ S hSd hSn a han had) (couLx f g ψ S hSd hSn a han had)
    (couB f g ψ S hSd hSn a han had)
    (couLy_den f g ψ S hSd hSn a han had) (couLy_num f g ψ S hSd hSn a han had)
    (couLx_den f g ψ S hSd hSn a han had) (couLx_num f g ψ S hSd hSn a han had)
    (couB_den f g ψ S hSd hSn a han had) (couB_num f g ψ S hSd hSn a han had)
    (coup_lipY f g ψ S hSd hSn a han had) (coup_fcY f g ψ S hSd hSn a han had)
    (coup_lipX f g ψ S hSd hSn a han had) (coup_fcX f g ψ S hSd hSn a han had)
    lo w hlo hw hwn
    (fun x u _ _ => coup_bd f g ψ S hSd hSn a han had x (affineMap lo w hlo hw u))

/-- **The transposed `t`-outer parametric test of the coupled integrand** `coupOuterTestSwap.f t =
    ∫ₓ coupIntegrand x t dx` — the inner `x`-window integral of the coupled integrand with the roles of
    the two variables exchanged, bundled as an `L2Test` in `t`. Its `t`-integral over `[lo, lo+w]` is the
    `t`-outer / `x`-inner double integral produced by the Fubini swap. -/
def coupOuterTestSwap (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (xlo xw : Q) (hxlo : 0 < xlo.den)
    (hxw : 0 < xw.den) (hxwn : 0 ≤ xw.num) : L2Test :=
  paramIntegralTest (fun p q => coupIntegrand f g ψ S hSd hSn a han had q p)
    (couLx f g ψ S hSd hSn a han had) (couLy f g ψ S hSd hSn a han had)
    (couB f g ψ S hSd hSn a han had)
    (couLx_den f g ψ S hSd hSn a han had) (couLx_num f g ψ S hSd hSn a han had)
    (couLy_den f g ψ S hSd hSn a han had) (couLy_num f g ψ S hSd hSn a han had)
    (couB_den f g ψ S hSd hSn a han had) (couB_num f g ψ S hSd hSn a han had)
    (fun x y y' => coup_lipX f g ψ S hSd hSn a han had y y' x)
    (fun x y y' h => coup_fcX f g ψ S hSd hSn a han had y y' x h)
    (fun x x' y => coup_lipY f g ψ S hSd hSn a han had y x x')
    (fun x x' y h => coup_fcY f g ψ S hSd hSn a han had y x x' h)
    xlo xw hxlo hxw hxwn
    (fun x u _ _ => coup_bd f g ψ S hSd hSn a han had (affineMap xlo xw hxlo hxw u) x)

/-- **The per-`x` convolution identity** `coupOuterTest.f x = (f⋆g)(x)·ψ(x)` — the inner `t`-integral of
    the coupled integrand at outer point `x` equals the convolution value times the weight, since `ψ(x)`
    is `t`-constant (`intI_pull_right`) and `∫ₜ (couTest x)(t) dt` is definitionally `mulConvRTest.f x`. -/
private theorem coupOuterTest_f (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den)
    (hwn : 0 ≤ w.num) (x : Real) :
    Req ((coupOuterTest f g ψ S hSd hSn a han had lo w hlo hw hwn).f x)
        (Rmul ((mulConvRTest f g S hSd hSn a han had lo w hlo hw hwn).f x) (ψ.f x)) :=
  intI_pull_right (couTest f g S hSd hSn a han had x) (ψ.f x)
    (couLy f g ψ S hSd hSn a han had) (couLy_den f g ψ S hSd hSn a han had)
    (couLy_num f g ψ S hSd hSn a han had) (coup_lipY f g ψ S hSd hSn a han had x)
    (coup_fcY f g ψ S hSd hSn a han had x) lo w hlo hw hwn

/-- **Part A — the structural identity.** `mellinConv f g ψ` equals the `x`-outer double integral of the
    coupled integrand: `∫ₓ (∫ₜ coupIntegrand x t dt) dx` over the Mellin window `[xlo, xlo+xw]`. The
    `mellinConv` integrand `(f⋆g)(x)·ψ(x)` agrees pointwise with the parametric inner integral
    (`coupOuterTest_f`), so the two `x`-integrals coincide up to certificate reconciliation
    (`riemannIntegralI_congr` / `riemannIntegralI_certif_irrel`). A definitional/scalar-linearity
    identity: no swap yet, no new limit, no positivity, no crux. -/
theorem mellinConv_eq_paramInt (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den)
    (hwn : 0 ≤ w.num) (xlo xw : Q) (hxlo : 0 < xlo.den) (hxw : 0 < xw.den) (hxwn : 0 ≤ xw.num) :
    Req (mellinConv f g ψ S hSd hSn a han had lo w hlo hw hwn xlo xw hxlo hxw hxwn)
        (riemannIntegralI
          (coupOuterTest f g ψ S hSd hSn a han had lo w hlo hw hwn).hLd
          (coupOuterTest f g ψ S hSd hSn a han had lo w hlo hw hwn).hLn
          (coupOuterTest f g ψ S hSd hSn a han had lo w hlo hw hwn).hlip
          (coupOuterTest f g ψ S hSd hSn a han had lo w hlo hw hwn).hfc
          xlo xw hxlo hxw hxwn) := by
  let P := coupOuterTest f g ψ S hSd hSn a han had lo w hlo hw hwn
  let MC := mulConvRTest f g S hSd hSn a han had lo w hlo hw hwn
  have Lsd : 0 < (add (l2L MC ψ) P.L).den := add_den_pos (l2L_den MC ψ) P.hLd
  have Lsn : 0 ≤ (add (l2L MC ψ) P.L).num := Qadd_num_nonneg_loc (l2L_num MC ψ) P.hLn
  have hout_star := lip_weaken (l2L_den MC ψ) Lsd (Qle_self_add P.hLn) (l2lip MC ψ)
  have hP_star := lip_weaken P.hLd Lsd (Qle_self_add_l (l2L_num MC ψ)) P.hlip
  have s1 := riemannIntegralI_certif_irrel (l2L_den MC ψ) (l2L_num MC ψ) (l2lip MC ψ) (l2fc MC ψ)
    Lsd Lsn hout_star (l2fc MC ψ) xlo xw hxlo hxw hxwn
  have s2 := riemannIntegralI_congr Lsd Lsn hout_star (l2fc MC ψ) hP_star P.hfc
    xlo xw hxlo hxw hxwn
    (fun x => Req_symm (coupOuterTest_f f g ψ S hSd hSn a han had lo w hlo hw hwn x))
  have s3 := riemannIntegralI_certif_irrel Lsd Lsn hP_star P.hfc P.hLd P.hLn P.hlip P.hfc
    xlo xw hxlo hxw hxwn
  exact Req_trans s1 (Req_trans s2 s3)

/-- **Part B — the Fubini swap.** `mellinConv f g ψ` equals the `t`-outer / `x`-inner double integral of
    the coupled integrand. Part A rewrites `mellinConv` as the `x`-outer double integral of
    `coupIntegrand`; `bern2D_general_swap_window`, fed the coupled-integrand regularity witnesses at the
    outer `x`-window `[xlo, xlo+xw]` and inner `t`-window `[lo, lo+w]`, exchanges the two integration
    orders. This performs the Fubini swap honestly: no new estimate, no factorization, no positivity, no
    crux; the inner `x`-integral is left unevaluated (the later dilation-covariance step). -/
theorem mellinConv_fubini (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den)
    (hwn : 0 ≤ w.num) (xlo xw : Q) (hxlo : 0 < xlo.den) (hxw : 0 < xw.den) (hxwn : 0 ≤ xw.num) :
    Req (mellinConv f g ψ S hSd hSn a han had lo w hlo hw hwn xlo xw hxlo hxw hxwn)
        (riemannIntegralI
          (coupOuterTestSwap f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn).hLd
          (coupOuterTestSwap f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn).hLn
          (coupOuterTestSwap f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn).hlip
          (coupOuterTestSwap f g ψ S hSd hSn a han had xlo xw hxlo hxw hxwn).hfc
          lo w hlo hw hwn) :=
  Req_trans
    (mellinConv_eq_paramInt f g ψ S hSd hSn a han had lo w hlo hw hwn xlo xw hxlo hxw hxwn)
    (bern2D_general_swap_window (coupIntegrand f g ψ S hSd hSn a han had)
      (couLx f g ψ S hSd hSn a han had) (couLy f g ψ S hSd hSn a han had)
      (couB f g ψ S hSd hSn a han had)
      (couLx_den f g ψ S hSd hSn a han had) (couLx_num f g ψ S hSd hSn a han had)
      (couLy_den f g ψ S hSd hSn a han had) (couLy_num f g ψ S hSd hSn a han had)
      (couB_den f g ψ S hSd hSn a han had) (couB_num f g ψ S hSd hSn a han had)
      (coup_lipY f g ψ S hSd hSn a han had) (coup_fcY f g ψ S hSd hSn a han had)
      (coup_lipX f g ψ S hSd hSn a han had) (coup_fcX f g ψ S hSd hSn a han had)
      (coup_lip f g ψ S hSd hSn a han had) (coup_bd f g ψ S hSd hSn a han had)
      xlo xw lo w hxlo hxw hxwn hlo hw hwn)

end Multiplicity.UOR.Bridge.F1Square.Square
