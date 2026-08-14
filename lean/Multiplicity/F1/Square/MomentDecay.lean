/-
F1 square — **the pre-Hilbert layer, brick 38** (`MomentDecay.lean`): **THE MOMENT MAP DECAYS
AT THE SHARP RATE** — for every test of the bounded-Lipschitz class,

    `|⟨φ, xⁿ⟩| ≤ M_φ / (n+1)`   (`mellinMoment_abs_le`).

This is the first quantitative rate on the moment map, and it is the sharp one: the bound is
attained in order for `φ = xᵏ`, where `⟨xᵏ, xⁿ⟩ = 1/(k+n+1)`. Cauchy–Schwarz would only give
`O(1/√n)` (through `⟨xⁿ,xⁿ⟩ = 1/(2n+1)`); the comparison route gives `O(1/n)`, so the squared
moments are summable — the `ℓ²` datum the completion axis wants, rather than a merely bounded
sequence.

The proof is a two-sided comparison on the sampling domain: on `[0,1]` the monomial is
nonnegative (`powTest_nonneg`), so `φ(x)·xⁿ ≤ M_φ·xⁿ` pointwise, and `riemannIntegral_le_unit`
integrates it against `riemannIntegral_smul` and brick 34's `∫₀¹ xⁿ = 1/(n+1)`. The lower half
is free: applying the upper bound to `L2Test.neg φ` — which carries the SAME `M` — and using
`innerI_neg_left` flips the sign.

HONEST SCOPE. A rate on the compact `[0,1]` moment map for the bounded-Lipschitz class; not
the truncation-uniform `ℓ²` weights of the completion axis (which are about the discrete
coordinates), and nothing about the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.HilbertGram
import Multiplicity.F1Square.Square.PairingLimitI

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The monomial tests are pointwise nonnegative. -/
theorem powTest_nonneg : ∀ (n : Nat) (x : Real), Rnonneg ((powTest n).f x)
  | 0, _ => Rnonneg_ofQ (by decide) (by decide)
  | n + 1, x => Rnonneg_Rmul (powTest_nonneg n x) (clamp01_nonneg x)

/-- **Scalar Lipschitz transfer**: if `f` is `L_f`-Lipschitz then `q·f` is `L`-Lipschitz for
    any `L ≥ |q|·L_f`. -/
theorem lip_smul_of {f : Real → Real} (q : Q) (hq : 0 < q.den) {Lf L : Q}
    (hLfd : 0 < Lf.den) (hLd : 0 < L.den)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ Lf hLfd) (Rabs (Rsub x y))))
    (h : Qle (mul (Qabs q) Lf) L) :
    ∀ x y, Rle (Rabs (Rsub (Rmul (ofQ q hq) (f x)) (Rmul (ofQ q hq) (f y))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr
    (Req_symm (Rmul_sub_distrib (ofQ q hq) (f x) (f y))))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul (ofQ q hq) (Rsub (f x) (f y)))) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr (Rabs_ofQ hq) (Req_refl _))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (Qabs_den_pos hq)
    (by show (0 : Int) ≤ ((q.num.natAbs : Nat) : Int); exact Int.ofNat_nonneg _))
    (hlip x y)) ?_
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_assoc _ _ _))) ?_
  refine Rmul_le_Rmul_right (Rnonneg_Rabs _) ?_
  exact Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (Qabs_den_pos hq) hLfd))
    (Rle_ofQ_ofQ (Qmul_den_pos (Qabs_den_pos hq) hLfd) hLd h)

/-- The shared comparison modulus for `φ·xⁿ`, `xⁿ` and `M_φ·xⁿ` — each summand present so
    every one of the three weakenings is a `Qle_self_add`. -/
private def decL (φ : L2Test) (n : Nat) : Q :=
  add (add (l2L φ (powTest n)) (mul (Qabs φ.M) (powTest n).L)) (powTest n).L

private theorem decB_num (φ : L2Test) (n : Nat) :
    0 ≤ (mul (Qabs φ.M) (powTest n).L).num :=
  Int.mul_nonneg (Int.ofNat_nonneg _) (powTest n).hLn

private theorem decAB_den (φ : L2Test) (n : Nat) :
    0 < (add (l2L φ (powTest n)) (mul (Qabs φ.M) (powTest n).L)).den :=
  add_den_pos (l2L_den φ (powTest n)) (Qmul_den_pos (Qabs_den_pos φ.hMd) (powTest n).hLd)

private theorem decAB_num (φ : L2Test) (n : Nat) :
    0 ≤ (add (l2L φ (powTest n)) (mul (Qabs φ.M) (powTest n).L)).num :=
  Qadd_num_nonneg_loc (l2L_num φ (powTest n)) (decB_num φ n)

private theorem decL_den (φ : L2Test) (n : Nat) : 0 < (decL φ n).den :=
  add_den_pos (decAB_den φ n) (powTest n).hLd

private theorem decL_num (φ : L2Test) (n : Nat) : 0 ≤ (decL φ n).num :=
  Qadd_num_nonneg_loc (decAB_num φ n) (powTest n).hLn

private theorem l2L_le_decL (φ : L2Test) (n : Nat) : Qle (l2L φ (powTest n)) (decL φ n) :=
  Qle_trans (decAB_den φ n) (Qle_self_add (decB_num φ n))
    (Qle_self_add (powTest n).hLn)

private theorem scal_le_decL (φ : L2Test) (n : Nat) :
    Qle (mul (Qabs φ.M) (powTest n).L) (decL φ n) :=
  Qle_trans (decAB_den φ n) (Qle_self_add_l (l2L_num φ (powTest n)))
    (Qle_self_add (powTest n).hLn)

private theorem pow_le_decL (φ : L2Test) (n : Nat) : Qle ((powTest n).L) (decL φ n) :=
  Qle_self_add_l (decAB_num φ n)

/-- **THE ONE-SIDED BOUND**: `⟨φ, xⁿ⟩ ≤ M_φ/(n+1)`. -/
theorem mellinMoment_le (φ : L2Test) (n : Nat) :
    Rle (mellinMoment φ n)
      (ofQ (mul φ.M (⟨1, n + 1⟩ : Q)) (Qmul_den_pos φ.hMd (Nat.succ_pos n))) := by
  have hf := lip_weaken (l2L_den φ (powTest n)) (decL_den φ n) (l2L_le_decL φ n)
    (l2lip φ (powTest n))
  have hp := lip_weaken (powTest n).hLd (decL_den φ n) (pow_le_decL φ n) (powTest n).hlip
  have hMp := lip_smul_of φ.M φ.hMd (powTest n).hLd (decL_den φ n) (powTest n).hlip
    (scal_le_decL φ n)
  have hfcMp : ∀ x y, Req x y →
      Req (Rmul (ofQ φ.M φ.hMd) ((powTest n).f x)) (Rmul (ofQ φ.M φ.hMd) ((powTest n).f y)) :=
    fun x y h => Rmul_congr (Req_refl _) ((powTest n).hfc x y h)
  -- pointwise comparison on the sampling domain
  have hpt : ∀ x, Rle zero x → Rle x one →
      Rle (Rmul (φ.f x) ((powTest n).f x)) (Rmul (ofQ φ.M φ.hMd) ((powTest n).f x)) := by
    intro x _ _
    exact Rmul_le_Rmul_right (powTest_nonneg n x) (Rle_of_Rabs_le (φ.hbd x))
  have hcmp := riemannIntegral_le_unit (decL_den φ n) (decL_num φ n) hf
    (l2fc φ (powTest n)) hMp hfcMp hpt
  -- the right end evaluates
  have hval : Req (riemannIntegral (decL_den φ n) (decL_num φ n) hMp hfcMp)
      (ofQ (mul φ.M (⟨1, n + 1⟩ : Q)) (Qmul_den_pos φ.hMd (Nat.succ_pos n))) := by
    refine Req_trans (riemannIntegral_smul φ.M φ.hMd (decL_den φ n) (decL_num φ n)
      hp (powTest n).hfc hMp hfcMp) ?_
    refine Req_trans (Rmul_congr (Req_refl _)
      (Req_trans (riemannIntegral_certif_irrel (decL_den φ n) (decL_num φ n) hp
        (powTest n).hfc (powTest n).hLd (powTest n).hLn (powTest n).hlip (powTest n).hfc)
        (riemannIntegral_powTest_all n))) ?_
    exact Rmul_ofQ_ofQ φ.hMd (Nat.succ_pos n)
  refine Rle_trans (Rle_of_Req (riemannIntegral_certif_irrel
    (l2L_den φ (powTest n)) (l2L_num φ (powTest n)) (l2lip φ (powTest n))
    (l2fc φ (powTest n)) (decL_den φ n) (decL_num φ n) hf (l2fc φ (powTest n)))) ?_
  exact Rle_trans hcmp (Rle_of_Req hval)

/-- **THE SHARP MOMENT DECAY**: `|⟨φ, xⁿ⟩| ≤ M_φ/(n+1)` — so the squared moments are
    summable. The lower half is the upper bound at `L2Test.neg φ`, which carries the same
    `M`, with `innerI_neg_left` flipping the sign. -/
theorem mellinMoment_abs_le (φ : L2Test) (n : Nat) :
    Rle (Rabs (mellinMoment φ n))
      (ofQ (mul φ.M (⟨1, n + 1⟩ : Q)) (Qmul_den_pos φ.hMd (Nat.succ_pos n))) := by
  refine Rabs_le_of_both (mellinMoment_le φ n) ?_
  refine Rle_trans (Rle_of_Req (Req_symm (innerI_neg_left φ (powTest n)))) ?_
  exact mellinMoment_le (L2Test.neg φ) n

end Multiplicity.UOR.Bridge.F1Square.Square
