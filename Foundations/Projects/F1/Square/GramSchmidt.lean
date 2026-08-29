/-
F1 square — **the Gram–Schmidt construction, foundations** (`GramSchmidt.lean`), the reusable core of
brick 3 of the Hausdorff *sufficiency* arc. To build the orthogonal polynomials `q_k` of the moment
problem we need: the monomial basis vectors, the projection coefficient `cf_i = ⟨e_m,q_i⟩/⟨q_i,q_i⟩`
with its inverse-cancellation law, and the "next vector" `q_m = e_m − Σ_{i<m} cf_i q_i` with its three
structural properties. This file supplies exactly those, so the orthogonality induction (next brick)
is a clean wiring:

  `eVec k`            : the `k`-th monomial coefficient vector `x^k`
  `projCoef d m q i`  : `⟨e_m, q_i⟩_d / ⟨q_i, q_i⟩_d`
  `projCoef_cancel`   : `cf_i · ⟨q_i,q_i⟩ = ⟨e_m,q_i⟩`   (the `Qinv` cancellation)
  `nextVec d m q`     : `e_m − Σ_{i<m} cf_i q_i`
  `nextVec_den`       : positive denominators
  `nextVec_support`   : vanishes strictly above index `m` (given `q_i` supported on `[0,i]`)
  `nextVec_monic`     : is `≉ 0` at index `m` (leading coefficient `1`)

HONEST SCOPE. The construction's *foundations* only — the monomial basis, the projection coefficient
with its cancellation, and the next-vector with its den/support/monic. This is NOT yet the
orthogonality (the induction that proves `⟨q_i,q_j⟩ = 0` for `i≠j` — the next brick), NOT positivity.
Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.QHilbertComb
import Foundations.F1.Square.QHilbertPos

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Small ℚ zero laws (private).
-- ===========================================================================

/-- `b ≈ 0 ⟹ a·b ≈ 0` — no denominator hypothesis on `a`. -/
private theorem Qmul_zero_of_right {a b : Q} (hb : Qeq b (⟨0, 1⟩ : Q)) :
    Qeq (mul a b) (⟨0, 1⟩ : Q) := by
  have hbn : b.num = 0 := by simp only [Qeq] at hb; push_cast at hb; omega
  show a.num * b.num * ((1 : Nat) : Int) = 0 * ((a.den * b.den : Nat) : Int)
  rw [hbn]; push_cast; ring_uor

private theorem Qadd_zero_z {a b : Q} (ha : Qeq a (⟨0, 1⟩ : Q)) (hb : Qeq b (⟨0, 1⟩ : Q)) :
    Qeq (add a b) (⟨0, 1⟩ : Q) :=
  Qeq_trans (b := add (⟨0, 1⟩ : Q) (⟨0, 1⟩ : Q)) (by decide) (Qadd_congr ha hb) (by decide)

private theorem Qneg_zero_z {a : Q} (ha : Qeq a (⟨0, 1⟩ : Q)) : Qeq (neg a) (⟨0, 1⟩ : Q) := by
  simp only [Qeq, neg] at ha ⊢; push_cast at ha ⊢; omega

-- ===========================================================================
-- The monomial basis vectors.
-- ===========================================================================

/-- The `k`-th monomial coefficient vector `x^k`: `1` at index `k`, `0` elsewhere. -/
def eVec (k : Nat) : Nat → Q := fun i => if i = k then (⟨1, 1⟩ : Q) else (⟨0, 1⟩ : Q)

theorem eVec_den (k i : Nat) : 0 < (eVec k i).den := by
  simp only [eVec]; split <;> exact Nat.one_pos

theorem eVec_self (k : Nat) : eVec k k = (⟨1, 1⟩ : Q) := if_pos rfl

theorem eVec_ne {k i : Nat} (h : i ≠ k) : Qeq (eVec k i) (⟨0, 1⟩ : Q) := by
  show Qeq (if i = k then (⟨1, 1⟩ : Q) else (⟨0, 1⟩ : Q)) (⟨0, 1⟩ : Q)
  rw [if_neg h]; exact Qeq_refl _

/-- The leading value is apart from `0`. -/
theorem eVec_self_ne_zero (k : Nat) : ¬ Qeq (eVec k k) (⟨0, 1⟩ : Q) := by
  rw [eVec_self]; decide

-- ===========================================================================
-- The projection coefficient and its cancellation.
-- ===========================================================================

/-- The Gram–Schmidt projection coefficient `cf_i = ⟨e_m, q_i⟩_d / ⟨q_i, q_i⟩_d` — **guarded** so it is
    total (a positive denominator at every `i`): the real quotient where `⟨q_i,q_i⟩ > 0`, else `0`. The
    guard is inert on the constructed range (`i < m`, where `⟨q_i,q_i⟩ > 0`) and lets every downstream
    `∀ i` denominator hypothesis be discharged. -/
def projCoef (d m : Nat) (q : Nat → (Nat → Q)) (i : Nat) : Q :=
  if 0 < (qHil (q i) (q i) d).num then
    mul (qHil (eVec m) (q i) d) (Qinv (qHil (q i) (q i) d))
  else (⟨0, 1⟩ : Q)

theorem projCoef_den (d m : Nat) (q : Nat → (Nat → Q)) (hqd : ∀ k idx, 0 < (q k idx).den)
    (i : Nat) : 0 < (projCoef d m q i).den := by
  unfold projCoef
  by_cases h : 0 < (qHil (q i) (q i) d).num
  · rw [if_pos h]
    exact Qmul_den_pos (qHil_den_pos (eVec m) (q i) (eVec_den m) (hqd i) d) (Qinv_den_pos h)
  · rw [if_neg h]; exact Nat.one_pos

/-- **The `Qinv` cancellation**: `cf_i · ⟨q_i,q_i⟩ = ⟨e_m,q_i⟩` (on the constructed range, `⟨q_i,q_i⟩>0`). -/
theorem projCoef_cancel (d m : Nat) (q : Nat → (Nat → Q)) (hqd : ∀ k idx, 0 < (q k idx).den)
    (i : Nat) (hpos : 0 < (qHil (q i) (q i) d).num) :
    Qeq (mul (projCoef d m q i) (qHil (q i) (q i) d)) (qHil (eVec m) (q i) d) := by
  unfold projCoef; rw [if_pos hpos]
  -- `(A · B⁻¹) · B = A · (B⁻¹ · B) = A · 1 = A`, with `A = ⟨e_m,q_i⟩`, `B = ⟨q_i,q_i⟩`.
  refine Qeq_trans (b := mul (qHil (eVec m) (q i) d)
      (mul (Qinv (qHil (q i) (q i) d)) (qHil (q i) (q i) d)))
    (Qmul_den_pos (qHil_den_pos (eVec m) (q i) (eVec_den m) (hqd i) d)
      (Qmul_den_pos (Qinv_den_pos hpos) (qHil_den_pos (q i) (q i) (hqd i) (hqd i) d)))
    (Qmul_assoc (qHil (eVec m) (q i) d) (Qinv (qHil (q i) (q i) d)) (qHil (q i) (q i) d)) ?_
  refine Qeq_trans (b := mul (qHil (eVec m) (q i) d) (⟨1, 1⟩ : Q))
    (Qmul_den_pos (qHil_den_pos (eVec m) (q i) (eVec_den m) (hqd i) d) (by decide))
    (Qmul_congr (Qeq_refl _)
      (Qeq_trans (b := mul (qHil (q i) (q i) d) (Qinv (qHil (q i) (q i) d)))
        (Qmul_den_pos (qHil_den_pos (q i) (q i) (hqd i) (hqd i) d) (Qinv_den_pos hpos))
        (Qmul_comm (Qinv (qHil (q i) (q i) d)) (qHil (q i) (q i) d)) (Qmul_Qinv hpos)))
    (Qeq_trans (b := mul (⟨1, 1⟩ : Q) (qHil (eVec m) (q i) d)) (by
        exact Qmul_den_pos (by decide) (qHil_den_pos (eVec m) (q i) (eVec_den m) (hqd i) d))
      (Qmul_comm (qHil (eVec m) (q i) d) (⟨1, 1⟩ : Q)) (Qone_mul (qHil (eVec m) (q i) d)))

-- ===========================================================================
-- The next Gram–Schmidt vector `q_m = e_m − Σ_{i<m} cf_i q_i`.
-- ===========================================================================

/-- The next Gram–Schmidt vector: `e_m − Σ_{i<m} cf_i q_i` (as a coefficient vector). -/
def nextVec (d m : Nat) (q : Nat → (Nat → Q)) : Nat → Q :=
  fun idx => add (eVec m idx) (neg (combVec (List.range m) (projCoef d m q) q idx))

theorem nextVec_den (d m : Nat) (q : Nat → (Nat → Q)) (hqd : ∀ k idx, 0 < (q k idx).den)
    (idx : Nat) : 0 < (nextVec d m q idx).den :=
  add_den_pos (eVec_den m idx)
    (neg_den_pos (combVec_den (List.range m) (projCoef d m q) q
      (fun i => projCoef_den d m q hqd i) hqd idx))

/-- The projection part vanishes strictly above index `m`, given each `q_i` is supported on `[0,i]`. -/
private theorem combVec_proj_zero (d m : Nat) (q : Nat → (Nat → Q))
    (hqsupp : ∀ k, k < m → ∀ jdx, k < jdx → Qeq (q k jdx) (⟨0, 1⟩ : Q))
    (idx : Nat) (hidx : m ≤ idx) :
    Qeq (combVec (List.range m) (projCoef d m q) q idx) (⟨0, 1⟩ : Q) := by
  show Qeq (qsumL (fun i => mul (projCoef d m q i) (q i idx)) (List.range m)) (⟨0, 1⟩ : Q)
  refine qsumL_zero_mem (List.range m) (fun i hi => ?_)
  have him : i < m := List.mem_range.mp hi
  exact Qmul_zero_of_right (hqsupp i him idx (Nat.lt_of_lt_of_le him hidx))

/-- **The next vector vanishes strictly above `m`** (leading degree `m`). -/
theorem nextVec_support (d m : Nat) (q : Nat → (Nat → Q))
    (hqsupp : ∀ k, k < m → ∀ jdx, k < jdx → Qeq (q k jdx) (⟨0, 1⟩ : Q))
    (idx : Nat) (hidx : m < idx) : Qeq (nextVec d m q idx) (⟨0, 1⟩ : Q) := by
  refine Qadd_zero_z (eVec_ne (Ne.symm (Nat.ne_of_lt hidx)))
    (Qneg_zero_z (combVec_proj_zero d m q hqsupp idx (Nat.le_of_lt hidx)))

/-- **The next vector is `≉ 0` at index `m`** (leading coefficient `1`). -/
theorem nextVec_monic (d m : Nat) (q : Nat → (Nat → Q)) (hqd : ∀ k idx, 0 < (q k idx).den)
    (hqsupp : ∀ k, k < m → ∀ jdx, k < jdx → Qeq (q k jdx) (⟨0, 1⟩ : Q)) :
    ¬ Qeq (nextVec d m q m) (⟨0, 1⟩ : Q) := by
  -- `nextVec_m = e_m[m] + (−projection[m]) ≈ 1 + 0 = 1 ≉ 0`
  have hproj : Qeq (neg (combVec (List.range m) (projCoef d m q) q m)) (⟨0, 1⟩ : Q) :=
    Qneg_zero_z (combVec_proj_zero d m q hqsupp m (Nat.le_refl m))
  have heq : Qeq (nextVec d m q m) (⟨1, 1⟩ : Q) := by
    show Qeq (add (eVec m m) (neg (combVec (List.range m) (projCoef d m q) q m))) (⟨1, 1⟩ : Q)
    rw [eVec_self]
    refine Qeq_trans (b := add (⟨1, 1⟩ : Q) (⟨0, 1⟩ : Q))
      (by decide) (Qadd_congr (Qeq_refl _) hproj) (by decide)
  intro hz
  have hcontra : Qeq (⟨1, 1⟩ : Q) (⟨0, 1⟩ : Q) :=
    Qeq_trans (nextVec_den d m q hqd m) (Qeq_symm heq) hz
  exact (by decide : ¬ Qeq (⟨1, 1⟩ : Q) (⟨0, 1⟩ : Q)) hcontra

end Multiplicity.UOR.Bridge.F1Square.Square
