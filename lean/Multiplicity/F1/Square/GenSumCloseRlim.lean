/-
F1 square — **a partial sum at any faster schedule is within `3/(j+1)` of the accelerated limit**
(`GenSumCloseRlim.lean`): for a generic decay term `T` with `|T m| ≤ K/((m+1)m)` and any integer
schedule `R` cofinal-above the canonical `digammaMidx K` (i.e. `digammaMidx K j ≤ R j`),

    `|genSum T (R j) − Rlim (genSum T ∘ digammaMidx K)| ≤ 3/(j+1)`.

This is the tail estimate the `∫_t` reconstruction of `M[f⋆g]=M[f]·M[g]` needs: the convolution's
outer sum runs on its OWN (`digammaMidx K_conv`) schedule, while the per-`t` dilated tail
`twTail (dilate c_t f) n` is a limit on the `digammaMidx (Cf·2ⁿ)` schedule; this lemma bounds the gap
between the convolution-schedule partial and the dilated-tail limit UNIFORMLY (the constant `Cf·2ⁿ`,
hence the rate, is scale-`c_t`-independent), so `Rlim_eval_real_rate` closes the commute.

Triangle through the canonical partial `genSum T (digammaMidx K j)`: `genSum_close` bounds the
schedule gap by `1/(j+1)`, and `Rabs_dist_Rlim` bounds the canonical partial's distance to its own
limit by `2/(j+1)`; `1/(j+1) + 2/(j+1) = 3/(j+1)`.

HONEST SCOPE. One general lemma about regular `genSum` series (no convolution, no tail assembly, no
covariance, no factorization, no positivity, no crux). Step 4 (band-coupling positivity) is RH; the
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.ImproperScheduleIndep
import Multiplicity.F1Square.Analysis.IntegralCertIrrel

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- `|a − d| ≤ |a − b| + |b − d|` at the real level (triangle through `b`). -/
private theorem Rabs_Rsub_tri (a b d : Real) :
    Rle (Rabs (Rsub a d)) (Radd (Rabs (Rsub a b)) (Rabs (Rsub b d))) := by
  have htel : Req (Rsub a d) (Radd (Rsub a b) (Rsub b d)) := by
    show Req (Radd a (Rneg d)) (Radd (Radd a (Rneg b)) (Radd b (Rneg d)))
    refine Req_symm (Req_trans (Radd_assoc a (Rneg b) (Radd b (Rneg d))) ?_)
    refine Radd_congr (Req_refl a) ?_
    refine Req_trans (Req_symm (Radd_assoc (Rneg b) b (Rneg d))) ?_
    refine Req_trans (Radd_congr (Req_trans (Radd_comm (Rneg b) b) (Radd_neg b))
      (Req_refl (Rneg d))) ?_
    exact Req_trans (Radd_comm zero (Rneg d)) (Radd_zero (Rneg d))
  exact Rle_trans (Rle_of_Req (Rabs_congr htel)) (Rabs_Radd (Rsub a b) (Rsub b d))

/-- **A partial sum at any faster schedule is within `3/(j+1)` of the accelerated limit.** For a
    generic decay term `T` with the two-sided `K/((m+1)m)` bound, and any integer schedule `R` with
    `digammaMidx K j ≤ R j`, `|genSum T (R j) − Rlim (genSum T ∘ digammaMidx K)| ≤ 3/(j+1)`. Triangle:
    `genSum_close` (schedule gap `≤ 1/(j+1)`) + `Rabs_dist_Rlim` (canonical partial to its limit
    `≤ 2/(j+1)`). The rate `3/(j+1)` has NO dependence on anything beyond `T`'s own decay constant
    `K`, so when `T = twTerm (dilateTestR c f) n` (constant `K = Cf·2ⁿ`, scale-independent) it is
    uniform in the dilation scale `c`. -/
theorem genSum_close_Rlim (T : Nat → Real) {K : Q} (hKd : 0 < K.den) (hK0 : 0 ≤ K.num)
    (hb : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul K (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKd (digamma_succ_mul_pos hm)))) (T m)
      ∧ Rle (T m) (ofQ (mul K (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKd (digamma_succ_mul_pos hm))))
    (R : Nat → Nat) (hgrow : ∀ j, digammaMidx K j ≤ R j) (j : Nat) :
    Rle (Rabs (Rsub (genSum T (R j))
          (Rlim (fun i => genSum T (digammaMidx K i)) (genSum_RReg T hKd hK0 hb))))
        (ofQ (⟨3, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  refine Rle_trans
    (Rabs_Rsub_tri (genSum T (R j)) (genSum T (digammaMidx K j))
      (Rlim (fun i => genSum T (digammaMidx K i)) (genSum_RReg T hKd hK0 hb))) ?_
  refine Rle_trans (Radd_le_add
    (genSum_close T hKd hK0 hb R hgrow j)
    (Rabs_dist_Rlim (genSum_RReg T hKd hK0 hb) j)) ?_
  refine Rle_of_Req (Req_trans (Radd_ofQ_ofQ (Nat.succ_pos j) (Nat.succ_pos j)) ?_)
  refine ofQ_congr (a := add (⟨1, j + 1⟩ : Q) (⟨2, j + 1⟩ : Q)) (b := (⟨3, j + 1⟩ : Q))
    (add_den_pos (Nat.succ_pos j) (Nat.succ_pos j)) (Nat.succ_pos j) ?_
  simp only [Qeq, add]; push_cast; ring_uor

end Multiplicity.UOR.Bridge.F1Square.Square
