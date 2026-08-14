/-
F1 square — **the convolution's twisted tail is the `∫_t` reconstruction of `M[f⋆g]=M[f]·M[g]`'s tail**
(`DilTailCommute.lean`): the tail commute. The convolution's clamp-free twisted half-line tail
`convTwTail f g n` equals the outer `∫_t` of ANY test `U` whose window values match the per-`t`
covariance-connected integrand `g(t)·(1/max(t,a))·twTail (dilateTestR (1/max(t,a)) f) n`:

    `convTwTail f g n = ∫_{lo}^{lo+w} g(t)·(1/max(t,a))·twTail (dilate c_t f) n  dt`.

The proof composes the Wall-3 bricks along one dominating evaluation schedule `K⋆`:
`convTwTail_eq_fast_schedule` re-expresses `convTwTail` as the limit at `K⋆ = ⟨K_conv.num.toNat +
(Cf·2ⁿ).num.toNat, 1⟩` (the common integer schedule dominating both `digammaMidx K_conv` and
`digammaMidx (Cf·2ⁿ)`, via `digammaMidx_common`), whose regularity is `genSum_RReg` fed by
`convTwTerm_two_sided` weakened to `K⋆` (`two_sided_weaken` + `Qle_self_toNat_add` +
`qmul_le_right_mono`). Then `Rlim_eval_real_rate` evaluates that limit against `∫_t U` at the per-index
rate: `convPartial_eq_intGenSum` collapses the partial sum to `∫_t (genSumTest coupFam)`,
`genSumTest_coupFam_eq` + `hU` recognize its integrand and `dilTail_partial_close` bounds the per-`t`
closeness by `(g.M·(1/a))·3/(j+1)`, `riemannIntegralI_dist_le_of_close` lifts that to `w·…` on the
integrals, and `rate_bound_Qle` collapses it to the constant `⟨C, j+1⟩` the evaluator consumes.

HONEST SCOPE. The tail commute, parametric in the covariance-connect `hU`. It supplies NO `U` (the
covariance identification `U.f = g·(1/max(t,a))·twTail (dilate f)` is a hypothesis — grounding `v=ĝ` is
still to come), applies NO positivity, builds NO crux. Step 4 (band-coupling positivity) is RH; the crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.ConvMellinHat
import Multiplicity.F1Square.Square.ConvPartialInterchange
import Multiplicity.F1Square.Square.ConvSummedIntegrand
import Multiplicity.F1Square.Square.DilTailPartialClose
import Multiplicity.F1Square.Square.ConvTwTailSchedule
import Multiplicity.F1Square.Square.DigammaMidxCommon
import Multiplicity.F1Square.Square.TwoSidedWeaken
import Multiplicity.F1Square.Square.IntegralDist

namespace Multiplicity.UOR.Bridge.F1Square.Square
open UOR.Bridge.F1Square.Analysis
set_option maxHeartbeats 4000000

/-- The convolution's twisted half-line tail equals the ∫_t of any test U whose window-values match
    g(t)·clampedInv(a,t)·twTail(dilateTestR (clampedInv a t) f) n — the tail ∫_t reconstruction,
    parametric in the covariance-connect (hU). -/
theorem convTwTail_eq_intTail (f g : L2Test) (n : Nat) {Cf : Q}
    (hCfd : 0 < Cf.den) (hCfn : 0 ≤ Cf.num)
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
      Rle (Rabs (f.f y)) (ofQ (mul Cf (⟨1, (k + 1) ^ (n + 2)⟩ : Q))
        (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos k)))))
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (ha1 : Qle a (⟨1, 1⟩ : Q))
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hw1 : Qle (add lo w) (⟨1, 1⟩ : Q))
    (U : L2Test)
    (hU : ∀ (s : Real) (h0 : Rle zero s) (h1 : Rle s one),
       Req (U.f (affineMap lo w hlo hw s))
           (Rmul (Rmul (g.f (affineMap lo w hlo hw s)) (clampedInv a han had (affineMap lo w hlo hw s)))
                 (twTail (dilateTestR (clampedInv a han had (affineMap lo w hlo hw s)) (Qinv a)
                           (Qinv_den_pos han) (Int.le_of_lt (Qinv_num_pos had))
                           ((recipTest a han had).hbd (affineMap lo w hlo hw s)) f)
                         n hCfd hCfn
                         (dilateTestR_window_hdec f n hCfd hCfn hfdec
                           (clampedInv a han had (affineMap lo w hlo hw s)) (Qinv a)
                           (Qinv_den_pos han) (Int.le_of_lt (Qinv_num_pos had))
                           ((recipTest a han had).hbd (affineMap lo w hlo hw s))
                           (window_clampedInv_ge_one a han had ha1 lo w hlo hw hwn hw1 s h1))))) :
    Req (convTwTail f g n hCfd hCfn hfdec a han had ha1 lo w hlo hw hwn hw1)
        (riemannIntegralI U.hLd U.hLn U.hlip U.hfc lo w hlo hw hwn) := by
  -- (1) Regularity of the convolution twisted sums along the common dominating schedule K⋆.
  have hRegR : RReg (fun j => genSum
      (fun m => twTerm (mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) Nat.one_pos
        (by show (0 : Int) ≤ (m : Int) + 2; omega) a han had lo w hlo hw hwn) n m)
      (digammaMidx (⟨((mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int)
          + ((mul Cf (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int), 1⟩ : Q) j)) :=
    genSum_RReg
      (fun m => twTerm (mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) Nat.one_pos
        (by show (0 : Int) ≤ (m : Int) + 2; omega) a han had lo w hlo hw hwn) n m)
      (K := (⟨((mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int)
          + ((mul Cf (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int), 1⟩ : Q))
      Nat.one_pos
      (by show (0 : Int) ≤ ((mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int)
          + ((mul Cf (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int); omega)
      (fun m hm => two_sided_weaken
        (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hw hCfd) g.hMd)
          (Qinv_den_pos han)) Nat.one_pos) (digamma_succ_mul_pos hm))
        (Qmul_den_pos Nat.one_pos (digamma_succ_mul_pos hm))
        (qmul_le_right_mono
          (Qle_self_toNat_add
            (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hw hCfd) g.hMd)
              (Qinv_den_pos han)) Nat.one_pos)
            (Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg hwn hCfn) g.hMn)
              (Int.le_of_lt (Qinv_num_pos had))) (Int.ofNat_nonneg _))
            ((mul Cf (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int) (by omega))
          (by show (0 : Int) ≤ 1; decide))
        (convTwTerm_two_sided f g n hCfd hCfn hfdec a han had ha1 lo w hlo hw hwn hw1 m hm))
  -- (2) convTwTail is that same limit (schedule-independence, K⋆ dominates K_conv).
  have hbump : Req (Rlim (fun j => genSum
        (fun m => twTerm (mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) Nat.one_pos
          (by show (0 : Int) ≤ (m : Int) + 2; omega) a han had lo w hlo hw hwn) n m)
        (digammaMidx (⟨((mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int)
            + ((mul Cf (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int), 1⟩ : Q) j)) hRegR)
      (convTwTail f g n hCfd hCfn hfdec a han had ha1 lo w hlo hw hwn hw1) :=
    convTwTail_eq_fast_schedule f g n hCfd hCfn hfdec a han had ha1 lo w hlo hw hwn hw1
      (fun j => digammaMidx (⟨((mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int)
          + ((mul Cf (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int), 1⟩ : Q) j)
      (fun j => (digammaMidx_common
        (mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))
        (mul Cf (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j).1)
      hRegR
  -- (3) evaluate that limit against ∫_t U at the per-index rate ⟨C, j+1⟩.
  refine Req_trans (Req_symm hbump)
    (Rlim_eval_real_rate hRegR
      (riemannIntegralI U.hLd U.hLn U.hlip U.hfc lo w hlo hw hwn)
      (C := (w.num * (g.M.num * (Qinv a).num) * 3).toNat) ?_)
  intro j
  -- partial sum collapses to a single ∫_t of the summed outer test.
  have hpart := convPartial_eq_intGenSum f g n a han had lo w hlo hw hwn
    (digammaMidx (⟨((mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int)
        + ((mul Cf (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int), 1⟩ : Q) j)
  -- ∫_t distance ≤ w·(g.M·(1/a)·3/(j+1)) via the per-t closeness.
  have hdist := riemannIntegralI_dist_le_of_close
    (genSumTest (coupFam f g n a han had lo w hlo hw hwn)
      (digammaMidx (⟨((mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int)
          + ((mul Cf (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int), 1⟩ : Q) j))
    U lo w hlo hw hwn
    (B := mul (mul g.M (Qinv a)) (⟨3, j + 1⟩ : Q))
    (Qmul_den_pos (Qmul_den_pos g.hMd (Qinv_den_pos han)) (Nat.succ_pos j))
    (fun x h0 h1 => Rle_trans
      (Rle_of_Req (Rabs_congr (Rsub_congr
        (genSumTest_coupFam_eq f g n a han had lo w hlo hw hwn (affineMap lo w hlo hw x)
          (digammaMidx (⟨((mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int)
              + ((mul Cf (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int), 1⟩ : Q) j))
        (hU x h0 h1))))
      (dilTail_partial_close f g n hCfd hCfn hfdec a han had (affineMap lo w hlo hw x)
        (window_clampedInv_ge_one a han had ha1 lo w hlo hw hwn hw1 x h1)
        (fun j' => digammaMidx (⟨((mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int)
            + ((mul Cf (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int), 1⟩ : Q) j')
        (fun j' => (digammaMidx_common
          (mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))
          (mul Cf (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j').2) j))
  -- bridge genSum → ∫_t via hpart, then collapse the rate to ⟨C, j+1⟩.
  exact Rle_trans
    (Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr hpart (Req_refl _)))) hdist)
    (Rle_ofQ_ofQ (Qmul_den_pos hw (Qmul_den_pos (Qmul_den_pos g.hMd (Qinv_den_pos han)) (Nat.succ_pos j)))
      (Nat.succ_pos j)
      (rate_bound_Qle hwn g.hMn (Int.le_of_lt (Qinv_num_pos had)) hw g.hMd (Qinv_den_pos han) j))

end Multiplicity.UOR.Bridge.F1Square.Square