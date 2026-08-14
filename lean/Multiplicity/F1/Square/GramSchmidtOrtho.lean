/-
F1 square — **the Gram–Schmidt orthogonality step** (`GramSchmidtOrtho.lean`), the mathematical heart
of brick 3 of the Hausdorff *sufficiency* arc. Given a family `q_0,…,q_{m-1}` that is mutually
orthogonal with positive self-norms, the next vector `q_m = e_m − Σ_{i<m} cf_i q_i` is orthogonal to
every earlier `q_j`:

  `nextVec_ortho` :  `j < m  ⟹  ⟨q_j, nextVec⟩_d = 0`.

The computation is the classical one, now in the certified symmetric-bilinear `qHil`: expand the
projection in the second argument (`qHil_add_right` + `qHil_neg_right` + `qHil_combVec_right`), collapse
the resulting sum to its diagonal term (`qsumL_erase` against the induction's off-diagonal vanishing),
cancel it with `projCoef_cancel` (`cf_j·⟨q_j,q_j⟩ = ⟨e_m,q_j⟩`), and flip the surviving term with
symmetry (`qHil_comm`) so it annihilates: `⟨q_j,e_m⟩ − ⟨e_m,q_j⟩ = 0`.

HONEST SCOPE. The single orthogonality *step* only (one new vector against the earlier ones), under
the induction hypotheses supplied as arguments. This is NOT yet the full family (the existential
induction that assembles it — the next brick), NOT positivity. Step 4 (band-coupling positivity) is
RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1Square.Square.GramSchmidt
import Multiplicity.F1Square.Square.QHilbertComb
import Multiplicity.F1Square.Square.QHilbertSymm

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Local ℚ helpers (private).
-- ===========================================================================

private theorem Qmul_zero_of_right {a b : Q} (hb : Qeq b (⟨0, 1⟩ : Q)) :
    Qeq (mul a b) (⟨0, 1⟩ : Q) := by
  have hbn : b.num = 0 := by simp only [Qeq] at hb; push_cast at hb; omega
  show a.num * b.num * ((1 : Nat) : Int) = 0 * ((a.den * b.den : Nat) : Int)
  rw [hbn]; push_cast; ring_uor

private theorem Qadd_neg_self (a : Q) : Qeq (add a (neg a)) (⟨0, 1⟩ : Q) := by
  simp only [Qeq, add, neg]; push_cast; ring_uor

/-- **Single-term collapse over `range m`** (choice-free): if `f` vanishes off the index `j < m`,
    then `Σ_{i<m} f i ≈ f j`. Induction on `m` peeling the top element via `List.range_succ`
    (avoiding the choice-tainted `List.nodup_range`/`Nodup.not_mem_erase`). -/
private theorem qsumL_range_single (f : Nat → Q) (hf : ∀ i, 0 < (f i).den) (j : Nat) :
    ∀ m, j < m → (∀ l, l < m → l ≠ j → Qeq (f l) (⟨0, 1⟩ : Q)) →
      Qeq (qsumL f (List.range m)) (f j)
  | 0, hj, _ => absurd hj (Nat.not_lt_zero j)
  | (m + 1), _, hz => by
    rw [List.range_succ]
    refine Qeq_trans (b := add (qsumL f (List.range m)) (qsumL f [m]))
      (add_den_pos (qsumL_den f hf (List.range m)) (qsumL_den f hf [m]))
      (qsumL_append f hf (List.range m) [m]) ?_
    by_cases hjm : j < m
    · -- `j < m`: the low block collapses to `f j` (IH); the top term `f m` vanishes (`m ≠ j`).
      have hIH : Qeq (qsumL f (List.range m)) (f j) :=
        qsumL_range_single f hf j m hjm (fun l hl hlj => hz l (Nat.lt_succ_of_lt hl) hlj)
      have hfm0 : Qeq (qsumL f [m]) (⟨0, 1⟩ : Q) :=
        Qeq_trans (hf m) (Qadd_zero_right (f m))
          (hz m (Nat.lt_succ_self m) (fun heq => absurd heq.symm (Nat.ne_of_lt hjm)))
      exact Qeq_trans (b := add (f j) (⟨0, 1⟩ : Q)) (add_den_pos (hf j) (by decide))
        (Qadd_congr hIH hfm0) (Qadd_zero_right (f j))
    · -- `j = m`: the low block vanishes (every `l < m` has `l ≠ j = m`); the top term is `f j`.
      have hjeq : j = m := by omega
      subst hjeq
      have hzero : Qeq (qsumL f (List.range j)) (⟨0, 1⟩ : Q) :=
        qsumL_zero_mem (List.range j) (fun l hl =>
          hz l (Nat.lt_succ_of_lt (List.mem_range.mp hl)) (Nat.ne_of_lt (List.mem_range.mp hl)))
      have hfj : Qeq (qsumL f [j]) (f j) := Qadd_zero_right (f j)
      exact Qeq_trans (b := add (⟨0, 1⟩ : Q) (f j)) (add_den_pos (by decide) (hf j))
        (Qadd_congr hzero hfj) (Qzero_add (f j))

-- ===========================================================================
-- The orthogonality step.
-- ===========================================================================

set_option maxHeartbeats 1000000 in
/-- **★ THE ORTHOGONALITY STEP**: with `q_0,…,q_{m-1}` mutually orthogonal and `⟨q_j,q_j⟩ > 0`, the next
    Gram–Schmidt vector is orthogonal to each earlier `q_j`: `⟨q_j, nextVec⟩_d = 0`. -/
theorem nextVec_ortho (d m j : Nat) (q : Nat → (Nat → Q)) (hqd : ∀ k idx, 0 < (q k idx).den)
    (hqorth : ∀ a b, a < m → b < m → a ≠ b → Qeq (qHil (q a) (q b) d) (⟨0, 1⟩ : Q))
    (hjm : j < m) (hposj : 0 < (qHil (q j) (q j) d).num) :
    Qeq (qHil (q j) (nextVec d m q) d) (⟨0, 1⟩ : Q) := by
  -- denominator facts, reused throughout
  have hcfden : ∀ i, 0 < (projCoef d m q i).den := fun i => projCoef_den d m q hqd i
  have hcombden : ∀ idx, 0 < (combVec (List.range m) (projCoef d m q) q idx).den :=
    fun idx => combVec_den (List.range m) (projCoef d m q) q hcfden hqd idx
  have hAden : 0 < (qHil (q j) (eVec m) d).den := qHil_den_pos (q j) (eVec m) (hqd j) (eVec_den m) d
  have hEAden : 0 < (qHil (eVec m) (q j) d).den := qHil_den_pos (eVec m) (q j) (eVec_den m) (hqd j) d
  have hSden : 0 < (qsumL (fun i => mul (projCoef d m q i) (qHil (q j) (q i) d))
      (List.range m)).den :=
    qsumL_den _ (fun i => Qmul_den_pos (hcfden i) (qHil_den_pos (q j) (q i) (hqd j) (hqd i) d))
      (List.range m)
  have hfjden : 0 < (mul (projCoef d m q j) (qHil (q j) (q j) d)).den :=
    Qmul_den_pos (hcfden j) (qHil_den_pos (q j) (q j) (hqd j) (hqd j) d)
  -- Step 1+2: expand the projection in the second argument.
  have h12 : Qeq (qHil (q j) (nextVec d m q) d)
      (add (qHil (q j) (eVec m) d)
        (neg (qHil (q j) (combVec (List.range m) (projCoef d m q) q) d))) :=
    Qeq_trans (b := add (qHil (q j) (eVec m) d)
        (qHil (q j) (fun idx => neg (combVec (List.range m) (projCoef d m q) q idx)) d))
      (add_den_pos hAden
        (qHil_den_pos (q j) _ (hqd j) (fun idx => neg_den_pos (hcombden idx)) d))
      (qHil_add_right (q j) (eVec m) (fun idx => neg (combVec (List.range m) (projCoef d m q) q idx))
        (hqd j) (eVec_den m) (fun idx => neg_den_pos (hcombden idx)) d)
      (Qadd_congr (Qeq_refl _)
        (qHil_neg_right (q j) (combVec (List.range m) (projCoef d m q) q) (hqd j) hcombden d))
  -- Step 3: the residual pairing is the sum `Σ_{i<m} cf_i·⟨q_j,q_i⟩`.
  have hPS : Qeq (qHil (q j) (combVec (List.range m) (projCoef d m q) q) d)
      (qsumL (fun i => mul (projCoef d m q i) (qHil (q j) (q i) d)) (List.range m)) :=
    qHil_combVec_right (projCoef d m q) q (q j) hcfden hqd (hqd j) d (List.range m)
  -- Step 4: collapse the sum to its diagonal term (off-diagonal terms vanish by orthogonality).
  have hScollapse : Qeq (qsumL (fun i => mul (projCoef d m q i) (qHil (q j) (q i) d)) (List.range m))
      (mul (projCoef d m q j) (qHil (q j) (q j) d)) :=
    qsumL_range_single (fun i => mul (projCoef d m q i) (qHil (q j) (q i) d))
      (fun i => Qmul_den_pos (hcfden i) (qHil_den_pos (q j) (q i) (hqd j) (hqd i) d)) j m hjm
      (fun l hlm hlj => Qmul_zero_of_right (hqorth j l hjm hlm (Ne.symm hlj)))
  -- Step 5: the diagonal term cancels to `⟨e_m,q_j⟩`.
  have hcancel : Qeq (mul (projCoef d m q j) (qHil (q j) (q j) d)) (qHil (eVec m) (q j) d) :=
    projCoef_cancel d m q hqd j hposj
  -- Step 6: `⟨q_j,e_m⟩ = ⟨e_m,q_j⟩` (symmetry), so the two survivors annihilate.
  have hcomm : Qeq (qHil (q j) (eVec m) d) (qHil (eVec m) (q j) d) :=
    qHil_comm (q j) (eVec m) (hqd j) (eVec_den m) d
  -- Assemble: `⟨q_j,nextVec⟩ ≈ A − P ≈ A − S ≈ A − fj ≈ A − ⟨e_m,q_j⟩ ≈ ⟨e_m,q_j⟩ − ⟨e_m,q_j⟩ ≈ 0`.
  refine Qeq_trans (b := add (qHil (q j) (eVec m) d)
      (neg (qHil (q j) (combVec (List.range m) (projCoef d m q) q) d)))
    (add_den_pos hAden (neg_den_pos (qHil_den_pos (q j) _ (hqd j) hcombden d))) h12 ?_
  refine Qeq_trans (b := add (qHil (eVec m) (q j) d) (neg (qHil (eVec m) (q j) d)))
    (add_den_pos hEAden (neg_den_pos hEAden)) ?_ (Qadd_neg_self (qHil (eVec m) (q j) d))
  refine Qadd_congr hcomm ?_
  exact Qneg_congr (Qeq_trans hSden hPS (Qeq_trans hfjden hScollapse hcancel))

end Multiplicity.UOR.Bridge.F1Square.Square
