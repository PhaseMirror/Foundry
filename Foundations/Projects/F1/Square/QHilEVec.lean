/-
F1 square — **pairing against a monomial** (`QHilEVec.lean`), the second brick of the moment-realization
sub-arc. Pairing a coefficient vector against the monomial basis vector `e_j = x^j` picks out a single
component — the delta-collapse the realization identity runs on:

  `qHil_eVec_right` :  `j < d  ⟹  ⟨c, x^j⟩_d = innerHil c d j`   (the `j`-th Hilbert moment of `c`)
  `Lam_eVec`        :  `j < d  ⟹  Λ_μ(x^j) = μ_j`

Both follow from the single-term collapse `qsumL_range_single` (re-exported here as a public,
choice-free lemma) applied to the `eVec` delta: off the index `j` the summand vanishes (`eVec_ne`),
and at `j` it is the identity (`eVec_self`).

HONEST SCOPE. The monomial-pairing collapses only — finite ℚ linear algebra. NOT the Riesz projection
/ realization identity / convergence (later bricks), NOT positivity. Step 4 (band-coupling positivity)
is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.GramSchmidt
import Foundations.F1.Square.MomentFunctional

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The single-term collapse over `range m` (public, choice-free) and a scalar law.
-- ===========================================================================

/-- **Single-term collapse over `range m`** (choice-free, public): if `f` vanishes off the index
    `j < m`, then `Σ_{i<m} f i ≈ f j`. Induction on `m` peeling the top element via `List.range_succ`
    (avoiding the choice-tainted `List.nodup_range`/`Nodup.not_mem_erase`). -/
theorem qsumL_range_single (f : Nat → Q) (hf : ∀ i, 0 < (f i).den) (j : Nat) :
    ∀ m, j < m → (∀ l, l < m → l ≠ j → Qeq (f l) (⟨0, 1⟩ : Q)) →
      Qeq (qsumL f (List.range m)) (f j)
  | 0, hj, _ => absurd hj (Nat.not_lt_zero j)
  | (m + 1), _, hz => by
    rw [List.range_succ]
    refine Qeq_trans (b := add (qsumL f (List.range m)) (qsumL f [m]))
      (add_den_pos (qsumL_den f hf (List.range m)) (qsumL_den f hf [m]))
      (qsumL_append f hf (List.range m) [m]) ?_
    by_cases hjm : j < m
    · have hIH : Qeq (qsumL f (List.range m)) (f j) :=
        qsumL_range_single f hf j m hjm (fun l hl hlj => hz l (Nat.lt_succ_of_lt hl) hlj)
      have hfm0 : Qeq (qsumL f [m]) (⟨0, 1⟩ : Q) :=
        Qeq_trans (hf m) (Qadd_zero_right (f m))
          (hz m (Nat.lt_succ_self m) (fun heq => absurd heq.symm (Nat.ne_of_lt hjm)))
      exact Qeq_trans (b := add (f j) (⟨0, 1⟩ : Q)) (add_den_pos (hf j) (by decide))
        (Qadd_congr hIH hfm0) (Qadd_zero_right (f j))
    · have hjeq : j = m := by omega
      subst hjeq
      have hzero : Qeq (qsumL f (List.range j)) (⟨0, 1⟩ : Q) :=
        qsumL_zero_mem (List.range j) (fun l hl =>
          hz l (Nat.lt_succ_of_lt (List.mem_range.mp hl)) (Nat.ne_of_lt (List.mem_range.mp hl)))
      have hfj : Qeq (qsumL f [j]) (f j) := Qadd_zero_right (f j)
      exact Qeq_trans (b := add (⟨0, 1⟩ : Q) (f j)) (add_den_pos (by decide) (hf j))
        (Qadd_congr hzero hfj) (Qzero_add (f j))

/-- `a ≈ 0 ⟹ a·b ≈ 0` — no denominator hypothesis on `b`. -/
private theorem Qmul_zero_of_left {a b : Q} (ha : Qeq a (⟨0, 1⟩ : Q)) :
    Qeq (mul a b) (⟨0, 1⟩ : Q) := by
  have han : a.num = 0 := by simp only [Qeq] at ha; push_cast at ha; omega
  show a.num * b.num * ((1 : Nat) : Int) = 0 * ((a.den * b.den : Nat) : Int)
  rw [han]; push_cast; ring_uor

-- ===========================================================================
-- Pairing against a monomial.
-- ===========================================================================

/-- **The `j`-th Hilbert moment**: pairing `c` against the monomial `x^j` picks out `innerHil c d j`
    (the `j`-th column of the Hilbert contraction), for `j < d`. -/
theorem qHil_eVec_right (c : Nat → Q) (hc : ∀ i, 0 < (c i).den) (d j : Nat) (hjd : j < d) :
    Qeq (qHil c (eVec j) d) (innerHil c d j) := by
  show Qeq (qsumL (fun k => mul (eVec j k) (innerHil c d k)) (List.range d)) (innerHil c d j)
  refine Qeq_trans (b := mul (eVec j j) (innerHil c d j))
    (Qmul_den_pos (eVec_den j j) (innerHil_den c hc d j))
    (qsumL_range_single (fun k => mul (eVec j k) (innerHil c d k))
      (fun k => Qmul_den_pos (eVec_den j k) (innerHil_den c hc d k)) j d hjd
      (fun l _ hlj => Qmul_zero_of_left (eVec_ne hlj))) ?_
  rw [eVec_self]; exact Qone_mul (innerHil c d j)

/-- **The moment functional reads off `μ_j` at the monomial**: `Λ_μ(x^j) = μ_j` for `j < d`. -/
theorem Lam_eVec (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den) (d j : Nat) (hjd : j < d) :
    Qeq (Lam μ (eVec j) d) (μ j) := by
  show Qeq (qsumL (fun i => mul (eVec j i) (μ i)) (List.range d)) (μ j)
  refine Qeq_trans (b := mul (eVec j j) (μ j)) (Qmul_den_pos (eVec_den j j) (hμ j))
    (qsumL_range_single (fun i => mul (eVec j i) (μ i))
      (fun i => Qmul_den_pos (eVec_den j i) (hμ i)) j d hjd
      (fun l _ hlj => Qmul_zero_of_left (eVec_ne hlj))) ?_
  rw [eVec_self]; exact Qone_mul (μ j)

end Multiplicity.UOR.Bridge.F1Square.Square
