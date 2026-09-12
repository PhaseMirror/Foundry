/-
F1 square — **bilinearity of the rational Hilbert form** (`QHilbertBilinear.lean`), the algebraic
foundation of brick 3 of the Hausdorff *sufficiency* arc (the Gram–Schmidt orthogonalization of the
moment construction). The orthogonality proof expands `⟨q_k, q_j⟩` by linearity of `qHil` in each
coefficient-vector argument; this file supplies exactly those laws:

  `qHil_add_left`   : `qHil (a+b) c' d = qHil a c' d + qHil b c' d`
  `qHil_smul_left`  : `qHil (λ·a) c' d = λ · qHil a c' d`
  `qHil_neg_left`   : `qHil (−a) c' d = − qHil a c' d`
  `qHil_add_right`  : `qHil c (a+b) d = qHil c a d + qHil c b d`
  `qHil_smul_right` : `qHil c (λ·a) d = λ · qHil c a d`
  `qHil_neg_right`  : `qHil c (−a) d = − qHil c a d`

(vector `+`/`−`/`λ·` acting pointwise on the `Nat → Q` coefficient vectors). Each is a `Qeq` identity
proved by pushing the operation through the double `qsumL` (`qsumL_add`/`qsumL_smul`/`qsumL_neg`) plus
the scalar distributive/associative laws, factored through the inner-sum abbreviation `innerHil`.

HONEST SCOPE. The bilinearity laws of the *finite rational* Hilbert form only — the algebra the
orthogonalization consumes. This is NOT symmetry (`qHil c c' = qHil c' c`, which needs a `qsumL`
Fubini and is a separate brick), NOT the orthogonal-polynomial construction itself, NOT positivity.
Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.QHilbertForm

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Small ℚ scalar laws (private).
-- ===========================================================================

/-- Right distributivity `(a+b)·c = a·c + b·c`. -/
private theorem Qmul_add_right (a b c : Q) :
    Qeq (mul (add a b) c) (add (mul a c) (mul b c)) := by
  simp only [Qeq, mul, add]; push_cast; ring_uor

/-- `a·(b·c) = b·(a·c)` — left-commutativity of multiplication. -/
private theorem Qmul_left_comm (a b c : Q) :
    Qeq (mul a (mul b c)) (mul b (mul a c)) := by
  simp only [Qeq, mul]; push_cast; ring_uor

/-- `(−a)·c = −(a·c)`. -/
private theorem Qmul_neg_left (a c : Q) :
    Qeq (mul (neg a) c) (neg (mul a c)) := by
  simp only [Qeq, mul, neg]; push_cast; ring_uor

/-- `a·(−b) = −(a·b)`. -/
private theorem Qmul_neg_right (a b : Q) :
    Qeq (mul a (neg b)) (neg (mul a b)) := by
  simp only [Qeq, mul, neg]; push_cast; ring_uor

-- ===========================================================================
-- The inner sum `innerHil c d j = Σ_{i<d} c_i / (i+j+1)` and its linearity.
-- ===========================================================================

/-- The inner Hilbert sum at outer index `j`: `Σ_{i<d} c_i · 1/(i+j+1)`. `qHil c c' d` is definitionally
    `Σ_{j<d} c'_j · innerHil c d j`. -/
def innerHil (c : Nat → Q) (d j : Nat) : Q :=
  qsumL (fun i => mul (c i) (⟨1, i + j + 1⟩ : Q)) (List.range d)

/-- The inner sum keeps a positive denominator. -/
theorem innerHil_den (c : Nat → Q) (hc : ∀ i, 0 < (c i).den) (d j : Nat) :
    0 < (innerHil c d j).den :=
  qsumL_den _ (fun i => Qmul_den_pos (hc i) (Nat.succ_pos (i + j))) (List.range d)

/-- `qHil` in terms of `innerHil` (definitional). -/
theorem qHil_eq_innerHil (c c' : Nat → Q) (d : Nat) :
    qHil c c' d = qsumL (fun j => mul (c' j) (innerHil c d j)) (List.range d) := rfl

/-- Inner sum is additive in the coefficient vector. -/
theorem innerHil_add (a b : Nat → Q) (ha : ∀ i, 0 < (a i).den) (hb : ∀ i, 0 < (b i).den)
    (d j : Nat) :
    Qeq (innerHil (fun i => add (a i) (b i)) d j) (add (innerHil a d j) (innerHil b d j)) := by
  show Qeq (qsumL (fun i => mul (add (a i) (b i)) (⟨1, i + j + 1⟩ : Q)) (List.range d))
    (add (innerHil a d j) (innerHil b d j))
  refine Qeq_trans (b := qsumL (fun i => add (mul (a i) (⟨1, i + j + 1⟩ : Q))
      (mul (b i) (⟨1, i + j + 1⟩ : Q))) (List.range d))
    (qsumL_den _ (fun i => add_den_pos (Qmul_den_pos (ha i) (Nat.succ_pos (i + j)))
      (Qmul_den_pos (hb i) (Nat.succ_pos (i + j)))) (List.range d))
    (qsumL_congr (fun i => Qmul_add_right (a i) (b i) (⟨1, i + j + 1⟩ : Q)) (List.range d))
    (qsumL_add (fun i => mul (a i) (⟨1, i + j + 1⟩ : Q)) (fun i => mul (b i) (⟨1, i + j + 1⟩ : Q))
      (fun i => Qmul_den_pos (ha i) (Nat.succ_pos (i + j)))
      (fun i => Qmul_den_pos (hb i) (Nat.succ_pos (i + j))) (List.range d))

/-- Inner sum is homogeneous in the coefficient vector. -/
theorem innerHil_smul (l : Q) (a : Nat → Q) (hl : 0 < l.den) (ha : ∀ i, 0 < (a i).den)
    (d j : Nat) :
    Qeq (innerHil (fun i => mul l (a i)) d j) (mul l (innerHil a d j)) := by
  show Qeq (qsumL (fun i => mul (mul l (a i)) (⟨1, i + j + 1⟩ : Q)) (List.range d))
    (mul l (innerHil a d j))
  refine Qeq_trans (b := qsumL (fun i => mul l (mul (a i) (⟨1, i + j + 1⟩ : Q))) (List.range d))
    (qsumL_den _ (fun i => Qmul_den_pos hl (Qmul_den_pos (ha i) (Nat.succ_pos (i + j))))
      (List.range d))
    (qsumL_congr (fun i => Qmul_assoc l (a i) (⟨1, i + j + 1⟩ : Q)) (List.range d))
    (qsumL_smul l (fun i => mul (a i) (⟨1, i + j + 1⟩ : Q)) hl
      (fun i => Qmul_den_pos (ha i) (Nat.succ_pos (i + j))) (List.range d))

/-- Inner sum negates with the coefficient vector. -/
theorem innerHil_neg (a : Nat → Q) (ha : ∀ i, 0 < (a i).den) (d j : Nat) :
    Qeq (innerHil (fun i => neg (a i)) d j) (neg (innerHil a d j)) := by
  show Qeq (qsumL (fun i => mul (neg (a i)) (⟨1, i + j + 1⟩ : Q)) (List.range d))
    (neg (innerHil a d j))
  refine Qeq_trans (b := qsumL (fun i => neg (mul (a i) (⟨1, i + j + 1⟩ : Q))) (List.range d))
    (qsumL_den _ (fun i => neg_den_pos (Qmul_den_pos (ha i) (Nat.succ_pos (i + j)))) (List.range d))
    (qsumL_congr (fun i => Qmul_neg_left (a i) (⟨1, i + j + 1⟩ : Q)) (List.range d))
    (qsumL_neg (fun i => mul (a i) (⟨1, i + j + 1⟩ : Q))
      (fun i => Qmul_den_pos (ha i) (Nat.succ_pos (i + j))) (List.range d))

-- ===========================================================================
-- Linearity in the FIRST argument.
-- ===========================================================================

/-- **`qHil` is additive in its first argument**. -/
theorem qHil_add_left (a b c' : Nat → Q) (ha : ∀ i, 0 < (a i).den) (hb : ∀ i, 0 < (b i).den)
    (hc' : ∀ i, 0 < (c' i).den) (d : Nat) :
    Qeq (qHil (fun i => add (a i) (b i)) c' d) (add (qHil a c' d) (qHil b c' d)) := by
  show Qeq (qsumL (fun j => mul (c' j) (innerHil (fun i => add (a i) (b i)) d j)) (List.range d))
    (add (qHil a c' d) (qHil b c' d))
  refine Qeq_trans (b := qsumL (fun j => add (mul (c' j) (innerHil a d j))
      (mul (c' j) (innerHil b d j))) (List.range d))
    (qsumL_den _ (fun j => add_den_pos (Qmul_den_pos (hc' j) (innerHil_den a ha d j))
      (Qmul_den_pos (hc' j) (innerHil_den b hb d j))) (List.range d))
    (qsumL_congr (fun j => ?_) (List.range d))
    (qsumL_add (fun j => mul (c' j) (innerHil a d j)) (fun j => mul (c' j) (innerHil b d j))
      (fun j => Qmul_den_pos (hc' j) (innerHil_den a ha d j))
      (fun j => Qmul_den_pos (hc' j) (innerHil_den b hb d j)) (List.range d))
  refine Qeq_trans (b := mul (c' j) (add (innerHil a d j) (innerHil b d j)))
    (Qmul_den_pos (hc' j) (add_den_pos (innerHil_den a ha d j) (innerHil_den b hb d j)))
    (Qmul_congr (Qeq_refl (c' j)) (innerHil_add a b ha hb d j))
    (Qmul_add_left (c' j) (innerHil a d j) (innerHil b d j))

/-- **`qHil` is homogeneous in its first argument**. -/
theorem qHil_smul_left (l : Q) (a c' : Nat → Q) (hl : 0 < l.den) (ha : ∀ i, 0 < (a i).den)
    (hc' : ∀ i, 0 < (c' i).den) (d : Nat) :
    Qeq (qHil (fun i => mul l (a i)) c' d) (mul l (qHil a c' d)) := by
  show Qeq (qsumL (fun j => mul (c' j) (innerHil (fun i => mul l (a i)) d j)) (List.range d))
    (mul l (qHil a c' d))
  refine Qeq_trans (b := qsumL (fun j => mul l (mul (c' j) (innerHil a d j))) (List.range d))
    (qsumL_den _ (fun j => Qmul_den_pos hl (Qmul_den_pos (hc' j) (innerHil_den a ha d j)))
      (List.range d))
    (qsumL_congr (fun j => ?_) (List.range d))
    (qsumL_smul l (fun j => mul (c' j) (innerHil a d j)) hl
      (fun j => Qmul_den_pos (hc' j) (innerHil_den a ha d j)) (List.range d))
  refine Qeq_trans (b := mul (c' j) (mul l (innerHil a d j)))
    (Qmul_den_pos (hc' j) (Qmul_den_pos hl (innerHil_den a ha d j)))
    (Qmul_congr (Qeq_refl (c' j)) (innerHil_smul l a hl ha d j))
    (Qmul_left_comm (c' j) l (innerHil a d j))

/-- **`qHil` negates in its first argument**. -/
theorem qHil_neg_left (a c' : Nat → Q) (ha : ∀ i, 0 < (a i).den) (hc' : ∀ i, 0 < (c' i).den)
    (d : Nat) :
    Qeq (qHil (fun i => neg (a i)) c' d) (neg (qHil a c' d)) := by
  show Qeq (qsumL (fun j => mul (c' j) (innerHil (fun i => neg (a i)) d j)) (List.range d))
    (neg (qHil a c' d))
  refine Qeq_trans (b := qsumL (fun j => neg (mul (c' j) (innerHil a d j))) (List.range d))
    (qsumL_den _ (fun j => neg_den_pos (Qmul_den_pos (hc' j) (innerHil_den a ha d j)))
      (List.range d))
    (qsumL_congr (fun j => ?_) (List.range d))
    (qsumL_neg (fun j => mul (c' j) (innerHil a d j))
      (fun j => Qmul_den_pos (hc' j) (innerHil_den a ha d j)) (List.range d))
  refine Qeq_trans (b := mul (c' j) (neg (innerHil a d j)))
    (Qmul_den_pos (hc' j) (neg_den_pos (innerHil_den a ha d j)))
    (Qmul_congr (Qeq_refl (c' j)) (innerHil_neg a ha d j))
    (Qmul_neg_right (c' j) (innerHil a d j))

-- ===========================================================================
-- Linearity in the SECOND argument (the outer coefficient vector).
-- ===========================================================================

/-- **`qHil` is additive in its second argument**. -/
theorem qHil_add_right (c a b : Nat → Q) (hc : ∀ i, 0 < (c i).den) (ha : ∀ i, 0 < (a i).den)
    (hb : ∀ i, 0 < (b i).den) (d : Nat) :
    Qeq (qHil c (fun j => add (a j) (b j)) d) (add (qHil c a d) (qHil c b d)) := by
  show Qeq (qsumL (fun j => mul (add (a j) (b j)) (innerHil c d j)) (List.range d))
    (add (qHil c a d) (qHil c b d))
  exact Qeq_trans (b := qsumL (fun j => add (mul (a j) (innerHil c d j))
      (mul (b j) (innerHil c d j))) (List.range d))
    (qsumL_den _ (fun j => add_den_pos (Qmul_den_pos (ha j) (innerHil_den c hc d j))
      (Qmul_den_pos (hb j) (innerHil_den c hc d j))) (List.range d))
    (qsumL_congr (fun j => Qmul_add_right (a j) (b j) (innerHil c d j)) (List.range d))
    (qsumL_add (fun j => mul (a j) (innerHil c d j)) (fun j => mul (b j) (innerHil c d j))
      (fun j => Qmul_den_pos (ha j) (innerHil_den c hc d j))
      (fun j => Qmul_den_pos (hb j) (innerHil_den c hc d j)) (List.range d))

/-- **`qHil` is homogeneous in its second argument**. -/
theorem qHil_smul_right (l : Q) (c a : Nat → Q) (hl : 0 < l.den) (hc : ∀ i, 0 < (c i).den)
    (ha : ∀ i, 0 < (a i).den) (d : Nat) :
    Qeq (qHil c (fun j => mul l (a j)) d) (mul l (qHil c a d)) := by
  show Qeq (qsumL (fun j => mul (mul l (a j)) (innerHil c d j)) (List.range d))
    (mul l (qHil c a d))
  refine Qeq_trans (b := qsumL (fun j => mul l (mul (a j) (innerHil c d j))) (List.range d))
    (qsumL_den _ (fun j => Qmul_den_pos hl (Qmul_den_pos (ha j) (innerHil_den c hc d j)))
      (List.range d))
    (qsumL_congr (fun j => Qmul_assoc l (a j) (innerHil c d j)) (List.range d))
    (qsumL_smul l (fun j => mul (a j) (innerHil c d j)) hl
      (fun j => Qmul_den_pos (ha j) (innerHil_den c hc d j)) (List.range d))

/-- **`qHil` negates in its second argument**. -/
theorem qHil_neg_right (c a : Nat → Q) (hc : ∀ i, 0 < (c i).den) (ha : ∀ i, 0 < (a i).den)
    (d : Nat) :
    Qeq (qHil c (fun j => neg (a j)) d) (neg (qHil c a d)) := by
  show Qeq (qsumL (fun j => mul (neg (a j)) (innerHil c d j)) (List.range d))
    (neg (qHil c a d))
  exact Qeq_trans (b := qsumL (fun j => neg (mul (a j) (innerHil c d j))) (List.range d))
    (qsumL_den _ (fun j => neg_den_pos (Qmul_den_pos (ha j) (innerHil_den c hc d j))) (List.range d))
    (qsumL_congr (fun j => Qmul_neg_left (a j) (innerHil c d j)) (List.range d))
    (qsumL_neg (fun j => mul (a j) (innerHil c d j))
      (fun j => Qmul_den_pos (ha j) (innerHil_den c hc d j)) (List.range d))

end Multiplicity.UOR.Bridge.F1Square.Square
