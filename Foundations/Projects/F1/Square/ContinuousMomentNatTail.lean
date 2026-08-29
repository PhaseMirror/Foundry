/-
F1 square — **the pre-Hilbert layer, brick 114** (`ContinuousMomentNatTail.lean`): **the floor defect at
the integer exponent `n` decays like `1/2^m`** — the compact moment at exponent `n` with the dyadic
floor `1/2^m` differs from the integer Mellin moment `mellinMoment φ n` by at most `2·M_φ·(1/2^m)`:

    `|compactMoment φ (1/2^m) n  −  mellinMoment φ n|  ≤  2·M_φ·(1/2^m)`
      (`compactMomentF_natExpR_sub_mellin_bound`).

WHY (the Sonine route, step 3, integer-moment identification beyond `s = 1`). Brick 113 pins the
compact integrand at exponent `n` to the clamped monomial `(powTest n).f = clamp01ⁿ` on `[1/2^m, 1]`, so
their difference — realized as `innerI φ (compactPowTest_n −ₜ powTest n)` through `innerI_sub_right` —
vanishes on the dyadic tail and is bounded by `2·M_φ`, and the dyadic tail bound (brick 107) gives the
geometric decay. This is brick 108 (the `s = 1` floor defect) at general integer exponent, and the
Cauchy estimate that pins the `a → 0` limit of the continuous moment to the integer Mellin moment.

HONEST SCOPE. A quantitative floor-defect bound at the integer exponent `n`, compact side. NOT the limit
identification itself (brick 115), NOT the transform pair, NOT inversion. Step 4 is RH; crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.ContinuousMomentNatExp
import Foundations.F1.Square.ContinuousMomentGenTail

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `(powTest n).M = ⟨1,1⟩` — the clamped monomial is bounded by `1` (the `n`-fold product of `⟨1,1⟩`
    bounds; does not reduce for symbolic `n`, hence the induction). -/
private theorem powTest_M : ∀ n : Nat, (powTest n).M = (⟨1, 1⟩ : Q)
  | 0 => rfl
  | n + 1 => by show mul (powTest n).M (⟨1, 1⟩ : Q) = (⟨1, 1⟩ : Q); rw [powTest_M n]; rfl

set_option maxHeartbeats 1600000 in
/-- **★ THE FLOOR DEFECT AT THE INTEGER EXPONENT DECAYS LIKE `1/2^m`**:
    `|compactMoment φ (1/2^m) n − mellinMoment φ n| ≤ 2·M_φ·(1/2^m)`. Brick 113 makes the compact
    integrand agree with `(powTest n).f` on `[1/2^m,1]`, so the difference vanishes on the dyadic tail
    and the tail bound (brick 107) gives the geometric decay. Brick 108 at general integer exponent. -/
theorem compactMomentF_natExpR_sub_mellin_bound (φ : L2Test) (n m : Nat) :
    Rle (Rabs (Rsub (compactMomentF φ m (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q) Nat.one_pos
        (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n))) (mellinMoment φ n)))
        (ofQ (mul (mul φ.M (⟨2, 1⟩ : Q)) (⟨1, 2 ^ m⟩ : Q))
          (Qmul_den_pos (Qmul_den_pos φ.hMd (by decide)) (two_pow_pos m))) := by
  have ha1 : Qle (⟨1, 2 ^ m⟩ : Q) (⟨1, 1⟩ : Q) := by
    have h1m : (1 : Nat) ≤ 2 ^ m := two_pow_pos m
    have hc : ((1 : Nat) : Int) ≤ ((2 ^ m : Nat) : Int) := Int.ofNat_le.mpr h1m
    simp only [Qle]; omega
  -- the difference is `innerI φ (χ − powTest n)`
  have hdiff : Req (Rsub (compactMomentF φ m (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q) Nat.one_pos
        (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n))) (mellinMoment φ n))
      (innerI φ (L2Test.sub (compactPowTestF m (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q) Nat.one_pos
        (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n))) (powTest n))) :=
    Req_symm (innerI_sub_right φ (compactPowTestF m (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q) Nat.one_pos
      (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n))) (powTest n))
  -- the difference test is bounded by `2` (its `M = ⟨1,1⟩ + (powTest n).M = ⟨2,1⟩` via powTest_M)
  have hsubM : (L2Test.sub (compactPowTestF m (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q) Nat.one_pos
      (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n))) (powTest n)).M = (⟨2, 1⟩ : Q) := by
    show add (⟨1, 1⟩ : Q) (powTest n).M = (⟨2, 1⟩ : Q); rw [powTest_M n]; rfl
  have hsubbd : ∀ x, Rle (Rabs ((L2Test.sub (compactPowTestF m (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q)
      Nat.one_pos (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n))) (powTest n)).f x))
      (ofQ (⟨2, 1⟩ : Q) (by decide)) := fun x =>
    Rle_trans ((L2Test.sub (compactPowTestF m (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q) Nat.one_pos
        (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n))) (powTest n)).hbd x)
      (Rle_of_Req (ofQ_congr (L2Test.sub (compactPowTestF m (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q)
        Nat.one_pos (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n))) (powTest n)).hMd (by decide)
        (by rw [hsubM]; exact Qeq_refl _)))
  -- the product integrand is bounded by `2·M_φ`
  have hbd_prod : ∀ x, Rle (Rabs (Rmul (φ.f x)
      ((L2Test.sub (compactPowTestF m (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q) Nat.one_pos
        (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n))) (powTest n)).f x)))
      (ofQ (mul φ.M (⟨2, 1⟩ : Q)) (Qmul_den_pos φ.hMd (by decide))) := by
    intro x
    refine Rle_trans (Rle_of_Req (Rabs_Rmul (φ.f x) _)) ?_
    refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs _) (φ.hbd x)) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ φ.hMd φ.hMn) (hsubbd x)) ?_
    exact Rle_of_Req (Rmul_ofQ_ofQ φ.hMd (by decide))
  -- the product integrand vanishes on the dyadic tail `[1/2^m, 1]` (brick 113)
  have htail_prod : ∀ x, Rle (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m)) x → Rle x one →
      Req (Rmul (φ.f x) ((L2Test.sub (compactPowTestF m (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q)
        Nat.one_pos (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n))) (powTest n)).f x)) zero := by
    intro x hx0 hx1
    have hc : Req (compactPow (⟨1, 2 ^ m⟩ : Q) (by show (0 : Int) < 1; decide) (two_pow_pos m)
        (natExpR n) x) ((powTest n).f x) :=
      compactPow_natExpR_eq_powTest (⟨1, 2 ^ m⟩ : Q) (by show (0 : Int) < 1; decide) (two_pow_pos m)
        ha1 x hx0 hx1 n
    have hsub0 : Req ((L2Test.sub (compactPowTestF m (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q) Nat.one_pos
        (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n))) (powTest n)).f x) zero :=
      Req_trans (Radd_congr hc (Req_refl _)) (Radd_neg ((powTest n).f x))
    exact Req_trans (Rmul_congr (Req_refl _) hsub0) (Rmul_zero (φ.f x))
  -- apply the dyadic tail bound at depth `m`
  have htb := riemannIntegral_dyadic_tail_bound (mul φ.M (⟨2, 1⟩ : Q))
    (Qmul_den_pos φ.hMd (by decide)) (Qmul_num_nonneg φ.hMn (by decide)) m
    (fun x => Rmul (φ.f x) ((L2Test.sub (compactPowTestF m (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q)
      Nat.one_pos (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n))) (powTest n)).f x))
    (l2L φ (L2Test.sub (compactPowTestF m (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q) Nat.one_pos
      (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n))) (powTest n)))
    (l2L_den φ (L2Test.sub (compactPowTestF m (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q) Nat.one_pos
      (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n))) (powTest n)))
    (l2L_num φ (L2Test.sub (compactPowTestF m (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q) Nat.one_pos
      (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n))) (powTest n)))
    (l2lip φ (L2Test.sub (compactPowTestF m (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q) Nat.one_pos
      (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n))) (powTest n)))
    (l2fc φ (L2Test.sub (compactPowTestF m (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q) Nat.one_pos
      (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n))) (powTest n)))
    hbd_prod htail_prod
  exact Rle_trans (Rle_of_Req (Rabs_congr hdiff)) htb

end Multiplicity.UOR.Bridge.F1Square.Square
