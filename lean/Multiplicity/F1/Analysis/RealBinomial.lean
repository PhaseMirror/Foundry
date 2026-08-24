/-
F1 square — **the real binomial theorem** (`RealBinomial.lean`), the foundation of the Bernstein
approximation arc (step 3, general determinacy + inversion). Lean core / the repo's `Binomial.lean`
carry the binomial theorem only over `ℚ`; the Bernstein polynomials must be evaluated at a *real*
argument `x ∈ [0,1]`, so the theorem is reproved over the constructive reals:

    `(a + b)ⁿ ≈ Σ_{i=0}^{n} C(n,i)·aⁱ·bⁿ⁻ⁱ`   (`Rbinomial`, over `RsumN`/`Rpow`).

WHY (the Sonine route, step 3, the Mellin FRONT). General (bounded-Lipschitz) moment determinacy and
Mellin inversion both reduce to Bernstein-polynomial approximation, whose three moment identities
(partition of unity, mean, variance) all flow from the binomial theorem at `(x, 1−x)`. This brick lays
the real-variable foundation: the real Bernstein term `binTermR a b n i = C(n,i)·aⁱ·bⁿ⁻ⁱ`, its Pascal
per-term step `binTermR_succ`, and the theorem itself — mirroring the `ℚ` proof (`binomial`) but with
manual real-algebra chains (there is no `ring` tactic over the abstract reals). Reusable analysis
plumbing minted alongside: `RsumN_front` (finite-sum front-peel), `RofNat_add` (the `ℕ→ℝ` embedding is
additive), `Rpow_add` (`xᵐ⁺ⁿ = xᵐ·xⁿ`).

HONEST SCOPE. The binomial theorem over `Real`, plus the real Bernstein term and its transfer laws.
This is infrastructure for the Bernstein/determinacy arc; it is NOT itself any Mellin-front result, NOT
inversion, NOT positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.Binomial
import Multiplicity.F1.Analysis.RiemannSum
import Multiplicity.F1.Analysis.Pow

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **Front-peel for `RsumN`** (which folds by adding the *last* term): `Σ_{i<N+1} F i ≈ F 0 +
    Σ_{i<N} F (i+1)`. -/
theorem RsumN_front (F : Nat → Real) :
    ∀ N, Req (RsumN F (N + 1)) (Radd (F 0) (RsumN (fun i => F (i + 1)) N))
  | 0 => Radd_comm (RsumN F 0) (F 0)
  | N + 1 => by
      show Req (Radd (RsumN F (N + 1)) (F (N + 1)))
        (Radd (F 0) (Radd (RsumN (fun i => F (i + 1)) N) (F (N + 1))))
      refine Req_trans (Radd_congr (RsumN_front F N) (Req_refl _)) ?_
      exact Radd_assoc (F 0) (RsumN (fun i => F (i + 1)) N) (F (N + 1))

/-- The `ℕ → ℝ` embedding is additive: `RofNat (a+b) ≈ RofNat a + RofNat b`. -/
theorem RofNat_add (a b : Nat) : Req (RofNat (a + b)) (Radd (RofNat a) (RofNat b)) := by
  refine Req_trans ?_ (Req_symm (Radd_ofQ_ofQ Nat.one_pos Nat.one_pos))
  refine Req_of_seq_Qeq (fun _ => ?_)
  show Qeq (⟨((a + b : Nat) : Int), 1⟩) (add (⟨(a:Int),1⟩) (⟨(b:Int),1⟩))
  simp only [Qeq, add]; push_cast; ring_uor

/-- Real powers add exponents: `xᵐ⁺ⁿ ≈ xᵐ·xⁿ`. -/
theorem Rpow_add (x : Real) (m n : Nat) : Req (Rpow x (m + n)) (Rmul (Rpow x m) (Rpow x n)) := by
  induction m with
  | zero => rw [Nat.zero_add]; exact Req_symm (Rone_mul (Rpow x n))
  | succ k ih =>
      show Req (Rpow x (k + 1 + n)) (Rmul (Rmul x (Rpow x k)) (Rpow x n))
      rw [show k + 1 + n = (k + n) + 1 from by omega]
      show Req (Rmul x (Rpow x (k + n))) (Rmul (Rmul x (Rpow x k)) (Rpow x n))
      exact Req_trans (Rmul_congr (Req_refl x) ih) (Req_symm (Rmul_assoc x (Rpow x k) (Rpow x n)))

private theorem mul_pull_left (c a X : Real) : Req (Rmul a (Rmul c X)) (Rmul c (Rmul a X)) :=
  Req_trans (Rmul_comm a (Rmul c X))
    (Req_trans (Rmul_assoc c X a) (Rmul_congr (Req_refl c) (Rmul_comm X a)))

private theorem mul_pull_mid (b P Q : Real) : Req (Rmul b (Rmul P Q)) (Rmul P (Rmul b Q)) :=
  Req_trans (Rmul_comm b (Rmul P Q))
    (Req_trans (Rmul_assoc P Q b) (Rmul_congr (Req_refl P) (Rmul_comm Q b)))

private theorem radd_swap_left3 (x y z : Real) : Req (Radd x (Radd y z)) (Radd y (Radd x z)) :=
  Req_trans (Req_symm (Radd_assoc x y z))
    (Req_trans (Radd_congr (Radd_comm x y) (Req_refl z)) (Radd_assoc y x z))

/-- The real Bernstein/binomial term `C(n,i)·aⁱ·bⁿ⁻ⁱ`. -/
def binTermR (a b : Real) (n i : Nat) : Real :=
  Rmul (RofNat (choose n i)) (Rmul (Rpow a i) (Rpow b (n - i)))

private theorem RofNat_zero : Req (RofNat 0) zero := Req_of_seq_Qeq (fun _ => Qeq_refl _)

/-- Top boundary: `b · binTermR n (n+1) ≈ 0` (since `C(n,n+1) = 0`). -/
theorem binTermR_top_zero (a b : Real) (n : Nat) : Req (Rmul b (binTermR a b n (n + 1))) zero := by
  have hc : choose n (n + 1) = 0 := choose_eq_zero_of_lt (by omega)
  show Req (Rmul b (Rmul (RofNat (choose n (n + 1)))
    (Rmul (Rpow a (n + 1)) (Rpow b (n - (n + 1)))))) zero
  rw [hc]
  refine Req_trans (Rmul_congr (Req_refl b) (Rmul_congr RofNat_zero (Req_refl _))) ?_
  refine Req_trans (Rmul_congr (Req_refl b) (Req_trans (Rmul_comm zero _) (Rmul_zero _))) (Rmul_zero b)

/-- Bottom boundary: `binTermR (n+1) 0 ≈ b · binTermR n 0` (both `bⁿ⁺¹`). -/
theorem binTermR_zero_bot (a b : Real) (n : Nat) :
    Req (binTermR a b (n + 1) 0) (Rmul b (binTermR a b n 0)) := by
  show Req (Rmul (RofNat (choose (n + 1) 0)) (Rmul (Rpow a 0) (Rpow b (n + 1 - 0))))
    (Rmul b (Rmul (RofNat (choose n 0)) (Rmul (Rpow a 0) (Rpow b (n - 0)))))
  rw [choose_zero_right, choose_zero_right, Nat.sub_zero, Nat.sub_zero]
  refine Req_trans (Rmul_congr (Req_refl _) (Rmul_congr (Req_refl _)
    (Rpow_succ b n ▸ Req_refl (Rpow b (n+1))))) ?_
  refine Req_trans (Rone_mul _) ?_
  refine Req_symm ?_
  refine Req_trans (Rmul_congr (Req_refl b) (Rone_mul _)) ?_
  exact mul_pull_mid b (Rpow a 0) (Rpow b n)

/-- **The per-term Pascal step** `binTermR (n+1) (i+1) ≈ a·binTermR n i + b·binTermR n (i+1)` (for
    `i ≤ n`; at `i = n` the second summand vanishes since `C(n,n+1) = 0`). -/
theorem binTermR_succ (a b : Real) (n : Nat) : ∀ {i : Nat}, i ≤ n →
    Req (binTermR a b (n + 1) (i + 1))
      (Radd (Rmul a (binTermR a b n i)) (Rmul b (binTermR a b n (i + 1)))) := by
  intro i hi
  rcases Nat.eq_or_lt_of_le hi with heq | hlt
  · subst heq
    have hR : Req (Radd (Rmul a (binTermR a b i i)) (Rmul b (binTermR a b i (i + 1))))
        (Rmul a (binTermR a b i i)) :=
      Req_trans (Radd_congr (Req_refl _) (binTermR_top_zero a b i)) (Radd_zero _)
    refine Req_trans ?_ (Req_symm hR)
    show Req (Rmul (RofNat (choose (i + 1) (i + 1))) (Rmul (Rpow a (i + 1)) (Rpow b (i + 1 - (i + 1)))))
      (Rmul a (Rmul (RofNat (choose i i)) (Rmul (Rpow a i) (Rpow b (i - i)))))
    rw [choose_self, choose_self, Nat.sub_self, Nat.sub_self]
    refine Req_symm ?_
    refine Req_trans (mul_pull_left (RofNat 1) a (Rmul (Rpow a i) (Rpow b 0))) ?_
    refine Rmul_congr (Req_refl _) ?_
    refine Req_trans (Req_symm (Rmul_assoc a (Rpow a i) (Rpow b 0))) ?_
    exact Rmul_congr (Req_symm (Rpow_succ a i ▸ Req_refl (Rmul a (Rpow a i)))) (Req_refl _)
  · have he : n - i = (n - (i + 1)) + 1 := by omega
    have hb : Req (Rmul b (Rpow b (n - (i + 1)))) (Rpow b (n - i)) := by rw [he]; exact Req_refl _
    show Req (Rmul (RofNat (choose (n + 1) (i + 1))) (Rmul (Rpow a (i + 1)) (Rpow b (n + 1 - (i + 1)))))
      (Radd (Rmul a (Rmul (RofNat (choose n i)) (Rmul (Rpow a i) (Rpow b (n - i)))))
            (Rmul b (Rmul (RofNat (choose n (i + 1))) (Rmul (Rpow a (i + 1)) (Rpow b (n - (i + 1)))))))
    rw [show n + 1 - (i + 1) = n - i from by omega, choose_succ_succ]
    refine Req_trans (Rmul_congr (RofNat_add (choose n i) (choose n (i + 1))) (Req_refl _)) ?_
    refine Req_trans (Rmul_distrib_right (RofNat (choose n i)) (RofNat (choose n (i + 1)))
      (Rmul (Rpow a (i + 1)) (Rpow b (n - i)))) ?_
    refine Radd_congr ?_ ?_
    · refine Req_symm ?_
      refine Req_trans (mul_pull_left (RofNat (choose n i)) a (Rmul (Rpow a i) (Rpow b (n - i)))) ?_
      refine Rmul_congr (Req_refl _) ?_
      refine Req_trans (Req_symm (Rmul_assoc a (Rpow a i) (Rpow b (n - i)))) ?_
      exact Rmul_congr (Req_symm (Rpow_succ a i ▸ Req_refl (Rmul a (Rpow a i)))) (Req_refl _)
    · refine Req_symm ?_
      refine Req_trans (mul_pull_left (RofNat (choose n (i + 1))) b
        (Rmul (Rpow a (i + 1)) (Rpow b (n - (i + 1))))) ?_
      refine Rmul_congr (Req_refl _) ?_
      refine Req_trans (mul_pull_mid b (Rpow a (i + 1)) (Rpow b (n - (i + 1)))) ?_
      exact Rmul_congr (Req_refl _) hb

/-- **★ THE REAL BINOMIAL THEOREM** `(a+b)ⁿ ≈ Σ_{i=0}^{n} C(n,i)·aⁱ·bⁿ⁻ⁱ`. Induction on `n`: multiply
    the `n`-case by `(a+b)`, front-peel the `(n+1)`-sum, recombine by the Pascal per-term step
    `binTermR_succ`, and collapse each side to `a·S + b·S = (a+b)·S`. -/
theorem Rbinomial (a b : Real) :
    ∀ n, Req (Rpow (Radd a b) n) (RsumN (binTermR a b n) (n + 1))
  | 0 => by
      show Req one (Radd (RsumN (binTermR a b 0) 0) (binTermR a b 0 0))
      refine Req_trans ?_ (Req_symm (Radd_comm (RsumN (binTermR a b 0) 0) (binTermR a b 0 0)))
      show Req one (Radd (Rmul (RofNat (choose 0 0)) (Rmul (Rpow a 0) (Rpow b (0 - 0))))
        (RsumN (binTermR a b 0) 0))
      refine Req_trans ?_ (Req_symm (Radd_zero _))
      exact Req_symm (Req_trans (Rone_mul _) (Req_trans (Rone_mul _) (Req_refl one)))
  | n + 1 => by
      show Req (Rmul (Radd a b) (Rpow (Radd a b) n)) (RsumN (binTermR a b (n + 1)) (n + 2))
      refine Req_trans (Rmul_congr (Req_refl _) (Rbinomial a b n)) ?_
      refine Req_symm ?_
      refine Req_trans (RsumN_front (binTermR a b (n + 1)) (n + 1)) ?_
      have hT : Req (RsumN (fun i => binTermR a b (n + 1) (i + 1)) (n + 1))
          (Radd (Rmul a (RsumN (binTermR a b n) (n + 1)))
                (Rmul b (RsumN (fun i => binTermR a b n (i + 1)) (n + 1)))) := by
        refine Req_trans (RsumN_congr (n + 1) (fun i hi =>
          binTermR_succ a b n (Nat.lt_succ_iff.mp hi))) ?_
        refine Req_trans (RsumN_Radd (fun i => Rmul a (binTermR a b n i))
          (fun i => Rmul b (binTermR a b n (i + 1))) (n + 1)) ?_
        exact Radd_congr (RsumN_Rmul_const a (binTermR a b n) (n + 1))
          (RsumN_Rmul_const b (fun i => binTermR a b n (i + 1)) (n + 1))
      refine Req_trans (Radd_congr (Req_refl _) hT) ?_
      refine Req_trans (Radd_congr (binTermR_zero_bot a b n) (Req_refl _)) ?_
      have hbU : Req (Radd (Rmul b (binTermR a b n 0))
            (Radd (Rmul a (RsumN (binTermR a b n) (n + 1)))
                  (Rmul b (RsumN (fun i => binTermR a b n (i + 1)) (n + 1)))))
          (Radd (Rmul a (RsumN (binTermR a b n) (n + 1)))
                (Rmul b (RsumN (binTermR a b n) (n + 1)))) := by
        refine Req_trans (radd_swap_left3 (Rmul b (binTermR a b n 0))
          (Rmul a (RsumN (binTermR a b n) (n + 1)))
          (Rmul b (RsumN (fun i => binTermR a b n (i + 1)) (n + 1)))) ?_
        refine Radd_congr (Req_refl _) ?_
        refine Req_trans (Req_symm (Rmul_distrib b (binTermR a b n 0)
          (RsumN (fun i => binTermR a b n (i + 1)) (n + 1)))) ?_
        refine Rmul_congr (Req_refl _) ?_
        refine Req_trans (Req_symm (RsumN_front (binTermR a b n) (n + 1))) ?_
        show Req (Radd (RsumN (binTermR a b n) (n + 1)) (binTermR a b n (n + 1)))
          (RsumN (binTermR a b n) (n + 1))
        refine Req_trans (Radd_congr (Req_refl _) ?_) (Radd_zero _)
        show Req (Rmul (RofNat (choose n (n + 1))) (Rmul (Rpow a (n + 1)) (Rpow b (n - (n + 1))))) zero
        rw [choose_eq_zero_of_lt (by omega : n < n + 1)]
        exact Req_trans (Rmul_congr RofNat_zero (Req_refl _))
          (Req_trans (Rmul_comm zero _) (Rmul_zero _))
      refine Req_trans hbU ?_
      exact Req_symm (Rmul_distrib_right a b (RsumN (binTermR a b n) (n + 1)))

end Multiplicity.UOR.Bridge.F1Square.Analysis
