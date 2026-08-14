/-
F1 square — **the autocorrelation of a Mellin-even test is its self-convolution**
(`SelfDualAutocorr.lean`): the clean milestone of the self-dual arm — reached WITHOUT the nonlinear
change-of-variables.

    `autocorr (selfDualTest a φ) x  ≈  mulConv (selfDualTest a φ) (selfDualTest a φ) x`
    (window `[lo, lo+w] ⊆ [a, 1/a]`).

`autocorr g = mulConv g (reflectTest a g)` (`g ⋆ g^τ`), and for the self-dual test `reflectTest a
(selfDualTest a φ) ≈ selfDualTest a φ` on the window (`selfDualTest_self_dual_pointwise`); feeding that
window agreement to `mulConv_congr_right` replaces the reflected second factor by the plain test, so
the autocorrelation collapses to the self-convolution `g ⋆ g`. No reciprocal/exp substitution: the
reflection symmetry entered as a congruence, exactly because the test is Mellin-even.

WHY. This is the object identity `g ⋆ g^τ = g ⋆ g` that the transform factorization `M[g⋆g] = M[g]²`
(`convMellinHat_eq_MfMoment`) will act on to reach `weilPrimeGram (vHat g)` — the genuine
autocorrelation prime side — for the Mellin-even (Connes–Consani) class, without ever forming the
reflected moment `M[g^τ]` that the general case is gated behind.

HONEST SCOPE. The autocorrelation-is-self-convolution identity for the self-dual class, on the window.
It is NOT the transform identification (milestone B: `M(mulConv g g) = M[g]²`, then the
mellinHat-vs-mellinMoment-vs-window-moment reconciliation to `vHat`), NOT the full
`weilPrimeGram (vHat g) = weilPrimePart(g_i ⋆ g_j^τ)`, and applies NO step-4 positivity
(`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.SelfDualPointwise
import Multiplicity.F1Square.Square.MulConvCongr
import Multiplicity.F1Square.Square.Autocorr

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The autocorrelation of a Mellin-even test is its self-convolution** — `autocorr (selfDualTest a
    φ) x ≈ mulConv (selfDualTest a φ) (selfDualTest a φ) x` on `[lo, lo+w] ⊆ [a, 1/a]` (`a ≤ lo`,
    `lo+w ≤ 1/a`). `autocorr g = g ⋆ g^τ` and `g^τ ≈ g` on the window
    (`selfDualTest_self_dual_pointwise`), so `mulConv_congr_right` replaces `g^τ` by `g`. The reflection
    symmetry is carried as a congruence — no change of variables. -/
theorem autocorr_selfDual_eq_conv (φ : L2Test) (x : Q) (hxn : 0 < x.num) (hxd : 0 < x.den)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (halo : Qle a lo) (hhi : Qle (add lo w) (Qinv a)) :
    Req (autocorr (selfDualTest a han had φ) x hxn hxd a han had lo w hlo hw hwn)
        (mulConv (selfDualTest a han had φ) (selfDualTest a han had φ) x hxn hxd a han had
          lo w hlo hw hwn) := by
  refine mulConv_congr_right (selfDualTest a han had φ)
    (reflectTest a han had (selfDualTest a han had φ)) (selfDualTest a han had φ)
    x hxn hxd a han had lo w hlo hw hwn ?_
  intro y h0 h1
  -- t = affineMap lo w y ∈ [lo, lo+w] ⊆ [a, 1/a]
  have ht_lo : Rle (ofQ a had) (affineMap lo w hlo hw y) :=
    Rle_trans (Rle_ofQ_ofQ had hlo halo)
      (Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ hw hwn) (Rnonneg_of_Rle_zero h0)))
  have ht_hi : Rle (affineMap lo w hlo hw y) (ofQ (Qinv a) (Qinv_den_pos han)) := by
    have hwy : Rle (Rmul (ofQ w hw) y) (ofQ w hw) :=
      Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hw hwn) h1) (Rle_of_Req (Rmul_one (ofQ w hw)))
    exact Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _)) hwy)
      (Rle_trans (Rle_of_Req (Radd_ofQ_ofQ hlo hw))
        (Rle_ofQ_ofQ (add_den_pos hlo hw) (Qinv_den_pos han) hhi))
  obtain ⟨kt, hkt⟩ := Pos_of_Rle_ofQ han had ht_lo
  exact selfDualTest_self_dual_pointwise a han had φ hkt ht_lo ht_hi

end Multiplicity.UOR.Bridge.F1Square.Square
