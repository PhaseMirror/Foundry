/-
F1 square — **the Bessel-tail identity for the Riesz projection** (`RieszBessel.lean`), brick 5.5 of the
moment-realization sub-arc. The squared `L²`-distance between two Riesz projections telescopes to the
*difference* of their squared norms:

  `pVec_cross`        :  `M ≤ P  ⟹  ⟨p_P, p_M⟩_d = Σ_{k≤M} aCoef_k · Λ_μ(q_k)`   (the projection reads
                          the same low sum regardless of the higher degree `P`);
  `pVec_diff_normSq`  :  `M ≤ N  ⟹  ‖p_N − p_M‖²_d = ‖p_N‖²_d − ‖p_M‖²_d`.

`pVec_cross` expands the low projection (`qHil_combVec_right`) and reads each pairing as `Λ_μ(q_k)`
(`realize_basis`); it gives at once the cross-term identity `⟨p_N, p_M⟩ = ‖p_M‖²` (the increment
`p_N − p_M` is orthogonal to `p_M`). The difference identity is then pure bilinearity: expand
`⟨p_N−p_M, p_N−p_M⟩` into the four Gram entries (`qHil_sub_left`/`qHil_sub_right`, i.e. `qHil` over the
pointwise `Qsub`), substitute the two cross-terms (`qHil_comm` for the mirror), and the middle terms
cancel to `‖p_N‖² − ‖p_M‖²`.

This is the exact quantity the convergence brick bounds: reading it along a truncation schedule, the
squared increments are a *Bessel tail* `Σ_{M<k≤N} aCoef_k²‖q_k‖²`, and a supplied rational modulus on
that tail is the constructive Riesz–Fischer hypothesis.

HONEST SCOPE. The finite Bessel-tail *identity* at a *fixed* dimension `d`, under the orthogonal-family
invariants supplied as hypotheses — unconditional, pure finite ℚ arithmetic. This is NOT the L²-limit /
convergence (which additionally needs the dimension-independent family and a supplied Bessel convergence
modulus — the next brick), NOT positivity. Step 4 (band-coupling positivity) is RH; the crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1.Square.RieszRealize
import Multiplicity.F1.Square.QHilbertSymm

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Small ℚ / bilinearity helpers (private).
-- ===========================================================================

/-- `Qsub a a ≈ 0`. -/
private theorem Qsub_self0 (a : Q) : Qeq (Qsub a a) (⟨0, 1⟩ : Q) := by
  simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor

/-- `Qsub a 0 ≈ a` for a valid `a`. -/
private theorem Qsub_zero_r (a : Q) : Qeq (Qsub a (⟨0, 1⟩ : Q)) a := by
  simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor

/-- **`qHil` over a pointwise difference, first argument**:
    `qHil (a − b) c' d = qHil a c' d − qHil b c' d`. -/
private theorem qHil_sub_left (a b c' : Nat → Q) (ha : ∀ i, 0 < (a i).den) (hb : ∀ i, 0 < (b i).den)
    (hc' : ∀ i, 0 < (c' i).den) (d : Nat) :
    Qeq (qHil (fun i => Qsub (a i) (b i)) c' d) (Qsub (qHil a c' d) (qHil b c' d)) := by
  show Qeq (qHil (fun i => add (a i) (neg (b i))) c' d) (Qsub (qHil a c' d) (qHil b c' d))
  refine Qeq_trans (b := add (qHil a c' d) (qHil (fun i => neg (b i)) c' d))
    (add_den_pos (qHil_den_pos a c' ha hc' d)
      (qHil_den_pos (fun i => neg (b i)) c' (fun i => neg_den_pos (hb i)) hc' d))
    (qHil_add_left a (fun i => neg (b i)) c' ha (fun i => neg_den_pos (hb i)) hc' d) ?_
  exact Qadd_congr (Qeq_refl _) (qHil_neg_left b c' hb hc' d)

/-- **`qHil` over a pointwise difference, second argument**:
    `qHil c (a − b) d = qHil c a d − qHil c b d`. -/
private theorem qHil_sub_right (c a b : Nat → Q) (hc : ∀ i, 0 < (c i).den) (ha : ∀ i, 0 < (a i).den)
    (hb : ∀ i, 0 < (b i).den) (d : Nat) :
    Qeq (qHil c (fun j => Qsub (a j) (b j)) d) (Qsub (qHil c a d) (qHil c b d)) := by
  show Qeq (qHil c (fun j => add (a j) (neg (b j))) d) (Qsub (qHil c a d) (qHil c b d))
  refine Qeq_trans (b := add (qHil c a d) (qHil c (fun j => neg (b j)) d))
    (add_den_pos (qHil_den_pos c a hc ha d)
      (qHil_den_pos c (fun j => neg (b j)) hc (fun j => neg_den_pos (hb j)) d))
    (qHil_add_right c a (fun j => neg (b j)) hc ha (fun j => neg_den_pos (hb j)) d) ?_
  exact Qadd_congr (Qeq_refl _) (qHil_neg_right c b hc hb d)

-- ===========================================================================
-- The cross-term: the projection reads the same low sum at any higher degree.
-- ===========================================================================

/-- **★ THE PROJECTION CROSS-TERM**: `⟨p_P, p_M⟩_d = Σ_{k≤M} aCoef_k · Λ_μ(q_k)` for `M ≤ P`. Expand
    the low projection `p_M` in the second argument and read each pairing off the basis
    (`realize_basis`). In particular `⟨p_N, p_M⟩ = ⟨p_M, p_M⟩` — the increment is orthogonal to `p_M`. -/
theorem pVec_cross (μ : Nat → Q) (d : Nat) (q : Nat → (Nat → Q))
    (hqd : ∀ k idx, 0 < (q k idx).den) (hμ : ∀ i, 0 < (μ i).den)
    (hqorth : ∀ a b, a < d → b < d → a ≠ b → Qeq (qHil (q a) (q b) d) (⟨0, 1⟩ : Q))
    (hmonic : ∀ k, k < d → ¬ Qeq (q k k) (⟨0, 1⟩ : Q))
    (M P : Nat) (hMP : M ≤ P) (hPd : P < d) :
    Qeq (qHil (pVec μ d q P) (pVec μ d q M) d)
      (qsumL (fun k => mul (aCoef μ d q k) (Lam μ (q k) d)) (List.range (M + 1))) := by
  show Qeq (qHil (pVec μ d q P) (combVec (List.range (M + 1)) (aCoef μ d q) q) d) _
  refine Qeq_trans
    (b := qsumL (fun k => mul (aCoef μ d q k) (qHil (pVec μ d q P) (q k) d)) (List.range (M + 1)))
    (qsumL_den _ (fun k => Qmul_den_pos (aCoef_den μ d q hqd hμ k)
      (qHil_den_pos (pVec μ d q P) (q k) (pVec_den μ d q hqd hμ P) (hqd k) d)) (List.range (M + 1)))
    (qHil_combVec_right (aCoef μ d q) q (pVec μ d q P) (fun k => aCoef_den μ d q hqd hμ k) hqd
      (pVec_den μ d q hqd hμ P) d (List.range (M + 1)))
    ?_
  refine qsumL_congr_mem (List.range (M + 1)) (fun k hk => ?_)
  have hkM : k ≤ M := by have := List.mem_range.mp hk; omega
  exact Qmul_congr (Qeq_refl _)
    (realize_basis μ d q hqd hμ hqorth hmonic P k hPd (Nat.le_trans hkM hMP))

/-- The cross-term equals the low self-norm: `⟨p_N, p_M⟩_d = ⟨p_M, p_M⟩_d` for `M ≤ N`. -/
private theorem pVec_cross_self (μ : Nat → Q) (d : Nat) (q : Nat → (Nat → Q))
    (hqd : ∀ k idx, 0 < (q k idx).den) (hμ : ∀ i, 0 < (μ i).den)
    (hqorth : ∀ a b, a < d → b < d → a ≠ b → Qeq (qHil (q a) (q b) d) (⟨0, 1⟩ : Q))
    (hmonic : ∀ k, k < d → ¬ Qeq (q k k) (⟨0, 1⟩ : Q))
    (M N : Nat) (hMN : M ≤ N) (hNd : N < d) :
    Qeq (qHil (pVec μ d q N) (pVec μ d q M) d) (qHil (pVec μ d q M) (pVec μ d q M) d) :=
  Qeq_trans
    (qsumL_den _ (fun k => Qmul_den_pos (aCoef_den μ d q hqd hμ k) (Lam_den μ (q k) (hqd k) hμ d))
      (List.range (M + 1)))
    (pVec_cross μ d q hqd hμ hqorth hmonic M N hMN hNd)
    (Qeq_symm (pVec_cross μ d q hqd hμ hqorth hmonic M M (Nat.le_refl M) (Nat.lt_of_le_of_lt hMN hNd)))

-- ===========================================================================
-- ★ The Bessel-tail difference identity.
-- ===========================================================================

set_option maxHeartbeats 1000000 in
/-- **★ THE BESSEL-TAIL IDENTITY**: `‖p_N − p_M‖²_d = ‖p_N‖²_d − ‖p_M‖²_d` for `M ≤ N`. Expand the
    squared norm of the increment into the four Gram entries by bilinearity, substitute the two
    cross-terms `⟨p_N,p_M⟩ = ⟨p_M,p_N⟩ = ‖p_M‖²`, and the middle terms cancel. -/
theorem pVec_diff_normSq (μ : Nat → Q) (d : Nat) (q : Nat → (Nat → Q))
    (hqd : ∀ k idx, 0 < (q k idx).den) (hμ : ∀ i, 0 < (μ i).den)
    (hqorth : ∀ a b, a < d → b < d → a ≠ b → Qeq (qHil (q a) (q b) d) (⟨0, 1⟩ : Q))
    (hmonic : ∀ k, k < d → ¬ Qeq (q k k) (⟨0, 1⟩ : Q))
    (M N : Nat) (hMN : M ≤ N) (hNd : N < d) :
    Qeq (qHil (fun idx => Qsub (pVec μ d q N idx) (pVec μ d q M idx))
              (fun idx => Qsub (pVec μ d q N idx) (pVec μ d q M idx)) d)
      (Qsub (qHil (pVec μ d q N) (pVec μ d q N) d) (qHil (pVec μ d q M) (pVec μ d q M) d)) := by
  have hu : ∀ idx, 0 < (pVec μ d q N idx).den := pVec_den μ d q hqd hμ N
  have hv : ∀ idx, 0 < (pVec μ d q M idx).den := pVec_den μ d q hqd hμ M
  have hdiff : ∀ idx, 0 < ((fun idx => Qsub (pVec μ d q N idx) (pVec μ d q M idx)) idx).den :=
    fun idx => add_den_pos (hu idx) (neg_den_pos (hv idx))
  -- Gram-entry denominators (A=⟨u,u⟩, B=⟨u,v⟩, C=⟨v,u⟩, E=⟨v,v⟩)
  have dA : 0 < (qHil (pVec μ d q N) (pVec μ d q N) d).den := qHil_den_pos _ _ hu hu d
  have dE : 0 < (qHil (pVec μ d q M) (pVec μ d q M) d).den := qHil_den_pos _ _ hv hv d
  have dUdiff : 0 < (qHil (pVec μ d q N)
      (fun idx => Qsub (pVec μ d q N idx) (pVec μ d q M idx)) d).den := qHil_den_pos _ _ hu hdiff d
  have dVdiff : 0 < (qHil (pVec μ d q M)
      (fun idx => Qsub (pVec μ d q N idx) (pVec μ d q M idx)) d).den := qHil_den_pos _ _ hv hdiff d
  -- the two cross-terms
  have hB : Qeq (qHil (pVec μ d q N) (pVec μ d q M) d) (qHil (pVec μ d q M) (pVec μ d q M) d) :=
    pVec_cross_self μ d q hqd hμ hqorth hmonic M N hMN hNd
  have hC : Qeq (qHil (pVec μ d q M) (pVec μ d q N) d) (qHil (pVec μ d q M) (pVec μ d q M) d) :=
    Qeq_trans (qHil_den_pos (pVec μ d q N) (pVec μ d q M) hu hv d)
      (qHil_comm (pVec μ d q M) (pVec μ d q N) hv hu d) hB
  -- Step 1: split the first argument
  refine Qeq_trans
    (b := Qsub (qHil (pVec μ d q N) (fun idx => Qsub (pVec μ d q N idx) (pVec μ d q M idx)) d)
              (qHil (pVec μ d q M) (fun idx => Qsub (pVec μ d q N idx) (pVec μ d q M idx)) d))
    (add_den_pos dUdiff (neg_den_pos dVdiff))
    (qHil_sub_left (pVec μ d q N) (pVec μ d q M)
      (fun idx => Qsub (pVec μ d q N idx) (pVec μ d q M idx)) hu hv hdiff d) ?_
  -- Step 2: split each second argument into the four Gram entries
  refine Qeq_trans
    (b := Qsub (Qsub (qHil (pVec μ d q N) (pVec μ d q N) d) (qHil (pVec μ d q N) (pVec μ d q M) d))
              (Qsub (qHil (pVec μ d q M) (pVec μ d q N) d) (qHil (pVec μ d q M) (pVec μ d q M) d)))
    (add_den_pos (add_den_pos dA (neg_den_pos (qHil_den_pos _ _ hu hv d)))
      (neg_den_pos (add_den_pos (qHil_den_pos _ _ hv hu d) (neg_den_pos dE))))
    (Qsub_congr
      (qHil_sub_right (pVec μ d q N) (pVec μ d q N) (pVec μ d q M) hu hu hv d)
      (qHil_sub_right (pVec μ d q M) (pVec μ d q N) (pVec μ d q M) hv hu hv d)) ?_
  -- Step 3: substitute the two cross-terms
  refine Qeq_trans
    (b := Qsub (Qsub (qHil (pVec μ d q N) (pVec μ d q N) d) (qHil (pVec μ d q M) (pVec μ d q M) d))
              (Qsub (qHil (pVec μ d q M) (pVec μ d q M) d) (qHil (pVec μ d q M) (pVec μ d q M) d)))
    (add_den_pos (add_den_pos dA (neg_den_pos dE)) (neg_den_pos (add_den_pos dE (neg_den_pos dE))))
    (Qsub_congr (Qsub_congr (Qeq_refl _) hB) (Qsub_congr hC (Qeq_refl _))) ?_
  -- Step 4: the middle `E − E` collapses
  refine Qeq_trans
    (b := Qsub (Qsub (qHil (pVec μ d q N) (pVec μ d q N) d) (qHil (pVec μ d q M) (pVec μ d q M) d))
              (⟨0, 1⟩ : Q))
    (add_den_pos (add_den_pos dA (neg_den_pos dE)) (neg_den_pos (by decide)))
    (Qsub_congr (Qeq_refl _) (Qsub_self0 (qHil (pVec μ d q M) (pVec μ d q M) d))) ?_
  -- Step 5: drop the trailing zero
  exact Qsub_zero_r (Qsub (qHil (pVec μ d q N) (pVec μ d q N) d) (qHil (pVec μ d q M) (pVec μ d q M) d))

end Multiplicity.UOR.Bridge.F1Square.Square
