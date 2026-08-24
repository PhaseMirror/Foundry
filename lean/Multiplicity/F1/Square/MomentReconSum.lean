/-
F1 square — **the operator pairing IS the moment reconstruction sum** (`MomentReconSum.lean`), the
Mellin-inversion arc, sub-brick I₂. The Bernstein operator of a test `ψ` is
`B_n(ψ) = Σ_{k=0}^n ψ(k/n)·C(n,k)·xᵏ(1−x)ⁿ⁻ᵏ`; pairing it against `φ` and distributing over the finite
sum (`innerI_L2sumN`), pulling each real coefficient through (`innerI_constMul`, H₃), and rewriting each
single-basis integral as a finite difference of moments (`clampProd_integral_eq_momDiff`, I₁) gives

    `⟨φ, B_n(ψ)⟩ = Σ_{k=0}^n ψ(k/n)·C(n,k)·(Δⁿ⁻ᵏμ)_k`   (`innerI_bernOpCTest_eq_reconSum`),

the **reconstruction sum** (`bernReconSum`). Its right-hand side depends on `φ` ONLY through the finite
differences `(Δⁿ⁻ᵏμ)_k = momDiff φ k (n−k)` of `φ`'s moment sequence — so the pairing of `φ` with any
Bernstein-operated test is computed from `φ`'s moment data alone. This is the algebraic backbone of the
weak (pairing) inversion of the moment map.

WHY (the Sonine route, step 3, the Mellin FRONT). Determinacy (I₁ and the H-arc) is the transform pair's
injectivity half: the moments pin `φ`. Inversion is the constructive recovery, and its weak form recovers
the pairing action: since `B_n(ψ) → ψ` (Bernstein's theorem), one expects `⟨φ,ψ⟩ = lim_n ⟨φ, B_n(ψ)⟩`,
and this brick evaluates the right-hand side as an explicit moment sum. So `⟨φ,ψ⟩` becomes a limit of
quantities read off `φ`'s moments — reconstruction of the whole pairing functional from the transform
data. The convergence `⟨φ, B_n(ψ)⟩ → ⟨φ,ψ⟩` is the next step.

HONEST SCOPE. The exact identity `⟨φ, B_n(ψ)⟩ = bernReconSum φ ψ n`, over `Real`; `bernReconSum` reads
`φ` only through the finite differences of its moments. Infrastructure for inversion; NOT the convergence
`B_n(ψ) → ψ` under the pairing, NOT inversion, NOT the transform pair's surjectivity, NOT positivity.
Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.BernsteinOperatorTest
import Multiplicity.F1.Square.MomentFiniteDiff

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The pairing distributes over a finite sum of tests**: `⟨φ, Σ_{k<N} g k⟩ = Σ_{k<N} ⟨φ, g k⟩`.
    The general (non-null) companion of `innerI_L2sumN_zero`: `innerI_add_right` on each step, `RsumN`'s
    own successor, and the empty pairing `⟨φ, 0⟩ ≈ 0` at the base. -/
theorem innerI_L2sumN (φ : L2Test) (g : Nat → L2Test) :
    ∀ N, Req (innerI φ (L2sumN g N)) (RsumN (fun k => innerI φ (g k)) N)
  | 0 => Req_trans (innerI_symm φ zeroL2) (innerI_zeroL2 φ)
  | N + 1 =>
    Req_trans (innerI_add_right φ (L2sumN g N) (g N))
      (Radd_congr (innerI_L2sumN φ g N) (Req_refl _))

/-- **The Bernstein reconstruction sum on the moment data of `φ`**: the operator's coefficients
    `ψ(k/n)·C(n,k)` (`bernCoef`) weighting the finite differences `(Δⁿ⁻ᵏμ)_k = momDiff φ k (n−k)` of
    `φ`'s moments. This is `⟨φ, B_n(ψ)⟩` written purely in terms of `φ`'s moment sequence. -/
def bernReconSum (φ ψ : L2Test) (n : Nat) (hn : 0 < n) : Real :=
  RsumN (fun k => Rmul (bernCoef ψ n hn k) (momDiff φ k (n - k))) (n + 1)

/-- **★ THE OPERATOR PAIRING IS THE RECONSTRUCTION SUM**: `⟨φ, B_n(ψ)⟩ = bernReconSum φ ψ n`. Distribute
    the pairing over the operator's finite sum (`innerI_L2sumN`); each term is a constant test times a
    single Bernstein basis factor, so `innerI_constMul` (H₃) pulls the real coefficient `ψ(k/n)·C(n,k)`
    out and `clampProd_integral_eq_momDiff` (I₁) turns the residual `⟨φ, xᵏ(1−x)ⁿ⁻ᵏ⟩` into the finite
    difference `(Δⁿ⁻ᵏμ)_k`. No signed binomial coefficients and no operator `.f x` reduction appear — the
    identity lives entirely at the pairing level. -/
theorem innerI_bernOpCTest_eq_reconSum (φ ψ : L2Test) (n : Nat) (hn : 0 < n) :
    Req (innerI φ (bernOpCTest ψ n hn)) (bernReconSum φ ψ n hn) := by
  refine Req_trans (innerI_L2sumN φ (bernTermCTest ψ n hn) (n + 1)) ?_
  refine RsumN_congr (n + 1) (fun k _ => ?_)
  refine Req_trans (innerI_constMul φ (clampProdTest k (n - k)) (bernCoef ψ n hn k)
    (Qmul_den_pos ψ.hMd Nat.one_pos)
    (Int.mul_nonneg ψ.hMn (Int.ofNat_nonneg (choose n k)))
    (bernCoef_bound ψ n hn k)) ?_
  exact Rmul_congr (Req_refl _) (clampProd_integral_eq_momDiff φ (n - k) k)

end Multiplicity.UOR.Bridge.F1Square.Square
