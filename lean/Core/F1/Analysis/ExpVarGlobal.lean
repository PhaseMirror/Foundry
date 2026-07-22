/-
F1 square — analytic substrate: the **global exp variation** `1 − e^{−z} ≤ 4·z` for all `z ≥ 0`.

`RexpReal_one_sub_neg_le` (EtaVariation) gives this only on the *near* regime `z ≤ 1/2` (where the
linear lower bound `e^{−z} ≥ 1 − 4z` is available). The *far* regime `z ≥ 1/4` is trivial — `1 − e^{−z}
≤ 1 ≤ 4z` — but gluing the two needs a case split on a real, which is exactly the **Bishop comparison**
`Rle_or_Rle`: split at `1/4 < 1/2` so the regimes overlap. Either branch yields `1 − e^{−z} ≤ 4z`, so
the bound is global with no decidability assumption.

This is the one-sided Lipschitz modulus of `e^{−·}` at the origin, the per-term ingredient for the
Jacobi-theta Lipschitz bound on `[1, ∞)` that the Mellin integrand requires.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.EtaVariation
import Core.F1.Analysis.RealCompare

namespace UOR.Bridge.F1Square.Analysis

/-- **Global exp variation**: `1 − e^{−z} ≤ 4·z` for every `z ≥ 0` (no upper bound on `z`). -/
theorem RexpReal_one_sub_neg_le_global {z : Real} (hz0 : Rnonneg z) :
    Rle (Rsub one (RexpReal (Rneg z))) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) z) := by
  rcases Rle_or_Rle (x := z) (q1 := (⟨1, 4⟩ : Q)) (q2 := (⟨1, 2⟩ : Q)) (by decide) (by decide)
      (by decide) with hle | hge
  · -- near regime `z ≤ 1/2`
    exact RexpReal_one_sub_neg_le hz0 hle
  · -- far regime `z ≥ 1/4`: `1 − e^{−z} ≤ 1 ≤ 4z`
    -- `1 − e^{−z} ≤ 1`
    have hexp_nn : Rnonneg (RexpReal (Rneg z)) := RexpReal_nonneg _
    have hneg : Rle (Rneg (RexpReal (Rneg z))) zero :=
      Rle_trans (Rle_Rneg (Rle_zero_of_Rnonneg hexp_nn)) (Rle_of_Req Rneg_zero)
    have hub : Rle (Rsub one (RexpReal (Rneg z))) one :=
      Rle_trans (Radd_le_add (Rle_refl one) hneg) (Rle_of_Req (Radd_zero one))
    -- `1 ≤ 4z`
    have hone : Rle one (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) z) := by
      refine Rle_trans (Rle_of_Req ?_)
        (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by show (0 : Int) ≤ 4; decide)) hge)
      -- `1 = 4·(1/4)`
      refine Req_trans (Req_symm (ofQ_congr (by decide) (by decide)
        (by show Qeq (mul (⟨4, 1⟩ : Q) (⟨1, 4⟩ : Q)) (⟨1, 1⟩ : Q); decide)))
        (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide)))
    exact Rle_trans hub hone

/-- **The peak bound** `X·e^{−X} ≤ 1` for every `X ≥ 0` (the maximum of `x·e^{−x}` is `1/e < 1`).
    Proof: `X ≤ 1 + X ≤ e^X` (`RexpReal_ge_one_add_nonneg`), so `X·e^{−X} ≤ e^X·e^{−X} = 1`. No `π`
    bound, no rational exponent — pure real, used to bound the theta-term Lipschitz modulus
    `aₘ·e^{−aₘ}` (with `aₘ = (m+1)²π` a *real*) without an upper bound on `π`. -/
theorem Rmul_self_exp_neg_le_one {X : Real} (hX : Rnonneg X) :
    Rle (Rmul X (RexpReal (Rneg X))) one := by
  have hXle : Rle X (RexpReal X) :=
    Rle_trans (Rle_self_Radd_left Rnonneg_one) (RexpReal_ge_one_add_nonneg hX)
  refine Rle_trans (Rmul_le_Rmul_right (RexpReal_nonneg _) hXle) (Rle_of_Req ?_)
  exact Req_trans (Rmul_comm (RexpReal X) (RexpReal (Rneg X))) (RexpReal_mul_neg X)

/-- **The exp convexity bound** `u ≤ exp(u−1)` for a real `u ≥ 1` — the exp-side dual of the log bound
    `log q ≤ q−1` (`RartanhBounds.lean`). Directly from `1 + t ≤ exp t` (`RexpReal_ge_one_add_nonneg`) at
    `t = u−1 ≥ 0`, rewriting `1 + (u−1) = u`. Reusable for exponential growth / order-1 estimates. -/
theorem Rle_RexpReal_sub_one {u : Real} (hu : Rle one u) :
    Rle u (RexpReal (Rsub u one)) := by
  have ht : Rnonneg (Rsub u one) := Rnonneg_Rsub_of_Rle hu
  have heq : Req (Radd one (Rsub u one)) u :=
    Req_trans (Radd_comm one (Rsub u one))
      (Req_trans (Radd_assoc u (Rneg one) one)
        (Req_trans (Radd_congr (Req_refl u) (Req_trans (Radd_comm (Rneg one) one) (Radd_neg one)))
          (Radd_zero u)))
  exact Rle_trans (Rle_of_Req (Req_symm heq)) (RexpReal_ge_one_add_nonneg ht)

end UOR.Bridge.F1Square.Analysis
