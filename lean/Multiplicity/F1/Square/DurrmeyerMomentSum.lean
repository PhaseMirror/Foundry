/-
F1 square — **the Durrmeyer moments of the low monomials** (`DurrmeyerMomentSum.lean`), the
Mellin-inversion arc, sub-brick J₄. Summing the per-`k` weights (J₃) against `(n+1)·b_{n,k}(x)` and the
Bernstein moment identities (partition of unity, `bernR_mean`, `bernR_sq`) gives the Durrmeyer operator's
action on `1, x, x²`:

    `durrOp 1  n x = 1`                                     (`durrOp_powTest_zero`, normalization),
    `durrOp x  n x = (nx + 1)/(n+2)`                        (`durrOp_powTest_one`),
    `durrOp x² n x = (n(n−1)x² + 4nx + 2)/((n+2)(n+3))`     (`durrOp_powTest_two`).

The summation reindexes each weight (`RsumN_mul_const`) and collapses the `k`-sums against the raw Bernstein
moments: `Σ_k b_{n,k}(x)·(k+1) = nx+1` (`bernR_shift1`) and `Σ_k b_{n,k}(x)·(k+1)(k+2) = n(n−1)x²+4nx+2`
(`bernR_shift2`, via the Nat identity `(k+1)(k+2) = k(k−1)+4k+2` feeding `bernR_sq`).

WHY (the Sonine route, step 3, the Mellin FRONT). `M_n⁽⁰⁾ = 1` is the normalization `∫₀¹ K_n(x,t) dt = 1`
of the Durrmeyer kernel (a genuine averaging/probabilistic operator); together with `M_n⁽¹⁾`, `M_n⁽²⁾` it
gives the second central moment `T_n(x) = M_n⁽²⁾ − 2x·M_n⁽¹⁾ + x²`, the vanishing quantity that drives
`durrOp φ n x → φ(x)`.

HONEST SCOPE. The Durrmeyer moments `M_n⁽⁰⁾`, `M_n⁽¹⁾`, `M_n⁽²⁾`, over `Real` (exact closed forms). NOT the
second central moment `T_n` assembled/bounded, NOT convergence `durrOp φ n x → φ(x)`, NOT inversion, NOT
positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.DurrmeyerWeights

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- Pure-ℤ normalization identity `A·1 = 1·(1·A)`. -/
private theorem durrM0_id (A : Int) : A * 1 = 1 * (1 * A) := by ring_uor

/-- Pure-ℤ identity for `M_n⁽¹⁾`: `((N+1)·F)·(N+2) = 1·(1·((N+2)·((N+1)·F)))`. -/
private theorem durrM1_id (N F : Int) :
    ((N + 1) * F) * (N + 2) = 1 * (1 * ((N + 2) * ((N + 1) * F))) := by ring_uor

/-- Pure-ℤ identity behind `(k+1)(k+2) = k(k−1)+4k+2` at `k = M+1`. -/
private theorem durrNat_id (M : Int) :
    (M + 1 + 1) * (M + 1 + 2) = (M + 1) * M + 4 * (M + 1) + 2 := by ring_uor

/-- Pure-ℤ identity for `M_n⁽²⁾`: `((N+1)·F)·((N+2)(N+3)) = 1·(1·((N+3)·((N+2)·((N+1)·F))))`. -/
private theorem durrM2_id (N F : Int) :
    ((N + 1) * F) * ((N + 2) * (N + 3))
      = 1 * (1 * ((N + 3) * ((N + 2) * ((N + 1) * F)))) := by ring_uor

/-- `a·(b·c) ≈ b·(a·c)` (real, left-commute) — local copy. -/
private theorem Rmul_left_comm'' (a b c : Real) : Req (Rmul a (Rmul b c)) (Rmul b (Rmul a c)) :=
  Req_trans (Req_symm (Rmul_assoc a b c))
    (Req_trans (Rmul_congr (Rmul_comm a b) (Req_refl c)) (Rmul_assoc b a c))

/-- **`Σ_k b_{n,k}(x)·(k+1) = n·x + 1`** — the first raw Bernstein moment shifted by the partition of
    unity: `b_{n,k}·(k+1) = (k·b_{n,k}) + b_{n,k}`, summed via `RsumN_Radd`, `bernR_mean`, `bernR_partition`. -/
theorem bernR_shift1 (x : Real) (n : Nat) :
    Req (RsumN (fun k => Rmul (bernR x n k) (RofNat (k + 1))) (n + 1))
        (Radd (Rmul (RofNat n) x) one) := by
  refine Req_trans (RsumN_congr (n + 1) (fun k _ =>
      Req_trans (Rmul_congr (Req_refl _) (RofNat_add k 1))
        (Req_trans (Rmul_distrib (bernR x n k) (RofNat k) (RofNat 1))
          (Radd_congr (Rmul_comm (bernR x n k) (RofNat k)) (Rmul_one (bernR x n k)))))) ?_
  exact Req_trans (RsumN_Radd (fun k => Rmul (RofNat k) (bernR x n k)) (bernR x n) (n + 1))
    (Radd_congr (bernR_mean x n) (bernR_partition x n))

/-- **`Σ_k b_{n,k}(x)·(k+1)(k+2) = n(n−1)x² + 4nx + 2`** — the second raw Bernstein moment: the Nat identity
    `(k+1)(k+2) = k(k−1) + 4k + 2` splits the term into `bernR_sq` (`k(k−1)`), `4·bernR_mean` (`4k`), and
    `2·`partition (`2`). -/
theorem bernR_shift2 (x : Real) (n : Nat) :
    Req (RsumN (fun k => Rmul (bernR x n k) (RofNat ((k + 1) * (k + 2)))) (n + 1))
        (Radd (Radd (Rmul (RofNat (n * (n - 1))) (Rmul x x))
                    (Rmul (RofNat 4) (Rmul (RofNat n) x))) (RofNat 2)) := by
  have hterm : ∀ k, Req (Rmul (bernR x n k) (RofNat ((k + 1) * (k + 2))))
      (Radd (Radd (Rmul (RofNat (k * (k - 1))) (bernR x n k))
                  (Rmul (RofNat 4) (Rmul (RofNat k) (bernR x n k))))
            (Rmul (RofNat 2) (bernR x n k))) := by
    intro k
    have hnat : (k + 1) * (k + 2) = k * (k - 1) + 4 * k + 2 := by
      cases k with
      | zero => rfl
      | succ m =>
        have hZ : (((m + 1 + 1) * (m + 1 + 2) : Nat) : Int)
            = (((m + 1) * ((m + 1) - 1) + 4 * (m + 1) + 2 : Nat) : Int) := by
          have hm : (m + 1) - 1 = m := by omega
          rw [hm]; push_cast; exact durrNat_id _
        exact_mod_cast hZ
    rw [hnat]
    refine Req_trans (Rmul_congr (Req_refl _)
      (Req_trans (RofNat_add (k * (k - 1) + 4 * k) 2)
        (Radd_congr (Req_trans (RofNat_add (k * (k - 1)) (4 * k))
          (Radd_congr (Req_refl _) (RofNat_mul 4 k))) (Req_refl _)))) ?_
    refine Req_trans (Rmul_distrib (bernR x n k)
      (Radd (RofNat (k * (k - 1))) (Rmul (RofNat 4) (RofNat k))) (RofNat 2)) ?_
    refine Radd_congr ?_ (Rmul_comm (bernR x n k) (RofNat 2))
    refine Req_trans (Rmul_distrib (bernR x n k) (RofNat (k * (k - 1))) (Rmul (RofNat 4) (RofNat k))) ?_
    refine Radd_congr (Rmul_comm (bernR x n k) (RofNat (k * (k - 1)))) ?_
    exact Req_trans (Rmul_left_comm'' (bernR x n k) (RofNat 4) (RofNat k))
      (Rmul_congr (Req_refl _) (Rmul_comm (bernR x n k) (RofNat k)))
  refine Req_trans (RsumN_congr (n + 1) (fun k _ => hterm k)) ?_
  · refine Req_trans (RsumN_Radd
      (fun k => Radd (Rmul (RofNat (k * (k - 1))) (bernR x n k))
                     (Rmul (RofNat 4) (Rmul (RofNat k) (bernR x n k))))
      (fun k => Rmul (RofNat 2) (bernR x n k)) (n + 1)) ?_
    refine Radd_congr ?_ ?_
    · refine Req_trans (RsumN_Radd (fun k => Rmul (RofNat (k * (k - 1))) (bernR x n k))
        (fun k => Rmul (RofNat 4) (Rmul (RofNat k) (bernR x n k))) (n + 1)) ?_
      refine Radd_congr (bernR_sq x n) ?_
      exact Req_trans (RsumN_Rmul_const (RofNat 4) (fun k => Rmul (RofNat k) (bernR x n k)) (n + 1))
        (Rmul_congr (Req_refl _) (bernR_mean x n))
    · exact Req_trans (RsumN_Rmul_const (RofNat 2) (bernR x n) (n + 1))
        (Req_trans (Rmul_congr (Req_refl _) (bernR_partition x n)) (Rmul_one (RofNat 2)))

/-- **THE DURRMEYER OPERATOR PRESERVES THE CONSTANT `1`** (`M_n⁽⁰⁾ = 1`): `durrOp 1 n x = 1`. Each weight
    is the constant `⟨1, b_{n,k}⟩ = n!/(n+1)!` (J₃, `durrInt_zero`); pull it out of the sum
    (`RsumN_mul_right`), collapse `Σ_k b_{n,k}(x) = 1` (partition of unity), and `(n+1)·n!/(n+1)! = 1`. -/
theorem durrOp_powTest_zero (n : Nat) (x : Real) :
    Req (durrOp (powTest 0) n x) one := by
  show Req (Rmul (RofNat (n + 1))
      (RsumN (fun k => Rmul (bernR x n k) (innerI (powTest 0) (bernBasisTest n k))) (n + 1))) one
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (RsumN_congr (n + 1) (fun k hk =>
        Rmul_congr (Req_refl _) (durrInt_zero n k (by omega))))
      (Req_trans (RsumN_mul_const (bernR x n)
          (ofQ (⟨((fct n : Nat) : Int), fct (n + 1)⟩ : Q) (fct_pos _)) (n + 1))
        (Req_trans (Rmul_congr (bernR_partition x n) (Req_refl _))
          (Rone_mul _))))) ?_
  refine Req_trans (Rmul_ofQ_ofQ Nat.one_pos (fct_pos _)) ?_
  refine ofQ_congr (Qmul_den_pos Nat.one_pos (fct_pos _)) (by decide) ?_
  have hfn1 : fct (n + 1) = (n + 1) * fct n := fct_succ n
  simp only [Qeq, mul]
  rw [hfn1]
  push_cast
  exact durrM0_id _

/-- **THE DURRMEYER MOMENT `M_n⁽¹⁾ = (nx+1)/(n+2)`**: `durrOp x n x = (n·x + 1)/(n+2)`. Each weight is
    `⟨x, b_{n,k}⟩ = (k+1)·n!/(n+2)!` (J₃, `durrInt_one`), factored as `(k+1)·(n!/(n+2)!)`; pull the constant
    out (`RsumN_mul_const`), collapse `Σ_k b_{n,k}(x)·(k+1) = nx+1` (`bernR_shift1`), and
    `(n+1)·n!/(n+2)! = 1/(n+2)`. -/
theorem durrOp_powTest_one (n : Nat) (x : Real) :
    Req (durrOp (powTest 1) n x)
        (Rmul (Radd (Rmul (RofNat n) x) one) (ofQ (⟨1, n + 2⟩ : Q) (Nat.succ_pos (n + 1)))) := by
  show Req (Rmul (RofNat (n + 1))
      (RsumN (fun k => Rmul (bernR x n k) (innerI (powTest 1) (bernBasisTest n k))) (n + 1))) _
  -- the k-independent factor `c = n!/(n+2)!`
  have hsplit : ∀ k, k ≤ n → Req (innerI (powTest 1) (bernBasisTest n k))
      (Rmul (RofNat (k + 1)) (ofQ (⟨((fct n : Nat) : Int), fct (n + 2)⟩ : Q) (fct_pos _))) := by
    intro k hk
    refine Req_trans (durrInt_one n k hk) (Req_symm ?_)
    refine Req_trans (Rmul_ofQ_ofQ Nat.one_pos (fct_pos _)) ?_
    refine ofQ_congr (Qmul_den_pos Nat.one_pos (fct_pos _)) (fct_pos _) ?_
    simp only [Qeq, mul]; push_cast; ring_uor
  -- rewrite the sum to `(Σ_k b_{n,k}·(k+1))·c` and collapse
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (RsumN_congr (n + 1) (fun k hk =>
        Req_trans (Rmul_congr (Req_refl _) (hsplit k (by omega)))
          (Req_symm (Rmul_assoc (bernR x n k) (RofNat (k + 1))
            (ofQ (⟨((fct n : Nat) : Int), fct (n + 2)⟩ : Q) (fct_pos _))))))
      (Req_trans (RsumN_mul_const (fun k => Rmul (bernR x n k) (RofNat (k + 1)))
          (ofQ (⟨((fct n : Nat) : Int), fct (n + 2)⟩ : Q) (fct_pos _)) (n + 1))
        (Rmul_congr (bernR_shift1 x n) (Req_refl _))))) ?_
  -- `(n+1)·((nx+1)·c) = (nx+1)·((n+1)·c) = (nx+1)·(1/(n+2))`
  refine Req_trans (Rmul_left_comm'' (RofNat (n + 1)) (Radd (Rmul (RofNat n) x) one)
    (ofQ (⟨((fct n : Nat) : Int), fct (n + 2)⟩ : Q) (fct_pos _))) ?_
  refine Rmul_congr (Req_refl _) ?_
  refine Req_trans (Rmul_ofQ_ofQ Nat.one_pos (fct_pos _)) ?_
  refine ofQ_congr (Qmul_den_pos Nat.one_pos (fct_pos _)) (Nat.succ_pos (n + 1)) ?_
  have hfn2 : fct (n + 2) = (n + 2) * ((n + 1) * fct n) := by
    have h1 : fct (n + 2) = (n + 2) * fct (n + 1) := fct_succ (n + 1)
    rw [h1, fct_succ n]
  simp only [Qeq, mul]
  rw [hfn2]
  push_cast
  exact durrM1_id _ _

/-- **THE DURRMEYER MOMENT `M_n⁽²⁾ = (n(n−1)x² + 4nx + 2)/((n+2)(n+3))`**:
    `durrOp x² n x = (n(n−1)x² + 4nx + 2)/((n+2)(n+3))`. Each weight is
    `⟨x², b_{n,k}⟩ = (k+1)(k+2)·n!/(n+3)!` (J₃, `durrInt_two`); pull the constant out (`RsumN_mul_const`),
    collapse `Σ_k b_{n,k}(x)·(k+1)(k+2) = n(n−1)x²+4nx+2` (`bernR_shift2`), and `(n+1)·n!/(n+3)! =
    1/((n+2)(n+3))`. -/
theorem durrOp_powTest_two (n : Nat) (x : Real) :
    Req (durrOp (powTest 2) n x)
        (Rmul (Radd (Radd (Rmul (RofNat (n * (n - 1))) (Rmul x x))
                          (Rmul (RofNat 4) (Rmul (RofNat n) x))) (RofNat 2))
              (ofQ (⟨1, (n + 2) * (n + 3)⟩ : Q)
                (Nat.mul_pos (Nat.succ_pos (n + 1)) (Nat.succ_pos (n + 2))))) := by
  show Req (Rmul (RofNat (n + 1))
      (RsumN (fun k => Rmul (bernR x n k) (innerI (powTest 2) (bernBasisTest n k))) (n + 1))) _
  have hsplit : ∀ k, k ≤ n → Req (innerI (powTest 2) (bernBasisTest n k))
      (Rmul (RofNat ((k + 1) * (k + 2)))
        (ofQ (⟨((fct n : Nat) : Int), fct (n + 3)⟩ : Q) (fct_pos _))) := by
    intro k hk
    refine Req_trans (durrInt_two n k hk) (Req_symm ?_)
    refine Req_trans (Rmul_ofQ_ofQ Nat.one_pos (fct_pos _)) ?_
    refine ofQ_congr (Qmul_den_pos Nat.one_pos (fct_pos _)) (fct_pos _) ?_
    simp only [Qeq, mul]; push_cast; ring_uor
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (RsumN_congr (n + 1) (fun k hk =>
        Req_trans (Rmul_congr (Req_refl _) (hsplit k (by omega)))
          (Req_symm (Rmul_assoc (bernR x n k) (RofNat ((k + 1) * (k + 2)))
            (ofQ (⟨((fct n : Nat) : Int), fct (n + 3)⟩ : Q) (fct_pos _))))))
      (Req_trans (RsumN_mul_const (fun k => Rmul (bernR x n k) (RofNat ((k + 1) * (k + 2))))
          (ofQ (⟨((fct n : Nat) : Int), fct (n + 3)⟩ : Q) (fct_pos _)) (n + 1))
        (Rmul_congr (bernR_shift2 x n) (Req_refl _))))) ?_
  refine Req_trans (Rmul_left_comm'' (RofNat (n + 1))
    (Radd (Radd (Rmul (RofNat (n * (n - 1))) (Rmul x x))
                (Rmul (RofNat 4) (Rmul (RofNat n) x))) (RofNat 2))
    (ofQ (⟨((fct n : Nat) : Int), fct (n + 3)⟩ : Q) (fct_pos _))) ?_
  refine Rmul_congr (Req_refl _) ?_
  refine Req_trans (Rmul_ofQ_ofQ Nat.one_pos (fct_pos _)) ?_
  refine ofQ_congr (Qmul_den_pos Nat.one_pos (fct_pos _))
    (Nat.mul_pos (Nat.succ_pos (n + 1)) (Nat.succ_pos (n + 2))) ?_
  have hfn3 : fct (n + 3) = (n + 3) * ((n + 2) * ((n + 1) * fct n)) := by
    have h1 : fct (n + 3) = (n + 3) * fct (n + 2) := fct_succ (n + 2)
    have h2 : fct (n + 2) = (n + 2) * fct (n + 1) := fct_succ (n + 1)
    rw [h1, h2, fct_succ n]
  simp only [Qeq, mul]
  rw [hfn3]
  push_cast
  exact durrM2_id _ _

end Multiplicity.UOR.Bridge.F1Square.Square
