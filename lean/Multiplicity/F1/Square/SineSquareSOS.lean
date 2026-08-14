/-
F1 square — **the on-object sine-square block** (`SineSquareSOS.lean`), the kernel-checked heart of the
finite-rank impossibility fence (`AngleEmbeddingBound.lean`). On the critical line the Li term is
`1 − Re((1−1/ρ)ⁿ) = 1 − cos(nθ)` (the modulus `|1−1/ρ| = 1`), and the RH-correct *sum-of-squares*
decomposition of *twice* that term is the atomic 2-square block

    `(1 − cos φ)² + sin²φ = 2 − 2cos φ = 2(1 − cos φ)`   (`sineSquarePair`).

So the on-object certificate for `2λₙ` on the line is `gramOf` of the entries `(1 − cos(nθ_ρ), sin(nθ_ρ))`,
one pair per zero — `2λₙ = Σ_ρ [(1−cos nθ_ρ)² + sin² nθ_ρ] = Σ_ρ 2(1 − cos nθ_ρ)`. Composed with the fence
(`gramDiag_uniform_bound`, whose entries lie in `[−2,2]`), this pins the on-object certificate as
**infinite-rank**: a finite angle Gram is bounded uniformly in `n`, so it cannot host the (classically
unbounded) `2λₙ` — the `Σ_ρ` over zeros cannot be truncated.

HONEST SCOPE. A pure trig/algebra identity on a **free** angle `φ` (zero-free — no zeros, no `λ`, no claim
about the sign or growth of `2λₙ`): the *structure* of the on-object SOS made kernel-checked. It sharpens
the localization and does NOT close or approach the crux. Step 4 (band-coupling positivity) is RH; the
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1Square.Analysis.CosSinAdd
import Multiplicity.F1Square.Analysis.RealPow

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 2000000 in
/-- Algebraic expansion `(1 − c)² = (1 − 2c) + c²`, for a free real `c` (no `show`-unfolding of `Rsub`). -/
private theorem one_sub_sq (c : Real) :
    Req (Rmul (Rsub one c) (Rsub one c)) (Radd (Rsub one (Radd c c)) (Rmul c c)) := by
  -- (1−c)(1−c) = (1−c)·1 − (1−c)·c
  have h1 : Req (Rmul (Rsub one c) (Rsub one c))
      (Rsub (Rsub one c) (Rmul (Rsub one c) c)) :=
    Req_trans (Rmul_sub_distrib (Rsub one c) one c) (Rsub_congr (Rmul_one (Rsub one c)) (Req_refl _))
  -- (1−c)·c = c − c²
  have h2 : Req (Rmul (Rsub one c) c) (Rsub c (Rmul c c)) :=
    Req_trans (Rmul_comm (Rsub one c) c)
      (Req_trans (Rmul_sub_distrib c one c) (Rsub_congr (Rmul_one c) (Req_refl _)))
  refine Req_trans h1 (Req_trans (Rsub_congr (Req_refl _) h2) ?_)
  -- (1−c) − (c − c²) = ((1−c) − c) + c² = (1 − (c+c)) + c²
  refine Req_trans (Rsub_Radd_eq (Rsub one c) c (Rneg (Rmul c c))) ?_
  refine Req_trans (Rsub_neg_eq_add (Rmul c c) (Rsub (Rsub one c) c)) ?_
  refine Req_trans (Radd_comm (Rmul c c) (Rsub (Rsub one c) c)) ?_
  exact Radd_congr (Req_symm (Rsub_Radd_eq one c c)) (Req_refl _)

set_option maxHeartbeats 2000000 in
/-- **★ THE ON-OBJECT 2-SQUARE BLOCK**: `(1 − cos φ)² + sin²φ = 2 − 2cos φ`, for a free angle `φ`. On the
    critical line this is exactly `2·(1 − cos nθ)`, twice the per-zero Li term — the RH-correct sum-of-two-
    squares decomposition. Expand the first square (`one_sub_sq`), regroup, and collapse `cos² + sin² = 1`
    (`Rcos_sq_add_sin_sq`). -/
theorem sineSquarePair (φ : Real) :
    Req (Radd (Rmul (Rsub one (Rcos φ)) (Rsub one (Rcos φ))) (Rmul (Rsin φ) (Rsin φ)))
        (Rsub (Radd one one) (Radd (Rcos φ) (Rcos φ))) := by
  refine Req_trans (Radd_congr (one_sub_sq (Rcos φ)) (Req_refl _)) ?_
  -- ((1 − 2c) + c²) + s² ≈ (1 − 2c) + (c² + s²) ≈ (1 − 2c) + 1
  refine Req_trans (Radd_assoc (Rsub one (Radd (Rcos φ) (Rcos φ)))
    (Rmul (Rcos φ) (Rcos φ)) (Rmul (Rsin φ) (Rsin φ))) ?_
  refine Req_trans (Radd_congr (Req_refl _) (Rcos_sq_add_sin_sq φ)) ?_
  -- (1 − (c+c)) + 1 ≈ (1+1) − (c+c)   [all via Radd_assoc/comm on the defeq Radd/Rneg forms]
  refine Req_trans (Radd_assoc one (Rneg (Radd (Rcos φ) (Rcos φ))) one) ?_
  refine Req_trans (Radd_congr (Req_refl _)
    (Radd_comm (Rneg (Radd (Rcos φ) (Rcos φ))) one)) ?_
  exact Req_symm (Radd_assoc one one (Rneg (Radd (Rcos φ) (Rcos φ))))

end Multiplicity.UOR.Bridge.F1Square.Square
