/-
F1 square — **the Bernstein–Durrmeyer operator is computable from the moments** (`MomentDurrmeyer.lean`),
the Mellin-inversion arc, sub-brick J₁ — the FIRST step toward pointwise reconstruction of a test from its
moments. The Durrmeyer operator is the positive summability operator

    `durrOp φ n x = (n+1)·Σ_{k=0}^n b_{n,k}(x)·⟨φ, b_{n,k}⟩`,

with `⟨φ, b_{n,k}⟩ = ∫₀¹ φ(t)·b_{n,k}(t) dt` the pairing against the Bernstein basis test. Unlike the
Bernstein operator `B_n(φ)` (which uses the point *values* `φ(k/n)`), the Durrmeyer operator uses the
*integrals* `⟨φ, b_{n,k}⟩`, and those are exactly moment data: each is the scaled finite difference

    `⟨φ, b_{n,k}⟩ = C(n,k)·(Δⁿ⁻ᵏμ)_k`   (`innerI_bernBasis_eq_momDiff`, via `innerI_natScale_right` + I₁),

so `durrOp` is reconstructed from `φ`'s moment sequence alone (`durrOp_eq_momData`). This makes `durrOp`
the candidate for *pointwise* inversion: `durrOp φ n x` is a function of `x`, computed from moments, and (as
a standard positive kernel) `→ φ(x)`.

WHY (the Sonine route, step 3, the Mellin FRONT). Weak inversion (I₃b) recovers the *pairing* `⟨φ,ψ⟩`;
strong inversion recovers `φ(x)` itself. The Durrmeyer operator is the right vehicle — a positive kernel
`(n+1)Σ_k b_{n,k}(x)b_{n,k}(t)` with `∫₀¹ = 1`, no boundary or free-`x` pathology — and this brick shows its
value is moment-computable. The kernel's normalization and second-moment estimate (the convergence) are the
next steps.

HONEST SCOPE. The identity `durrOp φ n x = (moment-data sum)` and the single-basis moment value, over
`Real`. Infrastructure for pointwise inversion; NOT the normalization, NOT the second-moment estimate, NOT
the convergence `durrOp φ n x → φ(x)`, NOT inversion, NOT positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MomentReconSum
import Foundations.F1.Square.ContinuousMomentGenScale

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- `natScale` is `@[irreducible]`; re-derive its two defining equations as propositional `rfl`s so the
-- pairing scaling can recurse without forcing the seal.
unseal natScale in
private theorem natScale_zero' (φ : L2Test) : natScale 0 φ = zeroL2 := rfl

unseal natScale in
private theorem natScale_succ' (k : Nat) (φ : L2Test) :
    natScale (k + 1) φ = L2Test.add φ (natScale k φ) := rfl

/-- `≈` transports through the real `ℕ`-scaling `natScaleR`. -/
private theorem natScaleR_congr {a b : Real} (hab : Req a b) :
    ∀ m, Req (natScaleR m a) (natScaleR m b)
  | 0 => Req_refl zero
  | m + 1 => Radd_congr hab (natScaleR_congr hab m)

/-- **The pairing scales in the second slot**: `⟨φ, natScale m χ⟩ = natScaleR m ⟨φ, χ⟩` — the general
    (real-valued) companion of `innerI_natScale_zero`, by `innerI_add_right` on each `natScale` step. -/
theorem innerI_natScale_right (φ χ : L2Test) :
    ∀ m, Req (innerI φ (natScale m χ)) (natScaleR m (innerI φ χ))
  | 0 => by rw [natScale_zero']; exact Req_trans (innerI_symm φ zeroL2) (innerI_zeroL2 φ)
  | m + 1 => by
    rw [natScale_succ']
    exact Req_trans (innerI_add_right φ χ (natScale m χ))
      (Radd_congr (Req_refl _) (innerI_natScale_right φ χ m))

/-- **★ THE DURRMEYER COEFFICIENT IS A SCALED FINITE DIFFERENCE OF MOMENTS**:
    `⟨φ, b_{n,k}⟩ = C(n,k)·(Δⁿ⁻ᵏμ)_k`. The basis test is `C(n,k)·clamp01ᵏ(1−clamp01)ⁿ⁻ᵏ`
    (`natScale (choose n k)` of `clampProdTest`); `innerI_natScale_right` pulls the `C(n,k)` scaling out
    and `clampProd_integral_eq_momDiff` (I₁) turns the residual into the finite difference. -/
theorem innerI_bernBasis_eq_momDiff (φ : L2Test) (n k : Nat) :
    Req (innerI φ (bernBasisTest n k)) (natScaleR (choose n k) (momDiff φ k (n - k))) :=
  Req_trans (innerI_natScale_right φ (clampProdTest k (n - k)) (choose n k))
    (natScaleR_congr (clampProd_integral_eq_momDiff φ (n - k) k) (choose n k))

/-- **The Bernstein–Durrmeyer operator** `durrOp φ n x = (n+1)·Σ_{k=0}^n b_{n,k}(x)·⟨φ, b_{n,k}⟩` — the
    positive summability operator built from the *integrals* `⟨φ, b_{n,k}⟩` (vs. `B_n`'s point values). -/
def durrOp (φ : L2Test) (n : Nat) (x : Real) : Real :=
  Rmul (RofNat (n + 1))
    (RsumN (fun k => Rmul (bernR x n k) (innerI φ (bernBasisTest n k))) (n + 1))

/-- **★ THE DURRMEYER OPERATOR IS COMPUTABLE FROM THE MOMENTS**:
    `durrOp φ n x = (n+1)·Σ_k b_{n,k}(x)·C(n,k)·(Δⁿ⁻ᵏμ)_k` — every Durrmeyer coefficient replaced by its
    moment expression (`innerI_bernBasis_eq_momDiff`), so the whole operator reads `φ` only through its
    moment sequence. -/
theorem durrOp_eq_momData (φ : L2Test) (n : Nat) (x : Real) :
    Req (durrOp φ n x)
        (Rmul (RofNat (n + 1))
          (RsumN (fun k => Rmul (bernR x n k)
            (natScaleR (choose n k) (momDiff φ k (n - k)))) (n + 1))) :=
  Rmul_congr (Req_refl _)
    (RsumN_congr (n + 1) (fun k _ =>
      Rmul_congr (Req_refl _) (innerI_bernBasis_eq_momDiff φ n k)))

end Multiplicity.UOR.Bridge.F1Square.Square
