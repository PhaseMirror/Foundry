/-
F1 square — **the Archimedean squeeze for Bishop reals** (`RealNullFamily.lean`): if two reals are
within `C/(k+1)` of each other for EVERY `k`, they are equal.

    `(∀ k, |x − y| ≤ C/(k+1))  ⟹  x ≈ y`.

This is the density-argument closer: a continuous quantity pinned within an arbitrarily small rational
gap of a target at every resolution equals the target. The `k`-th real bound
`Rle (Rabs (Rsub x y)) (ofQ ⟨C, k+1⟩)` unfolds at each sequence index `n` to
`|(x−y).seq n| ≤ C/(k+1) + 2/(n+1)`; holding `n` fixed and letting `k` range, the Archimedean lemma
`Qarch_gen` kills the `C/(k+1)` term to leave `|(x−y).seq n| ≤ 2/(n+1)`, which the linear-bound
criterion `Req_of_lin_bound` turns into `x − y ≈ 0`, hence `x ≈ y`.

WHY (rung 6, the real-scale covariance's final step). The covariance capstone shows the combination
`F(c) = cⁿ⁺¹·mellinHat(dilateTestR c φ)` is continuous (`covComb_scale_split`) and constant on the
rationals (`covariance_at_rational_dilateTestR`); approximating `c` by rationals `q_k → c` gives
`|F(c) − mellinHat φ| = |F(c) − F(ofQ q_k)| ≤ C/(k+1)` for every `k` (continuity at a fast-enough rate),
and THIS lemma concludes `F(c) = mellinHat φ` — the real-scale covariance.

HONEST SCOPE. A general Bishop-real equality-from-null-family lemma only. It builds NO covariance, NO
factorization, NO positivity, NO determinacy, NO crux. Step 4 (band-coupling positivity) is RH; the crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.Real
import Foundations.F1.Analysis.RabsLemmas
import Foundations.F1.Analysis.QOrder
import Foundations.F1.Analysis.ROrder

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- Commutativity of `Q` addition (over abstract summands, avoiding blow-up on large sequence terms). -/
private theorem Qadd_comm_q (a b : Q) : Qeq (add a b) (add b a) := by
  simp only [Qeq, add]; push_cast; ring_uor

/-- `a − 0 ≈ a` in `Q`. -/
private theorem Qsub_zero_q (a : Q) : Qeq (Qsub a (⟨0, 1⟩ : Q)) a := by
  simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor

/-- **The Archimedean squeeze**: if `|x − y| ≤ C/(k+1)` for every `k` (as reals), then `x ≈ y`. Fix a
    sequence index `n`; the family gives `|(x−y).seq n| ≤ C/(k+1) + 2/(n+1)` for all `k`, so `Qarch_gen`
    yields `|(x−y).seq n| ≤ 2/(n+1)`; `Req_of_lin_bound` turns that into `x − y ≈ 0`, hence `x ≈ y`. -/
theorem Req_of_real_null_family {x y : Real} {C : Nat}
    (h : ∀ k, Rle (Rabs (Rsub x y)) (ofQ (⟨(C : Int), k + 1⟩ : Q) (Nat.succ_pos k))) :
    Req x y := by
  have key : ∀ n, Qle (Qabs ((Rsub x y).seq n)) (⟨2, n + 1⟩ : Q) := by
    intro n
    refine Qarch_gen (C := C) (Qabs_den_pos ((Rsub x y).den_pos n)) (Nat.succ_pos n) (fun k => ?_)
    exact Qle_trans (add_den_pos (Nat.succ_pos k) (Nat.succ_pos n)) (h k n)
      (Qeq_le (Qadd_comm_q _ _))
  have hz : Req (Rsub x y) zero := by
    refine Req_of_lin_bound (C := 2) (fun n => ?_)
    exact Qle_trans (Qabs_den_pos ((Rsub x y).den_pos n))
      (Qeq_le (Qabs_Qeq (Qsub_zero_q ((Rsub x y).seq n)))) (key n)
  have hid : Req x (Radd (Rsub x y) y) :=
    Req_symm (Req_trans (Radd_assoc x (Rneg y) y)
      (Req_trans (Radd_congr (Req_refl x)
        (Req_trans (Radd_comm (Rneg y) y) (Radd_neg y))) (Radd_zero x)))
  exact Req_trans hid
    (Req_trans (Radd_congr hz (Req_refl y)) (Req_trans (Radd_comm zero y) (Radd_zero y)))

end Multiplicity.UOR.Bridge.F1Square.Analysis
