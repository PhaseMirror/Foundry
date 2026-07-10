/-
F1 square — v0.22.0 crux frontier: **tightening the Euler–Mascheroni constant `γ`** toward the
`[0.577, 0.578]` bracket the `Pos Rlambda3` (`λ₃`) certificate needs (the dominant constant blocker —
the loose `γ ∈ [0.54, 0.66]` alone keeps `λ₃`'s certified lower bound negative via `−3γ²`).

`γ = Σ_{n≥0} cApprox n ∞`, `cApprox n ∞ = 1/(n+1) − 2·artanh(1/(2n+3))` (the accelerated γ-series term,
`GammaAccel.lean`). The per-term tight rational bracket reuses `GammaOne`'s artanh tail machinery at
`p = n+1` (the term's artanh argument `1/(2n+3) = 1/(2(n+1)+1)`):

  • **lower** `cApprox n T' ≥ cLowQ T n := 1/(n+1) − dPlusQ T (n+1)`  (`dPlusQ` over-estimates `2·artanh`,
    so this under-estimates the term — uniformly in the evaluation depth `T'`, since `artSum` at any
    depth is `≤ artanh ≤ dPlusQ`).

THIS FILE — part (A): the per-term lower bound `cApprox_ge_cLowQ`. The rounded accumulator over `K`
terms, the uniform tail correction `Σ_{n≥K} cApprox n ∞ ≥ 1/(2(K+1))`, and the `Rgamma_h` assembly
follow (mirroring the `GammaOneBracket`/`lnSumLo` pattern).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.GammaAccel
import F1Square.Analysis.GammaOne
import F1Square.Analysis.GammaUpper

namespace UOR.Bridge.F1Square.Analysis

/-- The **per-term rational lower bound** for the accelerated γ-series term: `1/(n+1) − dPlusQ T (n+1)`
    (`dPlusQ T (n+1)` over-estimates `2·artanh(1/(2n+3))`). -/
def cLowQ (T n : Nat) : Q := Qsub (⟨1, n + 1⟩ : Q) (dPlusQ T (n + 1))

theorem cLowQ_den_pos (T n : Nat) : 0 < (cLowQ T n).den :=
  Qsub_den_pos (Nat.succ_pos n) (dPlusQ_den_pos T (n + 1) (Nat.succ_pos n))

/-- **`cLowQ T n ≤ cApprox n T'`** for every evaluation depth `T'` — the term `cApprox n T'`
    (`= 1/(n+1) − 2·artSum(1/(2n+3), T')`) under-estimated by `cLowQ`, since
    `2·artSum(…, T') ≤ 2·artSum(…, T) + 2·tail = dPlusQ T (n+1)` (`artSum_le_value` + `deltaTail_eq`). -/
theorem cApprox_ge_cLowQ (T n T' : Nat) : Qle (cLowQ T n) (cApprox n T') := by
  -- `2n+3 = 2(n+1)+1` (so `cApprox`'s artanh argument matches `dPlusQ (n+1)`'s)
  have harg : 2 * n + 3 = 2 * (n + 1) + 1 := by omega
  unfold cLowQ cApprox dPlusQ
  rw [harg]
  refine Qadd_le_add (Qle_refl _) (Qneg_le_neg (Qmul_le_mul_left (by decide) ?_))
  -- artSum(1/(2(n+1)+1), T') ≤ artSum(1/(2(n+1)+1), T) + tail
  have htaild : 0 < (⟨1, npow (2 * (n + 1) + 1) (2 * T + 1) * (4 * (n + 1) * ((n + 1) + 1))⟩ : Q).den :=
    Nat.mul_pos (npow_pos (Nat.succ_pos _) _)
      (Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos n)) (Nat.succ_pos (n + 1)))
  have hWn : 0 < (Qsub (⟨1, 1⟩ : Q) (mul (⟨1, 2 * (n + 1) + 1⟩ : Q) ⟨1, 2 * (n + 1) + 1⟩)).num := by
    show 0 < (add (⟨1, 1⟩ : Q) (neg (mul ⟨1, 2 * (n + 1) + 1⟩ ⟨1, 2 * (n + 1) + 1⟩))).num
    simp only [add, neg, mul]
    have h9 : ((9 : Nat) : Int)
        ≤ (((2 * (n + 1) + 1) * (2 * (n + 1) + 1) : Nat) : Int) := by
      exact_mod_cast Nat.mul_le_mul (show 3 ≤ 2 * (n + 1) + 1 by omega) (show 3 ≤ 2 * (n + 1) + 1 by omega)
    push_cast at h9 ⊢; omega
  exact artSum_le_value (by show (0 : Int) ≤ 1; decide) (Nat.succ_pos _) htaild hWn T
    (deltaTail_eq (n + 1) T) T'

-- ===========================================================================
-- (B) The rounded accumulator and the partial-sum lower bound `gammaLoBound ≤ Ssum cLowQ ≤ gammaHseq`.
-- ===========================================================================

/-- The **rounded lower-bound accumulator** for `Σ_{n<K} cLowQ T n`, at fixed denominator `D`
    (round down each step, keeping the denominator bounded for a feasible final `decide`). -/
def gammaLoBound (T D : Nat) : Nat → Q
  | 0 => ⟨0, D⟩
  | (K + 1) => qRoundDown (add (gammaLoBound T D K) (cLowQ T K)) D

theorem gammaLoBound_den_pos (T D : Nat) (hD : 0 < D) : ∀ K, 0 < (gammaLoBound T D K).den
  | 0 => hD
  | (_ + 1) => hD

/-- **`gammaLoBound T D K ≤ Σ_{n<K} cLowQ T n`** — the round-down accumulator stays below the exact
    partial sum (`qRoundDown_le` at each step). -/
theorem gammaLoBound_le_Ssum (T D : Nat) (hD : 0 < D) :
    ∀ K, Qle (gammaLoBound T D K) (Ssum (cLowQ T) K)
  | 0 => by
      show Qle (⟨0, D⟩ : Q) (⟨0, 1⟩ : Q); simp only [Qle]; omega
  | (K + 1) => by
      have hadd : 0 < (add (gammaLoBound T D K) (cLowQ T K)).den :=
        add_den_pos (gammaLoBound_den_pos T D hD K) (cLowQ_den_pos T K)
      refine Qle_trans hadd
        (qRoundDown_le (add (gammaLoBound T D K) (cLowQ T K)) hadd D) ?_
      show Qle (add (gammaLoBound T D K) (cLowQ T K)) (add (Ssum (cLowQ T) K) (cLowQ T K))
      exact Qadd_le_add (gammaLoBound_le_Ssum T D hD K) (Qle_refl _)

/-- **`Σ_{n<K} cLowQ T n ≤ gammaHseq j`** for `K ≤ 2(j+1)` — the partial sum of per-term lower bounds
    is dominated by the (longer, deeper) accelerated approximant `gammaHseq j` (`Ssum_le_of_le` with
    `cApprox_ge_cLowQ`, then `Ssum_le` to extend the upper limit; `cApprox` terms are `≥ 0`). -/
theorem Ssum_cLowQ_le_gammaHseq (T j K : Nat) (hK : K ≤ 2 * (j + 1)) :
    Qle (Ssum (cLowQ T) K) (gammaHseq j) := by
  refine Qle_trans (Ssum_den_pos (fun i => cApprox_den_pos i (j + 1)) K)
    (Ssum_le_of_le (fun i => cApprox_ge_cLowQ T i (j + 1)) K) ?_
  show Qle (Ssum (fun i => cApprox i (j + 1)) K) (Ssum (fun i => cApprox i (j + 1)) (gammaHN j))
  exact Ssum_le (fun i => cApprox_num_nonneg i (j + 1)) (fun i => cApprox_den_pos i (j + 1))
    (by unfold gammaHN; omega)

-- ===========================================================================
-- (C) The uniform per-term tail bracket `1/(2(m+1)(m+2)) ≤ cLowQ 3 m ≤ 1/(2m(m+1))`.
-- ===========================================================================

/-- **`dPlusQ 1 (m+1)` in closed form** `[12(2m+3)²(m+1)(m+2) + 4(m+1)(m+2) + 3] / [6(2m+3)³(m+1)(m+2)]`
    (`= 2·(1/(2m+3) + 1/(3(2m+3)³) + 1/(2(2m+3)³(m+1)(m+2)))`). -/
theorem dPlusQ_one_eq (m : Nat) :
    Qeq (dPlusQ 1 (m + 1))
      (⟨12 * (2 * (m : Int) + 3) * (2 * (m : Int) + 3) * ((m : Int) + 1) * ((m : Int) + 2)
          + 4 * ((m : Int) + 1) * ((m : Int) + 2) + 3,
        6 * (2 * m + 3) * (2 * m + 3) * (2 * m + 3) * (m + 1) * (m + 2)⟩ : Q) := by
  unfold dPlusQ
  simp only [artSum, artTerm, qpow, npow, Qeq, mul, add]
  push_cast
  ring_uor

/-- The clean form `≤ (2m+3)/(2(m+1)(m+2))` (cleared difference `= 16·((m+1)(m+2))² ≥ 0`). -/
theorem gcf_le (m : Nat) :
    Qle (⟨12 * (2 * (m : Int) + 3) * (2 * (m : Int) + 3) * ((m : Int) + 1) * ((m : Int) + 2)
          + 4 * ((m : Int) + 1) * ((m : Int) + 2) + 3,
        6 * (2 * m + 3) * (2 * m + 3) * (2 * m + 3) * (m + 1) * (m + 2)⟩ : Q)
        (⟨2 * m + 3, 2 * (m + 1) * (m + 2)⟩ : Q) := by
  simp only [Qle]
  push_cast
  have hX : (0 : Int) ≤ ((m : Int) + 1) * ((m : Int) + 2) := Int.mul_nonneg (by omega) (by omega)
  have key :
      (2 * (m : Int) + 3) * (6 * (2 * (m : Int) + 3) * (2 * (m : Int) + 3) * (2 * (m : Int) + 3)
            * ((m : Int) + 1) * ((m : Int) + 2))
        - (12 * (2 * (m : Int) + 3) * (2 * (m : Int) + 3) * ((m : Int) + 1) * ((m : Int) + 2)
            + 4 * ((m : Int) + 1) * ((m : Int) + 2) + 3) * (2 * ((m : Int) + 1) * ((m : Int) + 2))
      = 16 * (((m : Int) + 1) * ((m : Int) + 2)) * (((m : Int) + 1) * ((m : Int) + 2)) := by ring_uor
  have hnn : (0 : Int) ≤ 16 * (((m : Int) + 1) * ((m : Int) + 2)) * (((m : Int) + 1) * ((m : Int) + 2)) :=
    Int.mul_nonneg (Int.mul_nonneg (by omega) hX) hX
  omega

theorem gcfDen_pos (m : Nat) :
    0 < (⟨12 * (2 * (m : Int) + 3) * (2 * (m : Int) + 3) * ((m : Int) + 1) * ((m : Int) + 2)
          + 4 * ((m : Int) + 1) * ((m : Int) + 2) + 3,
        6 * (2 * m + 3) * (2 * m + 3) * (2 * m + 3) * (m + 1) * (m + 2)⟩ : Q).den :=
  Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (by decide)
    (by omega)) (by omega)) (by omega)) (by omega)) (by omega)

/-- **`dPlusQ 1 (m+1) ≤ (2m+3)/(2(m+1)(m+2))`**. -/
theorem dPlusQ_one_le (m : Nat) :
    Qle (dPlusQ 1 (m + 1)) (⟨2 * m + 3, 2 * (m + 1) * (m + 2)⟩ : Q) :=
  Qle_congr_left (gcfDen_pos m) (Qeq_symm (dPlusQ_one_eq m)) (gcf_le m)

/-- **`d ≤ a − b ⟹ b ≤ a − d`** (both `⟺ b + d ≤ a`). -/
theorem Qle_sub_swap {a b d : Q} (h : Qle d (Qsub a b)) : Qle b (Qsub a d) := by
  simp only [Qle, Qsub, add, neg] at h ⊢
  push_cast at h ⊢
  have key :
      (a.num * (d.den : Int) + -d.num * (a.den : Int)) * (b.den : Int)
        - b.num * ((a.den : Int) * (d.den : Int))
      = (a.num * (b.den : Int) + -b.num * (a.den : Int)) * (d.den : Int)
        - d.num * ((a.den : Int) * (b.den : Int)) := by ring_uor
  omega

/-- **`1/(2(m+1)(m+2)) ≤ cLowQ 1 m`** — the per-term tail lower bound (from `dPlusQ_one_le`). -/
theorem cLowQ_one_tail_lower (m : Nat) :
    Qle (⟨1, 2 * (m + 1) * (m + 2)⟩ : Q) (cLowQ 1 m) := by
  have hQeqR : Qeq (⟨2 * m + 3, 2 * (m + 1) * (m + 2)⟩ : Q)
      (Qsub (⟨1, m + 1⟩ : Q) (⟨1, 2 * (m + 1) * (m + 2)⟩ : Q)) := by
    simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  have h : Qle (dPlusQ 1 (m + 1)) (Qsub (⟨1, m + 1⟩ : Q) (⟨1, 2 * (m + 1) * (m + 2)⟩ : Q)) :=
    Qle_congr_right (Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos m)) (Nat.succ_pos (m + 1)))
      hQeqR (dPlusQ_one_le m)
  exact Qle_sub_swap h

/-- **`1/(2(m+1)(m+2)) ≤ cApprox m T'`** for every depth `T'` — the uniform tail lower bound
    (`cLowQ_one_tail_lower` + `cApprox_ge_cLowQ`). -/
theorem cApprox_tail_lower (m T' : Nat) :
    Qle (⟨1, 2 * (m + 1) * (m + 2)⟩ : Q) (cApprox m T') :=
  Qle_trans (cLowQ_den_pos 1 m) (cLowQ_one_tail_lower m) (cApprox_ge_cLowQ 1 m T')

-- ===========================================================================
-- (D) The telescoped tail of `gammaHseq` and the `Rgamma_h` lower bound.
-- ===========================================================================

/-- **Telescoped γ-series tail** `Σ_{K≤m<K+d} cApprox m T' ≥ 1/(2(K+1)) − 1/(2(K+d+1))** (`d`-induction,
    `cApprox_tail_lower` per step; mirrors `zetaSum2_tail_ge`). -/
theorem Ssum_cApprox_tail (T' K : Nat) : ∀ d,
    Qle (Qsub (⟨1, 2 * (K + 1)⟩ : Q) (⟨1, 2 * (K + d + 1)⟩ : Q))
        (Qsub (Ssum (fun m => cApprox m T') (K + d)) (Ssum (fun m => cApprox m T') K)) := by
  intro d
  induction d with
  | zero =>
      simp only [Nat.add_zero]
      apply Qeq_le
      simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor
  | succ d ih =>
      have hstep := cApprox_tail_lower (K + d) T'
      have hpt : Qeq (⟨1, 2 * (K + d + 1) * (K + d + 2)⟩ : Q)
          (Qsub (⟨1, 2 * (K + d + 1)⟩ : Q) (⟨1, 2 * (K + d + 2)⟩ : Q)) := by
        simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor
      have hstep' : Qle (Qsub (⟨1, 2 * (K + d + 1)⟩ : Q) (⟨1, 2 * (K + d + 2)⟩ : Q))
          (cApprox (K + d) T') :=
        Qle_congr_left (Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos (K + d)))
          (Nat.succ_pos (K + d + 1))) hpt hstep
      have hsplit : Qeq (Qsub (Ssum (fun m => cApprox m T') (K + d + 1)) (Ssum (fun m => cApprox m T') K))
          (add (Qsub (Ssum (fun m => cApprox m T') (K + d)) (Ssum (fun m => cApprox m T') K))
            (cApprox (K + d) T')) := by
        show Qeq (add (add (Ssum (fun m => cApprox m T') (K + d)) (cApprox (K + d) T'))
              (neg (Ssum (fun m => cApprox m T') K)))
          (add (add (Ssum (fun m => cApprox m T') (K + d)) (neg (Ssum (fun m => cApprox m T') K)))
              (cApprox (K + d) T'))
        simp only [Qeq, add, neg]; push_cast; ring_uor
      have htel : Qeq (add (Qsub (⟨1, 2 * (K + 1)⟩ : Q) (⟨1, 2 * (K + d + 1)⟩ : Q))
            (Qsub (⟨1, 2 * (K + d + 1)⟩ : Q) (⟨1, 2 * (K + d + 2)⟩ : Q)))
          (Qsub (⟨1, 2 * (K + 1)⟩ : Q) (⟨1, 2 * (K + (d + 1) + 1)⟩ : Q)) := by
        simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor
      refine Qle_trans (add_den_pos
          (Qsub_den_pos (Nat.mul_pos (by decide) (Nat.succ_pos K))
            (Nat.mul_pos (by decide) (Nat.succ_pos (K + d))))
          (Qsub_den_pos (Nat.mul_pos (by decide) (Nat.succ_pos (K + d)))
            (Nat.mul_pos (by decide) (Nat.succ_pos (K + d + 1)))))
        (Qeq_le (Qeq_symm htel)) ?_
      refine Qle_trans (add_den_pos
          (Qsub_den_pos (Ssum_den_pos (fun i => cApprox_den_pos i T') (K + d))
            (Ssum_den_pos (fun i => cApprox_den_pos i T') K))
          (cApprox_den_pos (K + d) T'))
        (Qadd_le_add ih hstep') (Qeq_le (Qeq_symm hsplit))

/-- **`gammaLoBound T D K + (1/(2(K+1)) − 1/(2(2(j+1)+1))) ≤ gammaHseq j`** for `K ≤ 2(j+1)` — the
    accelerated approximant dominates the rounded `K`-term partial sum plus its telescoped tail. -/
theorem gammaHseq_ge_partial_tail (T D K j : Nat) (hD : 0 < D) (hKj : K ≤ 2 * (j + 1)) :
    Qle (add (gammaLoBound T D K) (Qsub (⟨1, 2 * (K + 1)⟩ : Q) (⟨1, 2 * (2 * (j + 1) + 1)⟩ : Q)))
        (gammaHseq j) := by
  obtain ⟨d, hd⟩ := Nat.le.dest hKj
  have hpart : Qle (gammaLoBound T D K) (Ssum (fun m => cApprox m (j + 1)) K) :=
    Qle_trans (Ssum_den_pos (fun i => cLowQ_den_pos T i) K) (gammaLoBound_le_Ssum T D hD K)
      (Ssum_le_of_le (fun i => cApprox_ge_cLowQ T i (j + 1)) K)
  have htail := Ssum_cApprox_tail (j + 1) K d
  have hcomb : Qle (add (gammaLoBound T D K) (Qsub (⟨1, 2 * (K + 1)⟩ : Q) (⟨1, 2 * (K + d + 1)⟩ : Q)))
      (Ssum (fun m => cApprox m (j + 1)) (K + d)) := by
    refine Qle_trans (add_den_pos (Ssum_den_pos (fun i => cApprox_den_pos i (j + 1)) K)
        (Qsub_den_pos (Ssum_den_pos (fun i => cApprox_den_pos i (j + 1)) (K + d))
          (Ssum_den_pos (fun i => cApprox_den_pos i (j + 1)) K)))
      (Qadd_le_add hpart htail) ?_
    apply Qeq_le
    simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  have e1 : gammaHseq j = Ssum (fun m => cApprox m (j + 1)) (K + d) := by
    show Ssum (fun i => cApprox i (j + 1)) (gammaHN j) = _
    unfold gammaHN; rw [← hd]
  have e2 : 2 * (2 * (j + 1) + 1) = 2 * (K + d + 1) := by omega
  rw [e1, e2]; exact hcomb

/-- **Single-witness lower bound**: if `q + 1/(k+1) ≤ gammaHseq k` for some `k`, then `q ≤ γ`
    (regularity: `gammaHseq n ≥ gammaHseq k − 1/(n+1) − 1/(k+1) ≥ q − 1/(n+1)` for all `n`). -/
theorem Rgamma_h_ge_of_witness {q : Q} (hq : 0 < q.den) (k : Nat)
    (h : Qle (add q (⟨1, k + 1⟩ : Q)) (gammaHseq k)) : Rle (ofQ q hq) Rgamma_h := by
  intro n
  show Qle q (add (gammaHseq n) ⟨2, n + 1⟩)
  have hkn : Qle (gammaHseq k) (add (gammaHseq n) (add (⟨1, n + 1⟩ : Q) (⟨1, k + 1⟩ : Q))) :=
    Qabs_upper (gammaHseq_den_pos n) (gammaHseq_den_pos k)
      (add_den_pos (Nat.succ_pos n) (Nat.succ_pos k)) (gammaHseq_regular n k)
  have hA : Qle q (Qsub (gammaHseq k) (⟨1, k + 1⟩ : Q)) := by
    refine Qle_congr_left (Qsub_den_pos (add_den_pos hq (Nat.succ_pos k)) (Nat.succ_pos k))
      (show Qeq (Qsub (add q (⟨1, k + 1⟩ : Q)) (⟨1, k + 1⟩ : Q)) q by
        simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor) (Qsub_le_sub h)
  refine Qle_trans (Qsub_den_pos (gammaHseq_den_pos k) (Nat.succ_pos k)) hA ?_
  refine Qle_trans (Qsub_den_pos (add_den_pos (gammaHseq_den_pos n)
      (add_den_pos (Nat.succ_pos n) (Nat.succ_pos k))) (Nat.succ_pos k))
    (Qsub_le_sub hkn) ?_
  refine Qle_trans (add_den_pos (gammaHseq_den_pos n) (Nat.succ_pos n))
    (Qeq_le (show Qeq (Qsub (add (gammaHseq n) (add (⟨1, n + 1⟩ : Q) (⟨1, k + 1⟩ : Q)))
        (⟨1, k + 1⟩ : Q)) (add (gammaHseq n) (⟨1, n + 1⟩ : Q)) by
      simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor)) ?_
  exact Qadd_le_add (Qle_refl _) (by simp only [Qle]; push_cast; omega)

set_option maxRecDepth 40000 in
/-- The numeric heart: `577/1000 + 1/(3·10⁶+1) ≤ gammaLoBound 3 10⁸ 60 + (1/122 − 1/(2(2·(3·10⁶+1)+1)))`
    (one big-integer kernel `decide`). -/
theorem gammaLo_decide :
    Qle (add (⟨577, 1000⟩ : Q) (⟨1, 3000000 + 1⟩ : Q))
        (add (gammaLoBound 3 100000000 60)
          (Qsub (⟨1, 2 * (60 + 1)⟩ : Q) (⟨1, 2 * (2 * (3000000 + 1) + 1)⟩ : Q))) := by decide

set_option maxRecDepth 40000 in
/-- **`γ ≥ 0.577`** (`= 577/1000`) — the tightened lower bracket on the Euler–Mascheroni constant
    (true `≈ 0.57722`, vs the prior loose `≥ 0.54`), via the per-term `cLowQ` lower bound, the rounded
    accumulator over `K = 60` terms, and the telescoped tail correction `Σ_{n≥60} ≥ 1/122`, certified
    at the witness index `k = 3·10⁶`. -/
theorem Rgamma_h_ge_577 : Rle (ofQ (⟨577, 1000⟩ : Q) (by decide)) Rgamma_h := by
  refine Rgamma_h_ge_of_witness (by decide) 3000000 ?_
  exact Qle_trans (add_den_pos (gammaLoBound_den_pos 3 100000000 (by decide) 60)
      (Qsub_den_pos (Nat.mul_pos (by decide) (by decide)) (Nat.mul_pos (by decide) (by decide))))
    gammaLo_decide (gammaHseq_ge_partial_tail 3 100000000 60 3000000 (by decide) (by omega))

-- ===========================================================================
-- (E) The γ UPPER bound `γ ≤ 0.578` — the dual (drives the `−3γ²` term in `λ₃`). `cApprox m T` is
-- itself a per-term UPPER bound (antitone in depth), tail upper `cApprox m T' ≤ 1/(2m(m+1))`.
-- ===========================================================================

/-- **`cApprox` is antitone in depth**: `cApprox m Tk ≤ cApprox m Tj` for `Tj ≤ Tk`. -/
theorem cApprox_antitone (m : Nat) {Tj Tk : Nat} (hT : Tj ≤ Tk) :
    Qle (cApprox m Tk) (cApprox m Tj) := by
  unfold cApprox Qsub
  exact Qadd_le_add (Qle_refl _) (Qneg_le_neg (Qmul_le_mul_left (by decide)
    (artSum_mono (by show (0 : Int) ≤ 1; decide) (Nat.succ_pos _) hT)))

/-- `cApprox m 0 = 1/((m+1)(2m+3))`. -/
theorem cApprox_zero_eq (m : Nat) :
    Qeq (cApprox m 0) (⟨1, (m + 1) * (2 * m + 3)⟩ : Q) := by
  unfold cApprox
  simp only [artSum, artTerm, qpow, npow, Qsub, Qeq, mul, add, neg]
  push_cast; ring_uor

/-- **`cApprox m T' ≤ 1/(2m(m+1))`** (`m ≥ 1`) — the per-term tail UPPER bound (`cApprox` antitone,
    `cApprox m 0 = 1/((m+1)(2m+3)) ≤ 1/(2m(m+1))`). -/
theorem cApprox_tail_upper (m T' : Nat) (hm : 1 ≤ m) :
    Qle (cApprox m T') (⟨1, 2 * m * (m + 1)⟩ : Q) := by
  refine Qle_trans (cApprox_den_pos m 0) (cApprox_antitone m (Nat.zero_le T')) ?_
  refine Qle_congr_left (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos (2 * m + 2)))
    (Qeq_symm (cApprox_zero_eq m)) ?_
  show Qle (⟨1, (m + 1) * (2 * m + 3)⟩ : Q) (⟨1, 2 * m * (m + 1)⟩ : Q)
  simp only [Qle]
  have h1 : (m + 1) * (2 * m) ≤ (m + 1) * (2 * m + 3) := Nat.mul_le_mul_left (m + 1) (by omega)
  have h2 : (m + 1) * (2 * m) = 2 * m * (m + 1) := Nat.mul_comm (m + 1) (2 * m)
  have hnat : 2 * m * (m + 1) ≤ (m + 1) * (2 * m + 3) := h2 ▸ h1
  omega

/-- The **rounded UPPER accumulator** for `Σ_{m<K} cApprox m T` (round up to `D`). -/
def gammaHiBound (T D : Nat) : Nat → Q
  | 0 => ⟨0, D⟩
  | (K + 1) => qRoundUp (add (gammaHiBound T D K) (cApprox K T)) D

theorem gammaHiBound_den_pos (T D : Nat) (hD : 0 < D) : ∀ K, 0 < (gammaHiBound T D K).den
  | 0 => hD
  | (_ + 1) => hD

/-- **`Σ_{m<K} cApprox m T ≤ gammaHiBound T D K`** (round-up dominates the exact partial sum). -/
theorem Ssum_le_gammaHiBound (T D : Nat) (hD : 0 < D) :
    ∀ K, Qle (Ssum (fun m => cApprox m T) K) (gammaHiBound T D K)
  | 0 => by show Qle (⟨0, 1⟩ : Q) (⟨0, D⟩ : Q); simp only [Qle]; omega
  | (K + 1) => by
      have hadd : 0 < (add (gammaHiBound T D K) (cApprox K T)).den :=
        add_den_pos (gammaHiBound_den_pos T D hD K) (cApprox_den_pos K T)
      refine Qle_trans hadd ?_ (qRoundUp_ge (add (gammaHiBound T D K) (cApprox K T)) hadd D)
      show Qle (add (Ssum (fun m => cApprox m T) K) (cApprox K T))
        (add (gammaHiBound T D K) (cApprox K T))
      exact Qadd_le_add (Ssum_le_gammaHiBound T D hD K) (Qle_refl _)

/-- **Telescoped γ-series tail UPPER bound** `Σ_{K≤m<K+d} cApprox m T' ≤ 1/(2K) − 1/(2(K+d))** (`K ≥ 1`). -/
theorem Ssum_cApprox_tail_upper (T' K : Nat) (hK : 1 ≤ K) : ∀ d,
    Qle (Qsub (Ssum (fun m => cApprox m T') (K + d)) (Ssum (fun m => cApprox m T') K))
        (Qsub (⟨1, 2 * K⟩ : Q) (⟨1, 2 * (K + d)⟩ : Q)) := by
  intro d
  induction d with
  | zero =>
      simp only [Nat.add_zero]
      apply Qeq_le
      simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor
  | succ d ih =>
      have hK0 : 0 < K := hK
      have hKd : 0 < K + d := by omega
      have hstep := cApprox_tail_upper (K + d) T' (by omega)
      have hpt : Qeq (⟨1, 2 * (K + d) * (K + d + 1)⟩ : Q)
          (Qsub (⟨1, 2 * (K + d)⟩ : Q) (⟨1, 2 * (K + d + 1)⟩ : Q)) := by
        simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor
      have hstep' : Qle (cApprox (K + d) T')
          (Qsub (⟨1, 2 * (K + d)⟩ : Q) (⟨1, 2 * (K + d + 1)⟩ : Q)) :=
        Qle_congr_right (Nat.mul_pos (Nat.mul_pos (by decide) hKd) (Nat.succ_pos (K + d)))
          hpt hstep
      have hsplit : Qeq (Qsub (Ssum (fun m => cApprox m T') (K + d + 1)) (Ssum (fun m => cApprox m T') K))
          (add (Qsub (Ssum (fun m => cApprox m T') (K + d)) (Ssum (fun m => cApprox m T') K))
            (cApprox (K + d) T')) := by
        show Qeq (add (add (Ssum (fun m => cApprox m T') (K + d)) (cApprox (K + d) T'))
              (neg (Ssum (fun m => cApprox m T') K)))
          (add (add (Ssum (fun m => cApprox m T') (K + d)) (neg (Ssum (fun m => cApprox m T') K)))
              (cApprox (K + d) T'))
        simp only [Qeq, add, neg]; push_cast; ring_uor
      have htel : Qeq (add (Qsub (⟨1, 2 * K⟩ : Q) (⟨1, 2 * (K + d)⟩ : Q))
            (Qsub (⟨1, 2 * (K + d)⟩ : Q) (⟨1, 2 * (K + d + 1)⟩ : Q)))
          (Qsub (⟨1, 2 * K⟩ : Q) (⟨1, 2 * (K + (d + 1))⟩ : Q)) := by
        simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor
      refine Qle_trans (add_den_pos
          (Qsub_den_pos (Ssum_den_pos (fun i => cApprox_den_pos i T') (K + d))
            (Ssum_den_pos (fun i => cApprox_den_pos i T') K))
          (cApprox_den_pos (K + d) T'))
        (Qeq_le hsplit) ?_
      refine Qle_trans (add_den_pos
          (Qsub_den_pos (Nat.mul_pos (by decide) hK0)
            (Nat.mul_pos (by decide) hKd))
          (Qsub_den_pos (Nat.mul_pos (by decide) hKd)
            (Nat.mul_pos (by decide) (Nat.succ_pos (K + d)))))
        (Qadd_le_add ih hstep') (Qeq_le htel)

/-- **`gammaHseq j ≤ gammaHiBound T D K + (1/(2K) − 1/(2·2(j+1)))`** for `1 ≤ K ≤ 2(j+1)`, `T ≤ j+1`. -/
theorem gammaHseq_le_partial_tail (T D K j : Nat) (hD : 0 < D) (hK1 : 1 ≤ K) (hTj : T ≤ j + 1)
    (hKj : K ≤ 2 * (j + 1)) :
    Qle (gammaHseq j)
        (add (gammaHiBound T D K) (Qsub (⟨1, 2 * K⟩ : Q) (⟨1, 2 * (2 * (j + 1))⟩ : Q))) := by
  obtain ⟨d, hd⟩ := Nat.le.dest hKj
  have hpart : Qle (Ssum (fun m => cApprox m (j + 1)) K) (gammaHiBound T D K) :=
    Qle_trans (Ssum_den_pos (fun i => cApprox_den_pos i T) K)
      (Ssum_le_of_le (fun i => cApprox_antitone i hTj) K) (Ssum_le_gammaHiBound T D hD K)
  have htail := Ssum_cApprox_tail_upper (j + 1) K hK1 d
  have hcomb : Qle (Ssum (fun m => cApprox m (j + 1)) (K + d))
      (add (gammaHiBound T D K) (Qsub (⟨1, 2 * K⟩ : Q) (⟨1, 2 * (K + d)⟩ : Q))) := by
    refine Qle_trans (add_den_pos (Ssum_den_pos (fun i => cApprox_den_pos i (j + 1)) K)
        (Qsub_den_pos (Ssum_den_pos (fun i => cApprox_den_pos i (j + 1)) (K + d))
          (Ssum_den_pos (fun i => cApprox_den_pos i (j + 1)) K)))
      (Qeq_le (show Qeq (Ssum (fun m => cApprox m (j + 1)) (K + d))
          (add (Ssum (fun m => cApprox m (j + 1)) K)
            (Qsub (Ssum (fun m => cApprox m (j + 1)) (K + d)) (Ssum (fun m => cApprox m (j + 1)) K)))
        by simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor))
      (Qadd_le_add hpart htail)
  have e1 : gammaHseq j = Ssum (fun m => cApprox m (j + 1)) (K + d) := by
    show Ssum (fun i => cApprox i (j + 1)) (gammaHN j) = _
    unfold gammaHN; rw [← hd]
  have e2 : 2 * (2 * (j + 1)) = 2 * (K + d) := by omega
  rw [e1, e2]; exact hcomb

/-- **Single-witness upper bound** (dual of `Rgamma_h_ge_of_witness`). -/
theorem Rgamma_h_le_of_witness {q : Q} (hq : 0 < q.den) (k : Nat)
    (h : Qle (add (gammaHseq k) (⟨1, k + 1⟩ : Q)) q) : Rle Rgamma_h (ofQ q hq) := by
  intro n
  show Qle (gammaHseq n) (add q ⟨2, n + 1⟩)
  have hnk : Qle (gammaHseq n) (add (gammaHseq k) (add (⟨1, k + 1⟩ : Q) (⟨1, n + 1⟩ : Q))) :=
    Qabs_upper (gammaHseq_den_pos k) (gammaHseq_den_pos n)
      (add_den_pos (Nat.succ_pos k) (Nat.succ_pos n)) (gammaHseq_regular k n)
  -- gammaHseq k ≤ q − 1/(k+1)
  have hkq : Qle (gammaHseq k) (Qsub q (⟨1, k + 1⟩ : Q)) := by
    refine Qle_congr_left (Qsub_den_pos (add_den_pos (gammaHseq_den_pos k) (Nat.succ_pos k))
      (Nat.succ_pos k))
      (show Qeq (Qsub (add (gammaHseq k) (⟨1, k + 1⟩ : Q)) (⟨1, k + 1⟩ : Q)) (gammaHseq k) by
        simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor) (Qsub_le_sub h)
  refine Qle_trans (add_den_pos (gammaHseq_den_pos k)
      (add_den_pos (Nat.succ_pos k) (Nat.succ_pos n))) hnk ?_
  refine Qle_trans (add_den_pos (Qsub_den_pos hq (Nat.succ_pos k))
      (add_den_pos (Nat.succ_pos k) (Nat.succ_pos n))) (Qadd_le_add hkq (Qle_refl _)) ?_
  refine Qle_trans (add_den_pos hq (Nat.succ_pos n))
    (Qeq_le (show Qeq (add (Qsub q (⟨1, k + 1⟩ : Q)) (add (⟨1, k + 1⟩ : Q) (⟨1, n + 1⟩ : Q)))
        (add q (⟨1, n + 1⟩ : Q)) by simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor)) ?_
  exact Qadd_le_add (Qle_refl _) (by simp only [Qle]; push_cast; omega)

set_option maxRecDepth 40000 in
/-- The numeric heart (upper): `gammaHiBound 3 10⁸ 60 + (1/120 − 1/(2·2·(5000+1))) + 1/(5000+1) ≤ 578/1000`. -/
theorem gammaHi_decide :
    Qle (add (add (gammaHiBound 3 100000000 60)
          (Qsub (⟨1, 2 * 60⟩ : Q) (⟨1, 2 * (2 * (5000 + 1))⟩ : Q))) (⟨1, 5000 + 1⟩ : Q))
        (⟨578, 1000⟩ : Q) := by decide

set_option maxRecDepth 40000 in
/-- **`γ ≤ 0.578`** (`= 578/1000`) — the tightened UPPER bracket on the Euler–Mascheroni constant
    (true `≈ 0.57722`, vs the prior loose `≤ 0.66`); the bound that drives the `−3γ²` term of `λ₃`.
    With `Rgamma_h_ge_577` this brackets `γ ∈ [0.577, 0.578]`. -/
theorem Rgamma_h_le_578 : Rle Rgamma_h (ofQ (⟨578, 1000⟩ : Q) (by decide)) := by
  refine Rgamma_h_le_of_witness (by decide) 5000 ?_
  exact Qle_trans (add_den_pos (add_den_pos (gammaHiBound_den_pos 3 100000000 (by decide) 60)
      (Qsub_den_pos (Nat.mul_pos (by decide) (by decide)) (Nat.mul_pos (by decide) (by decide))))
      (Nat.succ_pos 5000))
    (Qadd_le_add (gammaHseq_le_partial_tail 3 100000000 60 5000 (by decide) (by decide) (by decide)
      (by omega)) (Qle_refl _)) gammaHi_decide

end UOR.Bridge.F1Square.Analysis
