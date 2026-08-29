/-
F1 square — **the Bernstein variance identity** (`BernsteinVariance.lean`), the Bernstein arc, sub-brick
E. On the Bernstein moment identities (`BernsteinMoments.lean`) the variance is assembled:

    `Σ_{k=0}^n (k − nx)²·b_{n,k}(x) = nx(1−x)`   (`bernR_variance`).

WHY (the Sonine route, step 3, the Mellin FRONT). The variance is THE estimate the Bernstein operator's
ε-δ convergence divides by (Chebyshev: `Σ_{|k/n−x|>δ} b ≤ x(1−x)/(nδ²) ≤ 1/(4nδ²)`), so it is the
gateway from the moment identities to convergence, and thence to general moment determinacy and Mellin
inversion. The proof expands `(k−nx)²` by `Rsub_sq_expand` into `k² − 2·nx·k + (nx)²`, splits the sum by
`RsumN` linearity into the second factorial moment + mean (`Σk²b = Σk(k−1)b + Σkb`, `bernR_sq` +
`bernR_mean`), the partition of unity (`bernR_partition`), and the doubled cross term, then collapses the
`(nx)²` contributions: `(n(n−1)x² + nx + n²x²) − 2·n²x² = nx − nx² = nx(1−x)`. The real-algebra runs
manually (no `ring` over abstract reals); additive rearrangements go through `Rsub_Radd_Radd`/`Rsub_sq_expand`
and the `n²x²`-cancellation through `var_collapse`. Minted: `RofNat_sub` (`ℕ→ℝ` respects truncated
subtraction).

HONEST SCOPE. The Bernstein variance identity over `Real`. Infrastructure for the determinacy/inversion
arc; NOT the ε-δ convergence yet, NOT the moment-integral, NOT determinacy, NOT inversion, NOT positivity.
Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.BernsteinMoments
import Foundations.F1.Square.PreHilbert

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The `ℕ → ℝ` embedding respects truncated subtraction: `RofNat (a−b) ≈ RofNat a − RofNat b`
    (for `b ≤ a`). -/
theorem RofNat_sub (a b : Nat) (h : b ≤ a) : Req (RofNat (a - b)) (Rsub (RofNat a) (RofNat b)) := by
  have hab : (a - b) + b = a := by omega
  have key : Req (RofNat a) (Radd (RofNat (a - b)) (RofNat b)) := by
    have hadd := RofNat_add (a - b) b
    rw [hab] at hadd
    exact hadd
  refine Req_symm ?_
  show Req (Radd (RofNat a) (Rneg (RofNat b))) (RofNat (a - b))
  refine Req_trans (Radd_congr key (Req_refl _)) ?_
  refine Req_trans (Radd_assoc (RofNat (a - b)) (RofNat b) (Rneg (RofNat b))) ?_
  exact Req_trans (Radd_congr (Req_refl _) (Radd_neg (RofNat b))) (Radd_zero _)

/-- Per-term expansion: `(k − nx)²·b ≈ (k²·b + (nx)²·b) − (k·nx·b + k·nx·b)`. -/
private theorem var_term (x : Real) (n k : Nat) :
    Req (Rmul (Rmul (Rsub (RofNat k) (Rmul (RofNat n) x)) (Rsub (RofNat k) (Rmul (RofNat n) x)))
          (bernR x n k))
        (Rsub (Radd (Rmul (Rmul (RofNat k) (RofNat k)) (bernR x n k))
                    (Rmul (Rmul (Rmul (RofNat n) x) (Rmul (RofNat n) x)) (bernR x n k)))
              (Radd (Rmul (Rmul (RofNat k) (Rmul (RofNat n) x)) (bernR x n k))
                    (Rmul (Rmul (RofNat k) (Rmul (RofNat n) x)) (bernR x n k)))) := by
  refine Req_trans (Rmul_congr (Rsub_sq_expand (RofNat k) (Rmul (RofNat n) x)) (Req_refl _)) ?_
  refine Req_trans (Rmul_sub_distrib_right _ _ (bernR x n k)) ?_
  exact Rsub_congr (Rmul_distrib_right _ _ (bernR x n k)) (Rmul_distrib_right _ _ (bernR x n k))

/-- Per-term: `k²·b ≈ k(k-1)·b + k·b` (since `k² = k(k−1) + k`). -/
private theorem aa_split (x : Real) (n k : Nat) :
    Req (Rmul (Rmul (RofNat k) (RofNat k)) (bernR x n k))
        (Radd (Rmul (RofNat (k * (k - 1))) (bernR x n k)) (Rmul (RofNat k) (bernR x n k))) := by
  have hkk : k * k = k * (k - 1) + k := by
    cases k with
    | zero => rfl
    | succ j => rw [Nat.succ_sub_one]; exact Nat.mul_succ (j + 1) j
  refine Req_trans (Rmul_congr (Req_symm (RofNat_mul k k)) (Req_refl _)) ?_
  rw [hkk]
  refine Req_trans (Rmul_congr (RofNat_add (k * (k - 1)) k) (Req_refl _)) ?_
  exact Rmul_distrib_right _ _ (bernR x n k)

/-- Per-term: `(k·nx)·b ≈ nx·(k·b)` (pull the constant `nx` out). -/
private theorem abeta_pull (x : Real) (n k : Nat) :
    Req (Rmul (Rmul (RofNat k) (Rmul (RofNat n) x)) (bernR x n k))
        (Rmul (Rmul (RofNat n) x) (Rmul (RofNat k) (bernR x n k))) := by
  refine Req_trans (Rmul_congr (Rmul_comm (RofNat k) (Rmul (RofNat n) x)) (Req_refl _)) ?_
  exact Rmul_assoc (Rmul (RofNat n) x) (RofNat k) (bernR x n k)

private theorem Radd_sub_cancel' (X Y : Real) : Req (Rsub (Radd X Y) Y) X :=
  Req_trans (Radd_assoc X Y (Rneg Y))
    (Req_trans (Radd_congr (Req_refl X) (Radd_neg Y)) (Radd_zero X))

private theorem radd_reassoc3 (Q R S : Real) : Req (Radd (Rsub Q R) S) (Radd (Rsub S R) Q) := by
  refine Req_trans (Radd_assoc Q (Rneg R) S) ?_
  refine Req_trans (Radd_congr (Req_refl Q) (Radd_comm (Rneg R) S)) ?_
  exact Radd_comm Q (Radd S (Rneg R))

/-- The `n²x²`-cancellation: `((Q − R) + S + Q) − (Q + Q) ≈ S − R`. -/
private theorem var_collapse (Q R S : Real) :
    Req (Rsub (Radd (Radd (Rsub Q R) S) Q) (Radd Q Q)) (Rsub S R) := by
  refine Req_trans (Rsub_Radd_Radd (Radd (Rsub Q R) S) Q Q Q) ?_
  refine Req_trans (Radd_congr (Req_refl _) (Radd_neg Q)) ?_
  refine Req_trans (Radd_zero _) ?_
  refine Req_trans (Rsub_congr (radd_reassoc3 Q R S) (Req_refl Q)) ?_
  exact Radd_sub_cancel' (Rsub S R) Q

/-- `(nx)² ≈ n²·x²`. -/
private theorem fact_bb (x : Real) (n : Nat) :
    Req (Rmul (Rmul (RofNat n) x) (Rmul (RofNat n) x))
        (Rmul (Rmul (RofNat n) (RofNat n)) (Rmul x x)) := prod_sq_reassoc (RofNat n) x

/-- `n(n−1)·x² ≈ n²x² − n·x²`. -/
private theorem fact_T2 (x : Real) (n : Nat) :
    Req (Rmul (RofNat (n * (n - 1))) (Rmul x x))
        (Rsub (Rmul (Rmul (RofNat n) (RofNat n)) (Rmul x x)) (Rmul (RofNat n) (Rmul x x))) := by
  have hnn : n * (n - 1) = n * n - n := by
    cases n with
    | zero => rfl
    | succ j => rw [Nat.succ_sub_one, Nat.mul_succ, Nat.add_sub_cancel]
  have hle : n ≤ n * n := by
    cases n with
    | zero => omega
    | succ j => exact Nat.le_mul_of_pos_left (j + 1) (Nat.succ_pos j)
  rw [hnn]
  refine Req_trans (Rmul_congr (RofNat_sub (n * n) n hle) (Req_refl _)) ?_
  refine Req_trans (Rmul_congr (Rsub_congr (RofNat_mul n n) (Req_refl _)) (Req_refl _)) ?_
  exact Rmul_sub_distrib_right (Rmul (RofNat n) (RofNat n)) (RofNat n) (Rmul x x)

/-- `nx(1−x) ≈ nx − n·x²`. -/
private theorem target_eq (x : Real) (n : Nat) :
    Req (Rmul (Rmul (RofNat n) x) (Rsub one x))
        (Rsub (Rmul (RofNat n) x) (Rmul (RofNat n) (Rmul x x))) := by
  refine Req_trans (Rmul_sub_distrib (Rmul (RofNat n) x) one x) ?_
  exact Rsub_congr (Rmul_one _) (Rmul_assoc (RofNat n) x x)

/-- **★ THE BERNSTEIN VARIANCE IDENTITY**: `Σ_{k=0}^n (k − nx)²·b_{n,k}(x) = nx(1−x)`. Expand `(k−nx)²`
    (`Rsub_sq_expand`), split the sum into the second factorial moment, the mean, the partition, and the
    doubled cross term (`bernR_sq`, `bernR_mean`, `bernR_partition`), then collapse the `(nx)²` terms
    (`var_collapse`). The estimate the Bernstein convergence divides by. -/
theorem bernR_variance (x : Real) (n : Nat) :
    Req (RsumN (fun k => Rmul (Rmul (Rsub (RofNat k) (Rmul (RofNat n) x))
                                     (Rsub (RofNat k) (Rmul (RofNat n) x)))
                               (bernR x n k)) (n + 1))
        (Rmul (Rmul (RofNat n) x) (Rsub one x)) := by
  have hAA : Req (RsumN (fun k => Rmul (Rmul (RofNat k) (RofNat k)) (bernR x n k)) (n + 1))
      (Radd (Rmul (RofNat (n * (n - 1))) (Rmul x x)) (Rmul (RofNat n) x)) :=
    Req_trans (RsumN_congr (n + 1) (fun k _ => aa_split x n k))
      (Req_trans (RsumN_Radd _ _ (n + 1)) (Radd_congr (bernR_sq x n) (bernR_mean x n)))
  have hBB : Req (RsumN (fun k => Rmul (Rmul (Rmul (RofNat n) x) (Rmul (RofNat n) x))
        (bernR x n k)) (n + 1))
      (Rmul (Rmul (RofNat n) x) (Rmul (RofNat n) x)) :=
    Req_trans (RsumN_Rmul_const (Rmul (Rmul (RofNat n) x) (Rmul (RofNat n) x)) (bernR x n) (n + 1))
      (Req_trans (Rmul_congr (Req_refl _) (bernR_partition x n)) (Rmul_one _))
  have hAB : Req (RsumN (fun k => Rmul (Rmul (RofNat k) (Rmul (RofNat n) x)) (bernR x n k)) (n + 1))
      (Rmul (Rmul (RofNat n) x) (Rmul (RofNat n) x)) :=
    Req_trans (RsumN_congr (n + 1) (fun k _ => abeta_pull x n k))
      (Req_trans (RsumN_Rmul_const (Rmul (RofNat n) x) (fun k => Rmul (RofNat k) (bernR x n k)) (n + 1))
        (Rmul_congr (Req_refl _) (bernR_mean x n)))
  refine Req_trans (RsumN_congr (n + 1) (fun k _ => var_term x n k)) ?_
  refine Req_trans (RsumN_Rsub _ _ (n + 1)) ?_
  refine Req_trans (Rsub_congr (RsumN_Radd _ _ (n + 1)) (RsumN_Radd _ _ (n + 1))) ?_
  refine Req_trans (Rsub_congr (Radd_congr hAA hBB) (Radd_congr hAB hAB)) ?_
  refine Req_trans (Rsub_congr
    (Radd_congr (Radd_congr (fact_T2 x n) (Req_refl _)) (fact_bb x n))
    (Radd_congr (fact_bb x n) (fact_bb x n))) ?_
  refine Req_trans (var_collapse (Rmul (Rmul (RofNat n) (RofNat n)) (Rmul x x))
    (Rmul (RofNat n) (Rmul x x)) (Rmul (RofNat n) x)) ?_
  exact Req_symm (target_eq x n)

end Multiplicity.UOR.Bridge.F1Square.Square
