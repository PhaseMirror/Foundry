/-
F1 square — **the Bessel partial norm and the tail identity** (`BesselPartialNorm.lean`), the closing
brick of the moment-realization sub-arc — it exhibits the rational Riesz–Fischer modulus in its classical
shape. The `ℚ`-squared-distance `besselDiffNorm` (the coda's checkable modulus datum) is exactly the
*tail* of the Bessel sum:

  `pNorm μ N`               :  `qHil p_N p_N (N+1)` — the rational squared norm `‖p_N‖²`;
  `pNorm_parseval`          :  `‖p_N‖² = Σ_{k≤N} aCoef_k · (aCoef_k · ⟨q_k,q_k⟩)` — the Bessel sum;
  `besselDiffNorm_eq_pNorm_sub` :  `j ≤ k  ⟹  besselDiffNorm μ j k = ‖p_k‖² − ‖p_j‖²`.

So the coda's modulus condition `besselDiffNorm μ j k ≤ (1/(j+1)+1/(k+1))²` is precisely the statement
that the Bessel partial sums `‖p_N‖² = Σ aCoef_k²‖q_k‖²` form a `ℚ`-Cauchy (convergent) sequence at the
framework rate — the classical Hausdorff/Riesz–Fischer validity condition for a moment sequence, now
exact and rational.

The tail identity rests on `pVec_diff_normSq` (brick 5.5) after fixing the difference's orientation
(`qHil` squared-difference symmetry) and pinning each squared norm to its minimal dimension (`pNorm`
dimension-independence, from `pVec_dim_inv` + `qHil_trunc_eq`); both use the new `qHil_congr`
(pointwise-`Qeq` congruence of the Hilbert form).

HONEST SCOPE. The recognizable *rational* shape of the constructive Riesz–Fischer input, unconditional
finite ℚ arithmetic. This does NOT remove the conditionality of the realization (the modulus is still a
supplied, audit-visible hypothesis), NOT surjectivity onto arbitrary sequences, NOT positivity. Step 4
(band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.RieszBessel
import Foundations.F1.Square.RieszParseval
import Foundations.F1.Square.RieszDimInv
import Foundations.F1.Square.BesselCauchyModulus

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Congruence of the rational Hilbert form (public), and small helpers.
-- ===========================================================================

/-- The inner sum respects pointwise `Qeq`. -/
private theorem innerHil_congr {c c₂ : Nat → Q} (h : ∀ i, Qeq (c i) (c₂ i)) (d j : Nat) :
    Qeq (innerHil c d j) (innerHil c₂ d j) :=
  qsumL_congr (fun i => Qmul_congr (h i) (Qeq_refl _)) (List.range d)

/-- **★ `qHil` CONGRUENCE**: pointwise `Qeq` in each coefficient vector gives `Qeq` of the forms. -/
theorem qHil_congr {c c' c₂ c'₂ : Nat → Q} (hc : ∀ i, Qeq (c i) (c₂ i))
    (hc' : ∀ j, Qeq (c' j) (c'₂ j)) (d : Nat) :
    Qeq (qHil c c' d) (qHil c₂ c'₂ d) :=
  qsumL_congr (fun j => Qmul_congr (hc' j) (innerHil_congr hc d j)) (List.range d)

/-- `b ≈ 0 ⟹ a·b ≈ 0`. -/
private theorem Qmul_zero_of_right {a b : Q} (hb : Qeq b (⟨0, 1⟩ : Q)) :
    Qeq (mul a b) (⟨0, 1⟩ : Q) := by
  have hbn : b.num = 0 := by simp only [Qeq] at hb; push_cast at hb; omega
  show a.num * b.num * ((1 : Nat) : Int) = 0 * ((a.den * b.den : Nat) : Int)
  rw [hbn]; push_cast; ring_uor

/-- The Riesz projection vanishes strictly above its degree. -/
private theorem pVec_support (μ : Nat → Q) (d N idx : Nat) (hidx : N < idx) :
    Qeq (pVec μ d gsFam N idx) (⟨0, 1⟩ : Q) := by
  show Qeq (qsumL (fun k => mul (aCoef μ d gsFam k) (gsFam k idx)) (List.range (N + 1))) (⟨0, 1⟩ : Q)
  refine qsumL_zero_mem (List.range (N + 1)) (fun k hk => ?_)
  have hkN : k ≤ N := by have := List.mem_range.mp hk; omega
  exact Qmul_zero_of_right (gsFam_support k idx (by omega))

/-- `Qsub a b ≈ neg (Qsub b a)` (pointwise sign flip). -/
private theorem Qsub_neg_swap (a b : Q) : Qeq (Qsub a b) (neg (Qsub b a)) := by
  simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor

/-- Double negation. -/
private theorem Qneg_neg (a : Q) : Qeq (neg (neg a)) a := by
  simp only [Qeq, neg]; push_cast; ring_uor

-- ===========================================================================
-- The Bessel partial norm and its Parseval form.
-- ===========================================================================

/-- **The rational Bessel partial norm** `‖p_N‖² = qHil p_N p_N (N+1)`, at the projection's minimal
    dimension. -/
def pNorm (μ : Nat → Q) (N : Nat) : Q :=
  qHil (pVec μ (N + 1) gsFam N) (pVec μ (N + 1) gsFam N) (N + 1)

/-- **★ THE BESSEL SUM**: `‖p_N‖² = Σ_{k≤N} aCoef_k · (aCoef_k · ⟨q_k,q_k⟩)` — the projection's squared
    norm is the finite Bessel sum. -/
theorem pNorm_parseval (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den) (N : Nat) :
    Qeq (pNorm μ N)
      (qsumL (fun k => mul (aCoef μ (N + 1) gsFam k)
        (mul (aCoef μ (N + 1) gsFam k) (qHil (gsFam k) (gsFam k) (N + 1)))) (List.range (N + 1))) :=
  parseval_norm μ (N + 1) gsFam gsFam_den hμ
    (fun a b ha hb hab => gsFam_ortho a b hab (N + 1) ha hb) (fun k _ => gsFam_monic k)
    N (Nat.lt_succ_self N)

/-- **★ DIMENSION-INDEPENDENCE OF THE PARTIAL NORM**: `qHil p_N p_N d = ‖p_N‖²` for any `d > N`. -/
theorem pNorm_dim_inv (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den) (N d : Nat) (hNd : N < d) :
    Qeq (qHil (pVec μ d gsFam N) (pVec μ d gsFam N) d) (pNorm μ N) := by
  have hsupp : ∀ idx, N + 1 ≤ idx → Qeq (pVec μ (N + 1) gsFam N idx) (⟨0, 1⟩ : Q) :=
    fun idx hidx => pVec_support μ (N + 1) N idx (by omega)
  refine Qeq_trans (qHil_den_pos (pVec μ (N + 1) gsFam N) (pVec μ (N + 1) gsFam N)
      (pVec_den μ (N + 1) gsFam gsFam_den hμ N) (pVec_den μ (N + 1) gsFam gsFam_den hμ N) d)
    (qHil_congr (fun i => pVec_dim_inv μ hμ N d (N + 1) hNd (Nat.lt_succ_self N) i)
      (fun i => pVec_dim_inv μ hμ N d (N + 1) hNd (Nat.lt_succ_self N) i) d) ?_
  exact qHil_trunc_eq (pVec μ (N + 1) gsFam N) (pVec μ (N + 1) gsFam N)
    (pVec_den μ (N + 1) gsFam gsFam_den hμ N) (pVec_den μ (N + 1) gsFam gsFam_den hμ N)
    (N + 1) hsupp hsupp d (N + 1) hNd (Nat.le_refl (N + 1))

-- ===========================================================================
-- ★ The tail identity: the squared distance is the Bessel-sum tail.
-- ===========================================================================

/-- `qHil` of a pointwise difference is orientation-symmetric: `qHil (a−b)(a−b) = qHil (b−a)(b−a)`. -/
private theorem qHil_sqdiff_symm (a b : Nat → Q) (ha : ∀ i, 0 < (a i).den) (hb : ∀ i, 0 < (b i).den)
    (d : Nat) :
    Qeq (qHil (fun i => Qsub (a i) (b i)) (fun i => Qsub (a i) (b i)) d)
        (qHil (fun i => Qsub (b i) (a i)) (fun i => Qsub (b i) (a i)) d) := by
  have hd : ∀ i, 0 < ((fun i => Qsub (a i) (b i)) i).den :=
    fun i => add_den_pos (ha i) (neg_den_pos (hb i))
  have hnd : ∀ i, 0 < ((fun i => neg (Qsub (b i) (a i))) i).den :=
    fun i => neg_den_pos (add_den_pos (hb i) (neg_den_pos (ha i)))
  -- (a−b) ≈ neg(b−a) pointwise; then pull both negs out and cancel the double negation.
  refine Qeq_trans (qHil_den_pos _ _ hnd hnd d)
    (qHil_congr (fun i => Qsub_neg_swap (a i) (b i)) (fun i => Qsub_neg_swap (a i) (b i)) d) ?_
  refine Qeq_trans (b := neg (qHil (fun i => Qsub (b i) (a i))
      (fun i => neg (Qsub (b i) (a i))) d))
    (neg_den_pos (qHil_den_pos _ _ (fun i => add_den_pos (hb i) (neg_den_pos (ha i))) hnd d))
    (qHil_neg_left (fun i => Qsub (b i) (a i)) (fun i => neg (Qsub (b i) (a i)))
      (fun i => add_den_pos (hb i) (neg_den_pos (ha i))) hnd d) ?_
  refine Qeq_trans (b := neg (neg (qHil (fun i => Qsub (b i) (a i))
      (fun i => Qsub (b i) (a i)) d)))
    (neg_den_pos (neg_den_pos (qHil_den_pos _ _ (fun i => add_den_pos (hb i) (neg_den_pos (ha i)))
      (fun i => add_den_pos (hb i) (neg_den_pos (ha i))) d)))
    (Qneg_congr (qHil_neg_right (fun i => Qsub (b i) (a i)) (fun i => Qsub (b i) (a i))
      (fun i => add_den_pos (hb i) (neg_den_pos (ha i)))
      (fun i => add_den_pos (hb i) (neg_den_pos (ha i))) d)) ?_
  exact Qneg_neg _

/-- **★ THE TAIL IDENTITY**: for `j ≤ k`, the rational squared distance of the `j`-th and `k`-th Riesz
    projections is the tail of the Bessel sum — `besselDiffNorm μ j k = ‖p_k‖² − ‖p_j‖²`. -/
theorem besselDiffNorm_eq_pNorm_sub (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den) (j k : Nat) (hjk : j ≤ k) :
    Qeq (besselDiffNorm μ hμ j k) (Qsub (pNorm μ k) (pNorm μ j)) := by
  have hjd : j < j + k + 1 := by omega
  have hkd : k < j + k + 1 := by omega
  -- flip the difference's orientation to `p_k − p_j`
  refine Qeq_trans (qHil_den_pos _ _
      (fun i => add_den_pos (pVec_den μ (j + k + 1) gsFam gsFam_den hμ k i)
        (neg_den_pos (pVec_den μ (j + k + 1) gsFam gsFam_den hμ j i)))
      (fun i => add_den_pos (pVec_den μ (j + k + 1) gsFam gsFam_den hμ k i)
        (neg_den_pos (pVec_den μ (j + k + 1) gsFam gsFam_den hμ j i))) (j + k + 1))
    (qHil_sqdiff_symm (pVec μ (j + k + 1) gsFam j) (pVec μ (j + k + 1) gsFam k)
      (pVec_den μ (j + k + 1) gsFam gsFam_den hμ j) (pVec_den μ (j + k + 1) gsFam gsFam_den hμ k)
      (j + k + 1)) ?_
  -- the Bessel-tail identity at the common dimension, then pin each norm to its minimal dimension
  refine Qeq_trans (b := Qsub (qHil (pVec μ (j + k + 1) gsFam k) (pVec μ (j + k + 1) gsFam k) (j + k + 1))
      (qHil (pVec μ (j + k + 1) gsFam j) (pVec μ (j + k + 1) gsFam j) (j + k + 1)))
    (add_den_pos
      (qHil_den_pos _ _ (pVec_den μ (j + k + 1) gsFam gsFam_den hμ k)
        (pVec_den μ (j + k + 1) gsFam gsFam_den hμ k) (j + k + 1))
      (neg_den_pos (qHil_den_pos _ _ (pVec_den μ (j + k + 1) gsFam gsFam_den hμ j)
        (pVec_den μ (j + k + 1) gsFam gsFam_den hμ j) (j + k + 1))))
    (pVec_diff_normSq μ (j + k + 1) gsFam gsFam_den hμ
      (fun a b ha hb hab => gsFam_ortho a b hab (j + k + 1) ha hb) (fun m _ => gsFam_monic m)
      j k hjk hkd) ?_
  exact Qsub_congr (pNorm_dim_inv μ hμ k (j + k + 1) hkd) (pNorm_dim_inv μ hμ j (j + k + 1) hjd)

end Multiplicity.UOR.Bridge.F1Square.Square
