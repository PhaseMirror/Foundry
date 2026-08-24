/-
F1 square — **the pre-Hilbert layer, brick 112** (`ContinuousMomentGenLimit.lean`): **THE CONTINUOUS
MELLIN MOMENT AT GENERAL REAL `s` EXISTS** — the compact moment at exponent `s` converges, as the
floor `→ 0`, to a constructed real that DEFINES the transform at `s`:

    `compactMomentGenLim φ s := Rlim_{j→∞} compactMoment φ (1/2^{r(j)}) s`
      (regular by `compactMomentGenSeq_RReg`).

WHY (the Sonine route, step 3, "the continuous parameter proper"). At `s = 1` the `a → 0` limit was
identified with the pre-existing integer moment (brick 109). At GENERAL real `s ∈ [0, σ]` there is no
integer target — so the content is that the floor sequence is CAUCHY (regular), hence has a Bishop
limit, and that limit IS the Mellin transform of `φ` at the continuous exponent `s`. The Cauchy
estimate is brick 111 (`|moment_p − moment_q| ≤ 2·M_φ/2^{min(p,q)}`); the same constant-absorbing
reindex `r(j)` as brick 109 (via `n < 2^n`) drops the gap below `1/(j+1) + 1/(k+1)`, feeding
`RReg_of_real_bound`. The limit `compactMomentGenLim φ s` is the genuine continuous-parameter object the
Mellin front was missing at general `s`.

HONEST SCOPE. The a→0 limit of the compact Mellin moment at general real `s`, as a constructed real
(existence via regularity). This DEFINES the continuous transform pointwise in `s`; it is NOT the
transform PAIR, NOT inversion, NOT any positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.ContinuousMomentGenTail
import Multiplicity.F1.Square.ContinuousMomentLimit

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The reindexed general-`s` compact-moment sequence** `j ↦ compactMoment φ (1/2^{r(j)}) s`, with
    the same constant-absorbing reindex `r = momRate φ` as brick 109. -/
def compactMomentGenSeq (φ : L2Test) {s : Real} (hs : Rnonneg s) (σ : Q) (hσd : 0 < σ.den)
    (hσn : 0 ≤ σ.num) (hsB : Rle s (ofQ σ hσd)) (j : Nat) : Real :=
  compactMomentF φ (momRate φ j) hs σ hσd hσn hsB

/-- The reindex inequality `2·M_φ·(1/2^{r(m)}) ≤ 1/(m+1)` (as a `Qle`; same computation as brick 109). -/
private theorem gen_reindex_Qle (φ : L2Test) (m : Nat) :
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

/-- The reindex `r = momRate φ` is monotone. -/
private theorem momRate_mono (φ : L2Test) {a b : Nat} (hab : a ≤ b) : momRate φ a ≤ momRate φ b := by
  unfold momRate
  exact Nat.mul_le_mul (Nat.le_refl _) (by omega)

/-- **★ THE GENERAL-`s` FLOOR SEQUENCE IS REGULAR** (`RReg`): `|Yⱼ − Yₖ| ≤ 1/(j+1) + 1/(k+1)`, the
    Cauchy content of the `a → 0` limit at general `s`. Brick 111's floor-difference bound at the two
    reindexed depths, weakened through the reindex inequality; the two orderings by `Nat.le_total`. -/
theorem compactMomentGenSeq_RReg (φ : L2Test) {s : Real} (hs : Rnonneg s) (σ : Q) (hσd : 0 < σ.den)
    (hσn : 0 ≤ σ.num) (hsB : Rle s (ofQ σ hσd)) : RReg (compactMomentGenSeq φ hs σ hσd hσn hsB) := by
  refine RReg_of_real_bound _ (fun j k => add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
    (fun j k => add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) (fun j k => Qle_refl _) ?_
  intro j k
  rcases Nat.le_total j k with hjk | hkj
  · have hbnd := compactMoment_floor_diff_bound φ hs σ hσd hσn hsB (momRate φ j) (momRate φ k)
      (momRate_mono φ hjk)
    refine Rle_trans (Rle_Rabs_self _) (Rle_trans hbnd ?_)
    refine Rle_trans (Rle_ofQ_ofQ (Qmul_den_pos (Qmul_den_pos φ.hMd (by decide)) (two_pow_pos _))
      (Nat.succ_pos j) (gen_reindex_Qle φ j)) ?_
    exact Rle_ofQ_ofQ (Nat.succ_pos j) (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
      (Qle_self_add (by show (0 : Int) ≤ 1; decide))
  · have hbnd := compactMoment_floor_diff_bound φ hs σ hσd hσn hsB (momRate φ k) (momRate φ j)
      (momRate_mono φ hkj)
    have hsymm : Req (Rabs (Rsub (compactMomentGenSeq φ hs σ hσd hσn hsB j)
        (compactMomentGenSeq φ hs σ hσd hσn hsB k)))
        (Rabs (Rsub (compactMomentGenSeq φ hs σ hσd hσn hsB k)
          (compactMomentGenSeq φ hs σ hσd hσn hsB j))) :=
      Req_trans (Rabs_congr (Req_symm (Rneg_Rsub _ _))) (Rabs_Rneg _)
    refine Rle_trans (Rle_Rabs_self _) (Rle_trans (Rle_of_Req hsymm) (Rle_trans hbnd ?_))
    refine Rle_trans (Rle_ofQ_ofQ (Qmul_den_pos (Qmul_den_pos φ.hMd (by decide)) (two_pow_pos _))
      (Nat.succ_pos k) (gen_reindex_Qle φ k)) ?_
    exact Rle_ofQ_ofQ (Nat.succ_pos k) (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
      (Qle_self_add_l (by show (0 : Int) ≤ 1; decide))

/-- **THE CONTINUOUS MELLIN MOMENT AT GENERAL REAL `s`**: the `a → 0` limit of the compact moment, a
    constructed real — the Mellin transform of `φ` at the continuous exponent `s ∈ [0, σ]`, defined as
    the Bishop limit of the (regular) reindexed floor sequence. -/
def compactMomentGenLim (φ : L2Test) {s : Real} (hs : Rnonneg s) (σ : Q) (hσd : 0 < σ.den)
    (hσn : 0 ≤ σ.num) (hsB : Rle s (ofQ σ hσd)) : Real :=
  Rlim (compactMomentGenSeq φ hs σ hσd hσn hsB) (compactMomentGenSeq_RReg φ hs σ hσd hσn hsB)

/-- **The general-`s` compact moment converges to its limit** — `RTendsTo` of the reindexed floor
    sequence to `compactMomentGenLim φ s`, the a→0 convergence at the continuous exponent. -/
theorem compactMomentGenSeq_tendsto (φ : L2Test) {s : Real} (hs : Rnonneg s) (σ : Q) (hσd : 0 < σ.den)
    (hσn : 0 ≤ σ.num) (hsB : Rle s (ofQ σ hσd)) :
    RTendsTo (compactMomentGenSeq φ hs σ hσd hσn hsB) (compactMomentGenLim φ hs σ hσd hσn hsB) :=
  Rlim_tendsTo (compactMomentGenSeq φ hs σ hσd hσn hsB) (compactMomentGenSeq_RReg φ hs σ hσd hσn hsB)

end Multiplicity.UOR.Bridge.F1Square.Square
