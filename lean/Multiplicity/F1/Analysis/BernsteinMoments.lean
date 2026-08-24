/-
F1 square — **the Bernstein mean and second factorial moment** (`BernsteinMoments.lean`), the Bernstein
arc, sub-bricks C–D. On the Bernstein basis (`Bernstein.lean`) the first two moment identities are proved:

    `Σ_{k=0}^n k·b_{n,k}(x) = n·x`            (`bernR_mean`, sub-brick C),
    `Σ_{k=0}^n k(k-1)·b_{n,k}(x) = n(n-1)·x²`  (`bernR_sq`, sub-brick D).

WHY (the Sonine route, step 3, the Mellin FRONT). The Bernstein operator's convergence rests on the
variance `Σ(k−nx)²b = nx(1−x)` — the estimate the ε-δ convergence divides by — which is the mean plus
the second factorial moment (`Σk²b = Σk(k-1)b + Σkb`). Each proof is the classic reindex: the low-`k`
terms drop, and each surviving term collapses by the combinatorial identity `(k+1)·C(n+1,k+1) =
(n+1)·C(n,k)` (`succ_mul_choose`, from `choose_mul_fct_mul_fct` by `ℕ`-cancellation; `dfact_choose` is its
double application) into a shifted basis term times `n·x` (resp. `n(n-1)·x²`), so the whole sum is that
constant times the partition of unity for `n−1` (resp. `n−2`). Minted: `RofNat_mul` (the `ℕ→ℝ` embedding
is multiplicative).

HONEST SCOPE. The Bernstein mean and second factorial moment over `Real` (plus the combinatorial
`succ_mul_choose`/`dfact_choose` and the per-term reindexes). Infrastructure for the determinacy/inversion
arc; NOT the variance assembly yet, NOT convergence, NOT inversion, NOT positivity. Step 4 is RH; crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.Bernstein

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **The combinatorial reindex** `(k+1)·C(n+1,k+1) = (n+1)·C(n,k)` (for `k ≤ n`) — the divisibility
    heart of the Bernstein mean, proved from the factorial identity `choose_mul_fct_mul_fct` by
    cancelling the positive common factor `k!·(n−k)!`. -/
theorem succ_mul_choose (n k : Nat) (h : k ≤ n) :
    (k + 1) * choose (n + 1) (k + 1) = (n + 1) * choose n k := by
  have e1 : choose (n + 1) (k + 1) * fct (k + 1) * fct (n - k) = fct (n + 1) := by
    have h1 := choose_mul_fct_mul_fct (show k + 1 ≤ n + 1 by omega)
    rwa [show n + 1 - (k + 1) = n - k from by omega] at h1
  have e2 : choose n k * fct k * fct (n - k) = fct n := choose_mul_fct_mul_fct h
  have hfk : fct (k + 1) = (k + 1) * fct k := fct_succ k
  have hfn : fct (n + 1) = (n + 1) * fct n := fct_succ n
  have hpos : 0 < fct k * fct (n - k) := Nat.mul_pos (fct_pos k) (fct_pos (n - k))
  refine Nat.eq_of_mul_eq_mul_right hpos ?_
  have hL : (k + 1) * choose (n + 1) (k + 1) * (fct k * fct (n - k)) = fct (n + 1) := by
    have hrw : (k + 1) * choose (n + 1) (k + 1) * (fct k * fct (n - k))
        = choose (n + 1) (k + 1) * ((k + 1) * fct k) * fct (n - k) := by
      have : ((k + 1) * choose (n + 1) (k + 1) * (fct k * fct (n - k)) : Int)
          = (choose (n + 1) (k + 1) * ((k + 1) * fct k) * fct (n - k) : Int) := by push_cast; ring_uor
      exact_mod_cast this
    rw [hrw, ← hfk, e1]
  have hR : (n + 1) * choose n k * (fct k * fct (n - k)) = fct (n + 1) := by
    have hrw : (n + 1) * choose n k * (fct k * fct (n - k))
        = (n + 1) * (choose n k * fct k * fct (n - k)) := by
      have : ((n + 1) * choose n k * (fct k * fct (n - k)) : Int)
          = ((n + 1) * (choose n k * fct k * fct (n - k)) : Int) := by push_cast; ring_uor
      exact_mod_cast this
    rw [hrw, e2, ← hfn]
  rw [hL, hR]

/-- The `ℕ → ℝ` embedding is multiplicative: `RofNat (a·b) ≈ RofNat a · RofNat b`. -/
theorem RofNat_mul (a b : Nat) : Req (RofNat (a * b)) (Rmul (RofNat a) (RofNat b)) := by
  refine Req_trans ?_ (Req_symm (Rmul_ofQ_ofQ Nat.one_pos Nat.one_pos))
  refine Req_of_seq_Qeq (fun _ => ?_)
  show Qeq (⟨((a * b : Nat) : Int), 1⟩) (mul (⟨(a:Int),1⟩) (⟨(b:Int),1⟩))
  simp only [Qeq, mul]; push_cast; ring_uor

private theorem RofNat_zero' : Req (RofNat 0) zero := Req_of_seq_Qeq (fun _ => Qeq_refl _)

private theorem mul_pull_left (c a X : Real) : Req (Rmul a (Rmul c X)) (Rmul c (Rmul a X)) :=
  Req_trans (Rmul_comm a (Rmul c X))
    (Req_trans (Rmul_assoc c X a) (Rmul_congr (Req_refl c) (Rmul_comm X a)))

/-- **Per-term reindex for the mean**: `(j+1)·b_{m+1,j+1}(x) = (m+1)·x · b_{m,j}(x)`. Combines the two
    `ℕ→ℝ` coefficients, rewrites by `succ_mul_choose`, peels `xʲ⁺¹ = x·xʲ`, and reassociates. -/
theorem bernR_mean_term (x : Real) (m j : Nat) (hj : j ≤ m) :
    Req (Rmul (RofNat (j + 1)) (bernR x (m + 1) (j + 1)))
        (Rmul (Rmul (RofNat (m + 1)) x) (bernR x m j)) := by
  show Req (Rmul (RofNat (j + 1)) (Rmul (RofNat (choose (m + 1) (j + 1)))
      (Rmul (Rpow x (j + 1)) (Rpow (Rsub one x) (m + 1 - (j + 1))))))
    (Rmul (Rmul (RofNat (m + 1)) x)
      (Rmul (RofNat (choose m j)) (Rmul (Rpow x j) (Rpow (Rsub one x) (m - j)))))
  rw [show m + 1 - (j + 1) = m - j from by omega]
  refine Req_trans (Req_symm (Rmul_assoc (RofNat (j + 1)) (RofNat (choose (m + 1) (j + 1)))
    (Rmul (Rpow x (j + 1)) (Rpow (Rsub one x) (m - j))))) ?_
  refine Req_trans (Rmul_congr (Req_symm (RofNat_mul (j + 1) (choose (m + 1) (j + 1)))) (Req_refl _)) ?_
  rw [succ_mul_choose m j hj]
  refine Req_trans (Rmul_congr (RofNat_mul (m + 1) (choose m j)) (Req_refl _)) ?_
  refine Req_trans (Rmul_assoc (RofNat (m + 1)) (RofNat (choose m j))
    (Rmul (Rmul x (Rpow x j)) (Rpow (Rsub one x) (m - j)))) ?_
  refine Req_trans (Rmul_congr (Req_refl _) (Rmul_congr (Req_refl _)
    (Rmul_assoc x (Rpow x j) (Rpow (Rsub one x) (m - j))))) ?_
  refine Req_symm ?_
  refine Req_trans (Rmul_assoc (RofNat (m + 1)) x
    (Rmul (RofNat (choose m j)) (Rmul (Rpow x j) (Rpow (Rsub one x) (m - j))))) ?_
  exact Rmul_congr (Req_refl _) (mul_pull_left (RofNat (choose m j)) x
    (Rmul (Rpow x j) (Rpow (Rsub one x) (m - j))))

/-- **★ THE BERNSTEIN MEAN IDENTITY**: `Σ_{k=0}^n k·b_{n,k}(x) = n·x`. The `k = 0` term vanishes; each
    `k = j+1` term reindexes (`bernR_mean_term`) to `(n·x)·b_{n−1,j}(x)`, so the sum is `n·x` times the
    partition of unity for `n−1`, i.e. `n·x`. -/
theorem bernR_mean (x : Real) :
    ∀ n, Req (RsumN (fun k => Rmul (RofNat k) (bernR x n k)) (n + 1)) (Rmul (RofNat n) x)
  | 0 => by
      show Req (Radd (RsumN (fun k => Rmul (RofNat k) (bernR x 0 k)) 0)
        (Rmul (RofNat 0) (bernR x 0 0))) (Rmul (RofNat 0) x)
      refine Req_trans (Radd_congr (Req_refl _)
        (Req_trans (Rmul_congr RofNat_zero' (Req_refl _))
          (Req_trans (Rmul_comm zero _) (Rmul_zero _)))) ?_
      refine Req_trans (Radd_zero _) ?_
      exact Req_symm (Req_trans (Rmul_congr RofNat_zero' (Req_refl _))
        (Req_trans (Rmul_comm zero _) (Rmul_zero _)))
  | m + 1 => by
      refine Req_trans (RsumN_front (fun k => Rmul (RofNat k) (bernR x (m + 1) k)) (m + 1)) ?_
      refine Req_trans (Radd_congr
        (Req_trans (Rmul_congr RofNat_zero' (Req_refl _))
          (Req_trans (Rmul_comm zero _) (Rmul_zero _)))
        (Req_refl _)) ?_
      refine Req_trans (Req_trans (Radd_comm zero _) (Radd_zero _)) ?_
      refine Req_trans (RsumN_congr (m + 1)
        (fun j hj => bernR_mean_term x m j (Nat.lt_succ_iff.mp hj))) ?_
      refine Req_trans (RsumN_Rmul_const (Rmul (RofNat (m + 1)) x) (bernR x m) (m + 1)) ?_
      refine Req_trans (Rmul_congr (Req_refl _) (bernR_partition x m)) ?_
      exact Rmul_one _

/-- **The double reindex** `(j+2)(j+1)·C(m+2,j+2) = (m+2)(m+1)·C(m,j)` (for `j ≤ m`) — two applications
    of `succ_mul_choose`, the divisibility heart of the Bernstein second factorial moment. -/
theorem dfact_choose (m j : Nat) (hj : j ≤ m) :
    (j + 2) * (j + 1) * choose (m + 2) (j + 2) = (m + 2) * (m + 1) * choose m j := by
  have s1 : (j + 2) * choose (m + 2) (j + 2) = (m + 2) * choose (m + 1) (j + 1) :=
    succ_mul_choose (m + 1) (j + 1) (by omega)
  have s2 : (j + 1) * choose (m + 1) (j + 1) = (m + 1) * choose m j := succ_mul_choose m j hj
  have key : ((j + 2) * (j + 1) * choose (m + 2) (j + 2) : Int)
      = ((m + 2) * (m + 1) * choose m j : Int) := by
    have s1Z : ((j + 2) * choose (m + 2) (j + 2) : Int) = ((m + 2) * choose (m + 1) (j + 1) : Int) := by
      exact_mod_cast s1
    have s2Z : ((j + 1) * choose (m + 1) (j + 1) : Int) = ((m + 1) * choose m j : Int) := by
      exact_mod_cast s2
    calc ((j + 2) * (j + 1) * choose (m + 2) (j + 2) : Int)
        = (j + 1) * ((j + 2) * choose (m + 2) (j + 2)) := by ring_uor
      _ = (j + 1) * ((m + 2) * choose (m + 1) (j + 1)) := by rw [s1Z]
      _ = (m + 2) * ((j + 1) * choose (m + 1) (j + 1)) := by ring_uor
      _ = (m + 2) * ((m + 1) * choose m j) := by rw [s2Z]
      _ = (m + 2) * (m + 1) * choose m j := by ring_uor
  exact_mod_cast key

/-- **Per-term reindex for the second factorial moment**: `(j+2)(j+1)·b_{m+2,j+2}(x) =
    (m+2)(m+1)·x² · b_{m,j}(x)`. -/
theorem bernR_sq_term (x : Real) (m j : Nat) (hj : j ≤ m) :
    Req (Rmul (RofNat ((j + 2) * (j + 1))) (bernR x (m + 2) (j + 2)))
        (Rmul (Rmul (RofNat ((m + 2) * (m + 1))) (Rmul x x)) (bernR x m j)) := by
  show Req (Rmul (RofNat ((j + 2) * (j + 1))) (Rmul (RofNat (choose (m + 2) (j + 2)))
      (Rmul (Rpow x (j + 2)) (Rpow (Rsub one x) (m + 2 - (j + 2))))))
    (Rmul (Rmul (RofNat ((m + 2) * (m + 1))) (Rmul x x))
      (Rmul (RofNat (choose m j)) (Rmul (Rpow x j) (Rpow (Rsub one x) (m - j)))))
  rw [show m + 2 - (j + 2) = m - j from by omega]
  refine Req_trans (Req_symm (Rmul_assoc (RofNat ((j + 2) * (j + 1)))
    (RofNat (choose (m + 2) (j + 2)))
    (Rmul (Rpow x (j + 2)) (Rpow (Rsub one x) (m - j))))) ?_
  refine Req_trans (Rmul_congr (Req_symm (RofNat_mul ((j + 2) * (j + 1))
    (choose (m + 2) (j + 2)))) (Req_refl _)) ?_
  rw [show (j + 2) * (j + 1) * choose (m + 2) (j + 2) = (m + 2) * (m + 1) * choose m j
        from dfact_choose m j hj]
  refine Req_trans (Rmul_congr (RofNat_mul ((m + 2) * (m + 1)) (choose m j)) (Req_refl _)) ?_
  refine Req_trans (Rmul_assoc (RofNat ((m + 2) * (m + 1))) (RofNat (choose m j))
    (Rmul (Rmul x (Rmul x (Rpow x j))) (Rpow (Rsub one x) (m - j)))) ?_
  refine Req_trans (Rmul_congr (Req_refl _) (Rmul_congr (Req_refl _)
    (Rmul_assoc x (Rmul x (Rpow x j)) (Rpow (Rsub one x) (m - j))))) ?_
  refine Req_trans (Rmul_congr (Req_refl _) (Rmul_congr (Req_refl _)
    (Rmul_congr (Req_refl x) (Rmul_assoc x (Rpow x j) (Rpow (Rsub one x) (m - j)))))) ?_
  refine Req_symm ?_
  refine Req_trans (Rmul_assoc (RofNat ((m + 2) * (m + 1))) (Rmul x x)
    (Rmul (RofNat (choose m j)) (Rmul (Rpow x j) (Rpow (Rsub one x) (m - j))))) ?_
  refine Rmul_congr (Req_refl _) ?_
  refine Req_trans (Rmul_assoc x x (Rmul (RofNat (choose m j))
    (Rmul (Rpow x j) (Rpow (Rsub one x) (m - j))))) ?_
  refine Req_trans (Rmul_congr (Req_refl x) (mul_pull_left (RofNat (choose m j)) x
    (Rmul (Rpow x j) (Rpow (Rsub one x) (m - j))))) ?_
  exact mul_pull_left (RofNat (choose m j)) x
    (Rmul x (Rmul (Rpow x j) (Rpow (Rsub one x) (m - j))))

/-- **★ THE BERNSTEIN SECOND FACTORIAL MOMENT**: `Σ_{k=0}^n k(k-1)·b_{n,k}(x) = n(n-1)·x²`. The
    `k = 0, 1` terms vanish; each `k = j+2` term reindexes (`bernR_sq_term`) to `(n(n-1)x²)·b_{n-2,j}(x)`,
    so the sum is `n(n-1)x²·(partition for n-2)`. Second moment for the variance. -/
theorem bernR_sq (x : Real) :
    ∀ n, Req (RsumN (fun k => Rmul (RofNat (k * (k - 1))) (bernR x n k)) (n + 1))
             (Rmul (RofNat (n * (n - 1))) (Rmul x x))
  | 0 => by
      show Req (Radd (RsumN (fun k => Rmul (RofNat (k * (k - 1))) (bernR x 0 k)) 0)
        (Rmul (RofNat (0 * (0 - 1))) (bernR x 0 0))) (Rmul (RofNat (0 * (0 - 1))) (Rmul x x))
      refine Req_trans (Radd_congr (Req_refl _)
        (Req_trans (Rmul_congr RofNat_zero' (Req_refl _))
          (Req_trans (Rmul_comm zero _) (Rmul_zero _)))) ?_
      refine Req_trans (Radd_zero _) ?_
      exact Req_symm (Req_trans (Rmul_congr RofNat_zero' (Req_refl _))
        (Req_trans (Rmul_comm zero _) (Rmul_zero _)))
  | 1 => by
      show Req (Radd (Radd (RsumN (fun k => Rmul (RofNat (k * (k - 1))) (bernR x 1 k)) 0)
          (Rmul (RofNat (0 * (0 - 1))) (bernR x 1 0)))
        (Rmul (RofNat (1 * (1 - 1))) (bernR x 1 1))) (Rmul (RofNat (1 * (1 - 1))) (Rmul x x))
      refine Req_trans (Radd_congr (Radd_congr (Req_refl _)
        (Req_trans (Rmul_congr RofNat_zero' (Req_refl _))
          (Req_trans (Rmul_comm zero _) (Rmul_zero _))))
        (Req_trans (Rmul_congr RofNat_zero' (Req_refl _))
          (Req_trans (Rmul_comm zero _) (Rmul_zero _)))) ?_
      refine Req_trans (Radd_congr (Radd_zero _) (Req_refl _)) ?_
      refine Req_trans (Radd_zero _) ?_
      exact Req_symm (Req_trans (Rmul_congr RofNat_zero' (Req_refl _))
        (Req_trans (Rmul_comm zero _) (Rmul_zero _)))
  | m + 2 => by
      refine Req_trans (RsumN_front (fun k => Rmul (RofNat (k * (k - 1))) (bernR x (m + 2) k)) (m + 2)) ?_
      refine Req_trans (Radd_congr
        (Req_trans (Rmul_congr RofNat_zero' (Req_refl _))
          (Req_trans (Rmul_comm zero _) (Rmul_zero _))) (Req_refl _)) ?_
      refine Req_trans (Req_trans (Radd_comm zero _) (Radd_zero _)) ?_
      refine Req_trans (RsumN_front
        (fun i => Rmul (RofNat ((i + 1) * ((i + 1) - 1))) (bernR x (m + 2) (i + 1))) (m + 1)) ?_
      refine Req_trans (Radd_congr
        (Req_trans (Rmul_congr RofNat_zero' (Req_refl _))
          (Req_trans (Rmul_comm zero _) (Rmul_zero _))) (Req_refl _)) ?_
      refine Req_trans (Req_trans (Radd_comm zero _) (Radd_zero _)) ?_
      refine Req_trans (RsumN_congr (m + 1)
        (fun j hj => bernR_sq_term x m j (Nat.lt_succ_iff.mp hj))) ?_
      refine Req_trans (RsumN_Rmul_const (Rmul (RofNat ((m + 2) * (m + 1))) (Rmul x x))
        (bernR x m) (m + 1)) ?_
      refine Req_trans (Rmul_congr (Req_refl _) (bernR_partition x m)) ?_
      exact Rmul_one _

end Multiplicity.UOR.Bridge.F1Square.Analysis
