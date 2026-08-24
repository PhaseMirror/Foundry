/-
F1 square — **the on-object angle embedding and its exact diagonal** (`AngleGramDiagonal.lean`),
completing the on-object SOS structure of the finite-rank fence. The **on-object angle embedding**
sends each pair of coordinates to the sine-square block `(1 − cos(nθ_k), sin(nθ_k))`; its Gram diagonal
is *exactly* the sum of the per-zero blocks:

    `gramOf (angleEmb θ) (2m) n n = Σ_{k<m} (2 − 2cos(nθ_k))`   (`angleGram_diag`).

On the critical line (`θ_k = arg(1 − 1/ρ_k)`, so `|1 − 1/ρ_k| = 1`) each block is `2·(1 − cos(nθ_k))`,
twice the per-zero Li term `1 − Re((1−1/ρ_k)ⁿ)`, so the diagonal is `Σ_ρ 2(1 − cos nθ_ρ) = 2λₙ`: the
on-object SOS certificate for `2λₙ` on the line, one two-square block per zero. Composed with the fence
(`gramDiag_uniform_bound`, entries in `[−2,2]`) this pins that certificate as **infinite-rank** — the
`Σ_ρ` over zeros cannot be truncated.

The diagonal identity is the finite `RsumN` pair-fold: the degree-`2(m+1)` Gram is the degree-`2m` Gram
plus the `m`-th block `(1−cos)² + sin²`, which `sineSquarePair` collapses to `2 − 2cos`.

HONEST SCOPE. Pure trig/algebra on a **free** angle family `θ` (zero-free by type — §6): no zeros, no
`λ`, no claim about the sign or growth of `2λₙ`. This makes the on-object certificate's *structure*
kernel-checked (its diagonal is the sine-square sum); it sharpens the localization and does NOT close or
approach the crux. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1.Square.SineSquareSOS
import Multiplicity.F1.Square.AngleEmbeddingBound

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The **on-object angle embedding** on a free angle family `θ`: even coordinates carry `1 − cos(nθ_k)`,
    odd coordinates `sin(nθ_k)`. On the critical line its Gram diagonal is `2λₙ`. -/
def angleEmb (θ : Nat → Real) : Nat → Nat → Real :=
  fun n k => if k % 2 = 0 then Rsub one (Rcos (nsmulR n (θ (k / 2)))) else Rsin (nsmulR n (θ (k / 2)))

/-- The block-diagonal target `Σ_{k<m} (2 − 2cos(nθ_k))` — twice the on-line Li sum. -/
def angleDiagTarget (θ : Nat → Real) (n : Nat) : Nat → Real
  | 0 => zero
  | (m + 1) => Radd (angleDiagTarget θ n m)
      (Rsub (Radd one one) (Radd (Rcos (nsmulR n (θ m))) (Rcos (nsmulR n (θ m)))))

set_option maxHeartbeats 2000000 in
/-- **★ THE ON-OBJECT DIAGONAL**: the degree-`2m` angle embedding's squared-norm diagonal is exactly
    `Σ_{k<m} (2 − 2cos(nθ_k))` — the sum of the on-object 2-square blocks, one per angle. On the critical
    line this is `2λₙ`; the embedding is the on-object SOS certificate. -/
theorem angleGram_diag (θ : Nat → Real) (n : Nat) :
    ∀ m, Req (gramOf (angleEmb θ) (2 * m) n n) (angleDiagTarget θ n m)
  | 0 => Req_refl _
  | (m + 1) => by
    have hd : 2 * (m + 1) = 2 * m + 1 + 1 := by omega
    rw [hd]
    -- gramOf over (2m+1)+1 = [gramOf over 2m] + [entry_{2m}² + entry_{2m+1}²]  (RsumN pair-fold)
    refine Req_trans (Radd_assoc (gramOf (angleEmb θ) (2 * m) n n)
      (Rmul (angleEmb θ n (2 * m)) (angleEmb θ n (2 * m)))
      (Rmul (angleEmb θ n (2 * m + 1)) (angleEmb θ n (2 * m + 1)))) ?_
    refine Radd_congr (angleGram_diag θ n m) ?_
    -- the m-th pair: (1−cos)² + sin² = 2 − 2cos, at angle nθ_m
    have he : angleEmb θ n (2 * m) = Rsub one (Rcos (nsmulR n (θ m))) := by
      simp only [angleEmb]
      rw [if_pos (show (2 * m) % 2 = 0 by omega), show (2 * m) / 2 = m by omega]
    have ho : angleEmb θ n (2 * m + 1) = Rsin (nsmulR n (θ m)) := by
      simp only [angleEmb]
      rw [if_neg (show ¬ (2 * m + 1) % 2 = 0 by omega), show (2 * m + 1) / 2 = m by omega]
    rw [he, ho]
    exact sineSquarePair (nsmulR n (θ m))

end Multiplicity.UOR.Bridge.F1Square.Square
