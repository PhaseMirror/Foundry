/-
F1 square — **weight-swap from the wide-band `powBandGen` window integral to the `mellinHat`
tail term `twTerm`** (`TwTermPowBand.lean`): the committed per-window dilation identity
`window_dilate_powBandGen` carries the WIDE-BAND twist weight `powBandGen lo hi … n`, whereas the
`mellinHat` tail term `twTerm` carries the INTEGER-WINDOW weight `powWinTest m n`. The two weights
AGREE on the window `[m+1, m+2]` (both equal `tⁿ` there) but differ off-window AND have different
Lipschitz constants, so bridging them needs a DIFFERENT-`L` window congruence.

Three facts. First, `riemannIntegralI_congr_unit_mod` — a REUSABLE different-`L` window congruence:
two integrands certified at possibly different moduli `Lf`, `Lg` that agree on the affine window
have equal interval integrals, obtained by weakening both certificates to the common `Lf+Lg`
(`lip_weaken` with `Qle_self_add`/`Qle_self_add_l`), running the same-`L` `riemannIntegralI_congr_unit`
there, and moving each side back by `riemannIntegralI_certif_irrel`. Second, `powWinTest_eq_Rpow_on`
— the window-inertness of the integer window power (`powWinTest m n = tⁿ` on `[m+1,m+2]`), the mirror
of `powBandGen_eq_Rpow_on`. Third, `twTerm_eq_window_powBandGen` — the weight swap itself: the
`(ψ · powBandGen)` window integral equals `twTerm ψ n m`, since on the affine window both integrands
reduce to `ψ(t)·tⁿ` (band-inertness of each weight).

HONEST SCOPE. The weight-swap connecting the wide-band `powBandGen` window integral to the
`mellinHat` tail term `twTerm` (`powWinTest`), via a reusable different-`L` window congruence
(`certif_irrel` + `lip_weaken` + `congr_unit`) and the shared band-inertness of both weights (equal
to `tⁿ` on the window). It builds NO half-line assembly, NO reschedule, NO factorization, NO
positivity, NO determinacy, NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MellinLinear
import Foundations.F1.Square.RationalWindowDilate
import Foundations.F1.Analysis.IntervalCert

set_option maxHeartbeats 4000000

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Different-`L` window congruence of the interval integral**: two integrands `f`, `g`,
    certified at possibly DIFFERENT Lipschitz moduli `Lf`, `Lg`, that agree on the affine window
    `[a, a+w]` have equal interval integrals. Both certificates are weakened to the common modulus
    `Lf + Lg` (`lip_weaken` with `Qle_self_add`/`Qle_self_add_l`); at that shared modulus the
    same-`L` `riemannIntegralI_congr_unit` applies, and each side is moved back to its own modulus
    by `riemannIntegralI_certif_irrel`. Reusable for every weight swap whose two weights agree on the
    window but carry different Lipschitz constants. -/
theorem riemannIntegralI_congr_unit_mod {f g : Real → Real} {Lf Lg : Q}
    (hLfd : 0 < Lf.den) (hLfn : 0 ≤ Lf.num)
    (hlipf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ Lf hLfd) (Rabs (Rsub x y))))
    (hfcf : ∀ x y, Req x y → Req (f x) (f y))
    (hLgd : 0 < Lg.den) (hLgn : 0 ≤ Lg.num)
    (hlipg : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ Lg hLgd) (Rabs (Rsub x y))))
    (hfcg : ∀ x y, Req x y → Req (g x) (g y))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hfg : ∀ x, Rle zero x → Rle x one →
      Req (f (affineMap a w ha hw x)) (g (affineMap a w ha hw x))) :
    Req (riemannIntegralI hLfd hLfn hlipf hfcf a w ha hw hwn)
        (riemannIntegralI hLgd hLgn hlipg hfcg a w ha hw hwn) := by
  have hLcd : 0 < (add Lf Lg).den := add_den_pos hLfd hLgd
  have hLcn : 0 ≤ (add Lf Lg).num := Qadd_num_nonneg_loc hLfn hLgn
  have hlipf' := lip_weaken hLfd hLcd (Qle_self_add hLgn) hlipf
  have hlipg' := lip_weaken hLgd hLcd (Qle_self_add_l hLfn) hlipg
  refine Req_trans (riemannIntegralI_certif_irrel hLfd hLfn hlipf hfcf
    hLcd hLcn hlipf' hfcf a w ha hw hwn) ?_
  refine Req_trans (riemannIntegralI_congr_unit hLcd hLcn hlipf' hfcf hlipg' hfcg
    a w ha hw hwn hfg) ?_
  exact riemannIntegralI_certif_irrel hLcd hLcn hlipg' hfcg
    hLgd hLgn hlipg hfcg a w ha hw hwn

/-- **The window power is `Rpow` on its window**: for `m+1 ≤ x ≤ m+2`, `(powWinTest m n) x ≈ xⁿ`.
    The mirror of `powBandGen_eq_Rpow_on`, with `powWinTest_succ_inert` as the band-inertness step.
    Proof by induction: base `≡ 1 = x⁰`; step chains `powWinTest_succ_inert` (`≈ (prev)·x`), the IH
    (`prev ≈ xⁿ`) and `Rmul_comm` to land on `Rpow x (n+1) = x·xⁿ`. -/
theorem powWinTest_eq_Rpow_on (m n : Nat) {x : Real}
    (hlo : Rle (ofQ (⟨(m : Int) + 1, 1⟩ : Q) Nat.one_pos) x)
    (hhi : Rle x (ofQ (⟨(m : Int) + 2, 1⟩ : Q) Nat.one_pos)) :
    Req ((powWinTest m n).f x) (Rpow x n) := by
  induction n with
  | zero => exact Req_refl one
  | succ n ih =>
    refine Req_trans (powWinTest_succ_inert m n hlo hhi) ?_
    refine Req_trans (Rmul_congr ih (Req_refl x)) ?_
    exact Rmul_comm (Rpow x n) x

/-- **The weight swap to the `mellinHat` tail term**: the wide-band `(ψ · powBandGen lo hi … n)`
    window integral over `[m+1, m+2]` equals `twTerm ψ n m` (the integer-window `(ψ · powWinTest m n)`
    integral). On the affine window point `y = affineMap (m+1) 1 x` (`0 ≤ x ≤ 1`, so `y ∈ [m+1,m+2]`,
    and `[m+1,m+2] ⊆ [lo,hi]` by `hc1`, `hc2`), both integrands reduce to `ψ(y)·yⁿ`:
    `powBandGen` by `powBandGen_eq_Rpow_on`, `powWinTest` by `powWinTest_eq_Rpow_on`. The
    different-`L` window congruence `riemannIntegralI_congr_unit_mod` closes it. -/
theorem twTerm_eq_window_powBandGen (ψ : L2Test) (n m : Nat) (lo hi : Q)
    (hlod : 0 < lo.den) (hhid : 0 < hi.den) (hle : Qle lo hi) (hlon : 0 ≤ lo.num)
    (hc1 : Qle lo (⟨(m : Int) + 1, 1⟩ : Q))
    (hc2 : Qle (⟨(m : Int) + 2, 1⟩ : Q) hi) :
    Req (riemannIntegralI
          (L2Test.mul ψ (powBandGen lo hi hlod hhid hle hlon n)).hLd
          (L2Test.mul ψ (powBandGen lo hi hlod hhid hle hlon n)).hLn
          (L2Test.mul ψ (powBandGen lo hi hlod hhid hle hlon n)).hlip
          (L2Test.mul ψ (powBandGen lo hi hlod hhid hle hlon n)).hfc
          (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide))
        (twTerm ψ n m) := by
  have hlo' : 0 < (⟨(m : Int) + 1, 1⟩ : Q).den := Nat.one_pos
  have hw' : 0 < (⟨1, 1⟩ : Q).den := Nat.one_pos
  have hm2' : 0 < (⟨(m : Int) + 2, 1⟩ : Q).den := Nat.one_pos
  have hw'nn : Rnonneg (ofQ (⟨1, 1⟩ : Q) hw') := Rnonneg_ofQ hw' (by decide)
  refine riemannIntegralI_congr_unit_mod
    (L2Test.mul ψ (powBandGen lo hi hlod hhid hle hlon n)).hLd
    (L2Test.mul ψ (powBandGen lo hi hlod hhid hle hlon n)).hLn
    (L2Test.mul ψ (powBandGen lo hi hlod hhid hle hlon n)).hlip
    (L2Test.mul ψ (powBandGen lo hi hlod hhid hle hlon n)).hfc
    (l2L_den ψ (powWinTest m n)) (l2L_num ψ (powWinTest m n))
    (l2lip ψ (powWinTest m n)) (l2fc ψ (powWinTest m n))
    (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide) ?_
  intro x h0 h1
  -- The affine window point `y = (m+1) + 1·x` and its membership in `[m+1, m+2] ⊆ [lo, hi]`.
  have hy_base :
      Rle (ofQ (⟨(m : Int) + 1, 1⟩ : Q) hlo')
        (Radd (ofQ (⟨(m : Int) + 1, 1⟩ : Q) hlo') (Rmul (ofQ (⟨1, 1⟩ : Q) hw') x)) :=
    Rle_self_Radd_right (Rnonneg_Rmul hw'nn (Rnonneg_of_Rle_zero h0))
  have hxle1 : Rle (Rmul (ofQ (⟨1, 1⟩ : Q) hw') x) (ofQ (⟨1, 1⟩ : Q) hw') :=
    Rle_trans (Rmul_le_Rmul_left hw'nn h1)
      (Rle_of_Req (Rmul_one (ofQ (⟨1, 1⟩ : Q) hw')))
  have hqeq : Qeq (add (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)) (⟨(m : Int) + 2, 1⟩ : Q) := by
    simp only [Qeq, add]; push_cast; ring_uor
  have boundB :
      Rle (Radd (ofQ (⟨(m : Int) + 1, 1⟩ : Q) hlo') (Rmul (ofQ (⟨1, 1⟩ : Q) hw') x))
        (ofQ (⟨(m : Int) + 2, 1⟩ : Q) hm2') :=
    Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _)) hxle1)
      (Rle_of_Req (Req_trans (Radd_ofQ_ofQ hlo' hw')
        (ofQ_congr (add_den_pos hlo' hw') hm2' hqeq)))
  have hy_lo :
      Rle (ofQ lo hlod)
        (Radd (ofQ (⟨(m : Int) + 1, 1⟩ : Q) hlo') (Rmul (ofQ (⟨1, 1⟩ : Q) hw') x)) :=
    Rle_trans (Rle_ofQ_ofQ hlod hlo' hc1) hy_base
  have hy_hi :
      Rle (Radd (ofQ (⟨(m : Int) + 1, 1⟩ : Q) hlo') (Rmul (ofQ (⟨1, 1⟩ : Q) hw') x))
        (ofQ hi hhid) :=
    Rle_trans boundB (Rle_ofQ_ofQ hm2' hhid hc2)
  -- Both weights reduce to `Rpow y n` on the window.
  have hpb := powBandGen_eq_Rpow_on lo hi hlod hhid hle hlon n hy_lo hy_hi
  have hpw := powWinTest_eq_Rpow_on m n hy_base boundB
  exact Req_trans (Rmul_congr (Req_refl _) hpb) (Req_symm (Rmul_congr (Req_refl _) hpw))

end Multiplicity.UOR.Bridge.F1Square.Square
