/-
F1 square — **THE FIRST REALIZED WEIL SLOT WITH A LIVE PRIME SIDE, AND ITS SIGN**
(`BumpSlot.lean`): the off-center tent with knots `1, 2, 3` (peak at the prime `2`) as a
fully realized `WeilSlot` — the first test whose support MEETS the primes, so the
finite-place side is NONZERO (`bumpPrimePart_eq ≈ log 2`) — with every interface field a
kernel-evaluated integral, the closed form

    `W(bump) ≈ (1 + 3·log 3 − 4·log 2) − (log 2 + (6·log 2 − 3·log 3))`
             `= 1 + 6·log 3 − 11·log 2 ≈ −0.0329`          (`bumpWeilValue_eq`)

and the certified sign: **`W(bump) < 0`** (`bumpWeilValue_neg`).

WHAT THE SIGN MEANS. The Weil criterion is `RH ⟺ W(g ⋆ g^τ) ≥ 0` for all tests — positivity
on the AUTOCORRELATION cone, not the whole admissible class. The bump is admissible
(Bombieri's class `W`: piecewise linear, rational knots) but is NOT an autocorrelation: it
vanishes at `1` (`f(1) = ∫|g|² = 0` forces `g = 0`) and its support sits asymmetrically in
`[1, 3]`. A kernel-certified `W < 0` at such a test is therefore CONSISTENT with RH and is
the honest counterpart of `tentWeilValue_pos`: positivity of the Weil functional is NOT a
pointwise feature of the test class — the autocorrelation structure (the `f, f̂` coupling
the Sonine route builds toward) is load-bearing. The same cancellation-not-magnitude
finding as `α(2) < 0` and `arch(1) < 0`, now at the level of the assembled functional.

HONEST SCOPE. One realized slot, one certified sign; no statement about the pairing FAMILY.
The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Square.Pairing
import Core.F1.Analysis.BumpPieces

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The bump test datum.
-- ===========================================================================

/-- **The bump test function** (knots `1, 2, 3`), as rational-point evaluations:
    `q − 1` on `(1, 2]`, `3 − q` on `(2, 3]`, `0` outside (and on junk denominators).
    This is the genuine function whose consumed evaluations `demoWeilTest` records. -/
def bumpF : Q → Real := fun q =>
  if hd : 0 < q.den then
    if Qle q ⟨1, 1⟩ then zero
    else if Qle q ⟨2, 1⟩ then
      ofQ (Qsub q ⟨1, 1⟩) (Qsub_den_pos hd (by decide))
    else if Qle q ⟨3, 1⟩ then
      ofQ (Qsub ⟨3, 1⟩ q) (Qsub_den_pos (by decide) hd)
    else zero
  else zero

/-- Vanishing above the support: `bumpF(n) ≈ 0` for `n > 3`. -/
theorem bumpF_supp_high : ∀ n : Nat, 3 < n → Req (bumpF ⟨(n : Int), 1⟩) zero := by
  intro n hn
  have h1 : ¬ Qle (⟨(n : Int), 1⟩ : Q) ⟨1, 1⟩ := by
    intro h; simp only [Qle] at h; push_cast at h; omega
  have h2 : ¬ Qle (⟨(n : Int), 1⟩ : Q) ⟨2, 1⟩ := by
    intro h; simp only [Qle] at h; push_cast at h; omega
  have h3 : ¬ Qle (⟨(n : Int), 1⟩ : Q) ⟨3, 1⟩ := by
    intro h; simp only [Qle] at h; push_cast at h; omega
  show Req (bumpF ⟨(n : Int), 1⟩) zero
  simp only [bumpF]
  rw [dif_pos (show 0 < (⟨(n : Int), 1⟩ : Q).den from Nat.one_pos),
    if_neg h1, if_neg h2, if_neg h3]
  exact Req_refl zero

/-- Vanishing below the support: `bumpF(1/n) ≈ 0` for `n > 3` (indeed for every `n ≥ 1`). -/
theorem bumpF_supp_low : ∀ n : Nat, 3 < n → Req (bumpF ⟨1, n⟩) zero := by
  intro n hn
  have h1 : Qle (⟨1, n⟩ : Q) ⟨1, 1⟩ := by
    show (1 : Int) * ((1 : Nat) : Int) ≤ (1 : Int) * ((n : Nat) : Int)
    omega
  show Req (bumpF ⟨1, n⟩) zero
  simp only [bumpF]
  rw [dif_pos (show 0 < (⟨1, n⟩ : Q).den from (show 0 < n by omega)), if_pos h1]
  exact Req_refl zero

/-- **The bump as a Weil test datum** (`X = 3` — the support meets the primes `2` and `3`). -/
def bumpTest : WeilTest where
  f := bumpF
  X := 3
  hX := by decide
  supp_high := bumpF_supp_high
  supp_low := bumpF_supp_low

-- ===========================================================================
-- The finite-place side is NONZERO: the prime 2 enters through the peak.
-- ===========================================================================

/-- `bumpF(1) ≈ 0` (the left knot — this kills the archimedean constant AND the
    improper tail). -/
theorem bumpF_one : Req (bumpF ⟨1, 1⟩) zero := Req_refl _

/-- `bumpF(1/2) ≈ 0` (below the support). -/
theorem bumpF_half : Req (bumpF ⟨1, 2⟩) zero := Req_refl _

/-- `bumpF(1/3) ≈ 0` (below the support). -/
theorem bumpF_third : Req (bumpF ⟨1, 3⟩) zero := Req_refl _

/-- `bumpF(2) ≈ 1` (the peak sits AT the prime `2`). -/
theorem bumpF_two : Req (bumpF ⟨(2 : Int), 1⟩) one :=
  Req_of_seq_Qeq (fun _ => by
    show Qeq (Qsub ⟨2, 1⟩ ⟨1, 1⟩) (⟨1, 1⟩ : Q)
    decide)

/-- `bumpF(3) ≈ 0` (the right knot sits at the prime-3 evaluation point). -/
theorem bumpF_three : Req (bumpF ⟨(3 : Int), 1⟩) zero :=
  Req_of_seq_Qeq (fun _ => by
    show Qeq (Qsub ⟨3, 1⟩ ⟨3, 1⟩) (⟨0, 1⟩ : Q)
    decide)

/-- **THE FINITE-PLACE SIDE IS NONZERO**: `weilPrimePart(bump) ≈ log 2` — the first
    realized test whose support meets the primes; the prime `2` enters the assembled
    functional with its von Mangoldt weight through the peak evaluation `f(2) = 1`
    (the `Λ(3)`-term dies on the right knot). -/
theorem bumpPrimePart_eq : Req (weilPrimePart bumpTest) (logN 2 (by omega)) := by
  show Req (Radd (Radd (Radd zero (weilPrimeTerm bumpTest 0))
    (weilPrimeTerm bumpTest 1)) (weilPrimeTerm bumpTest 2)) (logN 2 (by omega))
  have h0 : Req (weilPrimeTerm bumpTest 0) zero := by
    refine Req_trans (Rmul_congr vonMangoldt_one (Req_refl _)) ?_
    exact Req_trans (Rmul_comm zero _) (Rmul_zero _)
  have h1 : Req (weilPrimeTerm bumpTest 1) (logN 2 (by omega)) := by
    refine Req_trans (Rmul_congr vonMangoldt_two
      (Req_trans (Radd_congr bumpF_two
        (Req_trans (Rmul_congr (Req_refl _) bumpF_half) (Rmul_zero _)))
        (Radd_zero one))) ?_
    exact Rmul_one (logN 2 (by omega))
  have h2 : Req (weilPrimeTerm bumpTest 2) zero := by
    refine Req_trans (Rmul_congr (Req_refl (vonMangoldt 3))
      (Req_trans (Radd_congr bumpF_three
        (Req_trans (Rmul_congr (Req_refl _) bumpF_third) (Rmul_zero _)))
        (Radd_zero zero))) ?_
    exact Rmul_zero (vonMangoldt 3)
  refine Req_trans (Radd_congr (Radd_congr (Radd_congr (Req_refl zero) h0) h1) h2) ?_
  refine Req_trans (Radd_zero _) ?_
  refine Req_trans (Radd_congr (Radd_zero zero) (Req_refl _)) ?_
  exact Req_trans (Radd_comm zero _) (Radd_zero _)

/-- **The archimedean constant vanishes**: `weilArchConst(bump) ≈ 0` (`f(1) = 0`). -/
theorem bumpArchConst_eq : Req (weilArchConst bumpTest) zero := by
  show Req (Rmul (Radd Rlog4pic Rgamma_h) (bumpF ⟨1, 1⟩)) zero
  exact Req_trans (Rmul_congr (Req_refl _) bumpF_one) (Rmul_zero _)

-- ===========================================================================
-- THE REALIZED SLOT AND ITS VALUE.
-- ===========================================================================

/-- **THE FIRST REALIZED `WeilSlot` WITH A LIVE PRIME SIDE**: every interface field a
    kernel-evaluated constructed integral — poles `= bumpPoleA + bumpPoleB`
    (`≈ 1 + (3·log 3 − 4·log 2)`), archimedean tail `= bumpArchTail`
    (`≈ 6·log 2 − 3·log 3`, compact — `f(1) = 0` kills the improper remainder). -/
def bumpSlot : WeilSlot where
  test := bumpTest
  poles := Radd bumpPoleA bumpPoleB
  archTail := bumpArchTail

/-- **THE BUMP'S WEIL FUNCTIONAL VALUE, IN CLOSED FORM**: with every constituent a
    certified constant,
    `W(bump) ≈ (1 + ((1 − log 2) + (3·(log 3 − log 2) − 1)))`
             `− (log 2 + ((1 − (log 3 − log 2)) + ((−1 + log 2) + 2·(log 4 − log 3))))`
    `= 1 + 6·log 3 − 11·log 2 ≈ −0.0329` (using `log 4 = 2·log 2`). -/
theorem bumpWeilValue_eq :
    Req (weilValue bumpSlot)
      (Rsub
        (Radd (ofQ (⟨1, 1⟩ : Q) (by decide))
          (Radd (Rsub one (logN 2 (by omega)))
            (Rsub (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide))
              (Rsub (logN 3 (by omega)) (logN 2 (by omega)))) one)))
        (Radd (logN 2 (by omega))
          (Radd (Rsub one (Rsub (logN 3 (by omega)) (logN 2 (by omega))))
            (Radd (Radd (Rneg one) (logN 2 (by omega)))
              (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
                (Rsub (logN 4 (by omega)) (logN 3 (by omega)))))))) := by
  show Req (Rsub (Radd bumpPoleA bumpPoleB)
    (Radd (weilPrimePart bumpTest) (Radd (weilArchConst bumpTest) bumpArchTail))) _
  refine Rsub_congr (Radd_congr bumpPoleA_eq bumpPoleB_eq) ?_
  refine Radd_congr bumpPrimePart_eq ?_
  refine Req_trans (Radd_congr bumpArchConst_eq bumpArchTail_eq) ?_
  exact Req_trans (Radd_comm zero _) (Radd_zero _)

end UOR.Bridge.F1Square.Square

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- THE CERTIFIED SIGN: W(bump) < 0.
-- The rational brackets come from the harmonic wedges at M = 128 (log 2, the
-- base-2 wedge for log 3 − log 2, and the base-3 wedge for log 4 − log 3); the
-- single closing `decide` does the exact bignum arithmetic on the folds.
-- Worst-case wedge error 3/(2M) + 4/(6M) + 2/(12M) = 7/(2·128) ≈ 0.0273 against
-- the margin 0.0329, so M = 128 certifies unconditionally.
-- ===========================================================================

/-- `ofQ a − ofQ b ≈ ofQ (a − b)`. -/
private theorem bmp_ofQ_sub {a b : Q} (ha : 0 < a.den) (hb : 0 < b.den) :
    Req (Rsub (ofQ a ha) (ofQ b hb)) (ofQ (Qsub a b) (Qsub_den_pos ha hb)) :=
  Req_trans (Radd_congr (Req_refl _) (Rneg_ofQ b hb))
    (Radd_ofQ_ofQ (a := a) (b := neg b) ha hb)

/-- The `M = 128` rational lower bound for `log 2`: `hFold 128 128 − 1/256`. -/
def bmpL2q : Q := Qsub (hFold 128 128) ⟨1, 2 * 128⟩

theorem bmpL2q_den : 0 < bmpL2q.den :=
  Qsub_den_pos (hFold_den_pos 128 (by decide) 128) (by decide)

/-- The `M = 128` rational upper bound for `log 3 − log 2`: `hFold 256 128`. -/
def bmpU32q : Q := hFold (2 * 128) 128

theorem bmpU32q_den : 0 < bmpU32q.den := hFold_den_pos (2 * 128) (by decide) 128

/-- The `M = 128` rational lower bound for `log 4 − log 3`:
    `hFold 384 128 − 1/(3·4·128)`. -/
def bmpL43q : Q := Qsub (hFold (3 * 128) 128) ⟨1, 3 * (3 + 1) * 128⟩

theorem bmpL43q_den : 0 < bmpL43q.den :=
  Qsub_den_pos (hFold_den_pos (3 * 128) (by decide) 128) (by decide)

/-- **`log 2 ≥ hFold 128 128 − 1/256`** — the wedge's rational lower bound, realized. -/
theorem bmp_L2 : Rle (ofQ bmpL2q bmpL2q_den) (logN 2 (by omega)) := by
  refine Rle_trans (Rle_of_Req (Req_symm
    (bmp_ofQ_sub (hFold_den_pos 128 (by decide) 128) (by decide)))) ?_
  refine Rsub_le_of_le_Radd ?_
  exact Rle_trans (hFold_le_log2_add 128 (by decide)) (Rle_of_Req (Radd_comm _ _))

/-- **`log 3 − log 2 ≤ hFold 256 128`** — the base-2 wedge's rational upper bound. -/
theorem bmp_U32 : Rle (Rsub (logN 3 (by omega)) (logN 2 (by omega)))
    (ofQ bmpU32q bmpU32q_den) :=
  log32_le_hFold 128 (by decide)

/-- **`log 4 − log 3 ≥ hFold 384 128 − 1/1536`** — the base-3 wedge's rational lower
    bound (`hFoldC_le` at `c = 3`). -/
theorem bmp_L43 : Rle (ofQ bmpL43q bmpL43q_den)
    (Rsub (logN 4 (by omega)) (logN 3 (by omega))) := by
  refine Rle_trans (Rle_of_Req (Req_symm
    (bmp_ofQ_sub (hFold_den_pos (3 * 128) (by decide) 128) (by decide)))) ?_
  refine Rsub_le_of_le_Radd ?_
  exact Rle_trans (hFoldC_le 3 128 (by decide) (by decide)) (Rle_of_Req (Radd_comm _ _))

/-- The assembled rational upper bound for the pole side. -/
def bmpPUq : Q := add ⟨1, 1⟩ (add (Qsub ⟨1, 1⟩ bmpL2q) (Qsub (mul ⟨3, 1⟩ bmpU32q) ⟨1, 1⟩))

theorem bmpPUq_den : 0 < bmpPUq.den :=
  add_den_pos (by decide) (add_den_pos (Qsub_den_pos (by decide) bmpL2q_den)
    (Qsub_den_pos (Qmul_den_pos (by decide) bmpU32q_den) (by decide)))

/-- The assembled rational lower bound for the subtracted (prime + archimedean) side. -/
def bmpSLq : Q := add bmpL2q (add (Qsub ⟨1, 1⟩ bmpU32q)
  (add (add ⟨-1, 1⟩ bmpL2q) (mul ⟨2, 1⟩ bmpL43q)))

theorem bmpSLq_den : 0 < bmpSLq.den :=
  add_den_pos bmpL2q_den (add_den_pos (Qsub_den_pos (by decide) bmpU32q_den)
    (add_den_pos (add_den_pos (by decide) bmpL2q_den)
      (Qmul_den_pos (by decide) bmpL43q_den)))

/-- The pole-side upper bound: `poles-value ≤ bmpPUq`. -/
theorem bump_P_le : Rle
    (Radd (ofQ (⟨1, 1⟩ : Q) (by decide))
      (Radd (Rsub one (logN 2 (by omega)))
        (Rsub (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide))
          (Rsub (logN 3 (by omega)) (logN 2 (by omega)))) one)))
    (ofQ bmpPUq bmpPUq_den) := by
  have h1 : Rle (Rsub one (logN 2 (by omega)))
      (ofQ (Qsub ⟨1, 1⟩ bmpL2q) (Qsub_den_pos (by decide) bmpL2q_den)) := by
    refine Rle_trans (Radd_le_add (Rle_refl one) (Rneg_le bmp_L2)) ?_
    exact Rle_of_Req (bmp_ofQ_sub (by decide) bmpL2q_den)
  have h2 : Rle (Rsub (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide))
        (Rsub (logN 3 (by omega)) (logN 2 (by omega)))) one)
      (ofQ (Qsub (mul ⟨3, 1⟩ bmpU32q) ⟨1, 1⟩)
        (Qsub_den_pos (Qmul_den_pos (by decide) bmpU32q_den) (by decide))) := by
    refine Rle_trans (Radd_le_add
      (Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) bmp_U32)
        (Rle_of_Req (Rmul_ofQ_ofQ (by decide) bmpU32q_den)))
      (Rle_refl (Rneg one))) ?_
    exact Rle_of_Req (bmp_ofQ_sub (Qmul_den_pos (by decide) bmpU32q_den) (by decide))
  refine Rle_trans (Radd_le_add (Rle_refl (ofQ (⟨1, 1⟩ : Q) (by decide)))
    (Rle_trans (Radd_le_add h1 h2)
      (Rle_of_Req (Radd_ofQ_ofQ (Qsub_den_pos (by decide) bmpL2q_den)
        (Qsub_den_pos (Qmul_den_pos (by decide) bmpU32q_den) (by decide)))))) ?_
  exact Rle_of_Req (Radd_ofQ_ofQ (by decide)
    (add_den_pos (Qsub_den_pos (by decide) bmpL2q_den)
      (Qsub_den_pos (Qmul_den_pos (by decide) bmpU32q_den) (by decide))))

/-- The subtracted-side lower bound: `bmpSLq ≤ (primes + tail)-value`. -/
theorem bump_S_ge : Rle (ofQ bmpSLq bmpSLq_den)
    (Radd (logN 2 (by omega))
      (Radd (Rsub one (Rsub (logN 3 (by omega)) (logN 2 (by omega))))
        (Radd (Radd (Rneg one) (logN 2 (by omega)))
          (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
            (Rsub (logN 4 (by omega)) (logN 3 (by omega))))))) := by
  have t1 : Rle (ofQ (Qsub ⟨1, 1⟩ bmpU32q) (Qsub_den_pos (by decide) bmpU32q_den))
      (Rsub one (Rsub (logN 3 (by omega)) (logN 2 (by omega)))) := by
    refine Rle_trans (Rle_of_Req (Req_symm (bmp_ofQ_sub (by decide) bmpU32q_den))) ?_
    exact Radd_le_add (Rle_refl one) (Rneg_le bmp_U32)
  have t2 : Rle (ofQ (add ⟨-1, 1⟩ bmpL2q) (add_den_pos (by decide) bmpL2q_den))
      (Radd (Rneg one) (logN 2 (by omega))) := by
    refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ (a := (⟨-1, 1⟩ : Q))
      (b := bmpL2q) (by decide) bmpL2q_den))) ?_
    exact Radd_le_add (Rle_of_Req (Req_symm (Rneg_ofQ (⟨1, 1⟩ : Q) (by decide)))) bmp_L2
  have t3 : Rle (ofQ (mul ⟨2, 1⟩ bmpL43q) (Qmul_den_pos (by decide) bmpL43q_den))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
        (Rsub (logN 4 (by omega)) (logN 3 (by omega)))) := by
    refine Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) bmpL43q_den))) ?_
    exact Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) bmp_L43
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ bmpL2q_den
    (add_den_pos (Qsub_den_pos (by decide) bmpU32q_den)
      (add_den_pos (add_den_pos (by decide) bmpL2q_den)
        (Qmul_den_pos (by decide) bmpL43q_den)))))) ?_
  refine Radd_le_add bmp_L2 ?_
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ
    (Qsub_den_pos (by decide) bmpU32q_den)
    (add_den_pos (add_den_pos (by decide) bmpL2q_den)
      (Qmul_den_pos (by decide) bmpL43q_den))))) ?_
  refine Radd_le_add t1 ?_
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ
    (add_den_pos (by decide) bmpL2q_den)
    (Qmul_den_pos (by decide) bmpL43q_den)))) ?_
  exact Radd_le_add t2 t3

set_option maxRecDepth 100000 in
/-- **THE FIRST CERTIFIED NEGATIVE WEIL VALUE**: `W(bump) < 0` — the Weil functional of a
    genuine, fully constructed, Bombieri-admissible test with a LIVE prime side is strictly
    negative (margin `≈ 0.024` at the `M = 128` folds; the closing `decide` performs the
    exact bignum arithmetic). Kernel-checked proof that Weil positivity is NOT a pointwise
    feature of the admissible test class: it lives on the autocorrelation cone `g ⋆ g^τ`
    (this test is not one — `f(1) = 0`), exactly the coupling structure the Sonine route's
    steps 3–4 build toward. Consistent with RH; no crux claim. -/
theorem bumpWeilValue_neg : Pos (Rneg (weilValue bumpSlot)) := by
  refine Pos_of_Rle_ofQ (c := Qsub bmpSLq bmpPUq)
    (by decide) (Qsub_den_pos bmpSLq_den bmpPUq_den) ?_
  refine Rle_trans ?_ (Rle_of_Req (Req_symm
    (Req_trans (Rneg_congr bumpWeilValue_eq) (Rneg_Rsub _ _))))
  refine Rle_trans (Rle_of_Req (Req_symm (bmp_ofQ_sub bmpSLq_den bmpPUq_den))) ?_
  exact Radd_le_add bump_S_ge (Rneg_le bump_P_le)

end UOR.Bridge.F1Square.Square
