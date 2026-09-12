/-
F1 square — **the per-window rational-scale Mellin dilation** (`MellinWindowDilate.lean`): the first
sub-brick of the eventual dilation covariance of the Mellin twist.

For a bounded-Lipschitz base test `f`, a degree-`n` window weight `P`, a rational scale `s > 0`, and a
window `[lo, lo+w]`, the twisted integral over the `s`-SCALED window equals `s^(n+1)` times the
integral over the base window of the `s`-DILATED integrand:

    `∫_{s·lo}^{s·(lo+w)} f(y)·P(y) dy  =  s^(n+1) · ∫_lo^{lo+w} f(s·x)·P(x) dx`

— one linear change of variables `y = s·x` (`riemannIntegralI_dilate`, producing the Jacobian factor
`s`) composed with the degree-`n` homogeneity of the weight on the window (`P(s·x) = s^n·P(x)`, the
`s^n` pulled out by `riemannIntegralI_smul`), the two integrands reconciled at a common Lipschitz
modulus (`riemannIntegralI_certif_irrel`) and equated on the window alone (`riemannIntegralI_congr_unit`).
The homogeneity is an explicit hypothesis `hHom`; `powTest_dilate_on` discharges it for the genuine
clamped Mellin weight `powTest n` on any sub-`[0,1]` window (via `powTest_f_eq`, clamp-inertness
`clamp01_eq_self`, and the `Rpow` homogeneity `Rpow_dilate_ofQ`).

HONEST SCOPE. The per-window rational-scale Mellin dilation identity — one window's change of variables
(`riemannIntegralI_dilate`) plus `Rpow` homogeneity, the first sub-brick toward the dilation
covariance. It builds NO half-line limit, NO exhaustion-independence, NO real-scale dilation, NO
factorization, NO convolution theorem, NO positivity, NO determinacy, NO crux. Step 4 (band-coupling
positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.DilateIntegral
import Foundations.F1.Analysis.IntervalCert
import Foundations.F1.Analysis.ClampedInv
import Foundations.F1.Square.MellinLinear
import Foundations.F1.Square.MultShift
import Foundations.F1.Square.TestAlgebra
import Foundations.F1.Square.BernsteinClampMatch

set_option maxHeartbeats 4000000

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Value-scaling is Lipschitz**: `x ↦ q·f(x)` is `(q·L)`-Lipschitz when `f` is `L`-Lipschitz and
    `q ≥ 0` — `|q·f(x) − q·f(y)| = q·|f(x) − f(y)| ≤ (q·L)·|x−y|` (local copy of the Haar-assembly
    helper). -/
private theorem Rmul_ofQ_lip_loc {g : Real → Real} {L : Q} (hLd : 0 < L.den)
    (hlip : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (q : Q) (hqd : 0 < q.den) (hqn : 0 ≤ q.num) : ∀ x y,
    Rle (Rabs (Rsub (Rmul (ofQ q hqd) (g x)) (Rmul (ofQ q hqd) (g y))))
        (Rmul (ofQ (mul q L) (Qmul_den_pos hqd hLd)) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req
    (Req_trans (Rabs_congr (Req_symm (Rmul_sub_distrib (ofQ q hqd) (g x) (g y))))
      (Req_trans (Rabs_Rmul (ofQ q hqd) (Rsub (g x) (g y)))
        (Rmul_congr (Rabs_ofQ_nonneg hqd hqn) (Req_refl _))))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hqd hqn) (hlip x y)) (Rle_of_Req ?_)
  exact Req_trans (Req_symm (Rmul_assoc (ofQ q hqd) (ofQ L hLd) (Rabs (Rsub x y))))
    (Rmul_congr (Rmul_ofQ_ofQ hqd hLd) (Req_refl _))

/-- **`Rpow` is degree-`n` homogeneous under a rational scale**: `(s·x)ⁿ = sⁿ·xⁿ` — the pointwise
    power-homogeneity, from `Rpow_mul_dist` (`(a·b)ⁿ = aⁿ·bⁿ`) and `Rpow_ofQ` (`(ofQ s)ⁿ = ofQ (sⁿ)`).
    This is the algebra that turns the Jacobian factor `s` of the change of variables into `s^(n+1)`. -/
theorem Rpow_dilate_ofQ (s : Q) (hsd : 0 < s.den) (x : Real) (n : Nat) :
    Req (Rpow (Rmul (ofQ s hsd) x) n)
        (Rmul (ofQ (qpow s n) (qpow_den_pos hsd n)) (Rpow x n)) :=
  Req_trans (Rpow_mul_dist (ofQ s hsd) x n)
    (Rmul_congr (Rpow_ofQ hsd n) (Req_refl (Rpow x n)))

/-- **The clamped Mellin weight is degree-`n` homogeneous on a sub-`[0,1]` window**: for `y` and its
    scaling `s·y` both in `[0,1]`, `(powTest n)(s·y) = sⁿ·(powTest n)(y)`. The clamp `clamp01` is inert
    at both points (`clamp01_eq_self`), so the window value is the raw `Rpow`, and `Rpow_dilate_ofQ`
    supplies the homogeneity. This discharges the `hHom` hypothesis of `mellinWindowDilate` for the
    genuine Mellin weight `P = powTest n`. -/
theorem powTest_dilate_on (n : Nat) (s : Q) (hsd : 0 < s.den) (y : Real)
    (hy0 : Rle zero y) (hy1 : Rle y one)
    (hsy0 : Rle zero (Rmul (ofQ s hsd) y)) (hsy1 : Rle (Rmul (ofQ s hsd) y) one) :
    Req ((powTest n).f (Rmul (ofQ s hsd) y))
        (Rmul (ofQ (qpow s n) (qpow_den_pos hsd n)) ((powTest n).f y)) := by
  have hpow_y : Req (Rpow y n) ((powTest n).f y) :=
    Req_symm (Req_trans (powTest_f_eq y n) (Rpow_congr (clamp01_eq_self hy0 hy1) n))
  refine Req_trans (powTest_f_eq (Rmul (ofQ s hsd) y) n) ?_
  refine Req_trans (Rpow_congr (clamp01_eq_self hsy0 hsy1) n) ?_
  refine Req_trans (Rpow_dilate_ofQ s hsd y n) ?_
  exact Rmul_congr (Req_refl (ofQ (qpow s n) (qpow_den_pos hsd n))) hpow_y

/-- **The per-window rational-scale Mellin dilation.** For a base test `f`, a degree-`n` window weight
    `P` that is homogeneous on the window under the scale `s` (`hHom`), a rational scale `s > 0`, and a
    window `[lo, lo+w]`,

      `∫_{s·lo}^{s·(lo+w)} (f·P)(y) dy  =  s^(n+1) · ∫_lo^{lo+w} (dilate_s f · P)(x) dx`.

    The proof: the change of variables `y = s·x` (`riemannIntegralI_dilate`, Jacobian `s`); the dilated
    integrand `(f·P)(s·x)` reconciled to a common modulus (`riemannIntegralI_certif_irrel`) and equated
    on the window with `sⁿ·(dilate_s f · P)(x)` through `hHom` (`riemannIntegralI_congr_unit`); the `sⁿ`
    pulled out (`riemannIntegralI_smul`); and `s·sⁿ = s^(n+1)` collapsed definitionally (`qpow_succ`). -/
theorem mellinWindowDilate
    (f P : L2Test) (n : Nat) (s : Q) (hsn : 0 < s.num) (hsd : 0 < s.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hHom : ∀ x, Rle zero x → Rle x one →
      Req (P.f (Rmul (ofQ s hsd) (affineMap lo w hlo hw x)))
          (Rmul (ofQ (qpow s n) (qpow_den_pos hsd n)) (P.f (affineMap lo w hlo hw x)))) :
    Req (riemannIntegralI (L2Test.mul f P).hLd (L2Test.mul f P).hLn (L2Test.mul f P).hlip
            (L2Test.mul f P).hfc (mul s lo) (mul s w)
            (Qmul_den_pos hsd hlo) (Qmul_den_pos hsd hw)
            (Int.mul_nonneg (Int.le_of_lt hsn) hwn))
        (Rmul (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
          (riemannIntegralI (L2Test.mul (dilateTest s hsn hsd f) P).hLd
            (L2Test.mul (dilateTest s hsn hsd f) P).hLn (L2Test.mul (dilateTest s hsn hsd f) P).hlip
            (L2Test.mul (dilateTest s hsn hsd f) P).hfc lo w hlo hw hwn)) := by
  -- Moduli: LD = (f·P).L·s (the dilated integrand), LG = (dilate_s f · P).L (the base integrand),
  -- LSG = sⁿ·LG (the scaled base), Lc = LD + (LG + LSG) the common weakening.
  have LDd : 0 < (mul (L2Test.mul f P).L s).den := Qmul_den_pos (L2Test.mul f P).hLd hsd
  have LDn : (0 : Int) ≤ (mul (L2Test.mul f P).L s).num :=
    Int.mul_nonneg (L2Test.mul f P).hLn (Int.le_of_lt hsn)
  have LGd : 0 < (L2Test.mul (dilateTest s hsn hsd f) P).L.den :=
    (L2Test.mul (dilateTest s hsn hsd f) P).hLd
  have LGn : (0 : Int) ≤ (L2Test.mul (dilateTest s hsn hsd f) P).L.num :=
    (L2Test.mul (dilateTest s hsn hsd f) P).hLn
  have LSGd : 0 < (mul (qpow s n) (L2Test.mul (dilateTest s hsn hsd f) P).L).den :=
    Qmul_den_pos (qpow_den_pos hsd n) LGd
  have LSGn : (0 : Int) ≤ (mul (qpow s n) (L2Test.mul (dilateTest s hsn hsd f) P).L).num :=
    Int.mul_nonneg (qpow_nonneg (Int.le_of_lt hsn) n) LGn
  have Lcd : 0 < (add (mul (L2Test.mul f P).L s)
      (add (L2Test.mul (dilateTest s hsn hsd f) P).L
        (mul (qpow s n) (L2Test.mul (dilateTest s hsn hsd f) P).L))).den :=
    add_den_pos LDd (add_den_pos LGd LSGd)
  have Lcn : (0 : Int) ≤ (add (mul (L2Test.mul f P).L s)
      (add (L2Test.mul (dilateTest s hsn hsd f) P).L
        (mul (qpow s n) (L2Test.mul (dilateTest s hsn hsd f) P).L))).num :=
    Qadd_num_nonneg_loc LDn (Qadd_num_nonneg_loc LGn LSGn)
  -- Native certificates of the three integrands.
  have hD'nat := dilate_lip (L2Test.mul f P).hLd (L2Test.mul f P).hLn (L2Test.mul f P).hlip
    s hsd (Int.le_of_lt hsn)
  have hD'fc := dilate_fc (L2Test.mul f P).hfc s hsd
  have hGnat := (L2Test.mul (dilateTest s hsn hsd f) P).hlip
  have hGfc := (L2Test.mul (dilateTest s hsn hsd f) P).hfc
  have hSGnat := Rmul_ofQ_lip_loc LGd hGnat (qpow s n) (qpow_den_pos hsd n)
    (qpow_nonneg (Int.le_of_lt hsn) n)
  have hSGfc : ∀ x y, Req x y →
      Req (Rmul (ofQ (qpow s n) (qpow_den_pos hsd n))
            ((L2Test.mul (dilateTest s hsn hsd f) P).f x))
          (Rmul (ofQ (qpow s n) (qpow_den_pos hsd n))
            ((L2Test.mul (dilateTest s hsn hsd f) P).f y)) :=
    fun x y h => Rmul_congr (Req_refl (ofQ (qpow s n) (qpow_den_pos hsd n))) (hGfc x y h)
  -- Weaken all three to the common modulus Lc.
  have hD'lc := fun x y => lip_mono LDd Lcd (Qle_self_add (Qadd_num_nonneg_loc LGn LSGn))
    (Rnonneg_Rabs (Rsub x y)) (hD'nat x y)
  have hSGlc := fun x y => lip_mono LSGd Lcd
    (Qle_trans (add_den_pos LGd LSGd) (Qle_add_self LGn) (Qle_add_self LDn))
    (Rnonneg_Rabs (Rsub x y)) (hSGnat x y)
  have hGlc := fun x y => lip_mono LGd Lcd
    (Qle_trans (add_den_pos LGd LSGd) (Qle_self_add LSGn) (Qle_add_self LDn))
    (Rnonneg_Rabs (Rsub x y)) (hGnat x y)
  -- The window pointwise identity: (f·P)(s·y) ≈ sⁿ·(dilate_s f · P)(y) on [lo, lo+w].
  have hfg : ∀ x, Rle zero x → Rle x one →
      Req ((L2Test.mul f P).f (Rmul (ofQ s hsd) (affineMap lo w hlo hw x)))
          (Rmul (ofQ (qpow s n) (qpow_den_pos hsd n))
            ((L2Test.mul (dilateTest s hsn hsd f) P).f (affineMap lo w hlo hw x))) := by
    intro x h0 h1
    refine Req_trans (Rmul_congr (Req_refl _) (hHom x h0 h1)) ?_
    exact Req_trans (Req_symm (Rmul_assoc _ _ _))
      (Req_trans (Rmul_congr (Rmul_comm _ _) (Req_refl _)) (Rmul_assoc _ _ _))
  -- Assemble the chain.
  refine Req_trans (riemannIntegralI_dilate (L2Test.mul f P).hLd (L2Test.mul f P).hLn
    (L2Test.mul f P).hlip (L2Test.mul f P).hfc s lo w hsd (Int.le_of_lt hsn) hlo hw hwn) ?_
  refine Req_trans (Rmul_congr (Req_refl (ofQ s hsd))
    (riemannIntegralI_certif_irrel LDd LDn hD'nat hD'fc Lcd Lcn hD'lc hD'fc
      lo w hlo hw hwn)) ?_
  refine Req_trans (Rmul_congr (Req_refl (ofQ s hsd))
    (riemannIntegralI_congr_unit Lcd Lcn hD'lc hD'fc hSGlc hSGfc lo w hlo hw hwn hfg)) ?_
  refine Req_trans (Rmul_congr (Req_refl (ofQ s hsd))
    (riemannIntegralI_smul (qpow s n) (qpow_den_pos hsd n) Lcd Lcn hGlc hGfc hSGlc hSGfc
      lo w hlo hw hwn)) ?_
  refine Req_trans (Rmul_congr (Req_refl (ofQ s hsd))
    (Rmul_congr (Req_refl (ofQ (qpow s n) (qpow_den_pos hsd n)))
      (riemannIntegralI_certif_irrel Lcd Lcn hGlc hGfc LGd LGn hGnat hGfc
        lo w hlo hw hwn))) ?_
  refine Req_trans (Req_symm (Rmul_assoc (ofQ s hsd) (ofQ (qpow s n) (qpow_den_pos hsd n)) _)) ?_
  exact Rmul_congr (Rmul_ofQ_ofQ hsd (qpow_den_pos hsd n)) (Req_refl _)

end Multiplicity.UOR.Bridge.F1Square.Square

