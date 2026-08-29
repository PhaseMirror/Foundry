/-
F1 square — **the convolution's Mellin tail-term obeys the genSum-ready decay bound**
(`ConvTwTermBound.lean`): landing `mulConvR_window_decay` into the `twTerm_bound` shape. For a
`t`-window inside `(0,1]` and `f` with order-`(n+2)` window decay, the `m`-th twisted tail term of the
convolution's Mellin transform (at the minimal window-clearing clamp `S = m+2`) satisfies

    `|twTerm (mulConvRTest f g (m+2)) n m|  ≤  (Cconst·2ⁿ) / ((m+1)·m)`,  `Cconst = w·C_f·M_g·(1/a)`,

the exact `(C·2ⁿ)/((m+1)m)` form that `genSum_RReg` consumes — so the genuine (clamp-free, by
`twTerm_mulConv_S_indep`) per-window value is summable and the clamp-free half-line transform
`mellinHat(f⋆g)` converges.

The proof mirrors `twTerm_bound`'s single-window logic: on the window `[m+1,m+2]` the clamp is inert
(`qBandQ_eq_of_band` + `mulConvR_congr`), `mulConvR_window_decay` bounds the convolution value by
`Cconst/(m+1)^{n+2}`, the twist `× powWinTest.M ≤ (m+2)ⁿ` and the collapse `(m+2)ⁿ/(m+1)^{n+2} ≤
2ⁿ/((m+1)m)` (reproved inline as `cd_pow_core`/`cd_collapse`, since `MellinHat`'s versions are private)
land the genSum shape, all through `riemannIntegralI_abs_le_window`.

HONEST SCOPE. The per-window decay bound in genSum-ready form. It builds NO generalized tail
(`convTwTail`/`convMellinHat`), NO `∫_t` reconstruction, NO factorization `M[f⋆g]=M[f]·M[g]`, NO
positivity, NO crux. `f`-decay is an explicit hypothesis; the `t`-window is `(0,1]`. Step 4
(band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MellinConv
import Foundations.F1.Square.MellinHat
import Foundations.F1.Analysis.MulConvRDecay
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- The Nat core of the twisted decay (local copy of `MellinHat.pow_window_core`, which is private). -/
private theorem cd_pow_core (m n : Nat) :
    (m + 2) ^ n * ((m + 1) * m) ≤ 2 ^ n * (m + 1) ^ (n + 2) := by
  have h1 : (m + 2) ^ n ≤ 2 ^ n * (m + 1) ^ n := by
    calc (m + 2) ^ n ≤ (2 * (m + 1)) ^ n := Nat.pow_le_pow_left (by omega) n
    _ = 2 ^ n * (m + 1) ^ n := Nat.mul_pow 2 (m + 1) n
  have h2 : (m + 1) * m ≤ (m + 1) * (m + 1) := Nat.mul_le_mul_left _ (by omega)
  have h3 : (m + 1) ^ n * ((m + 1) * (m + 1)) = (m + 1) ^ (n + 2) := by
    rw [Nat.pow_succ, Nat.pow_succ, Nat.mul_assoc]
  calc (m + 2) ^ n * ((m + 1) * m)
      ≤ (2 ^ n * (m + 1) ^ n) * ((m + 1) * (m + 1)) := Nat.mul_le_mul h1 h2
    _ = 2 ^ n * ((m + 1) ^ n * ((m + 1) * (m + 1))) := Nat.mul_assoc _ _ _
    _ = 2 ^ n * (m + 1) ^ (n + 2) := by rw [h3]

/-- The exponent-generic collapse (local copy of `MellinHat.tw_collapse`, which is private). -/
private theorem cd_collapse {C : Q} (_hCd : 0 < C.den) (hCn : 0 ≤ C.num) (m n : Nat) :
    Qle (mul (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q)) (⟨(((m + 2) ^ n : Nat) : Int), 1⟩ : Q))
        (mul (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) (⟨1, (m + 1) * m⟩ : Q)) := by
  show ((C.num * 1) * (((m + 2) ^ n : Nat) : Int))
        * ((((C.den * 1) * ((m + 1) * m) : Nat)) : Int)
      ≤ ((C.num * ((2 ^ n : Nat) : Int)) * 1)
        * ((((C.den * ((m + 1) ^ (n + 2))) * 1 : Nat)) : Int)
  push_cast
  generalize hA : ((m : Int) + 2) ^ n = A
  generalize hB : ((m : Int) + 1) ^ (n + 2) = B
  generalize hT : (2 : Int) ^ n = T
  have hcoreZ : A * (((m : Int) + 1) * (m : Int)) ≤ T * B := by
    rw [← hA, ← hB, ← hT]
    exact_mod_cast cd_pow_core m n
  have e1 : C.num * 1 * A * ((C.den : Int) * 1 * (((m : Int) + 1) * (m : Int)))
      = (C.num * (C.den : Int)) * (A * (((m : Int) + 1) * (m : Int))) := by ring_uor
  have e2 : C.num * T * 1 * ((C.den : Int) * B * 1)
      = (C.num * (C.den : Int)) * (T * B) := by ring_uor
  rw [e1, e2]
  exact Int.mul_le_mul_of_nonneg_left hcoreZ
    (Int.mul_nonneg hCn (Int.ofNat_nonneg C.den))

/-- **The convolution's Mellin tail-term obeys the genSum-ready decay bound.** For a `t`-window
    `[lo,lo+w] ⊆ (0,1]` (`a ≤ 1`) and `f` with order-`(n+2)` window decay `|f(y)| ≤ C_f/(k+1)^{n+2}`
    for `|y| ≥ k+1`, the `m`-th twisted tail term of the convolution's Mellin transform at the minimal
    window-clearing clamp `S = m+2` satisfies `|twTerm (mulConvRTest f g (m+2)) n m| ≤
    (w·C_f·M_g·(1/a)·2ⁿ)/((m+1)·m)` — the `(C·2ⁿ)/((m+1)m)` shape `genSum_RReg` consumes. -/
theorem convTwTerm_bound (f g : L2Test) (n : Nat) {Cf : Q} (hCfd : 0 < Cf.den) (hCfn : 0 ≤ Cf.num)
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
      Rle (Rabs (f.f y)) (ofQ (mul Cf (⟨1, (k + 1) ^ (n + 2)⟩ : Q))
        (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos k)))))
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (ha1 : Qle a (⟨1, 1⟩ : Q))
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hw1 : Qle (add lo w) (⟨1, 1⟩ : Q)) (m : Nat) (hm : 1 ≤ m) :
    Rle (Rabs (twTerm (mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) Nat.one_pos
          (by show (0 : Int) ≤ (m : Int) + 2; omega) a han had lo w hlo hw hwn) n m))
        (ofQ (mul (mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))
              (⟨1, (m + 1) * m⟩ : Q))
          (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos
            (Qmul_den_pos hw hCfd) g.hMd) (Qinv_den_pos han)) Nat.one_pos)
            (digamma_succ_mul_pos hm))) := by
  have hSd : (0 : Nat) < (⟨(m : Int) + 2, 1⟩ : Q).den := Nat.one_pos
  have hSn : (0 : Int) ≤ (⟨(m : Int) + 2, 1⟩ : Q).num := by show (0 : Int) ≤ (m : Int) + 2; omega
  -- the window-decay constant and its num/den facts
  have hCcd : 0 < (mul (mul (mul w Cf) g.M) (Qinv a)).den :=
    Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hw hCfd) g.hMd) (Qinv_den_pos han)
  have hCcn : (0 : Int) ≤ (mul (mul (mul w Cf) g.M) (Qinv a)).num :=
    Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg hwn hCfn) g.hMn)
      (Int.le_of_lt (Qinv_num_pos had))
  -- pointwise bound on the twisted integrand at window points
  have hpt : ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((fun t => Rmul ((mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) hSd hSn a han had
              lo w hlo hw hwn).f t) ((powWinTest m n).f t))
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul (mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
              ((powWinTest m n).M))
          (Qmul_den_pos (Qmul_den_pos hCcd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))
            (powWinTest m n).hMd)) := by
    intro x h0 h1
    have hp_lo : Rle (ofQ (⟨0, 1⟩ : Q) (by decide))
        (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x) := by
      refine Rle_trans (Rle_ofQ_ofQ (by decide) Nat.one_pos ?_)
        (Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide))
          (Rnonneg_of_Rle_zero h0)))
      show Qle (⟨0, 1⟩ : Q) (⟨(m : Int) + 1, 1⟩ : Q)
      simp only [Qle]; push_cast; omega
    have hp_mid : Rle (ofQ (⟨(m : Int) + 1, 1⟩ : Q) Nat.one_pos)
        (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x) :=
      Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide))
        (Rnonneg_of_Rle_zero h0))
    have hp_hi : Rle (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)
        (ofQ (⟨(m : Int) + 2, 1⟩ : Q) hSd) := by
      have hxwx : Rle (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) x) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
        Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) h1)
          (Rle_of_Req (Rmul_one (ofQ (⟨1, 1⟩ : Q) (by decide))))
      refine Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _)) hxwx)
        (Rle_trans (Rle_of_Req (Radd_ofQ_ofQ Nat.one_pos (by decide)))
          (Rle_ofQ_ofQ (add_den_pos Nat.one_pos (by decide)) hSd
            (by show Qle (add (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)) (⟨(m : Int) + 2, 1⟩ : Q);
                simp only [Qle, add]; push_cast; omega)))
    have hp_nn : Rnonneg (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x) :=
      Rnonneg_of_Rle_zero (Rle_trans
        (Rle_zero_of_Rnonneg (Rnonneg_ofQ Nat.one_pos (by show (0 : Int) ≤ (m : Int) + 1; omega)))
        hp_mid)
    have hpS : Rle (Rabs (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x))
        (ofQ (⟨(m : Int) + 2, 1⟩ : Q) hSd) := Rle_trans (Rle_of_Req (Rabs_of_nonneg hp_nn)) hp_hi
    have hqeq : Req (qBandQ (⟨0, 1⟩ : Q) (⟨(m : Int) + 2, 1⟩ : Q) (by decide) hSd
        (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x))
        (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x) :=
      qBandQ_eq_of_band hp_lo hp_hi
    -- value bound: |mulConvRTest.f p| ≤ Cconst/(m+1)^{n+2}
    have hval : Rle (Rabs ((mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) hSd hSn a han had
          lo w hlo hw hwn).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCcd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))) := by
      refine Rle_trans (Rle_of_Req (Rabs_congr (mulConvR_congr f g
        (qBandQ (⟨0, 1⟩ : Q) (⟨(m : Int) + 2, 1⟩ : Q) (by decide) hSd
          (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x))
        (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)
        (⟨(m : Int) + 2, 1⟩ : Q) hSd hSn
        (clampS_absle (⟨(m : Int) + 2, 1⟩ : Q) hSd hSn _) hpS a han had lo w hlo hw hwn hqeq))) ?_
      refine Rle_trans (mulConvR_window_decay f g n hCfd hCfn hfdec m
        (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x) hp_mid
        (⟨(m : Int) + 2, 1⟩ : Q) hSd hSn hpS a han had ha1 lo w hlo hw hwn hw1) ?_
      exact Rle_of_Req (ofQ_congr _ _ (by simp only [Qeq, mul]; push_cast; ring_uor))
    -- multiply by the twist
    refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
    refine Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs _)
      (Rnonneg_ofQ (powWinTest m n).hMd (powWinTest m n).hMn) hval ((powWinTest m n).hbd _)) ?_
    exact Rle_of_Req (Rmul_ofQ_ofQ _ _)
  -- integrate: |twTerm| ≤ w·(pointwise bound) with w = window width 1
  have habs : Rle (Rabs (twTerm (mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) hSd hSn a han had
          lo w hlo hw hwn) n m))
      (ofQ (mul (⟨1, 1⟩ : Q) (mul (mul (mul (mul (mul w Cf) g.M) (Qinv a))
              (⟨1, (m + 1) ^ (n + 2)⟩ : Q)) ((powWinTest m n).M)))
        (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos hCcd
          (Nat.pos_pow_of_pos _ (Nat.succ_pos m))) (powWinTest m n).hMd))) :=
    riemannIntegralI_abs_le_window (l2L_den (mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) hSd hSn a han had
        lo w hlo hw hwn) (powWinTest m n))
      (l2L_num (mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) hSd hSn a han had lo w hlo hw hwn)
        (powWinTest m n))
      (l2lip (mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) hSd hSn a han had lo w hlo hw hwn)
        (powWinTest m n))
      (l2fc (mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) hSd hSn a han had lo w hlo hw hwn)
        (powWinTest m n))
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      (mul (mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨1, (m + 1) ^ (n + 2)⟩ : Q)) ((powWinTest m n).M))
      Nat.one_pos (by decide) (by decide)
      (Qmul_den_pos (Qmul_den_pos hCcd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))) (powWinTest m n).hMd)
      hpt
  -- collapse to the genSum shape
  have hq : Qle (mul (⟨1, 1⟩ : Q) (mul (mul (mul (mul (mul w Cf) g.M) (Qinv a))
          (⟨1, (m + 1) ^ (n + 2)⟩ : Q)) ((powWinTest m n).M)))
      (mul (mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))
        (⟨1, (m + 1) * m⟩ : Q)) := by
    refine Qle_congr_left
      (a := mul (mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
        ((powWinTest m n).M))
      (Qmul_den_pos (Qmul_den_pos hCcd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))) (powWinTest m n).hMd)
      (by simp only [Qeq, mul]; push_cast; ring_uor) ?_
    refine Qle_trans (Qmul_den_pos (Qmul_den_pos hCcd
      (Nat.pos_pow_of_pos _ (Nat.succ_pos m))) Nat.one_pos) ?_ (cd_collapse hCcd hCcn m n)
    exact qmul_le_left_mono
      (Int.mul_nonneg hCcn (by show (0 : Int) ≤ 1; decide)) (powWinTest_M_le m n)
  exact Rle_trans habs (Rle_ofQ_ofQ _ _ hq)

end Multiplicity.UOR.Bridge.F1Square.Square
