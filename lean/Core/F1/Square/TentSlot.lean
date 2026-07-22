/-
F1 square — **THE FIRST REALIZED WEIL SLOT** (`TentSlot.lean`): the tent test's `WeilSlot`
with every interface field CONSTRUCTED AND KERNEL-EVALUATED, and its Weil functional value
in closed form:

    `W(tent) ≈ (3/4 + log 2) − ((log 4π + γ) + (−1 − 6·log 2 + 3·log 3))`
             `= 7/4 + 7·log 2 − 3·log 3 − log 4π − γ`      (`tentWeilValue_eq`)

— the Sonine route's step-2 boundary crossed for one genuine test function: `Pairing.lean`'s
`WeilSlot` interface (poles and archimedean tail as data) is INHABITED by evaluated integrals
(`tentPoleA_eq` + `tentPoleB_eq` + `tentArchTail_eq`), the finite-place side vanishes
(`tentPrimePart_eq` — the prime-free window realized: the tent's knots `1/2, 2` sit exactly
at the prime-2 evaluation points), and `weilValue` reduces to a closed constant in
`{1, log 2, log 3, log 4π, γ}`.

The test datum: the piecewise-linear tent with knots `1/2, 1, 2` (Bombieri-admissible), as
rational-point evaluations `tentF : Q → Real` with support cutoff `X = 2`.

HONEST SCOPE. This realizes the slot for ONE test; it is step 2 substrate. No positivity for
the pairing FAMILY is claimed; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Square.Pairing
import Core.F1.Analysis.TentLogPiece
import Core.F1.Analysis.TentArchTail
import Core.F1.Analysis.LambdaThreePos
import Core.F1.Analysis.GammaZeroBracket

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The tent test datum.
-- ===========================================================================

/-- **The tent test function** (knots `1/2, 1, 2`), as rational-point evaluations:
    `2q − 1` on `(1/2, 1]`, `2 − q` on `(1, 2]`, `0` outside (and on junk denominators). -/
def tentF : Q → Real := fun q =>
  if hd : 0 < q.den then
    if Qle q ⟨1, 2⟩ then zero
    else if Qle q ⟨1, 1⟩ then
      ofQ (Qsub (mul ⟨2, 1⟩ q) ⟨1, 1⟩)
        (Qsub_den_pos (Qmul_den_pos (by decide) hd) (by decide))
    else if Qle q ⟨2, 1⟩ then
      ofQ (Qsub ⟨2, 1⟩ q) (Qsub_den_pos (by decide) hd)
    else zero
  else zero

/-- Vanishing above the support: `tentF(n) ≈ 0` for `n > 2`. -/
theorem tentF_supp_high : ∀ n : Nat, 2 < n → Req (tentF ⟨(n : Int), 1⟩) zero := by
  intro n hn
  have h1 : ¬ Qle (⟨(n : Int), 1⟩ : Q) ⟨1, 2⟩ := by
    intro h; simp only [Qle] at h; push_cast at h; omega
  have h2 : ¬ Qle (⟨(n : Int), 1⟩ : Q) ⟨1, 1⟩ := by
    intro h; simp only [Qle] at h; push_cast at h; omega
  have h3 : ¬ Qle (⟨(n : Int), 1⟩ : Q) ⟨2, 1⟩ := by
    intro h; simp only [Qle] at h; push_cast at h; omega
  show Req (tentF ⟨(n : Int), 1⟩) zero
  simp only [tentF]
  rw [dif_pos (show 0 < (⟨(n : Int), 1⟩ : Q).den from Nat.one_pos),
    if_neg h1, if_neg h2, if_neg h3]
  exact Req_refl zero

/-- Vanishing below the support: `tentF(1/n) ≈ 0` for `n > 2`. -/
theorem tentF_supp_low : ∀ n : Nat, 2 < n → Req (tentF ⟨1, n⟩) zero := by
  intro n hn
  have h1 : Qle (⟨1, n⟩ : Q) ⟨1, 2⟩ := by
    show (1 : Int) * ((2 : Nat) : Int) ≤ (1 : Int) * ((n : Nat) : Int)
    omega
  show Req (tentF ⟨1, n⟩) zero
  simp only [tentF]
  rw [dif_pos (show 0 < (⟨1, n⟩ : Q).den from (show 0 < n by omega)), if_pos h1]
  exact Req_refl zero

/-- **The tent as a Weil test datum** (`X = 2`). -/
def tentTest : WeilTest where
  f := tentF
  X := 2
  hX := by decide
  supp_high := tentF_supp_high
  supp_low := tentF_supp_low

-- ===========================================================================
-- The finite-place side vanishes: the prime-free window realized.
-- ===========================================================================

/-- `tentF(2) ≈ 0` (the right knot sits at the prime-2 evaluation point). -/
theorem tentF_two : Req (tentF ⟨(2 : Int), 1⟩) zero :=
  Req_of_seq_Qeq (fun _ => by
    show Qeq (Qsub ⟨2, 1⟩ ⟨2, 1⟩) (⟨0, 1⟩ : Q)
    decide)

/-- `tentF(1/2) ≈ 0` (the left knot). -/
theorem tentF_half : Req (tentF ⟨1, 2⟩) zero := Req_refl _

/-- `tentF(1) ≈ 1` (the peak). -/
theorem tentF_one : Req (tentF ⟨1, 1⟩) one :=
  Req_of_seq_Qeq (fun _ => by
    show Qeq (Qsub (mul ⟨2, 1⟩ ⟨1, 1⟩) ⟨1, 1⟩) (⟨1, 1⟩ : Q)
    decide)

/-- **The finite-place side vanishes**: `weilPrimePart(tent) ≈ 0` — the `X = 2` prime-free
    window realized by a genuine test function (`Λ(1) = 0`; the `Λ(2)`-term multiplies the
    vanishing knot evaluations `f(2)` and `f(1/2)`). -/
theorem tentPrimePart_eq : Req (weilPrimePart tentTest) zero := by
  show Req (Radd (Radd zero (weilPrimeTerm tentTest 0)) (weilPrimeTerm tentTest 1)) zero
  have t0 : Req (weilPrimeTerm tentTest 0) zero := by
    refine Req_trans (Rmul_congr vonMangoldt_one (Req_refl _)) ?_
    exact Req_trans (Rmul_comm zero _) (Rmul_zero _)
  have t1 : Req (weilPrimeTerm tentTest 1) zero := by
    refine Req_trans (Rmul_congr (Req_refl (vonMangoldt 2))
      (Req_trans (Radd_congr tentF_two
        (Req_trans (Rmul_congr (Req_refl _) tentF_half) (Rmul_zero _)))
        (Radd_zero zero))) ?_
    exact Rmul_zero (vonMangoldt 2)
  refine Req_trans (Radd_congr
    (Req_trans (Radd_congr (Req_refl zero) t0) (Radd_zero zero)) t1) ?_
  exact Radd_zero zero

/-- **The archimedean constant collapses**: `weilArchConst(tent) ≈ log 4π + γ` (`f(1) = 1`). -/
theorem tentArchConst_eq : Req (weilArchConst tentTest) (Radd Rlog4pic Rgamma_h) := by
  show Req (Rmul (Radd Rlog4pic Rgamma_h) (tentF ⟨1, 1⟩)) _
  exact Req_trans (Rmul_congr (Req_refl _) tentF_one) (Rmul_one _)

-- ===========================================================================
-- THE REALIZED SLOT AND ITS VALUE.
-- ===========================================================================

/-- **THE FIRST REALIZED `WeilSlot`**: the tent test with every interface field a
    kernel-evaluated constructed integral — poles `= tentPoleA + tentPoleB`
    (`≈ 3/4 + log 2`), archimedean tail `= tentArchTail` (`≈ −1 − 6·log 2 + 3·log 3`). -/
def tentSlot : WeilSlot where
  test := tentTest
  poles := Radd tentPoleA tentPoleB
  archTail := tentArchTail

/-- **THE TENT'S WEIL FUNCTIONAL VALUE, IN CLOSED FORM**:
    `W(tent) ≈ (3/4 + log 2) − ((log 4π + γ) + ((−(1 + 2·log 2 − 4·(log 3 − log 2))) − log 3))`
    — every constituent a certified constant; numerically `≈ +0.198`. -/
theorem tentWeilValue_eq :
    Req (weilValue tentSlot)
      (Rsub (Radd (ofQ (⟨3, 4⟩ : Q) (by decide)) (logN 2 (by omega)))
        (Radd (Radd Rlog4pic Rgamma_h)
          (Rsub (Rneg (Radd one
            (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
              (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide))
                (Rsub (logN 3 (by omega)) (logN 2 (by omega)))))))
            (logN 3 (by omega))))) := by
  show Req (Rsub (Radd tentPoleA tentPoleB)
    (Radd (weilPrimePart tentTest) (Radd (weilArchConst tentTest) tentArchTail))) _
  refine Rsub_congr (Radd_congr tentPoleA_eq tentPoleB_eq) ?_
  refine Req_trans (Radd_congr tentPrimePart_eq
    (Radd_congr tentArchConst_eq tentArchTail_eq)) ?_
  exact Req_trans (Radd_comm zero _) (Radd_zero _)

end UOR.Bridge.F1Square.Square

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- THE FIRST REALIZED WINDOW-POSITIVITY INSTANCE: W(tent) > 0.
-- The rational brackets come from the harmonic wedges at M = 32 (the fold
-- values are exact rationals; the single closing `decide` does the bignum
-- arithmetic), log 4π and γ from the standing numeric brackets.
-- ===========================================================================

/-- `ofQ a − ofQ b ≈ ofQ (a − b)`. -/
private theorem ofQ_sub_collapse {a b : Q} (ha : 0 < a.den) (hb : 0 < b.den) :
    Req (Rsub (ofQ a ha) (ofQ b hb)) (ofQ (Qsub a b) (Qsub_den_pos ha hb)) :=
  Req_trans (Radd_congr (Req_refl _) (Rneg_ofQ b hb))
    (Radd_ofQ_ofQ (a := a) (b := neg b) ha hb)

/-- `neg` keeps the denominator (symbolic — no unfolding of the argument). -/
private theorem Qneg_den_pos {q : Q} (h : 0 < q.den) : 0 < (neg q).den := h

/-- The `M = 32` rational lower bound for `log 2`: `hFold 32 32 − 1/64`. -/
def tentL2q : Q := Qsub (hFold 32 32) ⟨1, 2 * 32⟩

theorem tentL2q_den : 0 < tentL2q.den :=
  Qsub_den_pos (hFold_den_pos 32 (by decide) 32) (by decide)

/-- The `M = 32` rational upper bound for `log 3 − log 2`: `hFold 64 32`. -/
def tentU32q : Q := hFold (2 * 32) 32

theorem tentU32q_den : 0 < tentU32q.den := hFold_den_pos (2 * 32) (by decide) 32

/-- The `M = 32` rational lower bound for `log 3 − log 2`: `hFold 64 32 − 1/192`. -/
def tentL32q : Q := Qsub tentU32q ⟨1, 6 * 32⟩

theorem tentL32q_den : 0 < tentL32q.den := Qsub_den_pos tentU32q_den (by decide)

/-- **`log 2 ≥ hFold 32 32 − 1/64`** — the wedge's rational lower bound, realized. -/
theorem tent_L2 : Rle (ofQ tentL2q tentL2q_den) (logN 2 (by omega)) := by
  refine Rle_trans (Rle_of_Req (Req_symm
    (ofQ_sub_collapse (hFold_den_pos 32 (by decide) 32) (by decide)))) ?_
  refine Rsub_le_of_le_Radd ?_
  exact Rle_trans (hFold_le_log2_add 32 (by decide)) (Rle_of_Req (Radd_comm _ _))

/-- **`log 3 − log 2 ≤ hFold 64 32`** — the wedge's rational upper bound. -/
theorem tent_U32 : Rle (Rsub (logN 3 (by omega)) (logN 2 (by omega)))
    (ofQ tentU32q tentU32q_den) :=
  log32_le_hFold 32 (by decide)

/-- **`log 3 − log 2 ≥ hFold 64 32 − 1/192`** — the wedge's rational lower bound. -/
theorem tent_L32 : Rle (ofQ tentL32q tentL32q_den)
    (Rsub (logN 3 (by omega)) (logN 2 (by omega))) := by
  refine Rle_trans (Rle_of_Req (Req_symm
    (ofQ_sub_collapse tentU32q_den (by decide)))) ?_
  refine Rsub_le_of_le_Radd ?_
  exact Rle_trans (hFold32_le 32 (by decide)) (Rle_of_Req (Radd_comm _ _))

/-- **`log 3 ≥ (log-2 lower) + (log 3/2 lower)`** — assembled through the cancellation
    `log 2 + (log 3 − log 2) ≈ log 3`. -/
theorem tent_L3 : Rle (ofQ (add tentL2q tentL32q) (add_den_pos tentL2q_den tentL32q_den))
    (logN 3 (by omega)) := by
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ tentL2q_den tentL32q_den))) ?_
  refine Rle_trans (Radd_le_add tent_L2 tent_L32) ?_
  exact Rle_of_Req (Radd_Rsub_cancel (logN 3 (by omega)) (logN 2 (by omega)))

/-- The assembled rational bounds for the value chain. -/
def tentSLq : Q := Qsub (mul ⟨2, 1⟩ tentL2q) (mul ⟨4, 1⟩ tentU32q)

theorem tentSLq_den : 0 < tentSLq.den :=
  Qsub_den_pos (Qmul_den_pos (by decide) tentL2q_den) (Qmul_den_pos (by decide) tentU32q_den)

def tentTUq : Q := add (neg (add ⟨1, 1⟩ tentSLq)) (neg (add tentL2q tentL32q))

theorem tentTUq_den : 0 < tentTUq.den :=
  add_den_pos
    (Qneg_den_pos (add_den_pos (by decide) tentSLq_den))
    (Qneg_den_pos (add_den_pos tentL2q_den tentL32q_den))

def tentBUq : Q := add (add ⟨25316, 10000⟩ ⟨578, 1000⟩) tentTUq

theorem tentBUq_den : 0 < tentBUq.den :=
  add_den_pos (add_den_pos (by decide) (by decide)) tentTUq_den

def tentPLq : Q := add ⟨3, 4⟩ tentL2q

theorem tentPLq_den : 0 < tentPLq.den := add_den_pos (by decide) tentL2q_den

/-- The subtracted-side upper bound: `(log 4π + γ) + tail-value ≤ tentBUq`. -/
theorem tent_B_le : Rle
    (Radd (Radd Rlog4pic Rgamma_h)
      (Rsub (Rneg (Radd one
        (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
          (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide))
            (Rsub (logN 3 (by omega)) (logN 2 (by omega)))))))
        (logN 3 (by omega))))
    (ofQ tentBUq tentBUq_den) := by
  have hSlo : Rle (ofQ tentSLq tentSLq_den)
      (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
        (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide))
          (Rsub (logN 3 (by omega)) (logN 2 (by omega))))) := by
    refine Rle_trans (Rle_of_Req (Req_symm (ofQ_sub_collapse
      (Qmul_den_pos (by decide) tentL2q_den)
      (Qmul_den_pos (by decide) tentU32q_den)))) ?_
    refine Radd_le_add ?_ (Rneg_le ?_)
    · refine Rle_trans (Rle_of_Req (Req_symm
        (Rmul_ofQ_ofQ (by decide) tentL2q_den))) ?_
      exact Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) tent_L2
    · refine Rle_trans (Rmul_le_Rmul_left
        (Rnonneg_ofQ (by decide) (by decide)) tent_U32) ?_
      exact Rle_of_Req (Rmul_ofQ_ofQ (by decide) tentU32q_den)
  have h1S : Rle (ofQ (add ⟨1, 1⟩ tentSLq) (add_den_pos (by decide) tentSLq_den))
      (Radd one (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
        (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide))
          (Rsub (logN 3 (by omega)) (logN 2 (by omega)))))) := by
    refine Rle_trans (Rle_of_Req (Req_symm
      (Radd_ofQ_ofQ (by decide) tentSLq_den))) ?_
    exact Radd_le_add (Rle_refl one) hSlo
  have hT : Rle
      (Rsub (Rneg (Radd one
        (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
          (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide))
            (Rsub (logN 3 (by omega)) (logN 2 (by omega)))))))
        (logN 3 (by omega)))
      (ofQ tentTUq tentTUq_den) := by
    refine Rle_trans (Radd_le_add
      (Rle_trans (Rneg_le h1S) (Rle_of_Req
        (Rneg_ofQ (add ⟨1, 1⟩ tentSLq) (add_den_pos (by decide) tentSLq_den))))
      (Rle_trans (Rneg_le tent_L3) (Rle_of_Req
        (Rneg_ofQ (add tentL2q tentL32q) (add_den_pos tentL2q_den tentL32q_den))))) ?_
    exact Rle_of_Req (Radd_ofQ_ofQ
      (a := neg (add ⟨1, 1⟩ tentSLq)) (b := neg (add tentL2q tentL32q))
      (Qneg_den_pos (add_den_pos (by decide) tentSLq_den))
      (Qneg_den_pos (add_den_pos tentL2q_den tentL32q_den)))
  refine Rle_trans (Radd_le_add
    (Rle_trans (Radd_le_add Rlog4pic_le Rgamma_h_le_578)
      (Rle_of_Req (Radd_ofQ_ofQ (a := (⟨25316, 10000⟩ : Q)) (b := (⟨578, 1000⟩ : Q))
        (by decide) (by decide)))) hT) ?_
  exact Rle_of_Req (Radd_ofQ_ofQ (a := add ⟨25316, 10000⟩ ⟨578, 1000⟩) (b := tentTUq)
    (add_den_pos (by decide) (by decide)) tentTUq_den)

/-- The pole-side lower bound: `3/4 + log 2 ≥ tentPLq`. -/
theorem tent_P_ge : Rle (ofQ tentPLq tentPLq_den)
    (Radd (ofQ (⟨3, 4⟩ : Q) (by decide)) (logN 2 (by omega))) := by
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ (by decide) tentL2q_den))) ?_
  exact Radd_le_add (Rle_refl (ofQ (⟨3, 4⟩ : Q) (by decide))) tent_L2

set_option maxRecDepth 100000 in
/-- **THE FIRST REALIZED WINDOW-POSITIVITY INSTANCE**: `W(tent) > 0` — the Weil functional
    of a genuine, fully constructed test is strictly positive, certified through the
    kernel-evaluated slot fields and the harmonic-wedge rational brackets (margin `≈ 0.15`;
    the closing `decide` performs the exact bignum arithmetic on the `M = 32` folds). -/
theorem tentWeilValue_pos : Pos (weilValue tentSlot) := by
  refine Pos_of_Rle_ofQ (c := Qsub tentPLq tentBUq)
    (by decide) (Qsub_den_pos tentPLq_den tentBUq_den) ?_
  refine Rle_trans ?_ (Rle_of_Req (Req_symm tentWeilValue_eq))
  refine Rle_trans (Rle_of_Req (Req_symm (ofQ_sub_collapse tentPLq_den tentBUq_den))) ?_
  exact Radd_le_add tent_P_ge (Rneg_le tent_B_le)

end UOR.Bridge.F1Square.Square
