/-
F1 square — **the Riesz realization identity** (`RieszRealize.lean`), the fourth brick of the
moment-realization sub-arc and its mathematical core. The degree-`N` Riesz projection realizes the
moment functional against the orthogonal basis, and — by a strong induction dissolving the
change-of-basis — against every monomial up to degree `N`:

  `realize_basis`  :  `l ≤ N  ⟹  ⟨p_N, q_l⟩_d = Λ_μ(q_l)`
  `realize_moment` :  `j ≤ N  ⟹  ⟨p_N, x^j⟩_d = μ_j`

`realize_basis` is a one-line collapse: expand `p_N = Σ_k aCoef_k q_k` (`qHil_combVec_left`), kill the
off-diagonal by orthogonality (`qsumL_range_single`), cancel the diagonal (`aCoef_cancel`). The
realization `realize_moment` is a strong induction on `j`: writing `q_j = Σ_{i≤j} (q_j)_i x^i` (its own
coefficient expansion, `vec_self_expand`), both `⟨p_N,q_j⟩` and `Λ_μ(q_j)` split into a low part
(handled by the induction hypothesis and cancelling) plus the leading term, which the monic
normalization isolates as `⟨p_N,x^j⟩ = μ_j` — no explicit Hilbert-matrix inverse is ever built.

HONEST SCOPE. The realization identity for the *finite* Riesz projection at a *fixed* dimension `d`,
under the orthogonal-family invariants supplied as hypotheses. This is NOT Parseval, NOT the L²-limit
/ convergence (which additionally needs a dimension-independent family and a supplied Bessel
convergence modulus — later bricks), NOT positivity. Step 4 (band-coupling positivity) is RH; the crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1.Square.RieszCoeff
import Multiplicity.F1.Square.QHilEVec

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `b ≈ 0 ⟹ a·b ≈ 0` (local copy). -/
private theorem Qmul_zero_of_right {a b : Q} (hb : Qeq b (⟨0, 1⟩ : Q)) :
    Qeq (mul a b) (⟨0, 1⟩ : Q) := by
  have hbn : b.num = 0 := by simp only [Qeq] at hb; push_cast at hb; omega
  show a.num * b.num * ((1 : Nat) : Int) = 0 * ((a.den * b.den : Nat) : Int)
  rw [hbn]; push_cast; ring_uor

/-- `mul a ⟨1,1⟩ ≈ a` for a positive-denominator `a`. -/
private theorem Qmul_one_r {a : Q} (ha : 0 < a.den) : Qeq (mul a (⟨1, 1⟩ : Q)) a :=
  Qeq_trans (b := mul (⟨1, 1⟩ : Q) a) (Qmul_den_pos (by decide) ha)
    (Qmul_comm a (⟨1, 1⟩ : Q)) (Qone_mul a)

-- ===========================================================================
-- Realization against the orthogonal basis.
-- ===========================================================================

/-- **The Riesz projection realizes `Λ_μ` on the basis**: `⟨p_N, q_l⟩_d = Λ_μ(q_l)` for `l ≤ N`. Expand
    `p_N` over the basis, kill the off-diagonal by orthogonality, cancel the diagonal. -/
theorem realize_basis (μ : Nat → Q) (d : Nat) (q : Nat → (Nat → Q))
    (hqd : ∀ k idx, 0 < (q k idx).den) (hμ : ∀ i, 0 < (μ i).den)
    (hqorth : ∀ a b, a < d → b < d → a ≠ b → Qeq (qHil (q a) (q b) d) (⟨0, 1⟩ : Q))
    (hmonic : ∀ k, k < d → ¬ Qeq (q k k) (⟨0, 1⟩ : Q))
    (N l : Nat) (hNd : N < d) (hl : l ≤ N) :
    Qeq (qHil (pVec μ d q N) (q l) d) (Lam μ (q l) d) := by
  have hld : l < d := by omega
  have hposl : 0 < (qHil (q l) (q l) d).num := qHil_self_num_pos q hqd d l hld (hmonic l hld)
  show Qeq (qHil (combVec (List.range (N + 1)) (aCoef μ d q) q) (q l) d) (Lam μ (q l) d)
  refine Qeq_trans
    (b := qsumL (fun k => mul (aCoef μ d q k) (qHil (q k) (q l) d)) (List.range (N + 1)))
    (qsumL_den _ (fun k => Qmul_den_pos (aCoef_den μ d q hqd hμ k)
      (qHil_den_pos (q k) (q l) (hqd k) (hqd l) d)) (List.range (N + 1)))
    (qHil_combVec_left (aCoef μ d q) q (q l) (fun k => aCoef_den μ d q hqd hμ k) hqd (hqd l) d
      (List.range (N + 1)))
    ?_
  refine Qeq_trans (b := mul (aCoef μ d q l) (qHil (q l) (q l) d))
    (Qmul_den_pos (aCoef_den μ d q hqd hμ l) (qHil_den_pos (q l) (q l) (hqd l) (hqd l) d))
    (qsumL_range_single (fun k => mul (aCoef μ d q k) (qHil (q k) (q l) d))
      (fun k => Qmul_den_pos (aCoef_den μ d q hqd hμ k)
        (qHil_den_pos (q k) (q l) (hqd k) (hqd l) d)) l (N + 1) (by omega)
      (fun k hk hkl => Qmul_zero_of_right (hqorth k l (by omega) hld hkl)))
    (aCoef_cancel μ d q hqd hμ l hposl)

-- ===========================================================================
-- A vector equals its own coefficient expansion over the monomial basis.
-- ===========================================================================

/-- **Self-expansion**: a vector supported on `[0,j]` equals `Σ_{i≤j} c_i · x^i` — its own coefficient
    expansion over the monomial basis. -/
theorem vec_self_expand (c : Nat → Q) (hc : ∀ idx, 0 < (c idx).den)
    (j : Nat) (hjsupp : ∀ idx, j < idx → Qeq (c idx) (⟨0, 1⟩ : Q)) (idx : Nat) :
    Qeq (c idx) (combVec (List.range (j + 1)) (fun i => c i) eVec idx) := by
  show Qeq (c idx) (qsumL (fun i => mul (c i) (eVec i idx)) (List.range (j + 1)))
  by_cases hidx : idx < j + 1
  · -- idx ≤ j: the sum collapses to the i = idx term, which is c_idx · 1
    have hab : Qeq (c idx) (mul (c idx) (eVec idx idx)) := by
      rw [eVec_self]; exact Qeq_symm (Qmul_one_r (hc idx))
    refine Qeq_trans (b := mul (c idx) (eVec idx idx))
      (Qmul_den_pos (hc idx) (eVec_den idx idx)) hab ?_
    exact Qeq_symm (qsumL_range_single (fun i => mul (c i) (eVec i idx))
      (fun i => Qmul_den_pos (hc i) (eVec_den i idx)) idx (j + 1) hidx
      (fun i _ hiidx => Qmul_zero_of_right (eVec_ne (Ne.symm hiidx))))
  · -- idx > j: c_idx ≈ 0 (support) and every term vanishes (i ≤ j < idx ⟹ i ≠ idx)
    have hgt : j < idx := by omega
    refine Qeq_trans (b := (⟨0, 1⟩ : Q)) (by decide) (hjsupp idx hgt) ?_
    exact Qeq_symm (qsumL_zero_mem (List.range (j + 1)) (fun i hi =>
      Qmul_zero_of_right (eVec_ne (Ne.symm (Nat.ne_of_lt
        (by have := List.mem_range.mp hi; omega : i < idx))))))

end Multiplicity.UOR.Bridge.F1Square.Square
