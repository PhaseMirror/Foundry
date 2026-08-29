/-
F1 square — **the Bernstein convergence core: the first absolute central moment** (`BernsteinConverge.lean`),
the Bernstein arc, sub-brick F. On the variance (`BernsteinVariance.lean`) the sqrt-free convergence
estimate is assembled:

    `2δ·Σ_{k=0}^n |k − nx|·b_{n,k}(x) ≤ δ² + nx(1−x)`   (`bernR_abs_moment`, for `x ∈ [0,1]`, any `δ > 0`).

WHY (the Sonine route, step 3, the Mellin FRONT). Bernstein's theorem bounds `|B_n(φ)(x) − φ(x)| ≤
L·Σ|k/n − x|·b_{n,k}(x)` for an `L`-Lipschitz test `φ`, so the whole convergence rests on the first
absolute central moment of the basis. Classically that moment is bounded by `√(variance)` (Cauchy–Schwarz)
and the sum is split into a near band and a far band by `|k/n − x| ≷ δ` — but over the constructive reals
BOTH moves are unavailable: there is no `sqrt`, and `|k/n − x| ≤ δ` is undecidable for a real `x`. The
constructive substitute is the pointwise AM-GM `2δ|t| ≤ δ² + t²` (from `(δ − |t|)² ≥ 0`, `amgm_2delta`),
which needs neither: summed against the nonnegative basis (`bernR_nonneg`, `RsumN_le`) and closed by the
variance (`bernR_variance`) and the partition of unity (`bernR_partition`), it lands the bound directly.
Choosing `δ` small then `n` large drives the right side to `0` — the convergence, with no `sqrt` and no
case split.

HONEST SCOPE. The first absolute central moment of the Bernstein basis, over `Real`. Infrastructure for
the determinacy/inversion arc; NOT yet the Bernstein operator on a test, NOT the moment-integral, NOT
determinacy, NOT inversion, NOT positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.BernsteinVariance
import Foundations.F1.Analysis.RabsLemmas
import Foundations.F1.Analysis.ThetaLipschitz

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The Bernstein basis is nonnegative on `[0,1]`**: `b_{n,k}(x) = C(n,k)·xᵏ·(1−x)ⁿ⁻ᵏ ≥ 0` when
    `x ≥ 0` and `1 − x ≥ 0` — a product of nonnegatives. -/
theorem bernR_nonneg (x : Real) (hx : Rnonneg x) (h1x : Rnonneg (Rsub one x)) (n k : Nat) :
    Rnonneg (bernR x n k) :=
  Rnonneg_Rmul (Rnonneg_ofQ Nat.one_pos (Int.ofNat_nonneg (choose n k)))
    (Rnonneg_Rmul (Rnonneg_Rpow hx k) (Rnonneg_Rpow h1x (n - k)))

set_option maxHeartbeats 1600000 in
/-- **The pointwise AM-GM bound** `2δ·|t| ≤ δ² + t²` for any real `t` and rational `δ ≥ 0` — the
    sqrt-free, split-free substitute for Cauchy–Schwarz. From `(δ − |t|)² ≥ 0` (`Rnonneg_Rmul_self`),
    expanded by `Rsub_sq_expand`, with `|t|² = t²` (`Rabs_of_nonneg` on the square). -/
theorem amgm_2delta (δ : Q) (hδd : 0 < δ.den) (t : Real) :
    Rle (Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) (Qmul_den_pos Nat.one_pos hδd)) (Rabs t))
        (Radd (ofQ (mul δ δ) (Qmul_den_pos hδd hδd)) (Rmul t t)) := by
  have hsq : Rnonneg (Rmul (Rsub (ofQ δ hδd) (Rabs t)) (Rsub (ofQ δ hδd) (Rabs t))) :=
    Rnonneg_Rmul_self _
  have hexp := Rsub_sq_expand (ofQ δ hδd) (Rabs t)
  have hle0 : Rle zero (Rsub (Radd (Rmul (ofQ δ hδd) (ofQ δ hδd)) (Rmul (Rabs t) (Rabs t)))
      (Radd (Rmul (ofQ δ hδd) (Rabs t)) (Rmul (ofQ δ hδd) (Rabs t)))) :=
    Rle_trans (Rle_zero_of_Rnonneg hsq) (Rle_of_Req hexp)
  have hle := Rle_of_Rnonneg_Rsub (Rnonneg_of_Rle_zero hle0)
  have hcoef : Req (ofQ (mul (⟨2, 1⟩ : Q) δ) (Qmul_den_pos Nat.one_pos hδd))
      (Radd (ofQ δ hδd) (ofQ δ hδd)) :=
    Req_trans (ofQ_congr (Qmul_den_pos Nat.one_pos hδd) (add_den_pos hδd hδd)
        (by show Qeq (mul (⟨2, 1⟩ : Q) δ) (add δ δ); simp only [Qeq, mul, add]; push_cast; ring_uor))
      (Req_symm (Radd_ofQ_ofQ hδd hδd))
  have hLHS : Req (Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) (Qmul_den_pos Nat.one_pos hδd)) (Rabs t))
      (Radd (Rmul (ofQ δ hδd) (Rabs t)) (Rmul (ofQ δ hδd) (Rabs t))) :=
    Req_trans (Rmul_congr hcoef (Req_refl (Rabs t)))
      (Rmul_distrib_right (ofQ δ hδd) (ofQ δ hδd) (Rabs t))
  have hRHS : Req (Radd (Rmul (ofQ δ hδd) (ofQ δ hδd)) (Rmul (Rabs t) (Rabs t)))
      (Radd (ofQ (mul δ δ) (Qmul_den_pos hδd hδd)) (Rmul t t)) :=
    Radd_congr (Rmul_ofQ_ofQ hδd hδd)
      (Req_trans (Req_symm (Rabs_Rmul t t)) (Rabs_of_nonneg (Rnonneg_Rmul_self t)))
  exact Rle_trans (Rle_of_Req hLHS) (Rle_trans hle (Rle_of_Req hRHS))

/-- **★ THE FIRST ABSOLUTE CENTRAL MOMENT BOUND**: `2δ·Σ_{k=0}^n |k − nx|·b_{n,k}(x) ≤ δ² + nx(1−x)`
    for `x ∈ [0,1]` and any `δ > 0`. The sqrt-free, split-free heart of Bernstein convergence: the
    per-term AM-GM `2δ|k−nx| ≤ δ² + (k−nx)²` (`amgm_2delta`), summed against the nonnegative basis
    (`RsumN_le`, `bernR_nonneg`) and closed by the variance (`bernR_variance`) and partition
    (`bernR_partition`). -/
theorem bernR_abs_moment (x : Real) (hx : Rnonneg x) (h1x : Rnonneg (Rsub one x))
    (n : Nat) (δ : Q) (hδd : 0 < δ.den) :
    Rle (Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) (Qmul_den_pos Nat.one_pos hδd))
              (RsumN (fun k => Rmul (Rabs (Rsub (RofNat k) (Rmul (RofNat n) x))) (bernR x n k)) (n + 1)))
        (Radd (ofQ (mul δ δ) (Qmul_den_pos hδd hδd))
              (Rmul (Rmul (RofNat n) x) (Rsub one x))) := by
  have per_term : ∀ k, k < n + 1 →
      Rle (Rmul (Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) (Qmul_den_pos Nat.one_pos hδd))
                  (Rabs (Rsub (RofNat k) (Rmul (RofNat n) x)))) (bernR x n k))
          (Rmul (Radd (ofQ (mul δ δ) (Qmul_den_pos hδd hδd))
                  (Rmul (Rsub (RofNat k) (Rmul (RofNat n) x)) (Rsub (RofNat k) (Rmul (RofNat n) x))))
                (bernR x n k)) :=
    fun k _ => Rmul_le_Rmul_right (bernR_nonneg x hx h1x n k)
      (amgm_2delta δ hδd (Rsub (RofNat k) (Rmul (RofNat n) x)))
  have lhs_eq : Req (Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) (Qmul_den_pos Nat.one_pos hδd))
        (RsumN (fun k => Rmul (Rabs (Rsub (RofNat k) (Rmul (RofNat n) x))) (bernR x n k)) (n + 1)))
      (RsumN (fun k => Rmul (Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) (Qmul_den_pos Nat.one_pos hδd))
                  (Rabs (Rsub (RofNat k) (Rmul (RofNat n) x)))) (bernR x n k)) (n + 1)) :=
    Req_trans (Req_symm (RsumN_Rmul_const _ _ (n + 1)))
      (RsumN_congr (n + 1) (fun k _ => Req_symm (Rmul_assoc _ _ _)))
  have rhs_eq : Req
      (RsumN (fun k => Rmul (Radd (ofQ (mul δ δ) (Qmul_den_pos hδd hδd))
                  (Rmul (Rsub (RofNat k) (Rmul (RofNat n) x)) (Rsub (RofNat k) (Rmul (RofNat n) x))))
                (bernR x n k)) (n + 1))
      (Radd (ofQ (mul δ δ) (Qmul_den_pos hδd hδd)) (Rmul (Rmul (RofNat n) x) (Rsub one x))) := by
    refine Req_trans (RsumN_congr (n + 1) (fun k _ => Rmul_distrib_right _ _ (bernR x n k))) ?_
    refine Req_trans (RsumN_Radd _ _ (n + 1)) ?_
    refine Radd_congr ?_ (bernR_variance x n)
    exact Req_trans (RsumN_Rmul_const _ (bernR x n) (n + 1))
      (Req_trans (Rmul_congr (Req_refl _) (bernR_partition x n)) (Rmul_one _))
  exact Rle_trans (Rle_of_Req lhs_eq) (Rle_trans (RsumN_le (n + 1) per_term) (Rle_of_Req rhs_eq))

end Multiplicity.UOR.Bridge.F1Square.Square
