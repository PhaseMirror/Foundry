/-
F1 square — **the convolution-schedule partial of the dilated tail is close to `K·twTail`**
(`DilTailPartialClose.lean`): for a fixed window point `t` with inner scale `clampedInv(a,t) ≥ 1`, and
any integer schedule `R` cofinal-above the dilated tail's canonical `digammaMidx (Cf·2ⁿ)`,

    `|Σ_{m<R j} dilTailIntegrand f g n m a t − g(t)·(1/max(t,a))·twTail (dilateTestR (1/max(t,a)) f) n|
        ≤ (g.M·(1/a))·3/(j+1)`,

a bound whose rate is UNIFORM in `t` (the weight `|g(t)·clampedInv| ≤ g.M·(1/a)` is `t`-uniform, and
`genSum_close_Rlim`'s `3/(j+1)` depends only on the scale-independent decay constant `Cf·2ⁿ`). This is
the per-`t` closeness the `∫_t` reconstruction of `M[f⋆g]=M[f]·M[g]` feeds through
`riemannIntegralI_dist_le_of_close` and `Rlim_eval_real_rate` to commute the tail sum with `∫_t`.

Chain: `genSum_Rmul_of_termwise` pulls the `t`-constant `K = g(t)·clampedInv(a,t)` out of the finite
sum (`dilTailIntegrand_m t = K·twTerm (dilate c_t f) n m` definitionally); `Rmul_sub_distrib` factors
`K` out of the difference; `genSum_close_Rlim` bounds `|genSum (twTerm (dilate c_t f) n) (R j) − twTail|`
by `3/(j+1)` (its `Rlim` is `twTail (dilate c_t f) n` by definition); the `|K| ≤ g.M·(1/a)` weight bound
closes the product.

HONEST SCOPE. The per-`t` closeness only. It builds NO limit-inside-the-integral, NO `Ttail` test, NO
covariance application, NO factorization `M[f⋆g]=M[f]·M[g]`, NO positivity, NO crux. Step 4
(band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.DilTailUniformBound
import Foundations.F1.Square.GenSumCloseRlim
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- **The convolution-schedule partial of the dilated tail is within `(g.M·(1/a))·3/(j+1)` of
    `K·twTail`.** For `t` with `clampedInv(a,t) ≥ 1` and any schedule `R` with
    `digammaMidx (Cf·2ⁿ) j ≤ R j`,
    `|Σ_{m<R j} dilTailIntegrand·t − g(t)·clampedInv·twTail (dilate c_t f) n| ≤ (g.M·(1/a))·3/(j+1)`.
    The rate is uniform in `t`. -/
theorem dilTail_partial_close (f g : L2Test) (n : Nat) {Cf : Q}
    (hCfd : 0 < Cf.den) (hCfn : 0 ≤ Cf.num)
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
      Rle (Rabs (f.f y)) (ofQ (mul Cf (⟨1, (k + 1) ^ (n + 2)⟩ : Q))
        (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos k)))))
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (t : Real)
    (hc1 : Rle one (clampedInv a han had t))
    (R : Nat → Nat) (hgrow : ∀ j, digammaMidx (mul Cf (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j ≤ R j)
    (j : Nat) :
    Rle (Rabs (Rsub
          (genSum (fun m => dilTailIntegrand f g n m a han had t) (R j))
          (Rmul (Rmul (g.f t) (clampedInv a han had t))
                (twTail (dilateTestR (clampedInv a han had t) (Qinv a) (Qinv_den_pos han)
                          (Int.le_of_lt (Qinv_num_pos had)) ((recipTest a han had).hbd t) f)
                        n hCfd hCfn
                        (dilateTestR_window_hdec f n hCfd hCfn hfdec (clampedInv a han had t) (Qinv a)
                          (Qinv_den_pos han) (Int.le_of_lt (Qinv_num_pos had))
                          ((recipTest a han had).hbd t) hc1)))))
        (ofQ (mul (mul g.M (Qinv a)) (⟨3, j + 1⟩ : Q))
          (Qmul_den_pos (Qmul_den_pos g.hMd (Qinv_den_pos han)) (Nat.succ_pos j))) := by
  -- (1) pull the t-constant K = g(t)·clampedInv out of the finite sum
  have hpull := genSum_Rmul_of_termwise
    (c := Rmul (g.f t) (clampedInv a han had t))
    (T := fun m => dilTailIntegrand f g n m a han had t)
    (U := fun m => twTerm (dilateTestR (clampedInv a han had t) (Qinv a) (Qinv_den_pos han)
      (Int.le_of_lt (Qinv_num_pos had)) ((recipTest a han had).hbd t) f) n m)
    (fun _ => Req_refl _) (R j)
  -- (2) the tail closeness: |genSum (twTerm (dilate c_t f) n) (R j) − twTail| ≤ 3/(j+1)
  have hclose := genSum_close_Rlim
    (fun m => twTerm (dilateTestR (clampedInv a han had t) (Qinv a) (Qinv_den_pos han)
      (Int.le_of_lt (Qinv_num_pos had)) ((recipTest a han had).hbd t) f) n m)
    (K := mul Cf (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))
    (Qmul_den_pos hCfd Nat.one_pos)
    (Int.mul_nonneg hCfn (Int.ofNat_nonneg _))
    (twTerm_bound (dilateTestR (clampedInv a han had t) (Qinv a) (Qinv_den_pos han)
      (Int.le_of_lt (Qinv_num_pos had)) ((recipTest a han had).hbd t) f) n hCfd hCfn
      (dilateTestR_window_hdec f n hCfd hCfn hfdec (clampedInv a han had t) (Qinv a)
        (Qinv_den_pos han) (Int.le_of_lt (Qinv_num_pos had)) ((recipTest a han had).hbd t) hc1))
    R hgrow j
  -- (3) the weight bound |K| ≤ g.M·(1/a)
  have hK : Rle (Rabs (Rmul (g.f t) (clampedInv a han had t)))
      (ofQ (mul g.M (Qinv a)) (Qmul_den_pos g.hMd (Qinv_den_pos han))) := by
    refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
    refine Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs _)
      (Rnonneg_ofQ (Qinv_den_pos han) (Int.le_of_lt (Qinv_num_pos had)))
      (g.hbd _) ((recipTest a han had).hbd _)) ?_
    exact Rle_of_Req (Rmul_ofQ_ofQ _ _)
  -- assemble: factor K out of the difference, then bound |K|·|Rsub| ≤ (g.M/a)·(3/(j+1))
  refine Rle_trans (Rle_of_Req (Rabs_congr
    (Req_trans (Rsub_congr hpull (Req_refl _)) (Req_symm (Rmul_sub_distrib _ _ _))))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
  refine Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs _)
    (Rnonneg_ofQ (Nat.succ_pos j) (by decide : (0 : Int) ≤ 3)) hK hclose) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ _ _)

end Multiplicity.UOR.Bridge.F1Square.Square
