/-
F1 square — **the moment functional and its linearity** (`MomentFunctional.lean`), the first brick of
the moment-*realization* sub-arc (bricks 4–6 of the Hausdorff *sufficiency* direction). Given a
rational moment sequence `μ : Nat → Q`, the moment functional contracts a polynomial's coefficient
vector against `μ`:

  `Lam μ c d = Σ_{i<d} c_i · μ_i`.

The Riesz projection that realizes `μ` reads its coefficients off `Lam μ (q_k) / ‖q_k‖²`; the
realization and Parseval bricks expand `Lam` over the orthogonal basis, so they need `Lam` linear in
its coefficient-vector argument. This file supplies exactly those laws — a line-for-line clone of the
`qHil` bilinearity, with the inner Hilbert weight `1/(i+j+1)` replaced by the external `μ_i`:

  `Lam_add`, `Lam_smul`, `Lam_neg`, `Lam_combVec`  (linearity, including over a `combVec` combination).

HONEST SCOPE. The moment functional and its ℚ-linearity only — pure finite-dimensional linear
algebra, no new mathematics. This is NOT the Riesz projection, NOT the realization identity, NOT
convergence (later bricks); and it is a *finite-form* object, not positivity. Step 4 (band-coupling
positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.QHilbertComb

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Small ℚ scalar laws (private).
-- ===========================================================================

private theorem Qmul_add_right (a b c : Q) :
    Qeq (mul (add a b) c) (add (mul a c) (mul b c)) := by
  simp only [Qeq, mul, add]; push_cast; ring_uor

private theorem Qmul_neg_left (a c : Q) : Qeq (mul (neg a) c) (neg (mul a c)) := by
  simp only [Qeq, mul, neg]; push_cast; ring_uor

private theorem Qzero_mul_l (a : Q) : Qeq (mul (⟨0, 1⟩ : Q) a) (⟨0, 1⟩ : Q) := by
  simp only [Qeq, mul]; push_cast; ring_uor

-- ===========================================================================
-- The moment functional and its linearity.
-- ===========================================================================

/-- The **moment functional** `Λ_μ(c) = Σ_{i<d} c_i · μ_i` — the pairing of a polynomial's coefficient
    vector against the external moment sequence `μ`. -/
def Lam (μ c : Nat → Q) (d : Nat) : Q :=
  qsumL (fun i => mul (c i) (μ i)) (List.range d)

/-- `Λ_μ(c)` has a positive denominator. -/
theorem Lam_den (μ c : Nat → Q) (hc : ∀ i, 0 < (c i).den) (hμ : ∀ i, 0 < (μ i).den) (d : Nat) :
    0 < (Lam μ c d).den :=
  qsumL_den _ (fun i => Qmul_den_pos (hc i) (hμ i)) (List.range d)

/-- **`Λ_μ` is additive** in the coefficient vector. -/
theorem Lam_add (μ a b : Nat → Q) (hμ : ∀ i, 0 < (μ i).den) (ha : ∀ i, 0 < (a i).den)
    (hb : ∀ i, 0 < (b i).den) (d : Nat) :
    Qeq (Lam μ (fun i => add (a i) (b i)) d) (add (Lam μ a d) (Lam μ b d)) :=
  Qeq_trans (b := qsumL (fun i => add (mul (a i) (μ i)) (mul (b i) (μ i))) (List.range d))
    (qsumL_den _ (fun i => add_den_pos (Qmul_den_pos (ha i) (hμ i))
      (Qmul_den_pos (hb i) (hμ i))) (List.range d))
    (qsumL_congr (fun i => Qmul_add_right (a i) (b i) (μ i)) (List.range d))
    (qsumL_add (fun i => mul (a i) (μ i)) (fun i => mul (b i) (μ i))
      (fun i => Qmul_den_pos (ha i) (hμ i)) (fun i => Qmul_den_pos (hb i) (hμ i)) (List.range d))

/-- **`Λ_μ` is homogeneous** in the coefficient vector. -/
theorem Lam_smul (μ a : Nat → Q) (l : Q) (hl : 0 < l.den) (hμ : ∀ i, 0 < (μ i).den)
    (ha : ∀ i, 0 < (a i).den) (d : Nat) :
    Qeq (Lam μ (fun i => mul l (a i)) d) (mul l (Lam μ a d)) :=
  Qeq_trans (b := qsumL (fun i => mul l (mul (a i) (μ i))) (List.range d))
    (qsumL_den _ (fun i => Qmul_den_pos hl (Qmul_den_pos (ha i) (hμ i))) (List.range d))
    (qsumL_congr (fun i => Qmul_assoc l (a i) (μ i)) (List.range d))
    (qsumL_smul l (fun i => mul (a i) (μ i)) hl (fun i => Qmul_den_pos (ha i) (hμ i)) (List.range d))

/-- **`Λ_μ` negates** with the coefficient vector. -/
theorem Lam_neg (μ a : Nat → Q) (hμ : ∀ i, 0 < (μ i).den) (ha : ∀ i, 0 < (a i).den) (d : Nat) :
    Qeq (Lam μ (fun i => neg (a i)) d) (neg (Lam μ a d)) :=
  Qeq_trans (b := qsumL (fun i => neg (mul (a i) (μ i))) (List.range d))
    (qsumL_den _ (fun i => neg_den_pos (Qmul_den_pos (ha i) (hμ i))) (List.range d))
    (qsumL_congr (fun i => Qmul_neg_left (a i) (μ i)) (List.range d))
    (qsumL_neg (fun i => mul (a i) (μ i)) (fun i => Qmul_den_pos (ha i) (hμ i)) (List.range d))

/-- **`Λ_μ` distributes over a linear combination** of coefficient vectors:
    `Λ_μ(Σ cf_i v_i) = Σ cf_i · Λ_μ(v_i)`. Induction on the index list, from `Lam_add`/`Lam_smul`. -/
theorem Lam_combVec (μ cf : Nat → Q) (v : Nat → (Nat → Q)) (hμ : ∀ i, 0 < (μ i).den)
    (hcf : ∀ i, 0 < (cf i).den) (hv : ∀ i idx, 0 < (v i idx).den) (d : Nat) :
    ∀ ls : List Nat,
      Qeq (Lam μ (combVec ls cf v) d) (qsumL (fun i => mul (cf i) (Lam μ (v i) d)) ls)
  | [] => qsumL_zero (fun i => Qzero_mul_l (μ i)) (List.range d)
  | (a :: t) => by
      refine Qeq_trans (b := add (Lam μ (fun idx => mul (cf a) (v a idx)) d)
          (Lam μ (combVec t cf v) d))
        (add_den_pos (Lam_den μ _ (fun i => Qmul_den_pos (hcf a) (hv a i)) hμ d)
          (Lam_den μ _ (combVec_den t cf v hcf hv) hμ d))
        (Lam_add μ (fun idx => mul (cf a) (v a idx)) (combVec t cf v) hμ
          (fun i => Qmul_den_pos (hcf a) (hv a i)) (combVec_den t cf v hcf hv) d)
        ?_
      exact Qadd_congr (Lam_smul μ (v a) (cf a) (hcf a) hμ (hv a) d)
        (Lam_combVec μ cf v hμ hcf hv d t)

end Multiplicity.UOR.Bridge.F1Square.Square
