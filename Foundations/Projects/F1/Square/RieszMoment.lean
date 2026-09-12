/-
F1 square — **the moment realization** (`RieszMoment.lean`), the completion of brick 4 of the
moment-realization sub-arc. The degree-`N` Riesz projection realizes `μ` against every monomial up to
degree `N`:

  `realize_moment` :  `j ≤ N  ⟹  ⟨p_N, x^j⟩_d = μ_j`.

The proof is a strong induction on `j` that **dissolves the change of basis** (no Hilbert-matrix
inverse is ever built). Form the defect vector `D_i = ⟨p_N, x^i⟩ − μ_i`; the induction hypothesis
makes `D_i = 0` for `i < j`, so the combination `Σ_{i≤j} (q_j)_i · D_i` collapses to its single leading
term `(q_j)_j · D_j` (`qsumL_range_single`). But that same combination equals `⟨p_N, q_j⟩ − Λ_μ(q_j)`
(distribute over `q_j = Σ_i (q_j)_i x^i` via `vec_self_expand`, `qHil_combVec_right`, `Lam_combVec`,
`Lam_eVec`), which vanishes by `realize_basis`. So `(q_j)_j · D_j = 0`, and since the leading
coefficient is `≉ 0`, no-zero-divisors force `D_j = 0`, i.e. `⟨p_N, x^j⟩ = μ_j`.

HONEST SCOPE. The realization identity for the *finite* Riesz projection at a *fixed* dimension `d`,
under the orthogonal-family invariants supplied as hypotheses. This is NOT Parseval, NOT the L²-limit
/ convergence (which additionally needs a dimension-independent family and a supplied Bessel
convergence modulus — later bricks), NOT positivity. Step 4 (band-coupling positivity) is RH; the crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.RieszRealize

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- ℚ helpers (private).
-- ===========================================================================

private theorem Qmul_zero_of_right {a b : Q} (hb : Qeq b (⟨0, 1⟩ : Q)) :
    Qeq (mul a b) (⟨0, 1⟩ : Q) := by
  have hbn : b.num = 0 := by simp only [Qeq] at hb; push_cast at hb; omega
  show a.num * b.num * ((1 : Nat) : Int) = 0 * ((a.den * b.den : Nat) : Int)
  rw [hbn]; push_cast; ring_uor

/-- `mul c (a − b) = c·a − c·b`. -/
private theorem Qmul_sub_distrib (c a b : Q) :
    Qeq (mul c (Qsub a b)) (Qsub (mul c a) (mul c b)) := by
  simp only [Qeq, Qsub, mul, add, neg]; push_cast; ring_uor

/-- `a = b ⟹ a − b ≈ 0`. -/
private theorem Qsub_self_zero {a b : Q} (h : Qeq a b) : Qeq (Qsub a b) (⟨0, 1⟩ : Q) := by
  simp only [Qeq, Qsub, add, neg] at h ⊢; push_cast at h ⊢
  have hneg : -b.num * (a.den : Int) = -(b.num * (a.den : Int)) := by ring_uor
  omega

/-- `a − b ≈ 0 ⟹ a = b`. -/
private theorem Qsub_zero_imp_eq {a b : Q} (h : Qeq (Qsub a b) (⟨0, 1⟩ : Q)) : Qeq a b := by
  simp only [Qeq, Qsub, add, neg] at h ⊢; push_cast at h ⊢
  have hneg : -b.num * (a.den : Int) = -(b.num * (a.den : Int)) := by ring_uor
  omega

/-- No zero divisors: `c ≉ 0` and `c·d ≈ 0` force `d ≈ 0`. -/
private theorem Qmul_no_zero_div {c d : Q} (hc : ¬ Qeq c (⟨0, 1⟩ : Q))
    (h : Qeq (mul c d) (⟨0, 1⟩ : Q)) : Qeq d (⟨0, 1⟩ : Q) := by
  have hcn : c.num ≠ 0 := by intro hz; exact hc (by simp only [Qeq]; push_cast; omega)
  have hprod : c.num * d.num = 0 := by
    have := h; simp only [Qeq, mul] at this; push_cast at this; omega
  have hdn : d.num = 0 := by
    rcases Int.mul_eq_zero.mp hprod with h1 | h2
    · exact absurd h1 hcn
    · exact h2
  simp only [Qeq]; push_cast; omega

/-- Sum of differences is the difference of sums. -/
private theorem qsumL_sub (F G : Nat → Q) (hF : ∀ i, 0 < (F i).den) (hG : ∀ i, 0 < (G i).den)
    (vars : List Nat) :
    Qeq (qsumL (fun i => Qsub (F i) (G i)) vars) (Qsub (qsumL F vars) (qsumL G vars)) :=
  Qeq_trans (b := add (qsumL F vars) (qsumL (fun i => neg (G i)) vars))
    (add_den_pos (qsumL_den F hF vars) (qsumL_den _ (fun i => neg_den_pos (hG i)) vars))
    (qsumL_add F (fun i => neg (G i)) hF (fun i => neg_den_pos (hG i)) vars)
    (Qadd_congr (Qeq_refl _) (qsumL_neg G hG vars))

/-- `qHil` is congruent in its second argument under pointwise `Qeq`. -/
private theorem qHil_congr_right (c c' c'' : Nat → Q) (d : Nat) (h : ∀ k, Qeq (c' k) (c'' k)) :
    Qeq (qHil c c' d) (qHil c c'' d) := by
  show Qeq (qsumL (fun k => mul (c' k) (innerHil c d k)) (List.range d))
    (qsumL (fun k => mul (c'' k) (innerHil c d k)) (List.range d))
  exact qsumL_congr (fun k => Qmul_congr (h k) (Qeq_refl _)) (List.range d)

/-- `Λ_μ` is congruent in its coefficient argument under pointwise `Qeq`. -/
private theorem Lam_congr (μ c c' : Nat → Q) (d : Nat) (h : ∀ i, Qeq (c i) (c' i)) :
    Qeq (Lam μ c d) (Lam μ c' d) := by
  show Qeq (qsumL (fun i => mul (c i) (μ i)) (List.range d))
    (qsumL (fun i => mul (c' i) (μ i)) (List.range d))
  exact qsumL_congr (fun i => Qmul_congr (h i) (Qeq_refl _)) (List.range d)

-- ===========================================================================
-- The moment realization.
-- ===========================================================================

set_option maxHeartbeats 1000000 in
/-- **★ THE MOMENT REALIZATION**: `⟨p_N, x^j⟩_d = μ_j` for `j ≤ N`. Strong induction on `j` dissolving
    the change of basis. -/
theorem realize_moment (μ : Nat → Q) (d : Nat) (q : Nat → (Nat → Q))
    (hqd : ∀ k idx, 0 < (q k idx).den) (hμ : ∀ i, 0 < (μ i).den)
    (hqorth : ∀ a b, a < d → b < d → a ≠ b → Qeq (qHil (q a) (q b) d) (⟨0, 1⟩ : Q))
    (hmonic : ∀ k, k < d → ¬ Qeq (q k k) (⟨0, 1⟩ : Q))
    (hqsupp : ∀ k, k < d → ∀ idx, k < idx → Qeq (q k idx) (⟨0, 1⟩ : Q))
    (N : Nat) (hNd : N < d) :
    ∀ j, j ≤ N → Qeq (qHil (pVec μ d q N) (eVec j) d) (μ j) := by
  intro j
  induction j using Nat.strongRecOn with
  | ind j ih =>
    intro hjN
    have hjd : j < d := by omega
    have hPden : ∀ idx, 0 < (pVec μ d q N idx).den := pVec_den μ d q hqd hμ N
    -- moment reads at each index (a helper for the many denominators)
    have hhden : ∀ i, 0 < (qHil (pVec μ d q N) (eVec i) d).den :=
      fun i => qHil_den_pos (pVec μ d q N) (eVec i) hPden (eVec_den i) d
    -- `⟨p_N, q_j⟩ = Λ_μ(q_j)` and both split over `q_j = Σ_i (q_j)_i x^i`.
    have hbasis : Qeq (qHil (pVec μ d q N) (q j) d) (Lam μ (q j) d) :=
      realize_basis μ d q hqd hμ hqorth hmonic N j hNd hjN
    have hexp : ∀ idx, Qeq (q j idx)
        (combVec (List.range (j + 1)) (fun i => q j i) eVec idx) :=
      fun idx => vec_self_expand (q j) (hqd j) j (hqsupp j hjd) idx
    have hSf : Qeq (qHil (pVec μ d q N) (q j) d)
        (qsumL (fun i => mul (q j i) (qHil (pVec μ d q N) (eVec i) d)) (List.range (j + 1))) :=
      Qeq_trans
        (qHil_den_pos (pVec μ d q N) (combVec (List.range (j + 1)) (fun i => q j i) eVec)
          hPden (combVec_den (List.range (j + 1)) (fun i => q j i) eVec (fun i => hqd j i)
            (fun i idx => eVec_den i idx)) d)
        (qHil_congr_right (pVec μ d q N) (q j)
          (combVec (List.range (j + 1)) (fun i => q j i) eVec) d hexp)
        (qHil_combVec_right (fun i => q j i) eVec (pVec μ d q N) (fun i => hqd j i)
          (fun i idx => eVec_den i idx) hPden d (List.range (j + 1)))
    have hSg : Qeq (Lam μ (q j) d)
        (qsumL (fun i => mul (q j i) (μ i)) (List.range (j + 1))) :=
      Qeq_trans (b := qsumL (fun i => mul (q j i) (Lam μ (eVec i) d)) (List.range (j + 1)))
        (qsumL_den _ (fun i => Qmul_den_pos (hqd j i)
          (Lam_den μ (eVec i) (eVec_den i) hμ d)) (List.range (j + 1)))
        (Qeq_trans (Lam_den μ (combVec (List.range (j + 1)) (fun i => q j i) eVec)
            (combVec_den (List.range (j + 1)) (fun i => q j i) eVec (fun i => hqd j i)
              (fun i idx => eVec_den i idx)) hμ d)
          (Lam_congr μ (q j) (combVec (List.range (j + 1)) (fun i => q j i) eVec) d hexp)
          (Lam_combVec μ (fun i => q j i) eVec hμ (fun i => hqd j i)
            (fun i idx => eVec_den i idx) d (List.range (j + 1))))
        (qsumL_congr_mem (List.range (j + 1)) (fun i hi => Qmul_congr (Qeq_refl _)
          (Lam_eVec μ hμ d i (by have := List.mem_range.mp hi; omega))))
    -- `Σf ≈ Σg` (via `hSf`, `hbasis`, `hSg`).
    have hFG : Qeq (qsumL (fun i => mul (q j i) (qHil (pVec μ d q N) (eVec i) d)) (List.range (j + 1)))
        (qsumL (fun i => mul (q j i) (μ i)) (List.range (j + 1))) :=
      Qeq_trans (qHil_den_pos (pVec μ d q N) (q j) hPden (hqd j) d)
        (Qeq_symm hSf) (Qeq_trans (Lam_den μ (q j) (hqd j) hμ d) hbasis hSg)
    -- the defect combination `Σ_{i≤j} (q_j)_i·(⟨p_N,x^i⟩ − μ_i)`.
    have hden_defect : ∀ i, 0 < (mul (q j i) (Qsub (qHil (pVec μ d q N) (eVec i) d) (μ i))).den :=
      fun i => Qmul_den_pos (hqd j i) (Qsub_den_pos (hhden i) (hμ i))
    have hTerm0 : Qeq
        (qsumL (fun i => mul (q j i) (Qsub (qHil (pVec μ d q N) (eVec i) d) (μ i)))
          (List.range (j + 1))) (⟨0, 1⟩ : Q) :=
      Qeq_trans (b := Qsub
          (qsumL (fun i => mul (q j i) (qHil (pVec μ d q N) (eVec i) d)) (List.range (j + 1)))
          (qsumL (fun i => mul (q j i) (μ i)) (List.range (j + 1))))
        (Qsub_den_pos
          (qsumL_den _ (fun i => Qmul_den_pos (hqd j i) (hhden i)) (List.range (j + 1)))
          (qsumL_den _ (fun i => Qmul_den_pos (hqd j i) (hμ i)) (List.range (j + 1))))
        (Qeq_trans
          (qsumL_den _ (fun i => Qsub_den_pos (Qmul_den_pos (hqd j i) (hhden i))
            (Qmul_den_pos (hqd j i) (hμ i))) (List.range (j + 1)))
          (qsumL_congr (fun i => Qmul_sub_distrib (q j i) (qHil (pVec μ d q N) (eVec i) d) (μ i))
            (List.range (j + 1)))
          (qsumL_sub (fun i => mul (q j i) (qHil (pVec μ d q N) (eVec i) d))
            (fun i => mul (q j i) (μ i)) (fun i => Qmul_den_pos (hqd j i) (hhden i))
            (fun i => Qmul_den_pos (hqd j i) (hμ i)) (List.range (j + 1))))
        (Qsub_self_zero hFG)
    -- the same combination collapses to its leading term (IH kills `i < j`).
    have hTermj : Qeq
        (qsumL (fun i => mul (q j i) (Qsub (qHil (pVec μ d q N) (eVec i) d) (μ i)))
          (List.range (j + 1)))
        (mul (q j j) (Qsub (qHil (pVec μ d q N) (eVec j) d) (μ j))) :=
      qsumL_range_single (fun i => mul (q j i) (Qsub (qHil (pVec μ d q N) (eVec i) d) (μ i)))
        hden_defect j (j + 1) (Nat.lt_succ_self j)
        (fun i hi hij => Qmul_zero_of_right
          (Qsub_self_zero (ih i (by omega) (by omega))))
    -- leading term is `0`; leading coefficient is `≉ 0`; no zero divisors close it.
    exact Qsub_zero_imp_eq (Qmul_no_zero_div (hmonic j hjd)
      (Qeq_trans (qsumL_den _ hden_defect (List.range (j + 1))) (Qeq_symm hTermj) hTerm0))

end Multiplicity.UOR.Bridge.F1Square.Square
