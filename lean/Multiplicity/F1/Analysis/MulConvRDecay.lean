/-
F1 square — **the multiplicative convolution decays on windows when `f` decays** (`MulConvRDecay.lean`):
for a real output point `x` on the window `[m+1, m+2]` and a `t`-window inside `(0,1]`, if `f` has
polynomial window decay of order `n+2`, then so does the convolution value:

    `|mulConvR f g x|  ≤  w·M_g·(1/a)·C_f / (m+1)^{n+2}`.

This is the analytic heart of the half-line assembly: `mellinHat(f⋆g)` converges only if the
convolution's window values decay, and that decay comes from `f`'s decay pushed through the
multiplicative structure. The mechanism: the integrand reads `f` at `x·(1/max(t,a))`, and on a
`t`-window inside `(0,1]` (`lo+w ≤ 1`, `a ≤ 1`) the clamped reciprocal satisfies `1/max(t,a) ≥ 1`
(`ofQ_inv_le_clampedInv` at `B = 1`), so the argument `x·(1/max(t,a)) ≥ x ≥ m+1` clears the
INTEGER threshold `m+1` — no floor arithmetic. `f`'s decay then bounds `|f(arg)| ≤ C_f/(m+1)^{n+2}`,
and the pointwise product bound (`× M_g × 1/a`) integrates to `w·(…)` via `riemannIntegralI_abs_le_window`.

HONEST SCOPE. The convolution's window decay on a `(0,1]` `t`-window (the clean regime where the
clamped reciprocal is `≥ 1`). It builds NO half-line assembly, NO generalized tail, NO factorization
`M[f⋆g]=M[f]·M[g]`, NO positivity, NO crux. The general (`t`-window past `1`) case is a separate
estimate (weaker decay, floor arithmetic). The `f`-decay is an explicit hypothesis, never asserted for
a particular `f`. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Analysis.MulConvRBound
import Multiplicity.F1Square.Analysis.ClampedInvLower

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- **The multiplicative convolution inherits `f`'s window decay** (on a `(0,1]` `t`-window). If
    `|f(y)| ≤ C_f/(k+1)^{n+2}` whenever `|y| ≥ k+1`, then for `x` on `[m+1, m+2]` and the `t`-window
    `[lo, lo+w] ⊆ (0,1]` (`a ≤ 1`), `|mulConvR f g x| ≤ w·M_g·(1/a)·C_f/(m+1)^{n+2}`. On the window the
    clamped reciprocal is `≥ 1`, lifting the argument `x·(1/max(t,a))` above the integer threshold
    `m+1`, so `f`'s decay applies directly; the product bound integrates via
    `riemannIntegralI_abs_le_window`. -/
theorem mulConvR_window_decay (f g : L2Test) (n : Nat) {Cf : Q} (hCfd : 0 < Cf.den) (hCfn : 0 ≤ Cf.num)
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
      Rle (Rabs (f.f y)) (ofQ (mul Cf (⟨1, (k + 1) ^ (n + 2)⟩ : Q))
        (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos k)))))
    (m : Nat) (x : Real) (hxm : Rle (ofQ (⟨(m : Int) + 1, 1⟩ : Q) Nat.one_pos) x)
    (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num) (hxS : Rle (Rabs x) (ofQ S hSd))
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (ha1 : Qle a (⟨1, 1⟩ : Q))
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hw1 : Qle (add lo w) (⟨1, 1⟩ : Q)) :
    Rle (Rabs (mulConvR f g x S hSd hSn hxS a han had lo w hlo hw hwn))
        (ofQ (mul w (mul (mul (mul Cf (⟨1, (m + 1) ^ (n + 2)⟩ : Q)) g.M) (Qinv a)))
          (Qmul_den_pos hw (Qmul_den_pos (Qmul_den_pos
            (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))) g.hMd)
            (Qinv_den_pos han)))) := by
  refine riemannIntegralI_abs_le_window
    (l2L_den (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (l2L_num (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (l2lip (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (l2fc (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    lo w
    (mul (mul (mul Cf (⟨1, (m + 1) ^ (n + 2)⟩ : Q)) g.M) (Qinv a))
    hlo hw hwn
    (Qmul_den_pos (Qmul_den_pos
      (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))) g.hMd) (Qinv_den_pos han))
    ?_
  intro s h0 h1
  -- the t-window point t' = lo + w·s ∈ [lo, lo+w] ⊆ (0,1]
  -- (1) t' ≤ 1
  have ht'1 : Rle (affineMap lo w hlo hw s) (ofQ (⟨1, 1⟩ : Q) (by decide)) := by
    have hws : Rle (Rmul (ofQ w hw) s) (ofQ w hw) :=
      Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hw hwn) h1)
        (Rle_of_Req (Rmul_one (ofQ w hw)))
    refine Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _)) hws)
      (Rle_trans (Rle_of_Req (Radd_ofQ_ofQ hlo hw))
        (Rle_ofQ_ofQ (add_den_pos hlo hw) (by decide) hw1))
  -- (2) clampedInv a t' ≥ 1
  have hc1 : Rle (ofQ (⟨1, 1⟩ : Q) (by decide)) (clampedInv a han had (affineMap lo w hlo hw s)) :=
    Rle_trans (Rle_of_Req (ofQ_congr (by decide) (Qinv_den_pos (by decide)) (by decide)))
      (ofQ_inv_le_clampedInv han had (B := ⟨1, 1⟩) (by decide) (by decide) ht'1 ha1)
  -- (3) the argument x·clampedInv ≥ m+1 (as an absolute value)
  have hmnn : (0 : Int) ≤ (m : Int) + 1 := by omega
  have harg_nn : Rnonneg (Rmul x (clampedInv a han had (affineMap lo w hlo hw s))) :=
    Rnonneg_Rmul
      (Rnonneg_of_Rle_zero (Rle_trans
        (Rle_zero_of_Rnonneg (Rnonneg_ofQ Nat.one_pos hmnn)) hxm))
      (Rnonneg_clampedInv a han had _)
  have harg_ge : Rle (ofQ (⟨(m : Int) + 1, 1⟩ : Q) Nat.one_pos)
      (Rabs (Rmul x (clampedInv a han had (affineMap lo w hlo hw s)))) := by
    refine Rle_trans ?_ (Rle_of_Req (Req_symm (Rabs_of_nonneg harg_nn)))
    refine Rle_trans (Rle_of_Req (Req_symm (Rmul_one (ofQ (⟨(m : Int) + 1, 1⟩ : Q) Nat.one_pos))))
      (Rmul_le_Rmul_both (Rnonneg_ofQ Nat.one_pos hmnn)
        (Rnonneg_clampedInv a han had (affineMap lo w hlo hw s)) hxm hc1)
  -- (4) the pointwise product bound
  have hc : Rle (Rabs (clampedInv a han had (affineMap lo w hlo hw s)))
      (ofQ (Qinv a) (Qinv_den_pos han)) := (recipTest a han had).hbd (affineMap lo w hlo hw s)
  have hfg : Rle (Rabs (Rmul (f.f (Rmul x (clampedInv a han had (affineMap lo w hlo hw s))))
        (g.f (affineMap lo w hlo hw s))))
      (ofQ (mul (mul Cf (⟨1, (m + 1) ^ (n + 2)⟩ : Q)) g.M)
        (Qmul_den_pos (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))) g.hMd)) := by
    refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
    refine Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs _) (Rnonneg_ofQ g.hMd g.hMn)
      (hfdec m _ harg_ge) (g.hbd _)) ?_
    exact Rle_of_Req (Rmul_ofQ_ofQ _ _)
  refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
  refine Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs _)
    (Rnonneg_ofQ (Qinv_den_pos han) (Int.le_of_lt (Qinv_num_pos had))) hfg hc) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ _ _)

end Multiplicity.UOR.Bridge.F1Square.Analysis
