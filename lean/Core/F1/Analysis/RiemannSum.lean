/-
F1 square — Track 1/2 gateway: **certified integration**, the constructive Riemann integral over the
unit interval `[0,1]`, foundation layer.

The document names certified integration as the gateway for *both* tracks: the item-3 Mellin link
(`∫₁^∞ t^{s/2−1}ψ(t)dt`, connecting the Jacobi theta function `ThetaFunction.lean` to the completed
ζ) and Track-2's genuine `f, f̂` Weil-pairing objects. No `∫` exists beyond interface statements.

This file lays the foundation: the **left Riemann sum** `R_N(f) = (1/(N+1))·Σ_{i≤N} f(i/(N+1))` over
`[0,1]` with `N+1` equal subintervals (rational partition points, so no `Rdiv`-witness threading), its
congruence in `f`, and the first integral identity `∫₀¹ c = c` (`riemannSum_const`). Convergence for
Lipschitz integrands (via dyadic refinement → `RReg` → `Rlim`, the established UOR pattern) is the
next layer.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.RSum
import Core.F1.Analysis.ComplexPow
import Core.F1.Analysis.RealPow

namespace UOR.Bridge.F1Square.Analysis

/-- **The left Riemann sum** of `f` over `[0,1]` with `N+1` equal subintervals:
    `R_N(f) = (1/(N+1))·Σ_{i=0}^{N} f(i/(N+1))`. The partition points `i/(N+1)` are rational
    embeddings (`ofQ`), so the sum is `Rdiv`-free. -/
def riemannSum (f : Real → Real) (N : Nat) : Real :=
  Rmul (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
    (RsumN (fun i => f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1))

/-- The Riemann sum respects `≈` of the integrand at the partition points. -/
theorem riemannSum_congr {f g : Real → Real} (N : Nat)
    (h : ∀ i, i < N + 1 →
      Req (f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
          (g (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))) :
    Req (riemannSum f N) (riemannSum g N) :=
  Rmul_congr (Req_refl _) (RsumN_congr (N + 1) h)

/-- **Sum of `M` copies of `c` is `M·c`.** -/
theorem RsumN_const (c : Real) : ∀ M, Req (RsumN (fun _ => c) M) (Rmul (RofNat M) c)
  | 0 => Req_symm (Req_trans (Rmul_comm (RofNat 0) c) (Rmul_zero c))
  | (M + 1) => by
      have hsucc : Req (RofNat (M + 1)) (Radd (RofNat M) one) :=
        Req_symm (Req_trans (Radd_ofQ_ofQ Nat.one_pos Nat.one_pos)
          (ofQ_congr (add_den_pos Nat.one_pos Nat.one_pos) Nat.one_pos
            (by simp only [Qeq, add]; push_cast; ring_uor)))
      refine Req_trans (Radd_congr (RsumN_const c M) (Req_refl c)) ?_
      refine Req_symm (Req_trans (Rmul_congr hsucc (Req_refl c)) ?_)
      exact Req_trans (Rmul_distrib_right (RofNat M) one c) (Radd_congr (Req_refl _) (Rone_mul c))

/-- **`∫₀¹ c = c`** — the Riemann sum of a constant integrand equals the constant (the integral over
    the unit interval). The first integral identity: `(1/(N+1))·((N+1)·c) = c`. -/
theorem riemannSum_const (c : Real) (N : Nat) : Req (riemannSum (fun _ => c) N) c := by
  have hone : Req (Rmul (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N)) (RofNat (N + 1)))
      (ofQ (⟨1, 1⟩ : Q) Nat.one_pos) :=
    Req_trans (Rmul_ofQ_ofQ (Nat.succ_pos N) Nat.one_pos)
      (ofQ_congr (Qmul_den_pos (Nat.succ_pos N) Nat.one_pos) Nat.one_pos
        (by simp only [Qeq, mul]; push_cast; ring_uor))
  refine Req_trans (Rmul_congr (Req_refl _) (RsumN_const c (N + 1))) ?_
  refine Req_trans (Req_symm (Rmul_assoc _ (RofNat (N + 1)) c)) ?_
  exact Req_trans (Rmul_congr hone (Req_refl c)) (Rone_mul c)

/-- **Finite sums are additive**: `Σ(F+G) = ΣF + ΣG`. -/
theorem RsumN_Radd (F G : Nat → Real) : ∀ N,
    Req (RsumN (fun i => Radd (F i) (G i)) N) (Radd (RsumN F N) (RsumN G N))
  | 0 => Req_symm (Radd_zero zero)
  | (N + 1) =>
      Req_trans (Radd_congr (RsumN_Radd F G N) (Req_refl (Radd (F N) (G N))))
        (Radd_swap (RsumN F N) (RsumN G N) (F N) (G N))

/-- **The Riemann sum is monotone in the integrand** (pointwise at the partition points). -/
theorem riemannSum_le {f g : Real → Real} (N : Nat)
    (h : ∀ i, i < N + 1 →
      Rle (f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
          (g (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))) :
    Rle (riemannSum f N) (riemannSum g N) :=
  Rmul_le_Rmul_left (Rnonneg_ofQ (Nat.succ_pos N) (show (0:Int) ≤ 1 by decide)) (RsumN_le (N + 1) h)

/-- **The Riemann sum of a non-negative integrand is non-negative** (`∫₀¹ f ≥ 0` for `f ≥ 0`). -/
theorem riemannSum_nonneg {f : Real → Real} (N : Nat)
    (h : ∀ i, i < N + 1 → Rnonneg (f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))) :
    Rnonneg (riemannSum f N) :=
  Rnonneg_Rmul (Rnonneg_ofQ (Nat.succ_pos N) (show (0:Int) ≤ 1 by decide)) (Rnonneg_RsumN (N + 1) h)

/-- **The Riemann sum is additive in the integrand** (linearity, additive part):
    `∫₀¹ (f+g) = ∫₀¹ f + ∫₀¹ g`. -/
theorem riemannSum_add (f g : Real → Real) (N : Nat) :
    Req (riemannSum (fun x => Radd (f x) (g x)) N)
        (Radd (riemannSum f N) (riemannSum g N)) :=
  Req_trans
    (Rmul_congr (Req_refl _)
      (RsumN_Radd (fun i => f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
        (fun i => g (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1)))
    (Rmul_distrib _ _ _)

/-- **Finite sums respect negation**: `Σ(−F) = −ΣF`. -/
theorem RsumN_Rneg (F : Nat → Real) : ∀ N,
    Req (RsumN (fun i => Rneg (F i)) N) (Rneg (RsumN F N))
  | 0 => Req_of_seq_Qeq (fun _ => Qeq_refl _)
  | (N + 1) =>
      Req_trans (Radd_congr (RsumN_Rneg F N) (Req_refl (Rneg (F N))))
        (Req_symm (Rneg_Radd (RsumN F N) (F N)))

/-- **The Riemann sum respects negation in the integrand**: `∫₀¹ (−f) = −∫₀¹ f`. -/
theorem riemannSum_neg (f : Real → Real) (N : Nat) :
    Req (riemannSum (fun x => Rneg (f x)) N) (Rneg (riemannSum f N)) :=
  Req_trans
    (Rmul_congr (Req_refl _)
      (RsumN_Rneg (fun i => f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1)))
    (Rmul_neg_right _ _)

/-- **Finite sums respect a constant scalar**: `Σ(c·F) = c·ΣF`. -/
theorem RsumN_Rmul_const (c : Real) (F : Nat → Real) : ∀ N,
    Req (RsumN (fun i => Rmul c (F i)) N) (Rmul c (RsumN F N))
  | 0 => Req_symm (Rmul_zero c)
  | (N + 1) =>
      Req_trans (Radd_congr (RsumN_Rmul_const c F N) (Req_refl (Rmul c (F N))))
        (Req_symm (Rmul_distrib c (RsumN F N) (F N)))

/-- `x·(y·z) ≈ y·(x·z)` (left-commute; local). -/
private theorem Rmul_lc (x y z : Real) : Req (Rmul x (Rmul y z)) (Rmul y (Rmul x z)) :=
  Req_trans (Req_symm (Rmul_assoc x y z))
    (Req_trans (Rmul_congr (Rmul_comm x y) (Req_refl z)) (Rmul_assoc y x z))

/-- **The Riemann sum respects a constant scalar in the integrand**: `∫₀¹ (c·f) = c·∫₀¹ f`. -/
theorem riemannSum_smul (c : Real) (f : Real → Real) (N : Nat) :
    Req (riemannSum (fun x => Rmul c (f x)) N) (Rmul c (riemannSum f N)) :=
  Req_trans
    (Rmul_congr (Req_refl _)
      (RsumN_Rmul_const c (fun i => f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1)))
    (Rmul_lc _ c _)

/-- **Finite sums subtract**: `Σ(F−G) = ΣF − ΣG`. -/
theorem RsumN_Rsub (F G : Nat → Real) : ∀ N,
    Req (RsumN (fun i => Rsub (F i) (G i)) N) (Rsub (RsumN F N) (RsumN G N))
  | 0 => Req_symm (Radd_neg zero)
  | (N + 1) =>
      Req_trans (Radd_congr (RsumN_Rsub F G N) (Req_refl (Rsub (F N) (G N))))
        (Req_trans
          (Radd_swap (RsumN F N) (Rneg (RsumN G N)) (F N) (Rneg (G N)))
          (Radd_congr (Req_refl (Radd (RsumN F N) (F N)))
            (Req_symm (Rneg_Radd (RsumN G N) (G N)))))

/-- **The even refinement point equals the coarser point**: `2j/(2M) = j/M`. -/
theorem dyadic_even_point (j M : Nat) (hM : 0 < M) :
    Req (ofQ (⟨2 * j, 2 * M⟩ : Q) (Nat.mul_pos (by decide) hM)) (ofQ (⟨j, M⟩ : Q) hM) :=
  ofQ_congr (Nat.mul_pos (by decide) hM) hM (by simp only [Qeq]; push_cast; ring_uor)

/-- **Even–odd sum split** `Σ_{i<2N} F(i) = Σ_{j<N} F(2j) + Σ_{j<N} F(2j+1)` — the combinatorial heart
    of dyadic Riemann-sum refinement (a `2N`-point sum reindexed as `N` even/odd pairs). Reusable. -/
theorem RsumN_split2 (F : Nat → Real) : ∀ N,
    Req (RsumN F (2 * N))
      (Radd (RsumN (fun j => F (2 * j)) N) (RsumN (fun j => F (2 * j + 1)) N))
  | 0 => Req_symm (Radd_zero zero)
  | (N + 1) => by
      have h2 : 2 * (N + 1) = 2 * N + 1 + 1 := by omega
      rw [h2]
      refine Req_trans (Radd_congr (Radd_congr (RsumN_split2 F N) (Req_refl (F (2 * N))))
        (Req_refl (F (2 * N + 1)))) ?_
      exact Req_trans
        (Radd_assoc (Radd (RsumN (fun j => F (2 * j)) N) (RsumN (fun j => F (2 * j + 1)) N))
          (F (2 * N)) (F (2 * N + 1)))
        (Radd_swap (RsumN (fun j => F (2 * j)) N) (RsumN (fun j => F (2 * j + 1)) N)
          (F (2 * N)) (F (2 * N + 1)))

end UOR.Bridge.F1Square.Analysis
