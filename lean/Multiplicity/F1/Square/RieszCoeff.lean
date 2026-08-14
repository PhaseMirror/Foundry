/-
F1 square — **the Riesz projection coefficient and vector** (`RieszCoeff.lean`), the third brick of the
moment-realization sub-arc. Reading `μ` off the orthogonal basis, the Riesz coefficient of `q_k` is

  `aCoef μ d q k = Λ_μ(q_k) / ⟨q_k,q_k⟩_d`   (guarded, so total: `0` where `⟨q_k,q_k⟩ ≤ 0`)

and the degree-`N` Riesz projection is the combination `pVec μ d q N = Σ_{k≤N} aCoef_k · q_k`. This is
the exact structural clone of the Gram–Schmidt `projCoef`/`nextVec` machinery, with the monomial
pairing `⟨e_m,q_k⟩` replaced by the moment functional `Λ_μ(q_k)`. The cancellation law
`aCoef_cancel` (`aCoef_k · ⟨q_k,q_k⟩ = Λ_μ(q_k)`) is what the realization identity consumes.

HONEST SCOPE. The Riesz coefficient/vector and its cancellation only — finite ℚ linear algebra. NOT
the realization identity `⟨p_N, x^j⟩ = μ_j` (next brick), NOT Parseval, NOT convergence, NOT
positivity. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1Square.Square.GramSchmidt
import Multiplicity.F1Square.Square.MomentFunctional

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `⟨0,1⟩ < x` forces a positive numerator (local copy). -/
private theorem num_pos_of_Qlt_zero {x : Q} (h : Qlt (⟨0, 1⟩ : Q) x) : 0 < x.num := by
  have h' : (0 : Int) * (x.den : Int) < x.num * (1 : Int) := h
  omega

-- ===========================================================================
-- The Riesz coefficient.
-- ===========================================================================

/-- The **Riesz projection coefficient** `Λ_μ(q_k) / ⟨q_k,q_k⟩_d` — **guarded** (total, positive
    denominator at every `k`): the real quotient where `⟨q_k,q_k⟩ > 0`, else `0`. Verbatim structure
    of the Gram–Schmidt `projCoef`, with `⟨e_m,q_k⟩` replaced by `Λ_μ(q_k)`. -/
def aCoef (μ : Nat → Q) (d : Nat) (q : Nat → (Nat → Q)) (k : Nat) : Q :=
  if 0 < (qHil (q k) (q k) d).num then
    mul (Lam μ (q k) d) (Qinv (qHil (q k) (q k) d))
  else (⟨0, 1⟩ : Q)

theorem aCoef_den (μ : Nat → Q) (d : Nat) (q : Nat → (Nat → Q)) (hqd : ∀ k idx, 0 < (q k idx).den)
    (hμ : ∀ i, 0 < (μ i).den) (k : Nat) : 0 < (aCoef μ d q k).den := by
  unfold aCoef
  by_cases h : 0 < (qHil (q k) (q k) d).num
  · rw [if_pos h]; exact Qmul_den_pos (Lam_den μ (q k) (hqd k) hμ d) (Qinv_den_pos h)
  · rw [if_neg h]; exact Nat.one_pos

/-- **The Riesz cancellation**: `aCoef_k · ⟨q_k,q_k⟩ = Λ_μ(q_k)` (on the constructed range,
    `⟨q_k,q_k⟩ > 0`). -/
theorem aCoef_cancel (μ : Nat → Q) (d : Nat) (q : Nat → (Nat → Q)) (hqd : ∀ k idx, 0 < (q k idx).den)
    (hμ : ∀ i, 0 < (μ i).den) (k : Nat) (hpos : 0 < (qHil (q k) (q k) d).num) :
    Qeq (mul (aCoef μ d q k) (qHil (q k) (q k) d)) (Lam μ (q k) d) := by
  unfold aCoef; rw [if_pos hpos]
  refine Qeq_trans (b := mul (Lam μ (q k) d)
      (mul (Qinv (qHil (q k) (q k) d)) (qHil (q k) (q k) d)))
    (Qmul_den_pos (Lam_den μ (q k) (hqd k) hμ d)
      (Qmul_den_pos (Qinv_den_pos hpos) (qHil_den_pos (q k) (q k) (hqd k) (hqd k) d)))
    (Qmul_assoc (Lam μ (q k) d) (Qinv (qHil (q k) (q k) d)) (qHil (q k) (q k) d)) ?_
  refine Qeq_trans (b := mul (Lam μ (q k) d) (⟨1, 1⟩ : Q))
    (Qmul_den_pos (Lam_den μ (q k) (hqd k) hμ d) (by decide))
    (Qmul_congr (Qeq_refl _)
      (Qeq_trans (b := mul (qHil (q k) (q k) d) (Qinv (qHil (q k) (q k) d)))
        (Qmul_den_pos (qHil_den_pos (q k) (q k) (hqd k) (hqd k) d) (Qinv_den_pos hpos))
        (Qmul_comm (Qinv (qHil (q k) (q k) d)) (qHil (q k) (q k) d)) (Qmul_Qinv hpos)))
    (Qeq_trans (b := mul (⟨1, 1⟩ : Q) (Lam μ (q k) d))
      (Qmul_den_pos (by decide) (Lam_den μ (q k) (hqd k) hμ d))
      (Qmul_comm (Lam μ (q k) d) (⟨1, 1⟩ : Q)) (Qone_mul (Lam μ (q k) d)))

/-- The self-norm positivity a nonzero (monic) `q_k` gives, packaged for the guard/`Qinv`. -/
theorem qHil_self_num_pos (q : Nat → (Nat → Q)) (hqd : ∀ k idx, 0 < (q k idx).den) (d k : Nat)
    (hk : k < d) (hmonic : ¬ Qeq (q k k) (⟨0, 1⟩ : Q)) : 0 < (qHil (q k) (q k) d).num :=
  num_pos_of_Qlt_zero (qHil_self_pos (q k) (hqd k) d ⟨k, hk, hmonic⟩)

-- ===========================================================================
-- The Riesz projection vector.
-- ===========================================================================

/-- The degree-`N` **Riesz projection** `p_N = Σ_{k≤N} aCoef_k · q_k` (as a coefficient vector). -/
def pVec (μ : Nat → Q) (d : Nat) (q : Nat → (Nat → Q)) (N : Nat) : Nat → Q :=
  combVec (List.range (N + 1)) (aCoef μ d q) q

theorem pVec_den (μ : Nat → Q) (d : Nat) (q : Nat → (Nat → Q)) (hqd : ∀ k idx, 0 < (q k idx).den)
    (hμ : ∀ i, 0 < (μ i).den) (N idx : Nat) : 0 < (pVec μ d q N idx).den :=
  combVec_den (List.range (N + 1)) (aCoef μ d q) q (fun k => aCoef_den μ d q hqd hμ k) hqd idx

end Multiplicity.UOR.Bridge.F1Square.Square
