/-
F1 square — **the reflection MOMENT identity of the self-dual class** (`SelfDualMomentSymmetry.lean`):
Milestone B sub-goal 1. For a self-dual test `g = selfDualTest a φ` whose seed `φ` vanishes outside the
reciprocal-symmetric window `(a, 1/a)`,

    `mellinMoment (reflectTest a g) m  ≈  mellinMoment g m`   (`M[g^τ](m) = M[g](m)`).

The route is the CONGRUENCE, not a change of variables. Three bricks, in a dependency chain:

- `selfDual_vanish_below_floor` — below the floor `x ≤ a`, both `g` and `reflectTest a g` vanish
  (the clamp sends `x` to `1/a ≥ 1/a` and the double clamp back to `≤ a`, where `φ ≡ 0`); this
  supplies the `[0,a]`-support hypotheses the moment collapse needs.
- `windowMoment_eq_mellinMoment` — for a test vanishing on `[0,a]`, the `[0,1]` moment integral
  collapses to the window integral `∫_{[a,1]} h·tᵐ`: split `[0,1] = [0,a] ∪ [a,1]`
  (`riemannIntegralI_split_at`), the `[0,a]` piece is `0` (vanishing integrand), and the unit
  interval integral is `mellinMoment` (`riemannIntegralI_unit`).
- `mellinMoment_reflect_selfDual` — the capstone: chain the window collapse (both sides) around the
  window-moment reflection symmetry `windowMoment_reflect_selfDual` (brick 1).

HONEST SCOPE. The reflection MOMENT identity `M[reflectTest a g] = M[g]` for the self-dual class only
(Milestone B sub-goal 1). It is NOT the convolution factorization, NOT the symmetric transform Gram
identification `weilPrimeGram (vHat g) = Σ Λ·M[g_i⋆g_j^τ]` (blocked by the f-side window wall), and
applies NO step-4 positivity (`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.WindowMomentReflect
import Multiplicity.F1.Square.IntervalSplitAtCap
import Multiplicity.F1.Square.IntervalMinorant
import Multiplicity.F1.Square.IntervalPiece
import Multiplicity.F1.Square.TwTermPowBand
import Multiplicity.F1.Analysis.IntervalIntegral
import Multiplicity.F1.Analysis.ClampedInvLower
import Multiplicity.F1.Analysis.Inv

set_option maxHeartbeats 4000000

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Small rational/clamp helpers (local copies / one-off primitives).
-- ===========================================================================

/-- **The rational inverse is an involution** `Qinv (Qinv a) = a` (as `Qeq`), for `a.num > 0`
    (local copy of the `ValueInvolution` private lemma). -/
private theorem Qinv_Qinv {a : Q} (han : 0 < a.num) : Qeq (Qinv (Qinv a)) a := by
  have hn : (Qinv (Qinv a)).num = a.num := by
    simp only [Qinv]; exact Int.toNat_of_nonneg (Int.le_of_lt han)
  have hd : ((Qinv (Qinv a)).den : Int) = (a.den : Int) := by
    simp only [Qinv]; omega
  show (Qinv (Qinv a)).num * (a.den : Int) = a.num * ((Qinv (Qinv a)).den : Int)
  rw [hn, hd]

/-- **The clamp majorizes its argument** at the Real level: `x ≤ max(x, a)`. The mirror of
    `Rle_ofQ_qClampQ` on the first argument (`Qmax_ge_left`). -/
private theorem Rle_self_qClampQ (a : Q) (had : 0 < a.den) (x : Real) :
    Rle x (qClampQ a had x) := by
  intro n
  show Qle (x.seq n) (add (Qmax (x.seq n) a) (⟨2, n + 1⟩ : Q))
  exact Qle_trans (Qmax_den_pos (x.den_pos n) had) (Qmax_ge_left (x.seq n) a)
    (Qle_self_add (by show (0 : Int) ≤ 2; decide))

-- ===========================================================================
-- BRICK 2a — vanishing below the floor.
-- ===========================================================================

/-- **The self-dual test and its reflection both vanish below the floor**: for `x ≤ a`, both
    `(reflectTest a (selfDualTest a φ)).f x` and `(selfDualTest a φ).f x` are `≈ 0`, provided `φ`
    vanishes at/below the floor (`hlo0`) and at/above the ceiling `1/a` (`hhi0`).

    Below the floor the clamp is active: `clampedInv a x ≥ 1/a` (`ofQ_inv_le_clampedInv`), so
    `φ(clampedInv a x) = 0` (`hhi0`); and the DOUBLE clamp `clampedInv a (clampedInv a x) ≤ a`
    (reciprocal antitonicity through `max(clampedInv a x, a) ≥ 1/a`, `Qinv (Qinv a) = a`), so
    `φ(clampedInv²x) = 0` (`hlo0`). The `L2Test.add`/`reflectTest` distribution then makes both
    pointwise values a sum of vanishing terms. -/
theorem selfDual_vanish_below_floor (a : Q) (han : 0 < a.num) (had : 0 < a.den) (φ : L2Test)
    (hlo0 : ∀ y, Rle y (ofQ a had) → Req (φ.f y) zero)
    (hhi0 : ∀ y, Rle (ofQ (Qinv a) (Qinv_den_pos han)) y → Req (φ.f y) zero)
    {x : Real} (hx : Rle x (ofQ a had)) :
    Req ((reflectTest a han had (selfDualTest a han had φ)).f x) zero
    ∧ Req ((selfDualTest a han had φ).f x) zero := by
  -- φ vanishes at x itself
  have hphi_x : Req (φ.f x) zero := hlo0 x hx
  -- clampedInv a x ≥ 1/a, so φ vanishes there
  have hc_ge : Rle (ofQ (Qinv a) (Qinv_den_pos han)) (clampedInv a han had x) :=
    ofQ_inv_le_clampedInv han had had han hx (Qle_refl a)
  have hphi_cx : Req (φ.f (clampedInv a han had x)) zero := hhi0 (clampedInv a han had x) hc_ge
  -- the double clamp: max(clampedInv a x, a) ≥ 1/a, so clampedInv²x ≤ 1/(1/a) = a
  have hqc_ge : Rle (ofQ (Qinv a) (Qinv_den_pos han))
      (qClampQ a had (clampedInv a han had x)) :=
    Rle_trans hc_ge (Rle_self_qClampQ a had (clampedInv a han had x))
  have hcc_le : Rle (clampedInv a han had (clampedInv a han had x))
      (ofQ (Qinv (Qinv a)) (Qinv_den_pos (Qinv_num_pos had))) :=
    Rinv_le_ofQ_inv (Qinv_num_pos had) (Qinv_den_pos han)
      (qClampQ_witness a han had (clampedInv a han had x)) hqc_ge
  have hcc_le_a : Rle (clampedInv a han had (clampedInv a han had x)) (ofQ a had) :=
    Rle_trans hcc_le
      (Rle_of_Req (ofQ_congr (Qinv_den_pos (Qinv_num_pos had)) had (Qinv_Qinv han)))
  have hphi_ccx : Req (φ.f (clampedInv a han had (clampedInv a han had x))) zero :=
    hlo0 (clampedInv a han had (clampedInv a han had x)) hcc_le_a
  refine ⟨?_, ?_⟩
  · -- reflectTest a (selfDualTest a φ) at x = Radd (φ (clampedInv a x)) (φ (clampedInv² x))
    show Req (Radd (φ.f (clampedInv a han had x))
               (φ.f (clampedInv a han had (clampedInv a han had x)))) zero
    exact Req_trans (Radd_congr hphi_cx hphi_ccx) (Radd_zero zero)
  · -- selfDualTest a φ at x = Radd (φ x) (φ (clampedInv a x))
    show Req (Radd (φ.f x) (φ.f (clampedInv a han had x))) zero
    exact Req_trans (Radd_congr hphi_x hphi_cx) (Radd_zero zero)

-- ===========================================================================
-- BRICK 2 — the [0,a]-support collapse to the window integral.
-- ===========================================================================

/-- **The moment integral collapses to the window integral** for a test `h` vanishing on `[0,a]`:

      `∫_{[a,1]} h·tᵐ  ≈  mellinMoment h m`   (`= ∫_{[0,1]} h·tᵐ`).

    Split `[0,1] = [0,a] ∪ [a,1]` (`riemannIntegralI_split_at`); the `[0,a]` piece integrates the
    vanishing weight `h·tᵐ` (congruent to the zero integrand on the window, `riemannIntegralI_const`),
    hence is `0`; the `[0,1]` interval integral is `mellinMoment h m` (`riemannIntegralI_unit`). -/
theorem windowMoment_eq_mellinMoment (h : L2Test) (m : Nat) (a : Q) (han : 0 < a.num)
    (had : 0 < a.den) (ha1 : Qle a (⟨1, 1⟩ : Q)) (hw2n : (0 : Int) ≤ (Qsub (⟨1, 1⟩ : Q) a).num)
    (hsupp : ∀ x, Rle zero x → Rle x (ofQ a had) → Req (h.f x) zero) :
    Req (riemannIntegralI
          (L2Test.mul h (powTest m)).hLd (L2Test.mul h (powTest m)).hLn
          (L2Test.mul h (powTest m)).hlip (L2Test.mul h (powTest m)).hfc
          a (Qsub (⟨1, 1⟩ : Q) a) had (Qsub_den_pos (by decide) had) hw2n)
        (mellinMoment h m) := by
  -- `add ⟨0,1⟩ a = a` as a rational (for the base reconciliation of the right piece)
  have hQeq0a : Qeq (add (⟨0, 1⟩ : Q) a) a := by
    simp only [Qeq, add]; push_cast; ring_uor
  -- the [0,1] interval integral is `mellinMoment h m`
  have unit : Req (riemannIntegralI
        (L2Test.mul h (powTest m)).hLd (L2Test.mul h (powTest m)).hLn
        (L2Test.mul h (powTest m)).hlip (L2Test.mul h (powTest m)).hfc
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
      (mellinMoment h m) :=
    riemannIntegralI_unit (L2Test.mul h (powTest m)).hLd (L2Test.mul h (powTest m)).hLn
      (L2Test.mul h (powTest m)).hlip (L2Test.mul h (powTest m)).hfc
  -- split [0,1] = [0,a] ∪ [a,1]
  have split := riemannIntegralI_split_at
    (L2Test.mul h (powTest m)).hLd (L2Test.mul h (powTest m)).hLn
    (L2Test.mul h (powTest m)).hlip (L2Test.mul h (powTest m)).hfc
    (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) a (by decide) (by decide) (by decide) had han ha1 hw2n
  -- the [0,a] piece is zero (vanishing integrand)
  have hleft_zero : Req (riemannIntegralI
        (L2Test.mul h (powTest m)).hLd (L2Test.mul h (powTest m)).hLn
        (L2Test.mul h (powTest m)).hlip (L2Test.mul h (powTest m)).hfc
        (⟨0, 1⟩ : Q) a (by decide) had (Int.le_of_lt han)) zero := by
    refine Req_trans (riemannIntegralI_congr_unit_mod
        (L2Test.mul h (powTest m)).hLd (L2Test.mul h (powTest m)).hLn
        (L2Test.mul h (powTest m)).hlip (L2Test.mul h (powTest m)).hfc
        (by decide) (by decide) (const_lip0 zero) (fun _ _ _ => Req_refl zero)
        (⟨0, 1⟩ : Q) a (by decide) had (Int.le_of_lt han) ?_)
      (Req_trans (riemannIntegralI_const zero (⟨0, 1⟩ : Q) a (by decide) had (Int.le_of_lt han))
        (Rmul_zero (ofQ a had)))
    intro x h0 h1
    show Req (Rmul (h.f (affineMap (⟨0, 1⟩ : Q) a (by decide) had x))
               ((powTest m).f (affineMap (⟨0, 1⟩ : Q) a (by decide) had x))) zero
    have hY0 : Rle zero (affineMap (⟨0, 1⟩ : Q) a (by decide) had x) :=
      Rle_trans (Rle_zero_of_Rnonneg (Rnonneg_ofQ (by decide) (by decide)))
        (Rle_self_Radd_right
          (Rnonneg_Rmul (Rnonneg_ofQ had (Int.le_of_lt han)) (Rnonneg_of_Rle_zero h0)))
    have hY1 : Rle (affineMap (⟨0, 1⟩ : Q) a (by decide) had x) (ofQ a had) := by
      have hwy : Rle (Rmul (ofQ a had) x) (ofQ a had) :=
        Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ had (Int.le_of_lt han)) h1)
          (Rle_of_Req (Rmul_one (ofQ a had)))
      exact Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _)) hwy)
        (Rle_of_Req (Req_trans (Radd_ofQ_ofQ (by decide) had)
          (ofQ_congr (add_den_pos (by decide) had) had hQeq0a)))
    exact Req_trans
      (Rmul_congr (hsupp (affineMap (⟨0, 1⟩ : Q) a (by decide) had x) hY0 hY1) (Req_refl _))
      (Req_trans (Rmul_comm zero _) (Rmul_zero _))
  -- reconcile the right piece's base `add ⟨0,1⟩ a` back to `a`
  have hright_congr := riemannIntegralI_congr_Q
    (L2Test.mul h (powTest m)).hLd (L2Test.mul h (powTest m)).hLn
    (L2Test.mul h (powTest m)).hlip (L2Test.mul h (powTest m)).hfc
    (add (⟨0, 1⟩ : Q) a) (Qsub (⟨1, 1⟩ : Q) a) a (Qsub (⟨1, 1⟩ : Q) a)
    (add_den_pos (by decide) had) (Qsub_den_pos (by decide) had) hw2n
    had (Qsub_den_pos (by decide) had) hw2n hQeq0a (Qeq_refl _)
  -- assemble: [0,1] = [0,a] + [a,1] = 0 + [a,1] = [a,1] = mellinMoment
  have hA := Req_trans split
    (Req_trans (Radd_congr hleft_zero (Req_refl _))
      (Req_trans (Req_trans (Radd_comm zero _) (Radd_zero _)) hright_congr))
  exact Req_trans (Req_symm hA) unit

-- ===========================================================================
-- BRICK 3 — the reflection MOMENT identity (Milestone B sub-goal 1).
-- ===========================================================================

/-- **The reflection moment identity of the self-dual class** (Milestone B sub-goal 1):
    `mellinMoment (reflectTest a (selfDualTest a φ)) m ≈ mellinMoment (selfDualTest a φ) m`, for a
    seed `φ` vanishing outside `(a, 1/a)` and `a ≤ 1`.

    The `[0,a]`-support collapse (`windowMoment_eq_mellinMoment`, fed by
    `selfDual_vanish_below_floor`) turns each moment into the window integral `∫_{[a,1]} ·tᵐ`, and the
    window-moment reflection symmetry `windowMoment_reflect_selfDual` (brick 1) swaps the reflected
    weight for the plain one there. No change of variables. -/
theorem mellinMoment_reflect_selfDual (a : Q) (han : 0 < a.num) (had : 0 < a.den) (φ : L2Test)
    (m : Nat) (ha1 : Qle a (⟨1, 1⟩ : Q))
    (hlo0 : ∀ y, Rle y (ofQ a had) → Req (φ.f y) zero)
    (hhi0 : ∀ y, Rle (ofQ (Qinv a) (Qinv_den_pos han)) y → Req (φ.f y) zero) :
    Req (mellinMoment (reflectTest a han had (selfDualTest a han had φ)) m)
        (mellinMoment (selfDualTest a han had φ) m) := by
  -- `1 − a ≥ 0`
  have hw2n : (0 : Int) ≤ (Qsub (⟨1, 1⟩ : Q) a).num := by
    have h : a.num ≤ (a.den : Int) := by
      have h0 := ha1; simp only [Qle] at h0; push_cast at h0; omega
    simp only [Qsub, add, neg]; push_cast; omega
  -- `1 ≤ 1/a` (from `a ≤ 1`), hence `a + (1−a) = 1 ≤ 1/a` for brick 1's window inclusion
  have hone_le_inv : Qle (⟨1, 1⟩ : Q) (Qinv a) := by
    have h : a.num ≤ (a.den : Int) := by
      have h0 := ha1; simp only [Qle] at h0; push_cast at h0; omega
    simp only [Qle, Qinv]
    have ht : (a.num.toNat : Int) = a.num := by omega
    push_cast [ht]; omega
  have hQeq_one : Qeq (add a (Qsub (⟨1, 1⟩ : Q) a)) (⟨1, 1⟩ : Q) := by
    simp only [Qeq, add, Qsub, neg]; push_cast; ring_uor
  have hhi_window : Qle (add a (Qsub (⟨1, 1⟩ : Q) a)) (Qinv a) :=
    Qle_trans (by decide) (Qeq_le hQeq_one) hone_le_inv
  -- support hypotheses from brick 2a
  have hsupp_ref : ∀ x, Rle zero x → Rle x (ofQ a had) →
      Req ((reflectTest a han had (selfDualTest a han had φ)).f x) zero :=
    fun x _ hxle => (selfDual_vanish_below_floor a han had φ hlo0 hhi0 hxle).1
  have hsupp_g : ∀ x, Rle zero x → Rle x (ofQ a had) →
      Req ((selfDualTest a han had φ).f x) zero :=
    fun x _ hxle => (selfDual_vanish_below_floor a han had φ hlo0 hhi0 hxle).2
  -- brick 2 on each side + brick 1 in the middle
  have B2ref := windowMoment_eq_mellinMoment
    (reflectTest a han had (selfDualTest a han had φ)) m a han had ha1 hw2n hsupp_ref
  have B1 := windowMoment_reflect_selfDual a han had φ m a (Qsub (⟨1, 1⟩ : Q) a) had
    (Qsub_den_pos (by decide) had) hw2n (Qle_refl a) hhi_window
  have B2g := windowMoment_eq_mellinMoment
    (selfDualTest a han had φ) m a han had ha1 hw2n hsupp_g
  exact Req_trans (Req_symm B2ref) (Req_trans B1 B2g)

end Multiplicity.UOR.Bridge.F1Square.Square