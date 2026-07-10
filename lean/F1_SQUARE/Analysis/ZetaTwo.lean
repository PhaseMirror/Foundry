/-
F1 square — the **lower bracket `ζ(2) ≥ 1.63`** (a constituent of `Pos λ₂`, v0.16.0).

`ζ(s) = Σ_{i≥1} 1/iˢ` (`Zeta.zeta`) has **non-negative** terms, so every partial sum is a lower bound:
`ζ(s) ≥ zetaSum s N` (`zeta_ge_partial`), because the omitted tail is `≥ 0` (and within `1/(n+1)` of the
approximant, by `zetaabs_bound`). At `N = 70` the rational partial sum already exceeds `1.63`
(`Σ_{k=1}^{70} 1/k² ≈ 1.6307`; one `decide`), giving `ζ(2) ≥ 163/100`. (Plain `Σ 1/k²` decides cheaply —
no `lcm`-denominator blow-up, unlike the alternating `γ`-series.)

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.Zeta
import F1Square.Analysis.RealPow
import F1Square.Analysis.GammaUpper

namespace UOR.Bridge.F1Square.Analysis

/-- **`ζ(s) ≥ zetaSum s N`** — the value dominates each partial sum (the tail is `≥ 0`). -/
theorem zeta_ge_partial (s : Nat) (hs : 2 ≤ s) (N : Nat) :
    Rle (ofQ (zetaSum s N) (zetaSum_den_pos s N)) (zeta s hs) := by
  intro n
  show Qle (zetaSum s N) (add (zetaSum s n) ⟨2, n + 1⟩)
  rcases Nat.le_total n N with hnN | hNn
  · -- n ≤ N: zetaSum s N ≤ zetaSum s n + 1/(n+1) ≤ + 2/(n+1)
    have habs := zetaabs_bound s hs hnN
    have habs' : Qle (Qabs (Qsub (zetaSum s n) (zetaSum s N))) (⟨1, n + 1⟩ : Q) := by
      rw [Qabs_Qsub_comm]; exact habs
    have hb1 : Qle (zetaSum s N) (add (zetaSum s n) ⟨1, n + 1⟩) :=
      Qabs_upper (zetaSum_den_pos s n) (zetaSum_den_pos s N) (by show 0 < n + 1; omega) habs'
    have he : Qle (add (zetaSum s n) (⟨1, n + 1⟩ : Q)) (add (zetaSum s n) ⟨2, n + 1⟩) :=
      Qadd_le_add (Qle_refl _) (by simp only [Qle]; push_cast; omega)
    exact Qle_trans (add_den_pos (zetaSum_den_pos s n) (by show 0 < n + 1; omega)) hb1 he
  · -- n ≥ N: zetaSum s N ≤ zetaSum s n ≤ + 2/(n+1)
    exact Qle_trans (zetaSum_den_pos s n) (zetaSum_le s hNn)
      (Qle_self_add (by show (0 : Int) ≤ 2; decide))

set_option maxHeartbeats 4000000 in
set_option maxRecDepth 8192 in
/-- `Σ_{k=1}^{70} 1/k² ≥ 163/100` (one rational `decide`). -/
theorem zetaSum_two_70_ge : Qle (⟨163, 100⟩ : Q) (zetaSum 2 70) := by decide

/-- **`ζ(2) ≥ 1.63`** — the lower bracket for the Basel constant. -/
theorem zeta2_lower : Rle (ofQ (⟨163, 100⟩ : Q) (by decide)) (zeta 2 (by decide)) :=
  Rle_trans (Rle_ofQ_ofQ (by decide) (zetaSum_den_pos 2 70) zetaSum_two_70_ge)
    (zeta_ge_partial 2 (by decide) 70)

-- ===========================================================================
-- **Tail-corrected `ζ(2)` lower bound** `ζ(2) ≥ zetaSum 2 N + 1/(N+2)`. The partial-sum lower bound
-- `zeta_ge_partial` converges only as `1/N`, so reaching `1.644` would need `N ≈ 1100` (infeasible
-- decide). Adding the rigorous tail lower bound `Σ_{k≥N+2} 1/k² ≥ Σ 1/(k(k+1)) = 1/(N+2)` recovers the
-- bulk of the missing tail, lifting the *existing* `N = 70` certificate to `ζ(2) ≥ 1.644` — the tight
-- `ζ(2)` lower the `Pos Rlambda3` (`λ₃`) certificate needs.
-- ===========================================================================

/-- **Per-step tail bound** `1/(m+2) − 1/(m+3) ≤ 1/(m+2)²` (since `(m+2)² ≤ (m+2)(m+3)`); the
    `Usum_step_ineq` pattern (explicit `key`, `omega`). -/
theorem zetaSum2_perstep_ge (m : Nat) :
    Qle (Qsub (⟨1, m + 2⟩ : Q) (⟨1, m + 3⟩ : Q)) (⟨1, npow (m + 2) 2⟩ : Q) := by
  have hnp : npow (m + 2) 2 = (m + 2) * (m + 2) := by simp only [npow, Nat.mul_one]
  rw [hnp]
  simp only [Qle, Qsub, add, neg]
  push_cast
  have key : 1 * (((m : Int) + 2) * ((m : Int) + 3))
      - (1 * ((m : Int) + 3) + -1 * ((m : Int) + 2)) * (((m : Int) + 2) * ((m : Int) + 2))
      = (m : Int) + 2 := by ring_uor
  have hm : (0 : Int) ≤ (m : Int) := Int.ofNat_nonneg m
  omega

/-- **Telescoped tail bound** `1/(N+2) − 1/(N+d+2) ≤ zetaSum 2 (N+d) − zetaSum 2 N` (`d`-induction,
    mirroring `Vsum_tail_le`). -/
theorem zetaSum2_tail_ge (N : Nat) : ∀ d,
    Qle (Qsub (⟨1, N + 2⟩ : Q) (⟨1, N + d + 2⟩ : Q)) (Qsub (zetaSum 2 (N + d)) (zetaSum 2 N)) := by
  intro d
  induction d with
  | zero =>
      simp only [Nat.add_zero]
      apply Qeq_le
      simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor
  | succ d ih =>
      have hstep := zetaSum2_perstep_ge (N + d)
      have hsplit : Qeq (Qsub (zetaSum 2 (N + d + 1)) (zetaSum 2 N))
          (add (Qsub (zetaSum 2 (N + d)) (zetaSum 2 N)) (⟨1, npow (N + d + 2) 2⟩ : Q)) := by
        show Qeq (add (add (zetaSum 2 (N + d)) (⟨1, npow (N + d + 2) 2⟩ : Q)) (neg (zetaSum 2 N)))
          (add (add (zetaSum 2 (N + d)) (neg (zetaSum 2 N))) (⟨1, npow (N + d + 2) 2⟩ : Q))
        simp only [Qeq, add, neg]; push_cast; ring_uor
      have htel : Qeq (add (Qsub (⟨1, N + 2⟩ : Q) (⟨1, N + d + 2⟩ : Q))
            (Qsub (⟨1, N + d + 2⟩ : Q) (⟨1, N + d + 3⟩ : Q)))
          (Qsub (⟨1, N + 2⟩ : Q) (⟨1, N + (d + 1) + 2⟩ : Q)) := by
        simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor
      refine Qle_trans (add_den_pos
          (Qsub_den_pos (Nat.succ_pos (N + 1)) (Nat.succ_pos (N + d + 1)))
          (Qsub_den_pos (Nat.succ_pos (N + d + 1)) (Nat.succ_pos (N + d + 2))))
        (Qeq_le (Qeq_symm htel)) ?_
      refine Qle_trans (add_den_pos
          (Qsub_den_pos (zetaSum_den_pos 2 (N + d)) (zetaSum_den_pos 2 N))
          (npow_pos (Nat.succ_pos (N + d + 1)) 2))
        (Qadd_le_add ih hstep) (Qeq_le (Qeq_symm hsplit))

/-- **`ζ(2) ≥ zetaSum 2 N + 1/(N+2)`** — the tail-corrected lower bound. -/
theorem zeta2_ge_partial_tail (N : Nat) :
    Rle (ofQ (add (zetaSum 2 N) (⟨1, N + 2⟩ : Q))
        (add_den_pos (zetaSum_den_pos 2 N) (Nat.succ_pos (N + 1)))) (zeta 2 (by decide)) := by
  intro n
  show Qle (add (zetaSum 2 N) (⟨1, N + 2⟩ : Q)) (add (zetaSum 2 n) ⟨2, n + 1⟩)
  rcases Nat.le_total n N with hnN | hNn
  · -- n ≤ N
    have habs : Qle (zetaSum 2 N) (add (zetaSum 2 n) ⟨1, n + 1⟩) := by
      have h := zetaabs_bound 2 (by decide) hnN
      rw [Qabs_Qsub_comm] at h
      exact Qabs_upper (zetaSum_den_pos 2 n) (zetaSum_den_pos 2 N) (Nat.succ_pos n) h
    refine Qle_trans (add_den_pos (add_den_pos (zetaSum_den_pos 2 n) (Nat.succ_pos n))
        (Nat.succ_pos (N + 1)))
      (Qadd_le_add habs (Qle_refl _)) ?_
    refine Qle_trans (add_den_pos (zetaSum_den_pos 2 n)
        (add_den_pos (Nat.succ_pos n) (Nat.succ_pos (N + 1))))
      (Qeq_le (show Qeq (add (add (zetaSum 2 n) (⟨1, n + 1⟩ : Q)) (⟨1, N + 2⟩ : Q))
          (add (zetaSum 2 n) (add (⟨1, n + 1⟩ : Q) (⟨1, N + 2⟩ : Q)))
        by simp only [Qeq, add]; push_cast; ring_uor)) ?_
    refine Qadd_le_add (Qle_refl _) ?_
    simp only [Qle, add]; push_cast
    have hle : (n : Int) ≤ (N : Int) := by exact_mod_cast hnN
    have key : 2 * (((n : Int) + 1) * ((N : Int) + 2))
        - (1 * ((N : Int) + 2) + 1 * ((n : Int) + 1)) * ((n : Int) + 1)
        = ((n : Int) + 1) * (((N : Int) + 1) - (n : Int)) := by ring_uor
    have hp : (0 : Int) ≤ ((n : Int) + 1) * (((N : Int) + 1) - (n : Int)) :=
      Int.mul_nonneg (by omega) (by omega)
    omega
  · -- n ≥ N
    obtain ⟨d, rfl⟩ := Nat.le.dest hNn
    have htail := zetaSum2_tail_ge N d
    have hL : Qeq (add (zetaSum 2 N) (⟨1, N + 2⟩ : Q))
        (add (Qsub (⟨1, N + 2⟩ : Q) (⟨1, N + d + 2⟩ : Q))
          (add (zetaSum 2 N) (⟨1, N + d + 2⟩ : Q))) := by
      simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
    have hR : Qeq (add (Qsub (zetaSum 2 (N + d)) (zetaSum 2 N))
          (add (zetaSum 2 N) (⟨1, N + d + 2⟩ : Q)))
        (add (zetaSum 2 (N + d)) (⟨1, N + d + 2⟩ : Q)) := by
      simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
    refine Qle_trans (add_den_pos
        (Qsub_den_pos (Nat.succ_pos (N + 1)) (Nat.succ_pos (N + d + 1)))
        (add_den_pos (zetaSum_den_pos 2 N) (Nat.succ_pos (N + d + 1))))
      (Qeq_le hL) ?_
    refine Qle_trans (add_den_pos
        (Qsub_den_pos (zetaSum_den_pos 2 (N + d)) (zetaSum_den_pos 2 N))
        (add_den_pos (zetaSum_den_pos 2 N) (Nat.succ_pos (N + d + 1))))
      (Qadd_le_add htail (Qle_refl _)) ?_
    refine Qle_trans (add_den_pos (zetaSum_den_pos 2 (N + d)) (Nat.succ_pos (N + d + 1)))
      (Qeq_le hR) ?_
    exact Qadd_le_add (Qle_refl _)
      (show Qle (⟨1, N + d + 2⟩ : Q) (⟨2, N + d + 1⟩ : Q) by simp only [Qle]; push_cast; omega)

set_option maxHeartbeats 4000000 in
set_option maxRecDepth 8192 in
/-- `Σ_{k=1}^{71} 1/k² + 1/72 ≥ 1644/1000` (one rational `decide`; the tail-corrected `N = 70`
    value `≈ 1.6447`). -/
theorem zetaSum_two_70_tail_ge :
    Qle (⟨1644, 1000⟩ : Q) (add (zetaSum 2 70) (⟨1, 70 + 2⟩ : Q)) := by decide

set_option maxRecDepth 8192 in
/-- **`ζ(2) ≥ 1.644`** — the TIGHT lower bracket for the Basel constant (true `≈ 1.64493`), via the
    tail-corrected partial sum at the existing `N = 70`. With `zeta2_upper` (`≤ 1.646`) this brackets
    `ζ(2)` to ~3 figures — the tight `ζ(2)` lower the `Pos Rlambda3` (`λ₃`) certificate needs. -/
theorem zeta2_lower_tight : Rle (ofQ (⟨1644, 1000⟩ : Q) (by decide)) (zeta 2 (by decide)) :=
  Rle_trans (Rle_ofQ_ofQ (by decide)
    (add_den_pos (zetaSum_den_pos 2 70) (Nat.succ_pos (70 + 1))) zetaSum_two_70_tail_ge)
    (zeta2_ge_partial_tail 70)

/-- **`ζ(s) ≤ zetaU s N = S(N) + 1/(N+1)`** — the value is dominated by the decreasing upper sequence
    `U` (`zetaU_le`), the rigorous tail-overestimate `Σ_{k>N+1} 1/kˢ ≤ 1/(N+1)` made an explicit
    rational upper bound. The mirror of `zeta_ge_partial` (the upper bracket). -/
theorem zeta_le_partial (s : Nat) (hs : 2 ≤ s) (N : Nat) :
    Rle (zeta s hs) (ofQ (zetaU s N) (zetaU_den_pos s N)) := by
  intro n
  show Qle (zetaSum s n) (add (zetaU s N) ⟨2, n + 1⟩)
  rcases Nat.le_total n N with hnN | hNn
  · -- n ≤ N: S(n) ≤ S(N) ≤ S(N)+1/(N+1) = U(N) ≤ + 2/(n+1)
    have h1 : Qle (zetaSum s n) (zetaU s N) :=
      Qle_trans (zetaSum_den_pos s N) (zetaSum_le s hnN)
        (Qle_self_add (show (0 : Int) ≤ 1 by decide))
    exact Qle_trans (zetaU_den_pos s N) h1 (Qle_self_add (show (0 : Int) ≤ 2 by decide))
  · -- n ≥ N: S(n) ≤ S(N)+1/(N+1) = U(N) (zetadiff_bound) ≤ + 2/(n+1)
    have h1 : Qle (zetaSum s n) (zetaU s N) :=
      Qle_add_of_Qsub_le (zetaSum_den_pos s n) (zetaSum_den_pos s N) (Nat.succ_pos N)
        (zetadiff_bound s hs hNn)
    exact Qle_trans (zetaU_den_pos s N) h1 (Qle_self_add (show (0 : Int) ≤ 2 by decide))

set_option maxHeartbeats 4000000 in
set_option maxRecDepth 8192 in
/-- `zetaU 2 70 = Σ_{k=1}^{71} 1/k² + 1/71 ≤ 1645/1000` (one rational `decide`; `≈ 1.6450`). -/
theorem zetaU_two_70_le : Qle (zetaU 2 70) (⟨1646, 1000⟩ : Q) := by decide

/-- **`ζ(2) ≤ 1.646`** — the upper bracket for the Basel constant (true value `≈ 1.64493`), via the
    decreasing upper sequence `zetaU` at `N = 70`. With `zeta2_lower` this two-sided-brackets `ζ(2)`. -/
theorem zeta2_upper : Rle (zeta 2 (by decide)) (ofQ (⟨1646, 1000⟩ : Q) (by decide)) :=
  Rle_trans (zeta_le_partial 2 (by decide) 70)
    (Rle_ofQ_ofQ (zetaU_den_pos 2 70) (by decide) zetaU_two_70_le)

set_option maxHeartbeats 4000000 in
set_option maxRecDepth 8192 in
/-- `Σ_{k=1}^{71} 1/k³ ≥ 1201/1000` (`≈ 1.20206`; one rational `decide`). -/
theorem zetaSum_three_70_ge : Qle (⟨1201, 1000⟩ : Q) (zetaSum 3 70) := by decide

/-- **`ζ(3) ≥ 1.201`** — the lower bracket for Apéry's constant (true value `≈ 1.2020569`). -/
theorem zeta3_lower : Rle (ofQ (⟨1201, 1000⟩ : Q) (by decide)) (zeta 3 (by decide)) :=
  Rle_trans (Rle_ofQ_ofQ (by decide) (zetaSum_den_pos 3 70) zetaSum_three_70_ge)
    (zeta_ge_partial 3 (by decide) 70)

set_option maxHeartbeats 4000000 in
set_option maxRecDepth 8192 in
/-- `zetaU 3 70 = Σ_{k=1}^{71} 1/k³ + 1/71 ≤ 1217/1000` (one rational `decide`; `≈ 1.2161`). -/
theorem zetaU_three_70_le : Qle (zetaU 3 70) (⟨1217, 1000⟩ : Q) := by decide

/-- **`ζ(3) ≤ 1.217`** — the upper bracket for Apéry's constant, via the decreasing upper sequence
    `zetaU` at `N = 70`. With `zeta3_lower` this two-sided-brackets `ζ(3) ∈ [1.201, 1.217]` — the
    `two-sided ζ(3)` named missing for the `Pos Rlambda3` (`λ₃`) certificate. -/
theorem zeta3_upper : Rle (zeta 3 (by decide)) (ofQ (⟨1217, 1000⟩ : Q) (by decide)) :=
  Rle_trans (zeta_le_partial 3 (by decide) 70)
    (Rle_ofQ_ofQ (zetaU_den_pos 3 70) (by decide) zetaU_three_70_le)

set_option maxHeartbeats 4000000 in
set_option maxRecDepth 8192 in
/-- `Σ_{k=1}^{71} 1/k⁴ ≥ 1082/1000` (`ζ(4) ≈ 1.0823232`; one rational `decide`). -/
theorem zetaSum_four_70_ge : Qle (⟨1082, 1000⟩ : Q) (zetaSum 4 70) := by decide

/-- **`ζ(4) ≥ 1.082`** — lower bracket for `ζ(4) = π⁴/90 ≈ 1.0823232`. The `+(15/16)ζ(4)` term of the
    `n = 4` archimedean coupling (`genArchTerm 4 4`) needs this lower bound (toward `Pos Rlambda4`). -/
theorem zeta4_lower : Rle (ofQ (⟨1082, 1000⟩ : Q) (by decide)) (zeta 4 (by decide)) :=
  Rle_trans (Rle_ofQ_ofQ (by decide) (zetaSum_den_pos 4 70) zetaSum_four_70_ge)
    (zeta_ge_partial 4 (by decide) 70)

set_option maxHeartbeats 4000000 in
set_option maxRecDepth 8192 in
/-- `zetaU 4 70 = Σ_{k=1}^{71} 1/k⁴ + 1/71 ≤ 1097/1000` (one rational `decide`; `≈ 1.0964`). -/
theorem zetaU_four_70_le : Qle (zetaU 4 70) (⟨1097, 1000⟩ : Q) := by decide

/-- **`ζ(4) ≤ 1.097`** — (loose) upper bracket for `ζ(4)`, via the decreasing upper sequence `zetaU`
    at `N = 70`. With `zeta4_lower` this two-sided-brackets `ζ(4) ∈ [1.082, 1.097]`. -/
theorem zeta4_upper : Rle (zeta 4 (by decide)) (ofQ (⟨1097, 1000⟩ : Q) (by decide)) :=
  Rle_trans (zeta_le_partial 4 (by decide) 70)
    (Rle_ofQ_ofQ (zetaU_den_pos 4 70) (by decide) zetaU_four_70_le)

end UOR.Bridge.F1Square.Analysis
