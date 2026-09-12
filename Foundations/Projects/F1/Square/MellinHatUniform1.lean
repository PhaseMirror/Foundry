/-
F1 square — **`mellinHat` as the 1-uniform-tiling improper Mellin integral** (`MellinHatUniform1.lean`):
instantiating the committed `mellinHat_dilate_scaled` at the trivial scale `s = 1` and collapsing the
scale factor, so the tiling-independence hypothesis `htile` (carried in `MellinHatCovariance.lean`)
reduces to a pure WIDTH comparison — the `s`-uniform tiling against the `1`-uniform tiling of the same
improper integral.

At `s = ⟨1,1⟩` the committed identity

    `s^(n+1) · mellinHat (dilate_s φ) n  =  ∫_{[0,s]}(φ·powBandGen) + Rlim (scaled sums)`

specialises: the twist factor `qpow 1 (n+1)` is rationally `1` (so `ofQ (qpow 1 (n+1)) ≈ one`, and
`Rmul one z ≈ z`), and the dilated test `dilate_1 φ` is pointwise-`≈` to `φ` (`dilateTest_one`), which
lifts through both `mellinHat` summands: the compact `mellinMoment` (its integrand's Lipschitz modulus
is only weakened, reconciled by `riemannIntegral_congr_mod`) and the twisted `twTail` (window-by-window
via `riemannIntegralI_congr_unit_mod`, then `genSum_congr`, then `Rlim_congr`). Composing gives
`mellinHat φ n = ∫_{[0,1]}(φ·powBandGen_{[0,2]}) + Rlim (1-uniform scaled sums)` — the same right-hand
side as the `s = 1` instance of `mellinHat_dilate_scaled`, now identified with `mellinHat φ` itself.

HONEST SCOPE. `mellinHat(φ)` expressed as the 1-uniform-tiling improper Mellin integral
(`mellinHat_dilate_scaled` at `s = 1` + `qpow 1 = 1` + the `dilate_1 φ ≈ φ` congruence through
`mellinMoment` and `twTail`), reducing the committed dilation-covariance hypothesis `htile` to a pure
width comparison (`s`-uniform vs `1`-uniform). It builds NO width comparison, NO factorization, NO
positivity, NO determinacy, NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MellinHatDilateScaled
import Foundations.F1.Square.MultShift
import Foundations.F1.Square.TwTermPowBand
import Foundations.F1.Square.IntervalSplit
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The wide band `[0, 1+1]` low-end containment `0 ≤ 1 + 1` (own proof; `Qle` is a `Prop` over
    `Int ≤`, proof-irrelevant, so it coincides definitionally with the private `band01_le'` inside
    `MellinHatDilateScaled` at `s = 1`, hence the `powBandGen` weights are the same term). -/
private theorem band01_le1 :
    Qle (⟨0, 1⟩ : Q) (add (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q)) := by decide

/-- `qpow ⟨1,1⟩ k` is rationally `1`. -/
private theorem qpow_one_Qeq : ∀ k : Nat, Qeq (qpow (⟨1, 1⟩ : Q) k) (⟨1, 1⟩ : Q)
  | 0 => Qeq_refl _
  | (k + 1) => by
      show Qeq (mul (⟨1, 1⟩ : Q) (qpow (⟨1, 1⟩ : Q) k)) (⟨1, 1⟩ : Q)
      have ih := qpow_one_Qeq k
      simp only [Qeq, mul] at ih ⊢
      push_cast at ih ⊢
      -- ih : (qpow ⟨1,1⟩ k).num * 1 = 1 * (qpow ⟨1,1⟩ k).den
      omega

/-- `ofQ (qpow ⟨1,1⟩ (n+1)) ≈ one`. -/
private theorem ofQ_qpow_one (n : Nat) :
    Req (ofQ (qpow (⟨1, 1⟩ : Q) (n + 1)) (qpow_den_pos (by decide) (n + 1))) one :=
  Req_of_seq_Qeq (fun _ => qpow_one_Qeq (n + 1))

/-- The per-window twisted term is unchanged (up to `≈`) by the trivial dilation `dilate_1 φ ≈ φ`:
    the two integrands agree pointwise and their (different) Lipschitz moduli are reconciled by
    `riemannIntegralI_congr_unit_mod`. -/
private theorem twTerm_dilate1_congr (φ : L2Test) (n m : Nat) :
    Req (twTerm (dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ) n m) (twTerm φ n m) :=
  riemannIntegralI_congr_unit_mod
    (l2L_den (dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ) (powWinTest m n))
    (l2L_num (dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ) (powWinTest m n))
    (l2lip (dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ) (powWinTest m n))
    (l2fc (dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ) (powWinTest m n))
    (l2L_den φ (powWinTest m n)) (l2L_num φ (powWinTest m n))
    (l2lip φ (powWinTest m n)) (l2fc φ (powWinTest m n))
    (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)
    (fun _ _ _ => Rmul_congr (dilateTest_one φ _) (Req_refl _))

/-- The twisted tail is unchanged (up to `≈`) by `dilate_1 φ ≈ φ`: `genSum_congr` on the per-window
    bridge, then `Rlim_congr`. -/
private theorem twTail_dilate1_congr (φ : L2Test) (n : Nat) {C : Q} (hCd : 0 < C.den)
    (hCn : 0 ≤ C.num)
    (hdec_dil : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdec_phi : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    Req (twTail (dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ) n hCd hCn hdec_dil)
        (twTail φ n hCd hCn hdec_phi) :=
  Rlim_congr _ _ _ _
    (fun _j => genSum_congr _ _ (fun m => twTerm_dilate1_congr φ n m) _)

/-- The compact Mellin moment is unchanged (up to `≈`) by `dilate_1 φ ≈ φ`: the integrands agree
    pointwise, their Lipschitz moduli reconcile by `riemannIntegral_congr_mod`. -/
private theorem mellinMoment_dilate1_congr (φ : L2Test) (n : Nat) :
    Req (mellinMoment (dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ) n)
        (mellinMoment φ n) := by
  have hq : Qle (l2L (dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ) (powTest n))
      (l2L φ (powTest n)) := by
    apply Qeq_le
    show Qeq (add (mul φ.M (powTest n).L) (mul (powTest n).M (mul φ.L (⟨1, 1⟩ : Q))))
             (add (mul φ.M (powTest n).L) (mul (powTest n).M φ.L))
    simp only [Qeq, add, mul]; push_cast; ring_uor
  exact riemannIntegral_congr_mod
    (l2L_den (dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ) (powTest n))
    (l2L_num (dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ) (powTest n))
    (l2lip (dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ) (powTest n))
    (l2fc (dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ) (powTest n))
    (l2L_den φ (powTest n)) (l2L_num φ (powTest n))
    (l2lip φ (powTest n)) (l2fc φ (powTest n))
    hq (fun x => Rmul_congr (dilateTest_one φ x) (Req_refl _))

/-- The whole transform is unchanged (up to `≈`) by `dilate_1 φ ≈ φ`: `Radd_congr` on the two halves. -/
private theorem mellinHat_dilate1_congr (φ : L2Test) (n : Nat) {C : Q} (hCd : 0 < C.den)
    (hCn : 0 ≤ C.num)
    (hdec_dil : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdec_phi : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    Req (mellinHat (dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ) n hCd hCn hdec_dil)
        (mellinHat φ n hCd hCn hdec_phi) :=
  Radd_congr (mellinMoment_dilate1_congr φ n)
    (twTail_dilate1_congr φ n hCd hCn hdec_dil hdec_phi)

/-- **`mellinHat` AS THE 1-UNIFORM-TILING IMPROPER MELLIN INTEGRAL.** Instantiating the committed
    `mellinHat_dilate_scaled` at `s = 1` and collapsing the trivial scale factor
    (`qpow 1 (n+1) ≈ 1`, `Rmul one z ≈ z`) and the trivial dilation (`dilate_1 φ ≈ φ`, lifted through
    `mellinMoment` and `twTail`),

      `mellinHat φ n  =  ∫_{[0,1]}(φ·powBandGen_{[0,2]})  +  Rlim (1-uniform scaled twisted sums)`.

    The right-hand side is exactly the `s = 1` instance of `mellinHat_dilate_scaled`'s output — the
    improper Mellin integral of `φ` against `tⁿ`, exhausted by the `1`-uniform tiling
    `{[0,1],[1,2],[2,3],…}`. This reduces the committed tiling-independence hypothesis `htile` to a
    pure width comparison (the `s`-uniform against this `1`-uniform tiling); it introduces NO width
    comparison, NO factorization, NO positivity, NO crux. -/
theorem mellinHat_eq_uniform1 (φ : L2Test) (n : Nat) {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec_phi : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdec_dil1 : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hReg : RReg (fun j => genSum (fun m => scaledTwTerm φ (⟨1, 1⟩ : Q) (by decide) (by decide) n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j))) :
    Req
      (mellinHat φ n hCd hCn hdec_phi)
      (Radd
        (riemannIntegralI
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos (by decide) (by decide)) band01_le1 (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos (by decide) (by decide)) band01_le1 (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos (by decide) (by decide)) band01_le1 (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos (by decide) (by decide)) band01_le1 (by decide) n)).hfc
          (mul (⟨1, 1⟩ : Q) (⟨0, 1⟩ : Q)) (mul (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q))
          (Qmul_den_pos (by decide) (by decide)) (Qmul_den_pos (by decide) (by decide))
          (Int.mul_nonneg (Int.le_of_lt (by decide)) (by decide)))
        (Rlim (fun j => genSum (fun m => scaledTwTerm φ (⟨1, 1⟩ : Q) (by decide) (by decide) n m)
          (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j)) hReg)) := by
  -- The committed scaled identity at s = 1.
  have E1 := mellinHat_dilate_scaled φ n (⟨1, 1⟩ : Q) (by decide) (by decide) hCd hCn hdec_dil1 hReg
  -- The trivial-scale collapse: Rmul (ofQ (qpow 1 (n+1))) z ≈ z.
  have hi : Req
      (Rmul (ofQ (qpow (⟨1, 1⟩ : Q) (n + 1)) (qpow_den_pos (by decide) (n + 1)))
        (mellinHat (dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ) n hCd hCn hdec_dil1))
      (mellinHat (dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ) n hCd hCn hdec_dil1) :=
    Req_trans (Rmul_congr (ofQ_qpow_one n) (Req_refl _))
      (Req_trans (Rmul_comm one _) (Rmul_one _))
  -- The trivial-dilation congruence through mellinHat.
  have hii := mellinHat_dilate1_congr φ n hCd hCn hdec_dil1 hdec_phi
  exact Req_trans (Req_symm hii) (Req_trans (Req_symm hi) E1)

end Multiplicity.UOR.Bridge.F1Square.Square
