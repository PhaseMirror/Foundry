/-
F1 square — **the Bernstein operator as a test, and its moment-integral** (`BernsteinOperatorTest.lean`),
the Bernstein arc, sub-brick H₄. Assembling H₁–H₃ into the operator integral: the clamped Bernstein
operator `B_n(φ)` is realized as a genuine `L2Test`,

    `bernOpCTest φ n hn = Σ_{k=0}^n (constTest (φ(k/n)·C(n,k)))·(clampProdTest k (n−k))`,

which (a) pairs to zero against a moment-null `φ`,

    `⟨φ, bernOpCTest φ n hn⟩ ≈ 0`   (`innerI_bernOpCTest_zero`, when every moment of `φ` vanishes),

because each summand is a real coefficient times a single basis integral that already vanishes (H₁/H₃);
and (b) agrees with the honest operator `bernOp` (sub-brick G) on `[0,1]`,

    `(bernOpCTest φ n hn).f x ≈ B_n(φ)(x)`   for `0 ≤ x ≤ 1`   (`bernOpCTest_eq_on_unit`, via H₂),

so the pointwise deviation bound transfers to it. Together these are exactly `∫₀¹ φ·B_n(φ) = 0` plus the
handle on `∫₀¹ φ·(φ − B_n(φ))` that the determinacy step consumes.

WHY (the Sonine route, step 3, the Mellin FRONT). The determinacy identity is
`⟨φ,φ⟩ = ⟨φ, φ − B_nφ⟩ + ⟨φ, B_nφ⟩`; the second term vanishes here, and the first is controlled by the
deviation. The real coefficients `φ(k/n)` — which cannot scale an `L2Test` directly — are carried as
constant tests (H₃) with the `C(n,k)` factor folded in, so the whole operator stays a bounded-Lipschitz
test and the pairing is finite-additive over the basis.

HONEST SCOPE. The operator as a test, its vanishing pairing, and its `[0,1]`-agreement with `bernOp`.
Infrastructure for determinacy; NOT yet the deviation integral, NOT `⟨φ,φ⟩ ≈ 0`, NOT determinacy, NOT
inversion, NOT positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.BernsteinClampMatch
import Multiplicity.F1Square.Square.BernsteinDeviation
import Multiplicity.F1Square.Square.ConstScale

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Finite sums of tests.
-- ===========================================================================

/-- **The finite sum of a family of tests** `Σ_{k<N} g k` (mirrors `RsumN`: old sum first). -/
def L2sumN (g : Nat → L2Test) : Nat → L2Test
  | 0 => zeroL2
  | N + 1 => L2Test.add (L2sumN g N) (g N)

/-- **A finite sum's values are the finite sum of values**: `(Σ_{k<N} g k).f x = Σ_{k<N} (g k).f x`. -/
theorem L2sumN_f_eq (g : Nat → L2Test) (x : Real) :
    ∀ N, Req ((L2sumN g N).f x) (RsumN (fun k => (g k).f x) N)
  | 0 => Req_refl zero
  | N + 1 => Radd_congr (L2sumN_f_eq g x N) (Req_refl _)

/-- **A finite sum of tests pairs to zero** if every summand does. -/
theorem innerI_L2sumN_zero (φ : L2Test) (g : Nat → L2Test) :
    ∀ N, (∀ k, k < N → Req (innerI φ (g k)) zero) → Req (innerI φ (L2sumN g N)) zero
  | 0, _ => Req_trans (innerI_symm φ zeroL2) (innerI_zeroL2 φ)
  | N + 1, h => by
    refine Req_trans (innerI_add_right φ (L2sumN g N) (g N)) ?_
    exact Req_trans (Radd_congr
      (innerI_L2sumN_zero φ g N (fun k hk => h k (Nat.lt_succ_of_lt hk)))
      (h N (Nat.lt_succ_self N))) (Radd_zero zero)

-- ===========================================================================
-- The Bernstein operator as a test.
-- ===========================================================================

/-- The real coefficient of the `k`-th operator term, `φ(k/n)·C(n,k)`. -/
def bernCoef (φ : L2Test) (n : Nat) (hn : 0 < n) (k : Nat) : Real :=
  Rmul (φ.f (ratPt k n hn)) (RofNat (choose n k))

/-- The coefficient is bounded by the rational `M_φ·C(n,k)`. -/
theorem bernCoef_bound (φ : L2Test) (n : Nat) (hn : 0 < n) (k : Nat) :
    Rle (Rabs (bernCoef φ n hn k))
        (ofQ (mul φ.M (⟨(choose n k : Int), 1⟩ : Q)) (Qmul_den_pos φ.hMd Nat.one_pos)) := by
  refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl _)
    (Rabs_of_nonneg (Rnonneg_RofNat (choose n k))))) ?_
  refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_RofNat (choose n k)) (φ.hbd (ratPt k n hn))) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ φ.hMd Nat.one_pos)

/-- The `k`-th operator term as a test: `(constTest (φ(k/n)·C(n,k)))·(clampProdTest k (n−k))`. -/
def bernTermCTest (φ : L2Test) (n : Nat) (hn : 0 < n) (k : Nat) : L2Test :=
  L2Test.mul (constTest (bernCoef φ n hn k) (mul φ.M (⟨(choose n k : Int), 1⟩ : Q))
      (Qmul_den_pos φ.hMd Nat.one_pos)
      (Int.mul_nonneg φ.hMn (Int.ofNat_nonneg (choose n k))) (bernCoef_bound φ n hn k))
    (clampProdTest k (n - k))

/-- **The clamped Bernstein operator as a test** `B_n(φ) = Σ_{k=0}^n φ(k/n)·C(n,k)·clamp01ᵏ(1−clamp01)ⁿ⁻ᵏ`. -/
def bernOpCTest (φ : L2Test) (n : Nat) (hn : 0 < n) : L2Test :=
  L2sumN (bernTermCTest φ n hn) (n + 1)

/-- **★ THE OPERATOR PAIRS TO ZERO**: if every moment of `φ` vanishes, then `⟨φ, B_n(φ)⟩ ≈ 0`. Each
    summand is a real coefficient times a single-basis integral that already vanishes (`innerI_constMul_zero`
    ∘ `innerI_clampProd_zero`), and the finite sum stays zero. -/
theorem innerI_bernOpCTest_zero (φ : L2Test) (hmom : ∀ i, Req (mellinMoment φ i) zero)
    (n : Nat) (hn : 0 < n) : Req (innerI φ (bernOpCTest φ n hn)) zero :=
  innerI_L2sumN_zero φ (bernTermCTest φ n hn) (n + 1) (fun k _ =>
    innerI_constMul_zero φ (clampProdTest k (n - k)) (bernCoef φ n hn k)
      (Qmul_den_pos φ.hMd Nat.one_pos)
      (Int.mul_nonneg φ.hMn (Int.ofNat_nonneg (choose n k))) (bernCoef_bound φ n hn k)
      (innerI_clampProd_zero φ hmom (n - k) k))

/-- **★ THE OPERATOR TEST AGREES WITH `bernOp` ON `[0,1]`**: `(bernOpCTest φ n hn).f x ≈ B_n(φ)(x)` for
    `0 ≤ x ≤ 1`. Termwise, `φ(k/n)·C(n,k)·(clampProd).f x = φ(k/n)·bernR x n k` by the H₂ match plus
    associativity, so the deviation bound (sub-brick G) transfers to the test. -/
theorem bernOpCTest_eq_on_unit (φ : L2Test) (n : Nat) (hn : 0 < n) {x : Real}
    (h0 : Rle zero x) (h1 : Rle x one) :
    Req ((bernOpCTest φ n hn).f x) (bernOp φ n hn x) := by
  rw [bernOp_unfold]
  refine Req_trans (L2sumN_f_eq (bernTermCTest φ n hn) x (n + 1)) ?_
  refine RsumN_congr (n + 1) (fun k _ => ?_)
  show Req (Rmul (bernCoef φ n hn k) ((clampProdTest k (n - k)).f x))
      (Rmul (φ.f (ratPt k n hn)) (bernR x n k))
  refine Req_trans (Rmul_assoc (φ.f (ratPt k n hn)) (RofNat (choose n k))
    ((clampProdTest k (n - k)).f x)) ?_
  exact Rmul_congr (Req_refl _) (Req_symm (bernR_eq_scaled_clampProd n k h0 h1))

end Multiplicity.UOR.Bridge.F1Square.Square
