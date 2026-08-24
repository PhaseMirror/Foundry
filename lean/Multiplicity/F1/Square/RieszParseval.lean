/-
F1 square — **Parseval for the Riesz projection** (`RieszParseval.lean`), brick 5 of the
moment-realization sub-arc. The squared norm of the degree-`N` Riesz projection is the sum of its
squared Fourier coefficients times the basis self-norms:

  `parseval_norm` :  `⟨p_N, p_N⟩_d = Σ_{k≤N} aCoef_k · (aCoef_k · ⟨q_k,q_k⟩_d)`.

Expanding the outer `p_N = Σ_k aCoef_k q_k` (`qHil_combVec_left`) and using `⟨q_k, p_N⟩ = ⟨p_N, q_k⟩`
(`qHil_comm`) `= Λ_μ(q_k)` (`realize_basis`) `= aCoef_k · ⟨q_k,q_k⟩` (`aCoef_cancel`) collapses each
term — the same orthogonality telescoping as the Gram–Schmidt step, now on the projection. This is the
identity the convergence brick differences into a Bessel tail.

HONEST SCOPE. Parseval for the *finite* Riesz projection at a *fixed* dimension `d`, under the
orthogonal-family invariants supplied as hypotheses. This is NOT the L²-limit / convergence (which
additionally needs a dimension-independent family and a supplied Bessel convergence modulus — later
bricks), NOT positivity. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1.Square.RieszRealize
import Multiplicity.F1.Square.QHilbertSymm

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 1000000 in
/-- **★ PARSEVAL**: `⟨p_N, p_N⟩_d = Σ_{k≤N} aCoef_k · (aCoef_k · ⟨q_k,q_k⟩_d)` — the projection's squared
    norm is the sum of squared Fourier coefficients against the basis self-norms. -/
theorem parseval_norm (μ : Nat → Q) (d : Nat) (q : Nat → (Nat → Q))
    (hqd : ∀ k idx, 0 < (q k idx).den) (hμ : ∀ i, 0 < (μ i).den)
    (hqorth : ∀ a b, a < d → b < d → a ≠ b → Qeq (qHil (q a) (q b) d) (⟨0, 1⟩ : Q))
    (hmonic : ∀ k, k < d → ¬ Qeq (q k k) (⟨0, 1⟩ : Q))
    (N : Nat) (hNd : N < d) :
    Qeq (qHil (pVec μ d q N) (pVec μ d q N) d)
      (qsumL (fun k => mul (aCoef μ d q k) (mul (aCoef μ d q k) (qHil (q k) (q k) d)))
        (List.range (N + 1))) := by
  have hPden : ∀ idx, 0 < (pVec μ d q N idx).den := pVec_den μ d q hqd hμ N
  show Qeq (qHil (combVec (List.range (N + 1)) (aCoef μ d q) q) (pVec μ d q N) d) _
  refine Qeq_trans
    (b := qsumL (fun k => mul (aCoef μ d q k) (qHil (q k) (pVec μ d q N) d)) (List.range (N + 1)))
    (qsumL_den _ (fun k => Qmul_den_pos (aCoef_den μ d q hqd hμ k)
      (qHil_den_pos (q k) (pVec μ d q N) (hqd k) hPden d)) (List.range (N + 1)))
    (qHil_combVec_left (aCoef μ d q) q (pVec μ d q N) (fun k => aCoef_den μ d q hqd hμ k) hqd
      hPden d (List.range (N + 1)))
    ?_
  refine qsumL_congr_mem (List.range (N + 1)) (fun k hk => ?_)
  have hkN : k ≤ N := by have := List.mem_range.mp hk; omega
  have hkd : k < d := by omega
  have hposk : 0 < (qHil (q k) (q k) d).num := qHil_self_num_pos q hqd d k hkd (hmonic k hkd)
  refine Qmul_congr (Qeq_refl _) ?_
  -- ⟨q_k, p_N⟩ = ⟨p_N, q_k⟩ = Λ_μ(q_k) = aCoef_k·⟨q_k,q_k⟩
  exact Qeq_trans (qHil_den_pos (pVec μ d q N) (q k) hPden (hqd k) d)
    (qHil_comm (q k) (pVec μ d q N) (hqd k) hPden d)
    (Qeq_trans (Lam_den μ (q k) (hqd k) hμ d)
      (realize_basis μ d q hqd hμ hqorth hmonic N k hNd hkN)
      (Qeq_symm (aCoef_cancel μ d q hqd hμ k hposk)))

end Multiplicity.UOR.Bridge.F1Square.Square
