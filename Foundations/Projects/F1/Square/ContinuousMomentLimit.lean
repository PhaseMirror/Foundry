/-
F1 square — **the pre-Hilbert layer, brick 109** (`ContinuousMomentLimit.lean`): **THE `a → 0`
MELLIN LIMIT AS A CONSTRUCTED LIMIT OBJECT** — the compact Mellin moment at `s = 1` converges, as
the floor shrinks to `0`, to the integer Mellin moment:

    `Rlim_{j→∞} compactMoment φ (1/2^{r(j)}) 1  ≈  mellinMoment φ 1`
      (`compactMomentOne_limit_eq_mellin`).

WHY (the Sonine route, step 3, the `a → 0` Mellin limit). Brick 108 gives the quantitative defect
`|compactMoment φ (1/2^m) 1 − mellinMoment φ 1| ≤ 2·M_φ·(1/2^m)`. This brick packages that rate into
a genuine Bishop limit: reindexing the depth by `r(j) = (⌈2·M_φ⌉+1)·(j+1)` absorbs the constant
`2·M_φ` (using `n < 2^n`), so the reindexed sequence `compactMomentSeq φ j = compactMoment φ (1/2^{r(j)}) 1`
lies within `1/(j+1)` of the Mellin moment — a regular sequence (`RReg`, via the triangle through the
limit) whose Bishop limit `Rlim` **is** `mellinMoment φ 1` (`Rlim_eval_real_rate`). This is "the
continuous parameter proper" at the transform's boundary `s = 1`: the compact totalization's floor
dependence is a removable artifact, and the limit recovers the genuine integer Mellin moment.

HONEST SCOPE. The `a → 0` limit of the compact Mellin moment at `s = 1`, identified with the integer
Mellin moment, as a constructed real limit. NOT the transform pair, NOT inversion, NOT the full
continuous `s`-parameter transform. The crux fields stay `none`; step 4 is RH.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.ContinuousMomentTailBound

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The constant-absorbing depth reindex** `r(j) = (⌈2·M_φ⌉ + 1)·(j + 1)`, chosen so the geometric
    defect `2·M_φ/2^{r(j)}` (brick 108) drops below `1/(j+1)` via `n < 2^n`. -/
def momRate (φ : L2Test) (j : Nat) : Nat :=
  ((mul φ.M (⟨2, 1⟩ : Q)).num.toNat + 1) * (j + 1)

/-- **The reindexed compact-moment sequence** `compactMomentSeq φ j = compactMoment φ (1/2^{r(j)}) 1`. -/
def compactMomentSeq (φ : L2Test) (j : Nat) : Real := compactMomentOne φ (momRate φ j)

/-- The reindexed sequence is within `1/(j+1)` of the integer Mellin moment (brick 108 + the reindex
    inequality `2·M_φ·(1/2^{r(j)}) ≤ 1/(j+1)`). -/
theorem compactMomentSeq_rate (φ : L2Test) (j : Nat) :
    Rle (Rabs (Rsub (compactMomentSeq φ j) (mellinMoment φ 1)))
        (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have hDnn : (0 : Int) ≤ (mul φ.M (⟨2, 1⟩ : Q)).num := Qmul_num_nonneg φ.hMn (by decide)
  have hDden : 0 < (mul φ.M (⟨2, 1⟩ : Q)).den := Qmul_den_pos φ.hMd (by decide)
  -- the reindex inequality, in `Nat` (keeping `2^R` an atom)
  have hnat : (mul φ.M (⟨2, 1⟩ : Q)).num.toNat * (j + 1)
      ≤ (mul φ.M (⟨2, 1⟩ : Q)).den * 2 ^ momRate φ j := by
    have h1 : (mul φ.M (⟨2, 1⟩ : Q)).num.toNat * (j + 1)
        ≤ ((mul φ.M (⟨2, 1⟩ : Q)).num.toNat + 1) * (j + 1) :=
      Nat.mul_le_mul (Nat.le_succ _) (Nat.le_refl _)
    have h2 : momRate φ j < 2 ^ momRate φ j := Nat.lt_two_pow_self
    have h3 : 2 ^ momRate φ j ≤ (mul φ.M (⟨2, 1⟩ : Q)).den * 2 ^ momRate φ j :=
      Nat.le_mul_of_pos_left _ hDden
    exact Nat.le_trans (Nat.le_trans h1 (Nat.le_of_lt h2)) h3
  -- the same inequality as a rational `Qle`
  have hQ : Qle (mul (mul φ.M (⟨2, 1⟩ : Q)) (⟨1, 2 ^ momRate φ j⟩ : Q)) (⟨1, j + 1⟩ : Q) := by
    have hc : ((mul φ.M (⟨2, 1⟩ : Q)).num.toNat : Int) = (mul φ.M (⟨2, 1⟩ : Q)).num :=
      Int.toNat_of_nonneg hDnn
    have key : (mul φ.M (⟨2, 1⟩ : Q)).num * ((j + 1 : Nat) : Int)
        ≤ (((mul φ.M (⟨2, 1⟩ : Q)).den * 2 ^ momRate φ j : Nat) : Int) := by
      calc (mul φ.M (⟨2, 1⟩ : Q)).num * ((j + 1 : Nat) : Int)
            = ((mul φ.M (⟨2, 1⟩ : Q)).num.toNat : Int) * ((j + 1 : Nat) : Int) := by rw [hc]
        _ = (((mul φ.M (⟨2, 1⟩ : Q)).num.toNat * (j + 1) : Nat) : Int) := by push_cast; ring_uor
        _ ≤ (((mul φ.M (⟨2, 1⟩ : Q)).den * 2 ^ momRate φ j : Nat) : Int) := Int.ofNat_le.mpr hnat
    show (mul φ.M (⟨2, 1⟩ : Q)).num * 1 * ((j + 1 : Nat) : Int)
        ≤ (1 : Int) * (((mul φ.M (⟨2, 1⟩ : Q)).den * 2 ^ momRate φ j : Nat) : Int)
    rw [Int.mul_one, Int.one_mul]
    exact key
  -- brick 108 at depth `r(j)`, then weaken the bound through `hQ`
  refine Rle_trans (compactMomentOne_sub_mellin_bound φ (momRate φ j)) ?_
  exact Rle_ofQ_ofQ (Qmul_den_pos (Qmul_den_pos φ.hMd (by decide)) (two_pow_pos (momRate φ j)))
    (Nat.succ_pos j) hQ

/-- The reindexed sequence is regular (`RReg`) — the triangle through the shared limit
    `mellinMoment φ 1`: `|compactMomentSeq j − compactMomentSeq k| ≤ 1/(j+1) + 1/(k+1)`. -/
theorem compactMomentSeq_RReg (φ : L2Test) : RReg (compactMomentSeq φ) := by
  refine RReg_of_real_bound _ (fun j k => add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
    (fun j k => add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) (fun j k => Qle_refl _) ?_
  intro j k
  -- `compactMomentSeq j − L ≤ 1/(j+1)` and `L − compactMomentSeq k ≤ 1/(k+1)`
  have hj : Rle (Rsub (compactMomentSeq φ j) (mellinMoment φ 1)) (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) :=
    Rle_of_Rabs_le (compactMomentSeq_rate φ j)
  have hk : Rle (Rsub (mellinMoment φ 1) (compactMomentSeq φ k)) (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k)) :=
    Rle_of_Rabs_le (Rle_trans (Rle_of_Req (Req_trans
      (Rabs_congr (Req_symm (Rneg_Rsub (compactMomentSeq φ k) (mellinMoment φ 1))))
      (Rabs_Rneg (Rsub (compactMomentSeq φ k) (mellinMoment φ 1))))) (compactMomentSeq_rate φ k))
  -- `compactMomentSeq j − compactMomentSeq k = (L − compactMomentSeq k) + (compactMomentSeq j − L)`
  refine Rle_trans (Rle_of_Req (Req_symm
    (Radd_Rsub_Rsub (mellinMoment φ 1) (compactMomentSeq φ k) (compactMomentSeq φ j)))) ?_
  refine Rle_trans (Radd_le_add hk hj) ?_
  refine Rle_of_Req (Req_trans (Radd_ofQ_ofQ (Nat.succ_pos k) (Nat.succ_pos j))
    (ofQ_congr (add_den_pos (Nat.succ_pos k) (Nat.succ_pos j))
      (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k)) ?_))
  show Qeq (add (⟨1, k + 1⟩ : Q) (⟨1, j + 1⟩ : Q)) (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
  simp only [Qeq, add]; push_cast; ring_uor

/-- **★ THE `a → 0` MELLIN LIMIT**: the compact Mellin moment at `s = 1` converges, as the floor
    `1/2^{r(j)} → 0`, to the integer Mellin moment — `Rlim (compactMomentSeq φ) ≈ mellinMoment φ 1`. The
    reindexed sequence lies within `1/(j+1)` of the target (`compactMomentSeq_rate`), so its Bishop limit is
    exactly the target (`Rlim_eval_real_rate`, `C = 1`). -/
theorem compactMomentOne_limit_eq_mellin (φ : L2Test) :
    Req (Rlim (compactMomentSeq φ) (compactMomentSeq_RReg φ)) (mellinMoment φ 1) :=
  Rlim_eval_real_rate (compactMomentSeq_RReg φ) (mellinMoment φ 1) (C := 1) (compactMomentSeq_rate φ)

end Multiplicity.UOR.Bridge.F1Square.Square
