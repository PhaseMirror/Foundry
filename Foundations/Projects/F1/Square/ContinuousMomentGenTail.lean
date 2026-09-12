/-
F1 square — **the pre-Hilbert layer, brick 111** (`ContinuousMomentGenTail.lean`): **the compact
Mellin moment at general `s` is CAUCHY in the floor** — two dyadic floors `1/2^p ≥ 1/2^q` give moments
within `2·M_φ·(1/2^p)`:

    `|compactMoment φ (1/2^p) s  −  compactMoment φ (1/2^q) s|  ≤  2·M_φ·(1/2^p)`   (`p ≤ q`)
      (`compactMoment_floor_diff_bound`).

WHY (the Sonine route, step 3, the `a → 0` Mellin limit at general `s`). At `s = 1` the limit had an
integer target (`mellinMoment φ 1`, brick 109). At GENERAL real `s` there is no such target — the
deliverable is that the floor sequence CONVERGES (is Cauchy), so its Bishop limit exists and *defines*
the continuous Mellin moment. This brick supplies the Cauchy estimate. The two compact-power integrands
agree on the overlap `[1/2^p, 1]` (both floors are `≤ t` there, so real-level floor-independence
brick 110 makes them equal); their difference — realized as `innerI φ (compactPowTest_p −ₜ
compactPowTest_q)` through `innerI_sub_right` — vanishes on that dyadic tail and is bounded by `2·M_φ`,
so the dyadic tail bound (brick 107) gives the geometric decay. Structurally identical to brick 108,
with real-level floor-independence replacing the clamp identity.

HONEST SCOPE. The Cauchy estimate for the compact Mellin moment at general `s`, compact side. NOT the
limit object yet (brick 112), NOT the transform pair, NOT inversion. Step 4 is RH; crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.ContinuousMomentFloorReal
import Foundations.F1.Square.ContinuousMomentTailBound

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The compact power test at exponent `s` (bound `σ`) with the dyadic floor `1/2^m`**, as an
    `L2Test`. -/
def compactPowTestF (m : Nat) {s : Real} (hs : Rnonneg s) (σ : Q) (hσd : 0 < σ.den) (hσn : 0 ≤ σ.num)
    (hsB : Rle s (ofQ σ hσd)) : L2Test :=
  compactPowTest (⟨1, 2 ^ m⟩ : Q) (by show (0 : Int) < 1; decide) (two_pow_pos m) hs σ hσd hσn hsB

/-- **The compact Mellin moment at exponent `s` (bound `σ`) with the dyadic floor `1/2^m`**. -/
def compactMomentF (φ : L2Test) (m : Nat) {s : Real} (hs : Rnonneg s) (σ : Q) (hσd : 0 < σ.den)
    (hσn : 0 ≤ σ.num) (hsB : Rle s (ofQ σ hσd)) : Real :=
  innerI φ (compactPowTestF m hs σ hσd hσn hsB)

set_option maxHeartbeats 1600000 in
/-- **★ THE COMPACT MELLIN MOMENT IS CAUCHY IN THE FLOOR**: for `p ≤ q` the moments at floors `1/2^p`
    and `1/2^q` differ by at most `2·M_φ·(1/2^p)`. The two integrands agree on `[1/2^p, 1]` (real-level
    floor-independence, brick 110), so their difference vanishes on the dyadic tail and the tail bound
    (brick 107) gives the geometric decay. -/
theorem compactMoment_floor_diff_bound (φ : L2Test) {s : Real} (hs : Rnonneg s) (σ : Q)
    (hσd : 0 < σ.den) (hσn : 0 ≤ σ.num) (hsB : Rle s (ofQ σ hσd)) (p q : Nat) (hpq : p ≤ q) :
    Rle (Rabs (Rsub (compactMomentF φ p hs σ hσd hσn hsB) (compactMomentF φ q hs σ hσd hσn hsB)))
        (ofQ (mul (mul φ.M (⟨2, 1⟩ : Q)) (⟨1, 2 ^ p⟩ : Q))
          (Qmul_den_pos (Qmul_den_pos φ.hMd (by decide)) (two_pow_pos p))) := by
  -- `1/2^q ≤ 1/2^p` (as reals), for the second floor to sit below the first
  have hle : Qle (⟨1, 2 ^ q⟩ : Q) (⟨1, 2 ^ p⟩ : Q) := by
    have hpw : (2 : Nat) ^ p ≤ 2 ^ q := Nat.pow_le_pow_right (by decide) hpq
    have hc : ((2 ^ p : Nat) : Int) ≤ ((2 ^ q : Nat) : Int) := Int.ofNat_le.mpr hpw
    simp only [Qle]
    omega
  -- the difference is `innerI φ (χ − ψ)`
  have hdiff : Req (Rsub (compactMomentF φ p hs σ hσd hσn hsB) (compactMomentF φ q hs σ hσd hσn hsB))
      (innerI φ (L2Test.sub (compactPowTestF p hs σ hσd hσn hsB) (compactPowTestF q hs σ hσd hσn hsB))) :=
    Req_symm (innerI_sub_right φ (compactPowTestF p hs σ hσd hσn hsB) (compactPowTestF q hs σ hσd hσn hsB))
  -- the difference test is bounded by `2`
  have hsubbd : ∀ x, Rle (Rabs ((L2Test.sub (compactPowTestF p hs σ hσd hσn hsB)
      (compactPowTestF q hs σ hσd hσn hsB)).f x)) (ofQ (⟨2, 1⟩ : Q) (by decide)) :=
    fun x => (L2Test.sub (compactPowTestF p hs σ hσd hσn hsB) (compactPowTestF q hs σ hσd hσn hsB)).hbd x
  -- the product integrand is bounded by `2·M_φ`
  have hbd_prod : ∀ x, Rle (Rabs (Rmul (φ.f x)
      ((L2Test.sub (compactPowTestF p hs σ hσd hσn hsB) (compactPowTestF q hs σ hσd hσn hsB)).f x)))
      (ofQ (mul φ.M (⟨2, 1⟩ : Q)) (Qmul_den_pos φ.hMd (by decide))) := by
    intro x
    refine Rle_trans (Rle_of_Req (Rabs_Rmul (φ.f x) _)) ?_
    refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs _) (φ.hbd x)) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ φ.hMd φ.hMn) (hsubbd x)) ?_
    exact Rle_of_Req (Rmul_ofQ_ofQ φ.hMd (by decide))
  -- the product integrand vanishes on the dyadic tail `[1/2^p, 1]` (both floors ≤ t there)
  have htail_prod : ∀ x, Rle (ofQ (⟨1, 2 ^ p⟩ : Q) (two_pow_pos p)) x → Rle x one →
      Req (Rmul (φ.f x) ((L2Test.sub (compactPowTestF p hs σ hσd hσn hsB)
        (compactPowTestF q hs σ hσd hσn hsB)).f x)) zero := by
    intro x hx0 hx1
    have hx' : Rle (ofQ (⟨1, 2 ^ q⟩ : Q) (two_pow_pos q)) x :=
      Rle_trans (Rle_ofQ_ofQ (two_pow_pos q) (two_pow_pos p) hle) hx0
    have hsub0 : Req ((L2Test.sub (compactPowTestF p hs σ hσd hσn hsB)
        (compactPowTestF q hs σ hσd hσn hsB)).f x) zero :=
      Req_trans (Radd_congr (compactPow_floor_indep_real (⟨1, 2 ^ p⟩ : Q) (⟨1, 2 ^ q⟩ : Q)
          (by show (0 : Int) < 1; decide) (two_pow_pos p) (by show (0 : Int) < 1; decide)
          (two_pow_pos q) hs hx0 hx') (Req_refl _))
        (Radd_neg ((compactPowTestF q hs σ hσd hσn hsB).f x))
    exact Req_trans (Rmul_congr (Req_refl _) hsub0) (Rmul_zero (φ.f x))
  -- apply the dyadic tail bound at depth `p`
  have htb := riemannIntegral_dyadic_tail_bound (mul φ.M (⟨2, 1⟩ : Q))
    (Qmul_den_pos φ.hMd (by decide)) (Qmul_num_nonneg φ.hMn (by decide)) p
    (fun x => Rmul (φ.f x) ((L2Test.sub (compactPowTestF p hs σ hσd hσn hsB)
      (compactPowTestF q hs σ hσd hσn hsB)).f x))
    (l2L φ (L2Test.sub (compactPowTestF p hs σ hσd hσn hsB) (compactPowTestF q hs σ hσd hσn hsB)))
    (l2L_den φ (L2Test.sub (compactPowTestF p hs σ hσd hσn hsB) (compactPowTestF q hs σ hσd hσn hsB)))
    (l2L_num φ (L2Test.sub (compactPowTestF p hs σ hσd hσn hsB) (compactPowTestF q hs σ hσd hσn hsB)))
    (l2lip φ (L2Test.sub (compactPowTestF p hs σ hσd hσn hsB) (compactPowTestF q hs σ hσd hσn hsB)))
    (l2fc φ (L2Test.sub (compactPowTestF p hs σ hσd hσn hsB) (compactPowTestF q hs σ hσd hσn hsB)))
    hbd_prod htail_prod
  exact Rle_trans (Rle_of_Req (Rabs_congr hdiff)) htb

end Multiplicity.UOR.Bridge.F1Square.Square
