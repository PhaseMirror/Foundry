/-
F1 square — **the convolution's Mellin tail-term factors as the g-weighted dilated tail-term of `f`**
(`TwTermMulConvDilated.lean`): for a window that fits inside the clamp (`m+2 ≤ S`), the `m`-th twisted
tail term of the convolution's Mellin transform is the `t`-integral of the `g`-weighted `m`-th twisted
tail term of the *dilated* `f`:

    `twTerm (mulConvRTest f g S) n m  ≈  ∫_t (g(t)·(1/max(t,a))) · twTerm (dilateTestR (1/max(t,a)) f) n m  dt`.

This is the per-window bridge from the convolution side (`mulConvRTest`) onto the **dilation-covariance**
side (`twTerm` of a real-scale-dilated test), where `mellinHat_dilate_covariance_real_seq` lives — so it
is the step that connects the convolution's per-window Mellin data to the covariance
`cⁿ⁺¹·mellinHat(dilateTestR c f) = mellinHat f`. It composes `mellinConv_fubini` (the outer `∫_t` form)
with `dilMellinF_eq_twTerm` inside the integral: on the window `[m+1,m+2] ⊆ [0,S]` the inner `x`-integral
`dilMellinF` is inert-clamped and equals the dilated tail term `twTerm (dilateTestR (clampedInv a t) f) n m`,
transported across the `t`-integral by `riemannIntegralI_congr` (the target integrand inherits the swapped
outer test's Lipschitz/congruence certificate through the pointwise equality `dilTail_ptw`).

The dilated test is clamped at the scale bound `S' = 1/a` (`clampedInv(a,t)` is bounded by `1/a`, via
`recipTest.hbd`), a fixed rational independent of `t`.

WHY THIS MATTERS. `twTerm (mulConvRTest f g S) n m` is the `m`-th tail term of `mellinHat (mulConvRTest f g S)`;
the clamp is inert on windows `m+2 ≤ S` (and clamp-independent there, `twTerm_mulConv_S_indep`), so this
factored form is the genuine per-window Mellin value. Assembling these over `m` (the half-line tail) and
reading off the covariance is the remaining route to `M[f⋆g]=M[f]·M[g]`.

HONEST SCOPE. The per-window factorization onto the dilated-tail form. It builds NO `∫_t` reconstruction
of `M[g]`, NO half-line assembly over `m`, NO application of the dilation covariance, NO factorization
`M[f⋆g]=M[f]·M[g]`, NO positivity, NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.MellinConv
import Multiplicity.F1Square.Square.MellinHat
import Multiplicity.F1Square.Square.DilMellinFEval

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- **The dilated-tail integrand** `t ↦ (g(t)·(1/max(t,a)))·twTerm (dilateTestR (1/max(t,a)) f) n m` —
    the `x`-constant weight `g(t)·clampedInv(a,t)` against the `m`-th twisted tail term of the real-scale
    dilation `f(clampedInv(a,t)·x)` (clamped at the scale bound `1/a`). The `t`-integrand of the factored
    convolution tail-term. -/
def dilTailIntegrand (f g : L2Test) (n m : Nat) (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (t : Real) : Real :=
  Rmul (Rmul (g.f t) (clampedInv a han had t))
    (twTerm (dilateTestR (clampedInv a han had t) (Qinv a) (Qinv_den_pos han)
      (Int.le_of_lt (Qinv_num_pos had)) ((recipTest a han had).hbd t) f) n m)

/-- **The swapped outer test's value equals the dilated-tail integrand at each `t`** (for `m+2 ≤ S`) —
    the `g`-pullout `coupOuterTestSwap_gpull` puts it in `(g·clampedInv)·dilMellinF` form, then
    `dilMellinF_eq_twTerm` evaluates the inert-clamped inner integral as `twTerm (dilateTestR c f) n m`. -/
theorem dilTail_ptw (f g : L2Test) (n m : Nat) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den)
    (hwn : 0 ≤ w.num) (hSm : Qle (add (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)) S) (t : Real) :
    Req ((coupOuterTestSwap f g (powWinTest m n) S hSd hSn a han had
            (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)).f t)
        (dilTailIntegrand f g n m a han had t) :=
  Req_trans
    (coupOuterTestSwap_gpull f g (powWinTest m n) S hSd hSn a han had
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide) t)
    (Rmul_congr (Req_refl _)
      (dilMellinF_eq_twTerm f n m S hSd a han had t hSm (Qinv a) (Qinv_den_pos han)
        (Int.le_of_lt (Qinv_num_pos had)) ((recipTest a han had).hbd t)))

/-- **The convolution's Mellin tail-term factors as the g-weighted dilated tail-term of `f`.** For
    `m+2 ≤ S`, `twTerm (mulConvRTest f g S) n m = ∫_t (g(t)·(1/max(t,a)))·twTerm (dilateTestR (1/max(t,a)) f) n m dt`.
    Composes `mellinConv_fubini` (the outer `∫_t` form of the convolution–Mellin pairing at the window
    `[m+1,m+2]`, which is definitionally `twTerm (mulConvRTest f g S) n m`) with `riemannIntegralI_congr`
    rewriting the inner integral via `dilTail_ptw`. The per-window bridge onto the dilation-covariance side. -/
theorem twTerm_mulConv_dilated (f g : L2Test) (n m : Nat) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den)
    (hwn : 0 ≤ w.num) (hSm : Qle (add (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)) S) :
    Req (twTerm (mulConvRTest f g S hSd hSn a han had lo w hlo hw hwn) n m)
        (riemannIntegralI
          (coupOuterTestSwap f g (powWinTest m n) S hSd hSn a han had
            (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)).hLd
          (coupOuterTestSwap f g (powWinTest m n) S hSd hSn a han had
            (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)).hLn
          (fun t t' => Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr
            (Req_symm (dilTail_ptw f g n m S hSd hSn a han had lo w hlo hw hwn hSm t))
            (Req_symm (dilTail_ptw f g n m S hSd hSn a han had lo w hlo hw hwn hSm t')))))
            ((coupOuterTestSwap f g (powWinTest m n) S hSd hSn a han had
              (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)).hlip t t'))
          (fun t t' h => Req_trans
            (Req_symm (dilTail_ptw f g n m S hSd hSn a han had lo w hlo hw hwn hSm t))
            (Req_trans ((coupOuterTestSwap f g (powWinTest m n) S hSd hSn a han had
                (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)).hfc t t' h)
              (dilTail_ptw f g n m S hSd hSn a han had lo w hlo hw hwn hSm t')))
          lo w hlo hw hwn) := by
  refine Req_trans
    (mellinConv_fubini f g (powWinTest m n) S hSd hSn a han had lo w hlo hw hwn
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)) ?_
  exact riemannIntegralI_congr
    (coupOuterTestSwap f g (powWinTest m n) S hSd hSn a han had
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)).hLd
    (coupOuterTestSwap f g (powWinTest m n) S hSd hSn a han had
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)).hLn
    (coupOuterTestSwap f g (powWinTest m n) S hSd hSn a han had
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)).hlip
    (coupOuterTestSwap f g (powWinTest m n) S hSd hSn a han had
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)).hfc
    _ _
    lo w hlo hw hwn
    (fun t => dilTail_ptw f g n m S hSd hSn a han had lo w hlo hw hwn hSm t)

end Multiplicity.UOR.Bridge.F1Square.Square
