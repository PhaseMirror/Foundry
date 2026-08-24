/-
F1 square — **the pre-Hilbert layer, brick 115** (`ContinuousMomentNatLimit.lean`): **the continuous
Mellin transform at the integer exponent `n` IS the integer Mellin moment** — the `a → 0` limit of the
compact moment at exponent `n` equals `mellinMoment φ n`:

    `compactMomentGenLim φ n  ≈  mellinMoment φ n`
      (`compactMomentGenLim_natExpR_eq_mellin`).

WHY (the Sonine route, step 3). Brick 112 constructed the continuous Mellin moment at general real `s`
as the `a → 0` limit `compactMomentGenLim φ s` (existence via regularity). This brick pins that limit,
at every INTEGER exponent `s = n`, to the pre-existing integer moment `mellinMoment φ n = ∫₀¹ φ·xⁿ` —
closing the doc's "identification with the integer moments beyond `s = 1`" (brick 109 was `n = 1` only).
The floor defect at exponent `n` (brick 114) is within `1/(j+1)` of `mellinMoment φ n` after the same
constant-absorbing reindex `r(j)` as brick 109, so `Rlim_eval_real_rate` identifies the Bishop limit
with the integer moment. The continuous transform and the discrete moment sequence now agree on the
integers: `compactMomentGenLim φ n ≈ mellinMoment φ n` for every `n`.

HONEST SCOPE. The identification of the general-`s` continuous moment with the integer Mellin moment at
integer exponents. NOT the transform pair, NOT inversion. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.ContinuousMomentGenLimit
import Multiplicity.F1.Square.ContinuousMomentNatTail

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The reindex inequality `2·M_φ·(1/2^{r(m)}) ≤ 1/(m+1)` (same computation as bricks 109/112, whose
    copies are private). -/
private theorem nat_reindex_Qle (φ : L2Test) (m : Nat) :
    Qle (mul (mul φ.M (⟨2, 1⟩ : Q)) (⟨1, 2 ^ momRate φ m⟩ : Q)) (⟨1, m + 1⟩ : Q) := by
  have hDnn : (0 : Int) ≤ (mul φ.M (⟨2, 1⟩ : Q)).num := Qmul_num_nonneg φ.hMn (by decide)
  have hDden : 0 < (mul φ.M (⟨2, 1⟩ : Q)).den := Qmul_den_pos φ.hMd (by decide)
  have hnat : (mul φ.M (⟨2, 1⟩ : Q)).num.toNat * (m + 1)
      ≤ (mul φ.M (⟨2, 1⟩ : Q)).den * 2 ^ momRate φ m := by
    have h1 : (mul φ.M (⟨2, 1⟩ : Q)).num.toNat * (m + 1)
        ≤ ((mul φ.M (⟨2, 1⟩ : Q)).num.toNat + 1) * (m + 1) :=
      Nat.mul_le_mul (Nat.le_succ _) (Nat.le_refl _)
    have h2 : momRate φ m < 2 ^ momRate φ m := Nat.lt_two_pow_self
    have h3 : 2 ^ momRate φ m ≤ (mul φ.M (⟨2, 1⟩ : Q)).den * 2 ^ momRate φ m :=
      Nat.le_mul_of_pos_left _ hDden
    exact Nat.le_trans (Nat.le_trans h1 (Nat.le_of_lt h2)) h3
  have hc : ((mul φ.M (⟨2, 1⟩ : Q)).num.toNat : Int) = (mul φ.M (⟨2, 1⟩ : Q)).num :=
    Int.toNat_of_nonneg hDnn
  have key : (mul φ.M (⟨2, 1⟩ : Q)).num * ((m + 1 : Nat) : Int)
      ≤ (((mul φ.M (⟨2, 1⟩ : Q)).den * 2 ^ momRate φ m : Nat) : Int) := by
    calc (mul φ.M (⟨2, 1⟩ : Q)).num * ((m + 1 : Nat) : Int)
          = ((mul φ.M (⟨2, 1⟩ : Q)).num.toNat : Int) * ((m + 1 : Nat) : Int) := by rw [hc]
      _ = (((mul φ.M (⟨2, 1⟩ : Q)).num.toNat * (m + 1) : Nat) : Int) := by push_cast; ring_uor
      _ ≤ (((mul φ.M (⟨2, 1⟩ : Q)).den * 2 ^ momRate φ m : Nat) : Int) := Int.ofNat_le.mpr hnat
  show (mul φ.M (⟨2, 1⟩ : Q)).num * 1 * ((m + 1 : Nat) : Int)
      ≤ (1 : Int) * (((mul φ.M (⟨2, 1⟩ : Q)).den * 2 ^ momRate φ m : Nat) : Int)
  rw [Int.mul_one, Int.one_mul]
  exact key

/-- **★ THE CONTINUOUS TRANSFORM AT THE INTEGER EXPONENT IS THE INTEGER MELLIN MOMENT**:
    `compactMomentGenLim φ n ≈ mellinMoment φ n` for every `n`. The floor defect at exponent `n`
    (brick 114) is within `1/(j+1)` of the integer moment after the reindex, so `Rlim_eval_real_rate`
    identifies the a→0 limit with `mellinMoment φ n`. Closes integer-moment identification beyond `s=1`. -/
theorem compactMomentGenLim_natExpR_eq_mellin (φ : L2Test) (n : Nat) :
    Req (compactMomentGenLim φ (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q) Nat.one_pos
          (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n)))
        (mellinMoment φ n) := by
  refine Rlim_eval_real_rate (compactMomentGenSeq_RReg φ (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q)
    Nat.one_pos (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n))) (mellinMoment φ n) (C := 1) ?_
  intro j
  refine Rle_trans (compactMomentF_natExpR_sub_mellin_bound φ n (momRate φ j)) ?_
  exact Rle_ofQ_ofQ (Qmul_den_pos (Qmul_den_pos φ.hMd (by decide)) (two_pow_pos _))
    (Nat.succ_pos j) (nat_reindex_Qle φ j)

end Multiplicity.UOR.Bridge.F1Square.Square
