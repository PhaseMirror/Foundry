/-
F1 square — **the finite differences of the Hilbert moment sequence, in closed form**
(`DurrmeyerMoments.lean`), the Mellin-inversion arc, sub-brick J₂. The Bernstein–Durrmeyer coefficient of
the monomial test `xʲ` is a scaled finite difference of moments (J₁); to evaluate the Durrmeyer operator
on monomials — the moments the pointwise-convergence estimate consumes — one needs those finite
differences in closed form. Since the moment sequence of `xʲ` is the Hilbert-matrix row
`mellinMoment (powTest j) i = 1/(i+j+1)`, its forward finite differences telescope to

    `momDiff (powTest j) k m = m!·(k+j)! / (k+j+m+1)!`   (`momDiff_powTest`),

the finite difference of `1/(k+c)` (`Δᵐ[1/(k+c)] = m!/((k+c)(k+c+1)···(k+c+m))`). Induction on `m`, base
the moment `1/(k+j+1)`; the step is a factorial identity (`(k+j+m+2)−(k+j+1) = m+1` factors the
telescoping), discharged by `ring_uor` on explicit integer atoms.

WHY (the Sonine route, step 3, the Mellin FRONT). This is the exact-value input to the Durrmeyer
pointwise-inversion estimate: `∫₀¹ b_{n,k}(t)·tʲ dt = C(n,k)·momDiff (powTest j) k (n−k)` (J₁), so this
closed form makes the Durrmeyer moments (and hence the second-moment/convergence bound) computable.

HONEST SCOPE. The closed form of `momDiff (powTest j)`, over `Real` (an exact factorial value). NOT the
Durrmeyer moments, NOT the second-moment estimate, NOT convergence, NOT inversion, NOT positivity. Step 4
is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MomentDurrmeyer
import Multiplicity.F1.Square.HilbertGram

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The pure-`ℤ` polynomial identity behind the finite-difference step (`(k+j+m+2)−(k+j+1) = m+1`
    factors the telescoping); `ring_uor` on explicit integer atoms. -/
private theorem durr_step_id (kk jj mm Fm Fkj F1 : Int) :
    (Fm * Fkj * ((kk + jj + mm + 2) * F1) + -(Fm * ((kk + jj + 1) * Fkj)) * F1)
        * ((kk + jj + mm + 2) * F1)
      = (mm + 1) * Fm * Fkj * (F1 * ((kk + jj + mm + 2) * F1)) := by ring_uor

/-- **The finite differences of the Hilbert-matrix moment sequence** — the closed form
    `momDiff (powTest j) k m = m!·(k+j)!/(k+j+m+1)!`. Induction on `m`: base is the moment
    `mellinMoment (powTest j) k = 1/(k+j+1)`; the step is the finite-difference telescoping of `1/(k+c)`,
    a factorial identity discharged by `ring_uor` after `fct_succ` expansions. -/
theorem momDiff_powTest (j : Nat) :
    ∀ m k, Req (momDiff (powTest j) k m)
        (ofQ (⟨((fct m * fct (k + j) : Nat) : Int), fct (k + j + m + 1)⟩ : Q) (fct_pos _))
  | 0, k => by
    refine Req_trans (mellinMoment_powTest j k) (ofQ_congr (Nat.succ_pos (j + k)) (fct_pos _) ?_)
    have hfs : fct (k + j + 0 + 1) = (k + j + 1) * fct (k + j) := by
      have h : k + j + 0 + 1 = (k + j) + 1 := by omega
      rw [h, fct_succ]
    show (1 : Int) * ((fct (k + j + 0 + 1) : Nat) : Int)
        = ((fct 0 * fct (k + j) : Nat) : Int) * ((j + k + 1 : Nat) : Int)
    rw [hfs, show fct 0 = 1 from rfl]
    push_cast
    ring_uor
  | m + 1, k => by
    show Req (Rsub (momDiff (powTest j) k m) (momDiff (powTest j) (k + 1) m)) _
    refine Req_trans (Rsub_congr (momDiff_powTest j m k) (momDiff_powTest j m (k + 1))) ?_
    refine Req_trans (Rsub_ofQ_ofQ (fct_pos _) (fct_pos _))
      (ofQ_congr (add_den_pos (fct_pos _) (fct_pos _)) (fct_pos _) ?_)
    have hb1 : (k + 1) + j = k + j + 1 := by omega
    have hb2 : k + j + 1 + m + 1 = k + j + m + 2 := by omega
    have hc2 : k + j + (m + 1) + 1 = k + j + m + 2 := by omega
    have ekj1 : fct (k + j + 1) = (k + j + 1) * fct (k + j) := fct_succ _
    have em1 : fct (m + 1) = (m + 1) * fct m := fct_succ _
    have ekjm2 : fct (k + j + m + 2) = (k + j + m + 2) * fct (k + j + m + 1) := by
      have h : k + j + m + 2 = (k + j + m + 1) + 1 := by omega
      rw [h, fct_succ]
    simp only [Qeq, add, neg, mul]
    rw [hb1, hb2, hc2, ekj1, em1, ekjm2]
    push_cast
    exact durr_step_id _ _ _ _ _ _

end Multiplicity.UOR.Bridge.F1Square.Square
