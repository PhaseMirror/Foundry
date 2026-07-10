/-
F1 square — the **upper** bracket `γ ≤ 0.66` for the convergence-accelerated Euler–Mascheroni
constant `Rgamma_h` (the companion to `GammaAccel.Rgamma_h_lower : γ ≥ 0.54`).

The lower bracket only had to *truncate* the non-negative series `γ = Σ cᵢ`. The upper bracket also
needs the **tail**, which the harmonic-telescoped form supplies cleanly: each term obeys
`cᵢ ≤ 1/((i+1)(i+2))` (`cApprox_ub`), whose tail telescopes (`Ssum_tail_le`), so for the cutoff `K = 6`

    γ  =  Σ_{i<N} cᵢ  ≤  Σ_{i<6} chigh_i  +  1/7  ≤  0.66,

with `chigh_i = cApprox(i,3) + 1/3⁷` the depth-3 **upper** per-term approximant (mirror of `clow`); the
last `≤` is a single rational `decide`. Two-sided, `γ ∈ [0.54, 0.66]` — enough to bound `γ²` from above
for `Pos λ₂` (v0.16.0).

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.GammaAccel

namespace UOR.Bridge.F1Square.Analysis

/-- From `|a − b| ≤ e` extract the upper bound `b ≤ a + e` (mirror of `Qabs_lower`). -/
theorem Qabs_upper {a b e : Q} (had : 0 < a.den) (hbd : 0 < b.den) (hed : 0 < e.den)
    (h : Qle (Qabs (Qsub a b)) e) : Qle b (add a e) := by
  have hba : Qle (Qsub b a) e := by
    have h1 : Qle (Qsub b a) (Qabs (Qsub b a)) := Qle_self_Qabs _
    have h2 : Qabs (Qsub b a) = Qabs (Qsub a b) := Qabs_Qsub_comm b a
    rw [h2] at h1
    exact Qle_trans (Qabs_den_pos (Qsub_den_pos had hbd)) h1 h
  have hc : Qeq (add (Qsub b a) a) b := by
    simp only [Qeq, Qsub, add, neg]; push_cast
    generalize b.num = bn; generalize ((b.den : Nat) : Int) = bd
    generalize a.num = an; generalize ((a.den : Nat) : Int) = ad
    ring_uor
  have h3 : Qle (add (Qsub b a) a) (add e a) := Qadd_le_add hba (Qle_refl a)
  have h4 : Qle b (add e a) := Qle_congr_left (add_den_pos (Qsub_den_pos hbd had) had) hc h3
  have hcomm : Qeq (add e a) (add a e) := by simp only [Qeq, add]; push_cast; ring_uor
  exact Qle_congr_right (add_den_pos hed had) hcomm h4

/-- `a ≈ b + (a − b)`. -/
theorem Qadd_sub_cancel (a b : Q) : Qeq a (add b (Qsub a b)) := by
  simp only [Qeq, Qsub, add, neg]; push_cast
  generalize a.num = an; generalize ((a.den : Nat) : Int) = ad
  generalize b.num = bn; generalize ((b.den : Nat) : Int) = bd
  ring_uor

/-- The depth-3 **upper** per-term approximant `chigh i = cApprox(i,3) + 1/3⁷`. -/
def chigh (i : Nat) : Q := add (cApprox i 3) ⟨1, npow 3 7⟩

theorem chigh_den_pos (i : Nat) : 0 < (chigh i).den :=
  add_den_pos (cApprox_den_pos i 3) (by show 0 < npow 3 7; exact npow_pos (by omega) _)

/-- Each genuine term `cApprox(i, n+1)` (depth `n+1 ≥ 3`) is `≤ chigh i`. -/
theorem cApprox_le_chigh (i : Nat) {n : Nat} (hn : 3 ≤ n + 1) :
    Qle (cApprox i (n + 1)) (chigh i) :=
  Qabs_upper (cApprox_den_pos i 3) (cApprox_den_pos i (n + 1))
    (by show 0 < npow 3 7; exact npow_pos (by omega) _) (cApprox_depth_diff i hn)

/-- **Uniform γ-tail bound**: every approximant `gammaHseq n ≤ 1` (the full series telescopes by `≤ 1`). -/
theorem gammaHseq_le_one (n : Nat) : Qle (gammaHseq n) (⟨1, 1⟩ : Q) := by
  show Qle (Ssum (fun i => cApprox i (n + 1)) (gammaHN n)) (⟨1, 1⟩ : Q)
  have hgd : ∀ i, 0 < (cApprox i (n + 1)).den := fun i => cApprox_den_pos i (n + 1)
  have htail := Ssum_tail_le (f := fun i => cApprox i (n + 1)) hgd
    (fun i => cApprox_ub i (n + 1)) 0 (Nat.zero_le (gammaHN n))
  have hs0 : Ssum (fun i => cApprox i (n + 1)) 0 = (⟨0, 1⟩ : Q) := rfl
  rw [hs0] at htail
  have he1 : Qeq (Qsub (Ssum (fun i => cApprox i (n + 1)) (gammaHN n)) (⟨0, 1⟩ : Q))
      (Ssum (fun i => cApprox i (n + 1)) (gammaHN n)) := by
    simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  have he2 : Qle (Qsub (⟨1, 0 + 1⟩ : Q) ⟨1, gammaHN n + 1⟩) (⟨1, 1⟩ : Q) := by
    unfold Qle Qsub add neg; push_cast; omega
  have hmid : 0 < (Qsub (⟨1, 0 + 1⟩ : Q) ⟨1, gammaHN n + 1⟩).den :=
    Qsub_den_pos (by decide) (by show 0 < gammaHN n + 1; omega)
  exact Qle_congr_left (Qsub_den_pos (Ssum_den_pos hgd (gammaHN n)) (by decide)) he1
    (Qle_trans hmid htail he2)

/-- **The tight upper bound on the approximants** (`n ≥ 2`, depth `≥ 3`): split at `K = 6` — head
    `≤ Σ chigh`, tail `≤ 1/7`. -/
theorem gammaHseq_le_chigh {n : Nat} (hn : 2 ≤ n) :
    Qle (gammaHseq n) (add (Ssum chigh 6) ⟨1, 7⟩) := by
  show Qle (Ssum (fun i => cApprox i (n + 1)) (gammaHN n)) (add (Ssum chigh 6) ⟨1, 7⟩)
  have hgd : ∀ i, 0 < (cApprox i (n + 1)).den := fun i => cApprox_den_pos i (n + 1)
  have hdepth : 3 ≤ n + 1 := by omega
  have hhead : Qle (Ssum (fun i => cApprox i (n + 1)) 6) (Ssum chigh 6) :=
    Ssum_le_of_le (fun i => cApprox_le_chigh i hdepth) 6
  rcases Nat.lt_or_ge (gammaHN n) 6 with hlt | hge
  · have h1 : Qle (Ssum (fun i => cApprox i (n + 1)) (gammaHN n)) (Ssum (fun i => cApprox i (n + 1)) 6) :=
      Ssum_le (fun i => cApprox_num_nonneg i (n + 1)) hgd (Nat.le_of_lt hlt)
    exact Qle_trans (Ssum_den_pos hgd 6) h1
      (Qle_trans (Ssum_den_pos chigh_den_pos 6) hhead (Qle_self_add (by decide)))
  · have htail0 := Ssum_tail_le (f := fun i => cApprox i (n + 1)) hgd
      (fun i => cApprox_ub i (n + 1)) 6 hge
    have hsplit : Qeq (Ssum (fun i => cApprox i (n + 1)) (gammaHN n))
        (add (Ssum (fun i => cApprox i (n + 1)) 6)
          (Qsub (Ssum (fun i => cApprox i (n + 1)) (gammaHN n)) (Ssum (fun i => cApprox i (n + 1)) 6))) :=
      Qadd_sub_cancel _ _
    have htail : Qle (Qsub (Ssum (fun i => cApprox i (n + 1)) (gammaHN n))
        (Ssum (fun i => cApprox i (n + 1)) 6)) (⟨1, 7⟩ : Q) := by
      refine Qle_trans (Qsub_den_pos (by decide) (by show 0 < gammaHN n + 1; omega)) htail0 ?_
      show Qle (Qsub (⟨1, 6 + 1⟩ : Q) ⟨1, gammaHN n + 1⟩) (⟨1, 7⟩ : Q)
      unfold Qle Qsub add neg; push_cast; omega
    have hcombine : Qle (add (Ssum (fun i => cApprox i (n + 1)) 6)
        (Qsub (Ssum (fun i => cApprox i (n + 1)) (gammaHN n)) (Ssum (fun i => cApprox i (n + 1)) 6)))
        (add (Ssum chigh 6) ⟨1, 7⟩) := Qadd_le_add hhead htail
    exact Qle_congr_left (add_den_pos (Ssum_den_pos hgd 6)
      (Qsub_den_pos (Ssum_den_pos hgd (gammaHN n)) (Ssum_den_pos hgd 6))) (Qeq_symm hsplit) hcombine

set_option maxHeartbeats 1000000 in
set_option maxRecDepth 4096 in
/-- The shallow rational certificate `Σ_{i<6} chigh_i + 1/7 ≤ 0.66` (one `decide`). -/
theorem chigh_sum_bound : Qle (add (Ssum chigh 6) (⟨1, 7⟩ : Q)) (⟨66, 100⟩ : Q) := by decide

/-- **The γ upper bracket**: `Rgamma_h ≤ 66/100` (`γ ≈ 0.5772`). For `n ≥ 2` the depth-3 split gives
    `gammaHseq n ≤ Σ chigh 6 + 1/7 ≤ 0.66`; for `n ≤ 1` the trivial `≤ 1` bound suffices. -/
theorem Rgamma_h_upper : Rle Rgamma_h (ofQ (⟨66, 100⟩ : Q) (by decide)) := by
  intro n
  show Qle (gammaHseq n) (add (⟨66, 100⟩ : Q) ⟨2, n + 1⟩)
  match n with
  | 0 =>
    exact Qle_trans (by decide) (gammaHseq_le_one 0)
      (by decide : Qle (⟨1, 1⟩ : Q) (add (⟨66, 100⟩ : Q) ⟨2, 0 + 1⟩))
  | 1 =>
    exact Qle_trans (by decide) (gammaHseq_le_one 1)
      (by decide : Qle (⟨1, 1⟩ : Q) (add (⟨66, 100⟩ : Q) ⟨2, 1 + 1⟩))
  | (m + 2) =>
    have hAB := gammaHseq_le_chigh (show 2 ≤ m + 2 by omega)
    have hCD : Qle (⟨66, 100⟩ : Q) (add (⟨66, 100⟩ : Q) ⟨2, (m + 2) + 1⟩) :=
      Qle_self_add (by show (0 : Int) ≤ 2; decide)
    exact Qle_trans (add_den_pos (Ssum_den_pos chigh_den_pos 6) (by decide)) hAB
      (Qle_trans (by decide) chigh_sum_bound hCD)

end UOR.Bridge.F1Square.Analysis
