/-
F1 square — **the Bernstein operator and pointwise deviation** (`BernsteinDeviation.lean`), the
Bernstein arc, sub-brick G. On the convergence core (`BernsteinConverge.lean`) the Bernstein operator
`B_n(φ)(x) = Σ_{k=0}^n φ(k/n)·b_{n,k}(x)` (`bernOp`, for `n ≥ 1`) is introduced and its pointwise
distance to `φ` is bounded by the first absolute central moment:

    `|B_n(φ)(x) − φ(x)| ≤ L·Σ_{k=0}^n |k/n − x|·b_{n,k}(x)`   (`bernOp_deviation`, on `[0,1]`).

WHY (the Sonine route, step 3, the Mellin FRONT). This is Bernstein's theorem itself: `φ(x) = φ(x)·Σb`
(partition of unity), so `B_n(φ)(x) − φ(x) = Σ(φ(k/n) − φ(x))·b_{n,k}(x)`; the triangle inequality on
the finite sum (`RsumN_Rabs_le`, basis `≥ 0`) and the Lipschitz modulus `|φ(k/n) − φ(x)| ≤ L|k/n − x|`
(the `L2Test` field `hlip`) give the bound. With `bernR_abs_moment` (sub-brick F) the right side is
`≤ (L/2δ)(δ² + nx(1−x))`, which `→ 0` for suitable `δ`, `n` — the convergence, sqrt-free and split-free.

HONEST SCOPE. The Bernstein operator and the pointwise deviation bound, over `Real`. Infrastructure for
the determinacy/inversion arc; NOT yet the moment-integral, NOT determinacy, NOT inversion, NOT
positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.BernsteinConverge
import Multiplicity.F1Square.Analysis.IntegralInner

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The rational sample point `k/n` as a real (for `n ≥ 1`). Kept `irreducible` so the free-variable
    denominator `n` never triggers a `whnf` blow-up; the proofs use it only symbolically. -/
def ratPt (k n : Nat) (hn : 0 < n) : Real := ofQ (⟨(k : Int), n⟩ : Q) hn

attribute [local irreducible] ratPt bernR

/-- The **Bernstein operator** `B_n(φ)(x) = Σ_{k=0}^n φ(k/n)·b_{n,k}(x)` (for `n ≥ 1`). -/
def bernOp (φ : L2Test) (n : Nat) (hn : 0 < n) (x : Real) : Real :=
  RsumN (fun k => Rmul (φ.f (ratPt k n hn)) (bernR x n k)) (n + 1)

/-- Unfolding equation for `bernOp` — used to rewrite before matching, so `bernOp` never unfolds during
    unification (which would re-expose the sealed `ratPt`). -/
theorem bernOp_unfold (φ : L2Test) (n : Nat) (hn : 0 < n) (x : Real) :
    bernOp φ n hn x = RsumN (fun k => Rmul (φ.f (ratPt k n hn)) (bernR x n k)) (n + 1) := rfl

set_option maxHeartbeats 1600000 in
theorem bernOp_deviation (φ : L2Test) (n : Nat) (hn : 0 < n) (x : Real)
    (hx : Rnonneg x) (h1x : Rnonneg (Rsub one x)) :
    Rle (Rabs (Rsub (bernOp φ n hn x) (φ.f x)))
        (Rmul (ofQ φ.L φ.hLd)
          (RsumN (fun k => Rmul (Rabs (Rsub (ratPt k n hn) x)) (bernR x n k)) (n + 1))) := by
  have hfx : Req (φ.f x) (RsumN (fun k => Rmul (φ.f x) (bernR x n k)) (n + 1)) :=
    Req_trans (Req_symm (Rmul_one (φ.f x)))
      (Req_trans (Rmul_congr (Req_refl _) (Req_symm (bernR_partition x n)))
        (Req_symm (RsumN_Rmul_const (φ.f x) (bernR x n) (n + 1))))
  have hdiff : Req (Rsub (bernOp φ n hn x) (φ.f x))
      (RsumN (fun k => Rmul (Rsub (φ.f (ratPt k n hn)) (φ.f x)) (bernR x n k)) (n + 1)) := by
    rw [bernOp_unfold]
    refine Req_trans (Rsub_congr (Req_refl _) hfx) ?_
    refine Req_trans (Req_symm (RsumN_Rsub _ _ (n + 1))) ?_
    exact RsumN_congr (n + 1) (fun k _ => Req_symm (Rmul_sub_distrib_right _ _ (bernR x n k)))
  -- per-term Lipschitz bound
  have per_term : ∀ k, k < n + 1 →
      Rle (Rabs (Rmul (Rsub (φ.f (ratPt k n hn)) (φ.f x)) (bernR x n k)))
          (Rmul (ofQ φ.L φ.hLd) (Rmul (Rabs (Rsub (ratPt k n hn) x)) (bernR x n k))) := by
    intro k _
    refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
    refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl _)
      (Rabs_of_nonneg (bernR_nonneg x hx h1x n k)))) ?_
    refine Rle_trans (Rmul_le_Rmul_right (bernR_nonneg x hx h1x n k) (φ.hlip _ _)) ?_
    exact Rle_of_Req (Rmul_assoc (ofQ φ.L φ.hLd) (Rabs (Rsub (ratPt k n hn) x)) (bernR x n k))
  -- assemble
  have s1 : Rle (Rabs (Rsub (bernOp φ n hn x) (φ.f x)))
      (RsumN (fun k => Rabs (Rmul (Rsub (φ.f (ratPt k n hn)) (φ.f x)) (bernR x n k))) (n + 1)) :=
    Rle_trans (Rle_of_Req (Rabs_congr hdiff))
      (RsumN_Rabs_le (fun k => Rmul (Rsub (φ.f (ratPt k n hn)) (φ.f x)) (bernR x n k)) (n + 1))
  have s2 : Rle (RsumN (fun k => Rabs (Rmul (Rsub (φ.f (ratPt k n hn)) (φ.f x)) (bernR x n k))) (n + 1))
      (RsumN (fun k => Rmul (ofQ φ.L φ.hLd) (Rmul (Rabs (Rsub (ratPt k n hn) x)) (bernR x n k))) (n + 1)) :=
    RsumN_le (n + 1) per_term
  have s3 : Req (RsumN (fun k => Rmul (ofQ φ.L φ.hLd) (Rmul (Rabs (Rsub (ratPt k n hn) x)) (bernR x n k))) (n + 1))
      (Rmul (ofQ φ.L φ.hLd)
        (RsumN (fun k => Rmul (Rabs (Rsub (ratPt k n hn) x)) (bernR x n k)) (n + 1))) :=
    RsumN_Rmul_const (ofQ φ.L φ.hLd)
      (fun k => Rmul (Rabs (Rsub (ratPt k n hn) x)) (bernR x n k)) (n + 1)
  exact Rle_trans s1 (Rle_trans s2 (Rle_of_Req s3))

end Multiplicity.UOR.Bridge.F1Square.Square
