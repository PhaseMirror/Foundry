/-
F1 square — **`qHil` distributes over a linear combination of coefficient vectors**
(`QHilbertComb.lean`), the last algebraic tool before the Gram–Schmidt recursion (brick 3 of the
Hausdorff *sufficiency* arc). The recursion subtracts a *projection* `Σ_{i∈ls} cf_i · v_i` from a
monomial, and the orthogonality proof expands `⟨Σ cf_i v_i, w⟩`; this file supplies exactly that:

  `combVec ls cf v idx = Σ_{i∈ls} cf_i · (v_i)_idx`   (the coefficient vector of the combination)
  `qHil_combVec_left`  : `qHil (combVec ls cf v) w d = Σ_{i∈ls} cf_i · qHil (v_i) w d`
  `qHil_combVec_right` : `qHil w (combVec ls cf v) d = Σ_{i∈ls} cf_i · qHil w (v_i) d`

both by induction on `ls` from the atomic add/smul laws (`qHil_add_left/right`,
`qHil_smul_left/right`), with the zero (empty-list) base `qHil 0 w = 0`.

HONEST SCOPE. The combination-linearity of the *finite rational* Hilbert form only. NOT the
orthogonal-polynomial construction, NOT positivity. Step 4 (band-coupling positivity) is RH; the crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.QHilbertBilinear

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Small ℚ scalar zero laws (private).
-- ===========================================================================

private theorem Qmul_zero_right (a : Q) : Qeq (mul a (⟨0, 1⟩ : Q)) (⟨0, 1⟩ : Q) := by
  simp only [Qeq, mul]; push_cast; ring_uor

private theorem Qzero_mul (a : Q) : Qeq (mul (⟨0, 1⟩ : Q) a) (⟨0, 1⟩ : Q) := by
  simp only [Qeq, mul]; push_cast; ring_uor

-- ===========================================================================
-- `qHil` of the zero vector.
-- ===========================================================================

/-- `innerHil` of the zero vector is `0`. -/
private theorem innerHil_zero (d j : Nat) :
    Qeq (innerHil (fun _ => (⟨0, 1⟩ : Q)) d j) (⟨0, 1⟩ : Q) :=
  qsumL_zero (fun i => Qzero_mul (⟨1, i + j + 1⟩ : Q)) (List.range d)

/-- **`qHil 0 w = 0`**: the Hilbert form vanishes on the zero coefficient vector (first argument). -/
theorem qHil_zero_left (w : Nat → Q) (hw : ∀ i, 0 < (w i).den) (d : Nat) :
    Qeq (qHil (fun _ => (⟨0, 1⟩ : Q)) w d) (⟨0, 1⟩ : Q) := by
  show Qeq (qsumL (fun j => mul (w j) (innerHil (fun _ => (⟨0, 1⟩ : Q)) d j)) (List.range d))
    (⟨0, 1⟩ : Q)
  refine qsumL_zero (fun j => ?_) (List.range d)
  exact Qeq_trans (b := mul (w j) (⟨0, 1⟩ : Q)) (Qmul_den_pos (hw j) (by decide))
    (Qmul_congr (Qeq_refl (w j)) (innerHil_zero d j)) (Qmul_zero_right (w j))

/-- **`qHil w 0 = 0`**: the Hilbert form vanishes on the zero coefficient vector (second argument). -/
theorem qHil_zero_right (w : Nat → Q) (hw : ∀ i, 0 < (w i).den) (d : Nat) :
    Qeq (qHil w (fun _ => (⟨0, 1⟩ : Q)) d) (⟨0, 1⟩ : Q) := by
  show Qeq (qsumL (fun j => mul (⟨0, 1⟩ : Q) (innerHil w d j)) (List.range d)) (⟨0, 1⟩ : Q)
  exact qsumL_zero (fun j => Qzero_mul (innerHil w d j)) (List.range d)

-- ===========================================================================
-- The linear combination of coefficient vectors and its `qHil`-linearity.
-- ===========================================================================

/-- The coefficient vector of `Σ_{i∈ls} cf_i · v_i` (pointwise in the coordinate `idx`). -/
def combVec (ls : List Nat) (cf : Nat → Q) (v : Nat → (Nat → Q)) : Nat → Q :=
  fun idx => qsumL (fun i => mul (cf i) (v i idx)) ls

/-- The combination keeps positive denominators. -/
theorem combVec_den (ls : List Nat) (cf : Nat → Q) (v : Nat → (Nat → Q))
    (hcf : ∀ i, 0 < (cf i).den) (hv : ∀ i idx, 0 < (v i idx).den) (idx : Nat) :
    0 < (combVec ls cf v idx).den :=
  qsumL_den _ (fun i => Qmul_den_pos (hcf i) (hv i idx)) ls

/-- **★ `qHil` distributes over the combination in the first argument**:
    `qHil (Σ cf_i v_i) w d = Σ cf_i · qHil (v_i) w d`. Induction on `ls`. -/
theorem qHil_combVec_left (cf : Nat → Q) (v : Nat → (Nat → Q)) (w : Nat → Q)
    (hcf : ∀ i, 0 < (cf i).den) (hv : ∀ i idx, 0 < (v i idx).den) (hw : ∀ i, 0 < (w i).den)
    (d : Nat) :
    ∀ ls : List Nat,
      Qeq (qHil (combVec ls cf v) w d) (qsumL (fun i => mul (cf i) (qHil (v i) w d)) ls)
  | [] => qHil_zero_left w hw d
  | (i :: rest) => by
      -- `combVec (i::rest) = (cf i · v_i) + combVec rest`, pointwise
      refine Qeq_trans (b := add (qHil (fun idx => mul (cf i) (v i idx)) w d)
          (qHil (combVec rest cf v) w d))
        (add_den_pos (qsumL_den _ (fun j => Qmul_den_pos (hw j)
            (innerHil_den (fun idx => mul (cf i) (v i idx))
              (fun idx => Qmul_den_pos (hcf i) (hv i idx)) d j)) (List.range d))
          (qsumL_den _ (fun j => Qmul_den_pos (hw j)
            (innerHil_den (combVec rest cf v) (combVec_den rest cf v hcf hv) d j)) (List.range d)))
        (qHil_add_left (fun idx => mul (cf i) (v i idx)) (combVec rest cf v) w
          (fun idx => Qmul_den_pos (hcf i) (hv i idx)) (combVec_den rest cf v hcf hv) hw d)
        ?_
      -- `Σ_{i::rest} = cf_i · qHil(v_i) w + Σ_rest`
      refine Qadd_congr ?_ (qHil_combVec_left cf v w hcf hv hw d rest)
      exact qHil_smul_left (cf i) (v i) w (hcf i) (hv i) hw d

/-- **★ `qHil` distributes over the combination in the second argument**:
    `qHil w (Σ cf_i v_i) d = Σ cf_i · qHil w (v_i) d`. Induction on `ls`. -/
theorem qHil_combVec_right (cf : Nat → Q) (v : Nat → (Nat → Q)) (w : Nat → Q)
    (hcf : ∀ i, 0 < (cf i).den) (hv : ∀ i idx, 0 < (v i idx).den) (hw : ∀ i, 0 < (w i).den)
    (d : Nat) :
    ∀ ls : List Nat,
      Qeq (qHil w (combVec ls cf v) d) (qsumL (fun i => mul (cf i) (qHil w (v i) d)) ls)
  | [] => qHil_zero_right w hw d
  | (i :: rest) => by
      refine Qeq_trans (b := add (qHil w (fun idx => mul (cf i) (v i idx)) d)
          (qHil w (combVec rest cf v) d))
        (add_den_pos (qsumL_den _ (fun j => Qmul_den_pos
            (Qmul_den_pos (hcf i) (hv i j)) (innerHil_den w hw d j)) (List.range d))
          (qsumL_den _ (fun j => Qmul_den_pos (combVec_den rest cf v hcf hv j)
            (innerHil_den w hw d j)) (List.range d)))
        (qHil_add_right w (fun idx => mul (cf i) (v i idx)) (combVec rest cf v)
          hw (fun idx => Qmul_den_pos (hcf i) (hv i idx)) (combVec_den rest cf v hcf hv) d)
        ?_
      refine Qadd_congr ?_ (qHil_combVec_right cf v w hcf hv hw d rest)
      exact qHil_smul_right (cf i) w (v i) (hcf i) hw (hv i) d

end Multiplicity.UOR.Bridge.F1Square.Square
