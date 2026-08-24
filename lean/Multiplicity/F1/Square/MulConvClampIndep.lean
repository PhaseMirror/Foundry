/-
F1 square — **clamp-independence of the convolution's Mellin tail-term on inert windows**
(`MulConvClampIndep.lean`): the `m`-th twisted tail term of the convolution's Mellin transform,
`twTerm (mulConvRTest f g S) n m = ∫_{m+1}^{m+2} (f⋆g)(x)·xⁿ dx`, does **not depend on the clamp
bound `S`** once `S` exceeds the window (`m+2 ≤ S`):

    `twTerm (mulConvRTest f g S) n m  ≈  twTerm (mulConvRTest f g S') n m`   (both `≥ m+2`).

WHY THIS MATTERS. `mulConvRTest f g S` totalizes the convolution by clamping its argument into
`[0, S]` (`qBandQ 0 S`), so *beyond* `S` its value is frozen at `(f⋆g)(S)` — the frozen tail does
not decay, and `mellinHat (mulConvRTest f g S)` (the full half-line transform) does not converge for
a *fixed* `S`. The clamp-free convolution transform is therefore the `S → ∞` object, and the first
thing that object needs is that each *window's* value is **eventually constant in `S`**: this lemma
proves exactly that — once `S` clears the window `[m+1, m+2]`, the per-window Mellin value is `S`-stable.
So `twTerm (mulConvRTest f g ·) n m` is an eventually-constant sequence in the clamp, and its `S → ∞`
limit is well-defined window-by-window. This is the sub-brick that makes the clamp-free half-line
assembly of `M[f⋆g]` (and hence the factorization `M[f⋆g]=M[f]·M[g]`) approachable.

The proof rests on the structural fact that the convolution's *value* is clamp-free: `mulConvR`'s
integrand `f(x·(1/max(t,a)))·g(t)·(1/max(t,a))` carries `S` **only** in the dilation test's Lipschitz
modulus (`dilateTestR x S f .L = f.L·S`), never in its `.f` values — so the two integrands (at `S` and
`S'`) are the *same function* with different modulus certificates, bridged by
`riemannIntegralI_certif_irrel` (`mulConvR_S_indep`). On the window `[m+1, m+2] ⊆ [0, S]∩[0, S']` both
clamps are inert (`qBandQ_eq_of_band`), so the window integrands agree pointwise and
`riemannIntegralI_congr_unit_mod` transports the equality across the two moduli.

HONEST SCOPE. Clamp-independence of the per-window value. It builds NO `S → ∞` limit object, NO
half-line assembly, NO factorization `M[f⋆g]=M[f]·M[g]`, NO positivity, NO crux. Step 4
(band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MellinConv
import Multiplicity.F1.Square.MellinHat
import Multiplicity.F1.Square.MellinLinear
import Multiplicity.F1.Square.TwTermPowBand

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- **The convolution value is independent of the clamp bound `S`.** For a fixed output point `x`
    with `|x| ≤ S` and `|x| ≤ S'`, `mulConvR f g x S ≈ mulConvR f g x S'`: the two Haar integrals
    integrate the *same* function `f(x·(1/max(t,a)))·g(t)·(1/max(t,a))` (the dilation test's `.f` is
    `S`-free; `S` sits only in the modulus `.L = f.L·S`), so `riemannIntegralI_certif_irrel` — which
    equates two integrals of one function at different Lipschitz moduli — closes it directly. -/
theorem mulConvR_S_indep (f g : L2Test) (x : Real) (S S' : Q)
    (hSd : 0 < S.den) (hSn : 0 ≤ S.num) (hxS : Rle (Rabs x) (ofQ S hSd))
    (hS'd : 0 < S'.den) (hS'n : 0 ≤ S'.num) (hxS' : Rle (Rabs x) (ofQ S' hS'd))
    (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Req (mulConvR f g x S hSd hSn hxS a han had lo w hlo hw hwn)
        (mulConvR f g x S' hS'd hS'n hxS' a han had lo w hlo hw hwn) :=
  riemannIntegralI_certif_irrel
    (l2L_den (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (l2L_num (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (l2lip (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (l2fc (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (l2L_den (productTest (reflectTest a han had (dilateTestR x S' hS'd hS'n hxS' f)) g)
      (recipTest a han had))
    (l2L_num (productTest (reflectTest a han had (dilateTestR x S' hS'd hS'n hxS' f)) g)
      (recipTest a han had))
    (l2lip (productTest (reflectTest a han had (dilateTestR x S' hS'd hS'n hxS' f)) g)
      (recipTest a han had))
    (l2fc (productTest (reflectTest a han had (dilateTestR x S' hS'd hS'n hxS' f)) g)
      (recipTest a han had))
    lo w hlo hw hwn

/-- **Clamp-independence of the convolution's Mellin tail-term on inert windows.** For `m+2 ≤ S` and
    `m+2 ≤ S'`, the `m`-th twisted tail term of the convolution's Mellin transform is the same for
    both clamps:

      `twTerm (mulConvRTest f g S) n m  ≈  twTerm (mulConvRTest f g S') n m`.

    On the window `[m+1, m+2]` both `[0,·]`-clamps are inert (`qBandQ_eq_of_band`), so the two
    integrands `(f⋆g)_S(x)·xⁿ` and `(f⋆g)_{S'}(x)·xⁿ` agree pointwise (`mulConvR_S_indep` after
    stripping the inert clamps with `mulConvR_congr`); `riemannIntegralI_congr_unit_mod` then equates
    the interval integrals across the two Lipschitz moduli. The eventually-constant-in-`S` fact that
    makes the clamp-free (`S → ∞`) half-line transform well-defined per window. -/
theorem twTerm_mulConv_S_indep (f g : L2Test) (n m : Nat) (S S' : Q)
    (hSd : 0 < S.den) (hSn : 0 ≤ S.num) (hS'd : 0 < S'.den) (hS'n : 0 ≤ S'.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hSm : Qle (add (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)) S)
    (hS'm : Qle (add (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)) S') :
    Req (twTerm (mulConvRTest f g S hSd hSn a han had lo w hlo hw hwn) n m)
        (twTerm (mulConvRTest f g S' hS'd hS'n a han had lo w hlo hw hwn) n m) := by
  refine riemannIntegralI_congr_unit_mod
    (l2L_den (mulConvRTest f g S hSd hSn a han had lo w hlo hw hwn) (powWinTest m n))
    (l2L_num (mulConvRTest f g S hSd hSn a han had lo w hlo hw hwn) (powWinTest m n))
    (l2lip (mulConvRTest f g S hSd hSn a han had lo w hlo hw hwn) (powWinTest m n))
    (l2fc (mulConvRTest f g S hSd hSn a han had lo w hlo hw hwn) (powWinTest m n))
    (l2L_den (mulConvRTest f g S' hS'd hS'n a han had lo w hlo hw hwn) (powWinTest m n))
    (l2L_num (mulConvRTest f g S' hS'd hS'n a han had lo w hlo hw hwn) (powWinTest m n))
    (l2lip (mulConvRTest f g S' hS'd hS'n a han had lo w hlo hw hwn) (powWinTest m n))
    (l2fc (mulConvRTest f g S' hS'd hS'n a han had lo w hlo hw hwn) (powWinTest m n))
    (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide) ?_
  intro x h0 h1
  -- the window point p = (m+1) + x ∈ [m+1, m+2]
  have hp_lo : Rle (ofQ (⟨0, 1⟩ : Q) (by decide))
      (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x) := by
    refine Rle_trans (Rle_ofQ_ofQ (by decide) Nat.one_pos ?_)
      (Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide))
        (Rnonneg_of_Rle_zero h0)))
    show Qle (⟨0, 1⟩ : Q) (⟨(m : Int) + 1, 1⟩ : Q)
    simp only [Qle]; push_cast; omega
  have hp_hiS : Rle (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)
      (ofQ S hSd) := by
    have hxwx : Rle (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) x) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
      Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) h1)
        (Rle_of_Req (Rmul_one (ofQ (⟨1, 1⟩ : Q) (by decide))))
    refine Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _)) hxwx)
      (Rle_trans (Rle_of_Req (Radd_ofQ_ofQ Nat.one_pos (by decide)))
        (Rle_ofQ_ofQ (add_den_pos Nat.one_pos (by decide)) hSd hSm))
  have hp_hiS' : Rle (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)
      (ofQ S' hS'd) := by
    have hxwx : Rle (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) x) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
      Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) h1)
        (Rle_of_Req (Rmul_one (ofQ (⟨1, 1⟩ : Q) (by decide))))
    refine Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _)) hxwx)
      (Rle_trans (Rle_of_Req (Radd_ofQ_ofQ Nat.one_pos (by decide)))
        (Rle_ofQ_ofQ (add_den_pos Nat.one_pos (by decide)) hS'd hS'm))
  have hp_nn : Rnonneg (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x) :=
    Rnonneg_Radd (Rnonneg_ofQ Nat.one_pos (by show (0 : Int) ≤ (m : Int) + 1; omega))
      (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) (Rnonneg_of_Rle_zero h0))
  have hbS : Rle (Rabs (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x))
      (ofQ S hSd) := Rle_trans (Rle_of_Req (Rabs_of_nonneg hp_nn)) hp_hiS
  have hbS' : Rle (Rabs (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x))
      (ofQ S' hS'd) := Rle_trans (Rle_of_Req (Rabs_of_nonneg hp_nn)) hp_hiS'
  have hclS : Req (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd
      (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x))
      (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x) :=
    qBandQ_eq_of_band hp_lo hp_hiS
  have hclS' : Req (qBandQ (⟨0, 1⟩ : Q) S' (by decide) hS'd
      (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x))
      (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x) :=
    qBandQ_eq_of_band hp_lo hp_hiS'
  -- the window integrands are the product of the (S-clamped) convolution and xⁿ; reduce to the
  -- convolution factor and chain: strip clamp (S) → S-independence → restore clamp (S')
  refine Rmul_congr ?_ (Req_refl _)
  refine Req_trans (mulConvR_congr f g
    (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd
      (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x))
    (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)
    S hSd hSn (clampS_absle S hSd hSn _) hbS a han had lo w hlo hw hwn hclS) ?_
  refine Req_trans (mulConvR_S_indep f g
    (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)
    S S' hSd hSn hbS hS'd hS'n hbS' a han had lo w hlo hw hwn) ?_
  exact mulConvR_congr f g
    (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)
    (qBandQ (⟨0, 1⟩ : Q) S' (by decide) hS'd
      (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x))
    S' hS'd hS'n hbS' (clampS_absle S' hS'd hS'n _) a han had lo w hlo hw hwn (Req_symm hclS')

end Multiplicity.UOR.Bridge.F1Square.Square
