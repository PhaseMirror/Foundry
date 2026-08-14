/-
F1 square — **the coupled `(x,t)` integrand of the convolution–Mellin pairing**
(`ConvMellinIntegrand.lean`): the nested `mellinConv f g ψ = ∫ₓ [∫ₜ P_x(t) dt]·ψ(x) dx` has, as its
inner two-variable integrand, the coupled map

    `F(x,t) = f(x·(1/max(t,a)))·g(t)·(1/max(t,a))·ψ(x)`

with `x` the outer (Mellin) variable and `t` the inner (convolution) variable. Applying a Fubini
swap to `mellinConv` (via the general 2D-Bernstein swap) needs `F` presented as a jointly
bounded-Lipschitz `Real → Real → Real` carrying the six `paramIntegralTest` witnesses. This file
supplies exactly those six regularity facts for the (`[0,S]`-clamped-in-`x`) coupled integrand
`coupIntegrand`.

The `t`-factor of `F` is literally a product of two `L2Test`s — `couTest x = productTest (productTest
(reflectTest a (dilateTestR (clamp x) f)) g) (recipTest a)` — so the `t`-direction Lipschitz bound is
just `l2lip` of that product, times the `x`-uniform weight bound `|ψ(x)| ≤ M_ψ`. The `x`-direction
reuses `mulConvR_integrand_diff` (the `t`-uniform `x`-difference of the convolution integrand) folded
through the band clamp and the generic `Rmul_lipschitz` against `ψ`. The joint bound is the triangle
through `(x,t')`.

HONEST SCOPE. The joint `(x,t)`-Lipschitz and bound of the convolution–Mellin coupled integrand
`F(x,t) = f(x·clampedInv(a,t))·g(t)·clampedInv(a,t)·ψ(x)` — an analysis/regularity fact
(product-of-bounded-Lipschitz). This is the precondition for a later Fubini swap; it builds NO swap,
NO integral identity, NO positivity, NO determinacy, NO crux. Step 4 (band-coupling positivity) is
RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.MellinConv
import Multiplicity.F1Square.Analysis.MulConvRDiff
import Multiplicity.F1Square.Analysis.RmulLipschitz

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The convolution integrand as a test in `t`, parametrized by the clamped output `x`** —
    `couTest f g S a x = productTest (productTest (reflectTest a (dilateTestR (clamp x) S f)) g)
    (recipTest a)`, whose value at `t` is `f(clamp x·(1/max(t,a)))·g(t)·(1/max(t,a)) = P_{clamp x}(t)`.
    The `x`-independent rational `L`/`M` fields (the clamp scale enters only the value, never the
    moduli) are what make the coupled integrand's moduli uniform in `x`. -/
def couTest (f g : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (x : Real) : L2Test :=
  productTest
    (productTest
      (reflectTest a han had
        (dilateTestR (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x) S hSd hSn
          (clampS_absle S hSd hSn x) f)) g)
    (recipTest a han had)

/-- **The coupled `(x,t)` integrand** `coupIntegrand f g ψ S a x t = P_{clamp x}(t)·ψ(x)`, the inner
    two-variable integrand of `mellinConv f g ψ`: the convolution integrand in `t` (at the
    `[0,S]`-clamped output `x`) weighted by the Mellin test `ψ(x)`. A total `Real → Real → Real`. -/
def coupIntegrand (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) : Real → Real → Real :=
  fun x t => Rmul ((couTest f g S hSd hSn a han had x).f t) (ψ.f x)

/-- The `t`-direction (inner) Lipschitz modulus `L_t·M_ψ` of the coupled integrand, where
    `L_t = (couTest …).L` is the `x`-uniform product-Lipschitz constant of the convolution integrand
    in `t`. -/
def couLy (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) : Q :=
  mul (couTest f g S hSd hSn a han had zero).L ψ.M

/-- The `x`-direction (outer) Lipschitz modulus `M_P·L_ψ + M_ψ·(f.L·(1/a)·g.M·(1/a))` of the coupled
    integrand: the convolution integrand's bound times `ψ`'s slope, plus `ψ`'s bound times the
    `t`-uniform `x`-difference constant of the convolution integrand (`mulConvR_integrand_diff`). -/
def couLx (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) : Q :=
  add (mul (couTest f g S hSd hSn a han had zero).M ψ.L)
    (mul ψ.M (mul (mul f.L (Qinv a)) (mul g.M (Qinv a))))

/-- The global bound `M_P·M_ψ` of the coupled integrand. -/
def couB (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) : Q :=
  mul (couTest f g S hSd hSn a han had zero).M ψ.M

theorem couLy_den (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) :
    0 < (couLy f g ψ S hSd hSn a han had).den :=
  Qmul_den_pos (couTest f g S hSd hSn a han had zero).hLd ψ.hMd

theorem couLy_num (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) :
    0 ≤ (couLy f g ψ S hSd hSn a han had).num :=
  Int.mul_nonneg (couTest f g S hSd hSn a han had zero).hLn ψ.hMn

theorem couLx_den (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) :
    0 < (couLx f g ψ S hSd hSn a han had).den :=
  add_den_pos (Qmul_den_pos (couTest f g S hSd hSn a han had zero).hMd ψ.hLd)
    (Qmul_den_pos ψ.hMd (Qmul_den_pos (Qmul_den_pos f.hLd (Qinv_den_pos han))
      (Qmul_den_pos g.hMd (Qinv_den_pos han))))

theorem couLx_num (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) :
    0 ≤ (couLx f g ψ S hSd hSn a han had).num :=
  Rmul_lip_const_nonneg
    (Int.mul_nonneg (Int.mul_nonneg f.hLn (Int.le_of_lt (Qinv_num_pos had)))
      (Int.mul_nonneg g.hMn (Int.le_of_lt (Qinv_num_pos had))))
    ψ.hLn (couTest f g S hSd hSn a han had zero).hMn ψ.hMn

theorem couB_den (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) :
    0 < (couB f g ψ S hSd hSn a han had).den :=
  Qmul_den_pos (couTest f g S hSd hSn a han had zero).hMd ψ.hMd

theorem couB_num (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) :
    0 ≤ (couB f g ψ S hSd hSn a han had).num :=
  Int.mul_nonneg (couTest f g S hSd hSn a han had zero).hMn ψ.hMn

/-- **The `t`-direction (inner) Lipschitz bound — the key new content.** For every clamped output
    `x`, `|F(x,t) − F(x,t')| ≤ (L_t·M_ψ)·|t − t'|`. Since `F(x,·) = P_{clamp x}(·)·ψ(x)` and
    `P_{clamp x} = couTest x` is a genuine product `L2Test` in `t`, this is `l2lip (couTest x)` folded
    by the `x`-uniform weight bound `|ψ(x)| ≤ M_ψ`. -/
theorem coup_lipY (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (x t t' : Real) :
    Rle (Rabs (Rsub (coupIntegrand f g ψ S hSd hSn a han had x t)
        (coupIntegrand f g ψ S hSd hSn a han had x t')))
      (Rmul (ofQ (couLy f g ψ S hSd hSn a han had) (couLy_den f g ψ S hSd hSn a han had))
        (Rabs (Rsub t t'))) := by
  refine Rle_trans (Rle_of_Req (Req_trans
      (Rabs_congr (Req_symm (Rmul_sub_distrib_right
        ((couTest f g S hSd hSn a han had x).f t) ((couTest f g S hSd hSn a han had x).f t')
        (ψ.f x))))
      (Rabs_Rmul (Rsub ((couTest f g S hSd hSn a han had x).f t)
        ((couTest f g S hSd hSn a han had x).f t')) (ψ.f x)))) ?_
  refine Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs _) (Rnonneg_ofQ ψ.hMd ψ.hMn)
      ((couTest f g S hSd hSn a han had x).hlip t t') (ψ.hbd x)) (Rle_of_Req ?_)
  refine Req_trans (Rmul_assoc (ofQ (couTest f g S hSd hSn a han had x).L
      (couTest f g S hSd hSn a han had x).hLd) (Rabs (Rsub t t')) (ofQ ψ.M ψ.hMd)) ?_
  refine Req_trans (Rmul_congr (Req_refl _)
      (Rmul_comm (Rabs (Rsub t t')) (ofQ ψ.M ψ.hMd))) ?_
  refine Req_trans (Req_symm (Rmul_assoc (ofQ (couTest f g S hSd hSn a han had x).L
      (couTest f g S hSd hSn a han had x).hLd) (ofQ ψ.M ψ.hMd) (Rabs (Rsub t t')))) ?_
  exact Rmul_congr (Rmul_ofQ_ofQ (couTest f g S hSd hSn a han had x).hLd ψ.hMd) (Req_refl _)

/-- The convolution integrand's `x`-difference, folded through the band clamp: for every `t`,
    `|(couTest u).f t − (couTest v).f t| ≤ (f.L·(1/a)·g.M·(1/a))·|u − v|` — `mulConvR_integrand_diff`
    at the clamped points, then the `1`-Lipschitz band clamp. -/
private theorem couf_lipX (f g : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (t u v : Real) :
    Rle (Rabs (Rsub ((couTest f g S hSd hSn a han had u).f t)
        ((couTest f g S hSd hSn a han had v).f t)))
      (Rmul (ofQ (mul (mul f.L (Qinv a)) (mul g.M (Qinv a)))
        (Qmul_den_pos (Qmul_den_pos f.hLd (Qinv_den_pos han))
          (Qmul_den_pos g.hMd (Qinv_den_pos han)))) (Rabs (Rsub u v))) := by
  refine Rle_trans (mulConvR_integrand_diff f g
      (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd u) (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd v)
      S hSd hSn (clampS_absle S hSd hSn u) (clampS_absle S hSd hSn v) a han had t) ?_
  exact Rmul_le_Rmul_left
    (Rnonneg_ofQ (Qmul_den_pos (Qmul_den_pos f.hLd (Qinv_den_pos han))
        (Qmul_den_pos g.hMd (Qinv_den_pos han)))
      (Int.mul_nonneg (Int.mul_nonneg f.hLn (Int.le_of_lt (Qinv_num_pos had)))
        (Int.mul_nonneg g.hMn (Int.le_of_lt (Qinv_num_pos had)))))
    (qBandQ_lipschitz (⟨0, 1⟩ : Q) S (by decide) hSd u v)

/-- **The `x`-direction (outer) Lipschitz bound.** For every `t`,
    `|F(x,t) − F(x',t)| ≤ couLx·|x − x'|`. The coupled integrand is the product `(u ↦ (couTest u).f t)·
    (u ↦ ψ(u))` in the parameter, each factor bounded-Lipschitz (`couf_lipX` / `ψ`), so the generic
    product-Lipschitz estimate `Rmul_lipschitz` gives the modulus `M_P·L_ψ + M_ψ·C_P`. -/
theorem coup_lipX (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (x x' t : Real) :
    Rle (Rabs (Rsub (coupIntegrand f g ψ S hSd hSn a han had x t)
        (coupIntegrand f g ψ S hSd hSn a han had x' t)))
      (Rmul (ofQ (couLx f g ψ S hSd hSn a han had) (couLx_den f g ψ S hSd hSn a han had))
        (Rabs (Rsub x x'))) :=
  Rmul_lipschitz
    (f := fun u => (couTest f g S hSd hSn a han had u).f t) (g := ψ.f)
    (Lf := mul (mul f.L (Qinv a)) (mul g.M (Qinv a))) (Lg := ψ.L)
    (Mf := (couTest f g S hSd hSn a han had zero).M) (Mg := ψ.M)
    (Qmul_den_pos (Qmul_den_pos f.hLd (Qinv_den_pos han)) (Qmul_den_pos g.hMd (Qinv_den_pos han)))
    ψ.hLd (couTest f g S hSd hSn a han had zero).hMd ψ.hMd
    (Int.mul_nonneg (Int.mul_nonneg f.hLn (Int.le_of_lt (Qinv_num_pos had)))
      (Int.mul_nonneg g.hMn (Int.le_of_lt (Qinv_num_pos had))))
    ψ.hLn (couTest f g S hSd hSn a han had zero).hMn ψ.hMn
    (fun u v => couf_lipX f g S hSd hSn a han had t u v)
    (fun u v => ψ.hlip u v)
    (fun u => (couTest f g S hSd hSn a han had u).hbd t)
    (fun u => ψ.hbd u) x x'

/-- The coupled integrand's `x`-scale congruence at fixed `t`: `x ≈ x' ⟹ (couTest x).f t ≈
    (couTest x').f t` — the clamp scale `clamp x` enters only the value `f(clamp x·(1/max(t,a)))`, so
    this is `f`'s congruence through the `1`-Lipschitz band clamp. -/
private theorem couf_fcX (f g : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (t : Real) {x x' : Real} (h : Req x x') :
    Req ((couTest f g S hSd hSn a han had x).f t) ((couTest f g S hSd hSn a han had x').f t) :=
  Rmul_congr
    (Rmul_congr
      (f.hfc _ _ (Rmul_congr (qBandQ_congr (⟨0, 1⟩ : Q) S (by decide) hSd h)
        (Req_refl (clampedInv a han had t)))) (Req_refl (g.f t)))
    (Req_refl ((recipTest a han had).f t))

/-- **The joint `(x,t)`-Lipschitz bound.** `|F(x,t) − F(x',t')| ≤ couLx·|x − x'| + couLy·|t − t'|` —
    the triangle through `F(x',t)` closed by `coup_lipX` (fixed `t`) and `coup_lipY` (fixed `x'`). -/
theorem coup_lip (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (x x' t t' : Real) :
    Rle (Rabs (Rsub (coupIntegrand f g ψ S hSd hSn a han had x t)
        (coupIntegrand f g ψ S hSd hSn a han had x' t')))
      (Radd
        (Rmul (ofQ (couLx f g ψ S hSd hSn a han had) (couLx_den f g ψ S hSd hSn a han had))
          (Rabs (Rsub x x')))
        (Rmul (ofQ (couLy f g ψ S hSd hSn a han had) (couLy_den f g ψ S hSd hSn a han had))
          (Rabs (Rsub t t')))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Rsub_split
      (coupIntegrand f g ψ S hSd hSn a han had x t)
      (coupIntegrand f g ψ S hSd hSn a han had x' t)
      (coupIntegrand f g ψ S hSd hSn a han had x' t'))))) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  exact Radd_le_add (coup_lipX f g ψ S hSd hSn a han had x x' t)
    (coup_lipY f g ψ S hSd hSn a han had x' t t')

/-- **The global bound.** `|F(x,t)| ≤ couB` — the product of the convolution integrand's bound
    `|P_{clamp x}(t)| ≤ M_P` and the weight bound `|ψ(x)| ≤ M_ψ`. -/
theorem coup_bd (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (x t : Real) :
    Rle (Rabs (coupIntegrand f g ψ S hSd hSn a han had x t))
      (ofQ (couB f g ψ S hSd hSn a han had) (couB_den f g ψ S hSd hSn a han had)) := by
  refine Rle_trans (Rle_of_Req (Rabs_Rmul ((couTest f g S hSd hSn a han had x).f t) (ψ.f x))) ?_
  refine Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs _) (Rnonneg_ofQ ψ.hMd ψ.hMn)
    ((couTest f g S hSd hSn a han had x).hbd t) (ψ.hbd x)) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ (couTest f g S hSd hSn a han had x).hMd ψ.hMd)

/-- **The `t`-direction (inner) congruence.** `t ≈ t' ⟹ F(x,t) ≈ F(x,t')` — `couTest x`'s own
    congruence in `t`, with the weight `ψ(x)` fixed. -/
theorem coup_fcY (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (x t t' : Real) (h : Req t t') :
    Req (coupIntegrand f g ψ S hSd hSn a han had x t)
      (coupIntegrand f g ψ S hSd hSn a han had x t') :=
  Rmul_congr ((couTest f g S hSd hSn a han had x).hfc t t' h) (Req_refl (ψ.f x))

/-- **The `x`-direction (outer) congruence.** `x ≈ x' ⟹ F(x,t) ≈ F(x',t)` — the `x`-scale
    congruence of the convolution integrand (`couf_fcX`) times `ψ`'s own congruence. -/
theorem coup_fcX (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (x x' t : Real) (h : Req x x') :
    Req (coupIntegrand f g ψ S hSd hSn a han had x t)
      (coupIntegrand f g ψ S hSd hSn a han had x' t) :=
  Rmul_congr (couf_fcX f g S hSd hSn a han had t h) (ψ.hfc x x' h)

end Multiplicity.UOR.Bridge.F1Square.Square

