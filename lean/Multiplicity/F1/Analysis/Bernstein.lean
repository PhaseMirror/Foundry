/-
F1 square — **the Bernstein basis and partition of unity** (`Bernstein.lean`), the Bernstein arc,
sub-brick B. On the real binomial theorem (`RealBinomial.lean`) the Bernstein basis polynomials

    `bernR x n k = b_{n,k}(x) = C(n,k)·xᵏ·(1−x)ⁿ⁻ᵏ`

are introduced, and their **partition of unity** `Σ_{k=0}^n b_{n,k}(x) = 1` (`bernR_partition`) is
read off the binomial theorem at `(a, b) = (x, 1−x)`, since `x + (1−x) = 1` and `1ⁿ = 1`.

WHY (the Sonine route, step 3, the Mellin FRONT). The Bernstein operator `B_n(φ)(x) = Σ_k φ(k/n)
b_{n,k}(x)` is the constructive approximation engine that general (bounded-Lipschitz) moment determinacy
and Mellin inversion both reduce to; its convergence rests on the three Bernstein moment identities, of
which the partition of unity is the first (and the normalization every later estimate divides by). This
brick pins the basis and that identity; the mean and variance identities follow.

HONEST SCOPE. The Bernstein basis and the partition of unity, over `Real`. Infrastructure for the
determinacy/inversion arc; NOT the mean/variance identities yet, NOT convergence, NOT inversion, NOT
positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.RealBinomial

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- The real **Bernstein basis polynomial** `b_{n,k}(x) = C(n,k)·xᵏ·(1−x)ⁿ⁻ᵏ`. -/
def bernR (x : Real) (n k : Nat) : Real := binTermR x (Rsub one x) n k

/-- `x + (1 − x) ≈ 1`. -/
private theorem radd_sub_self (x : Real) : Req (Radd x (Rsub one x)) one := by
  show Req (Radd x (Radd one (Rneg x))) one
  refine Req_trans (Req_symm (Radd_assoc x one (Rneg x))) ?_
  refine Req_trans (Radd_congr (Radd_comm x one) (Req_refl _)) ?_
  refine Req_trans (Radd_assoc one x (Rneg x)) ?_
  exact Req_trans (Radd_congr (Req_refl one) (Radd_neg x)) (Radd_zero one)

/-- `1ⁿ ≈ 1`. -/
private theorem Rpow_one_base : ∀ n, Req (Rpow one n) one
  | 0 => Req_refl one
  | k + 1 => Req_trans (Rone_mul (Rpow one k)) (Rpow_one_base k)

/-- **★ PARTITION OF UNITY**: `Σ_{k=0}^n b_{n,k}(x) = 1`. The binomial theorem at `(x, 1−x)` gives the
    sum as `(x + (1−x))ⁿ = 1ⁿ = 1`. -/
theorem bernR_partition (x : Real) (n : Nat) : Req (RsumN (bernR x n) (n + 1)) one := by
  refine Req_symm (Req_trans ?_ (Rbinomial x (Rsub one x) n))
  refine Req_trans (Req_symm (Rpow_one_base n)) ?_
  exact Rpow_congr (Req_symm (radd_sub_self x)) n

end Multiplicity.UOR.Bridge.F1Square.Analysis
