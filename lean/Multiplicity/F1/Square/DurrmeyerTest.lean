/-
F1 square — **the Bernstein–Durrmeyer image as a test, and its L²-convergence** (`DurrmeyerTest.lean`),
the Mellin-inversion arc, the reconstruction companion of `BernsteinL2Density.lean`. The honest
Durrmeyer operator

    `durrOp φ n x = (n+1)·Σ_{k=0}^n b_{n,k}(x)·⟨φ, b_{n,k}⟩`

(computed from `φ`'s moment data, `MomentDurrmeyer.lean`) is packaged here as a genuine bounded-Lipschitz
test,

    `durrTest φ n hn = Σ_{k=0}^n (constTest ((n+1)·⟨φ, b_{n,k}⟩))·(bernBasisTest n k)`,

which (a) agrees with `durrOp` on `[0,1]`,

    `(durrTest φ n hn).f x ≈ durrOp φ n x`   for `0 ≤ x ≤ 1`   (`durrTest_eq_on_unit`, via the H₂ match),

each real coefficient `(n+1)·⟨φ, b_{n,k}⟩` carried as a constant test (bound `innerI_abs_le`) so the whole
image stays a test; and (b) has L²-small residual at a rational rate,

    `‖φ − durrTest φ ((k+3)²−2) …‖²_{L²[0,1]} ≤ (φ.L/(k+3))²`   (`durrTest_L2_converges`).

The convergence is the exact analogue of `bernOp_L2_converges`: the uniform pointwise deviation
(`durrOp_converges`, sub-brick J₆) `|durrOp φ ((k+3)²−2) x − φ(x)| ≤ φ.L/(k+3)` on `[0,1]` transfers to
`g = φ − durrTest φ ((k+3)²−2) …` by the `[0,1]`-agreement, and `innerI_self_le_of_bound` turns the sup
bound into the energy bound.

WHY (the Sonine route, step 3, the Mellin FRONT). Unlike the Bernstein operator, the Durrmeyer image is
built from the *integrals* `⟨φ, b_{n,k}⟩` — moment data — so this test is the vehicle for *reconstructing*
an arbitrary L² element from its moments: an approximating family that both reads `φ` through its moments
and converges to it in energy.

HONEST SCOPE. The Durrmeyer image packaged as an `L2Test` and its `L²[0,1]`-convergence to a
bounded-Lipschitz test, at an explicit rational rate. NOT positivity, NOT surjectivity onto function
space, NOT a completed L² space of functions, NOT inversion of an arbitrary L² element. Step 4 (the
band-coupling positivity) is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.BernsteinOperatorTest
import Multiplicity.F1.Square.BernsteinL2Density
import Multiplicity.F1.Square.DurrmeyerConverge

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Value-side unfolding of the sealed `natScale` and its real companion `natScaleR`.
-- ===========================================================================

-- `natScale` is `@[irreducible]`; re-derive its two defining equations as propositional `rfl`s so the
-- pointwise-value recursion can proceed without forcing the seal.
unseal natScale in
private theorem natScale_zero_dt (φ : L2Test) : natScale 0 φ = zeroL2 := rfl

unseal natScale in
private theorem natScale_succ_dt (k : Nat) (φ : L2Test) :
    natScale (k + 1) φ = L2Test.add φ (natScale k φ) := rfl

/-- **The pointwise value scales**: `(natScale m ψ).f x = natScaleR m (ψ.f x)` — the real-valued
    companion of `natScale_val` (which needs a rational value); the `[0,1]`-agreement below reads the
    basis test's value through it. -/
private theorem natScale_f_eq (ψ : L2Test) (x : Real) :
    ∀ m, Req ((natScale m ψ).f x) (natScaleR m (ψ.f x))
  | 0 => by rw [natScale_zero_dt]; exact Req_refl zero
  | m + 1 => by
    rw [natScale_succ_dt]
    exact Radd_congr (Req_refl (ψ.f x)) (natScale_f_eq ψ x m)

/-- `RofNat 0 ≈ 0` (the rational embedding of `0`). -/
private theorem RofNat_zero_dt : Req (RofNat 0) zero := Req_of_seq_Qeq (fun _ => Qeq_refl _)

/-- `RofNat 1 ≈ 1`. -/
private theorem RofNat_one_dt : Req (RofNat 1) one := Req_of_seq_Qeq (fun _ => Qeq_refl _)

/-- **The `k`-fold real sum is the `RofNat` multiple**: `natScaleR m a = (RofNat m)·a` — by induction,
    the step splitting `RofNat (m+1) = RofNat m + RofNat 1` (`RofNat_add`). -/
private theorem natScaleR_eq_Rmul (a : Real) :
    ∀ m, Req (natScaleR m a) (Rmul (RofNat m) a)
  | 0 => by
    refine Req_symm ?_
    exact Req_trans (Rmul_congr RofNat_zero_dt (Req_refl a))
      (Req_trans (Rmul_comm zero a) (Rmul_zero a))
  | m + 1 => by
    refine Req_trans (Radd_congr (Req_refl a) (natScaleR_eq_Rmul a m)) ?_
    refine Req_trans ?_ (Req_symm (Rmul_congr (RofNat_add m 1) (Req_refl a)))
    refine Req_trans ?_ (Req_symm (Rmul_distrib_right (RofNat m) (RofNat 1) a))
    refine Req_trans (Radd_comm a (Rmul (RofNat m) a)) ?_
    exact Radd_congr (Req_refl _)
      (Req_symm (Req_trans (Rmul_congr RofNat_one_dt (Req_refl a)) (Rone_mul a)))

/-- **The Bernstein basis test matches the honest basis on `[0,1]`**:
    `(bernBasisTest n k).f x ≈ bernR x n k` for `0 ≤ x ≤ 1`. Its value is `C(n,k)·(clampProdTest).f x`
    (`natScale_f_eq` + `natScaleR_eq_Rmul`), and that is `bernR x n k` on the unit interval
    (`bernR_eq_scaled_clampProd`, H₂). -/
private theorem bernBasisTest_f_eq_bernR (n k : Nat) {x : Real} (h0 : Rle zero x) (h1 : Rle x one) :
    Req ((bernBasisTest n k).f x) (bernR x n k) := by
  refine Req_trans (natScale_f_eq (clampProdTest k (n - k)) x (choose n k)) ?_
  refine Req_trans (natScaleR_eq_Rmul ((clampProdTest k (n - k)).f x) (choose n k)) ?_
  exact Req_symm (bernR_eq_scaled_clampProd n k h0 h1)

-- ===========================================================================
-- The `k`-th Durrmeyer term as a test.
-- ===========================================================================

/-- The real coefficient of the `k`-th Durrmeyer term, `(n+1)·⟨φ, b_{n,k}⟩`. -/
private def durrCoef (φ : L2Test) (n k : Nat) : Real :=
  Rmul (RofNat (n + 1)) (innerI φ (bernBasisTest n k))

/-- A rational bound for the coefficient: `(n+1)·(M_φ·M_{b} + (⌈L⌉+2))` — through the uniform pairing
    bound `innerI_abs_le`. (Any valid rational bound would do; the tight `(n+1)·C(n,k)·M_φ` is not needed
    downstream — the L²-convergence proof never reads it.) -/
private def durrMB (φ : L2Test) (n k : Nat) : Q :=
  mul (⟨((n + 1 : Nat) : Int), 1⟩ : Q)
    (add (mul φ.M (bernBasisTest n k).M)
      (⟨(((l2L φ (bernBasisTest n k)).num.toNat + 2 : Nat) : Int), 1⟩ : Q))

private theorem durrMB_den (φ : L2Test) (n k : Nat) : 0 < (durrMB φ n k).den :=
  Qmul_den_pos Nat.one_pos
    (add_den_pos (Qmul_den_pos φ.hMd (bernBasisTest n k).hMd) Nat.one_pos)

private theorem durrMB_num (φ : L2Test) (n k : Nat) : 0 ≤ (durrMB φ n k).num :=
  Int.mul_nonneg (Int.ofNat_nonneg (n + 1))
    (Qadd_num_nonneg_loc (Int.mul_nonneg φ.hMn (bernBasisTest n k).hMn) (Int.ofNat_nonneg _))

/-- The coefficient is bounded by the rational `durrMB φ n k`. `|(n+1)·⟨φ, b_{n,k}⟩| =
    (n+1)·|⟨φ, b_{n,k}⟩| ≤ (n+1)·(uniform pairing bound)` (`Rabs_Rmul`, `Rnonneg_RofNat`, `innerI_abs_le`),
    the `RofNat (n+1)` folded into the rational scalar (`Rmul_ofQ_ofQ`). -/
private theorem durrCoef_bound (φ : L2Test) (n k : Nat) :
    Rle (Rabs (durrCoef φ n k)) (ofQ (durrMB φ n k) (durrMB_den φ n k)) := by
  have hB'd : 0 < (add (mul φ.M (bernBasisTest n k).M)
      (⟨(((l2L φ (bernBasisTest n k)).num.toNat + 2 : Nat) : Int), 1⟩ : Q)).den :=
    add_den_pos (Qmul_den_pos φ.hMd (bernBasisTest n k).hMd) Nat.one_pos
  show Rle (Rabs (Rmul (RofNat (n + 1)) (innerI φ (bernBasisTest n k))))
      (ofQ (durrMB φ n k) (durrMB_den φ n k))
  refine Rle_trans (Rle_of_Req (Rabs_Rmul (RofNat (n + 1)) (innerI φ (bernBasisTest n k)))) ?_
  refine Rle_trans (Rle_of_Req
    (Rmul_congr (Rabs_of_nonneg (Rnonneg_RofNat (n + 1))) (Req_refl _))) ?_
  refine Rle_trans
    (Rmul_le_Rmul_left (Rnonneg_RofNat (n + 1)) (innerI_abs_le φ (bernBasisTest n k))) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ (a := (⟨((n + 1 : Nat) : Int), 1⟩ : Q)) Nat.one_pos hB'd)

/-- The `k`-th Durrmeyer term as a test: `(constTest ((n+1)·⟨φ, b_{n,k}⟩))·(bernBasisTest n k)`. -/
private def durrTermTest (φ : L2Test) (n k : Nat) : L2Test :=
  L2Test.mul
    (constTest (durrCoef φ n k) (durrMB φ n k) (durrMB_den φ n k) (durrMB_num φ n k)
      (durrCoef_bound φ n k))
    (bernBasisTest n k)

-- ===========================================================================
-- The Durrmeyer image as a test.
-- ===========================================================================

/-- **★ THE BERNSTEIN–DURRMEYER IMAGE AS A TEST**
    `durrTest φ n hn = Σ_{k=0}^n (constTest ((n+1)·⟨φ, b_{n,k}⟩))·(bernBasisTest n k)`. -/
def durrTest (φ : L2Test) (n : Nat) (hn : 0 < n) : L2Test :=
  L2sumN (durrTermTest φ n) (n + 1)

/-- **★ THE DURRMEYER TEST AGREES WITH `durrOp` ON `[0,1]`**: `(durrTest φ n hn).f x ≈ durrOp φ n x` for
    `0 ≤ x ≤ 1`. Termwise, the constant `(n+1)·⟨φ, b_{n,k}⟩` times the basis value `(bernBasisTest n k).f x
    ≈ bernR x n k` reorders to `(n+1)·bernR x n k·⟨φ, b_{n,k}⟩`, matching `durrOp`'s summand after the
    `(n+1)` is pulled out of the finite sum (`RsumN_Rmul_const`). -/
theorem durrTest_eq_on_unit (φ : L2Test) (n : Nat) (hn : 0 < n) {x : Real}
    (h0 : Rle zero x) (h1 : Rle x one) :
    Req ((durrTest φ n hn).f x) (durrOp φ n x) := by
  refine Req_trans (L2sumN_f_eq (durrTermTest φ n) x (n + 1)) ?_
  refine Req_trans (RsumN_congr (n + 1) (fun k _ => ?_))
    (RsumN_Rmul_const (RofNat (n + 1))
      (fun k => Rmul (bernR x n k) (innerI φ (bernBasisTest n k))) (n + 1))
  show Req (Rmul (Rmul (RofNat (n + 1)) (innerI φ (bernBasisTest n k))) ((bernBasisTest n k).f x))
      (Rmul (RofNat (n + 1)) (Rmul (bernR x n k) (innerI φ (bernBasisTest n k))))
  refine Req_trans (Rmul_congr (Req_refl _) (bernBasisTest_f_eq_bernR n k h0 h1)) ?_
  refine Req_trans (Rmul_assoc (RofNat (n + 1)) (innerI φ (bernBasisTest n k)) (bernR x n k)) ?_
  exact Rmul_congr (Req_refl _) (Rmul_comm (innerI φ (bernBasisTest n k)) (bernR x n k))

-- ===========================================================================
-- L²-convergence of the Durrmeyer image.
-- ===========================================================================

/-- The operator degree `(k+3)²−2` is positive: `(k+3)² ≥ 9 > 2`. -/
private theorem durrN_pos (k : Nat) : 0 < (k + 3) * (k + 3) - 2 := by
  have h9 := Nat.mul_le_mul (show 3 ≤ k + 3 by omega) (show 3 ≤ k + 3 by omega)
  omega

/-- **★ L²-CONVERGENCE OF THE DURRMEYER IMAGE**: the residual of `φ` against `durrTest φ ((k+3)²−2)` has
    vanishing energy at a rational rate, `‖φ − durrTest φ ((k+3)²−2) …‖²_{L²[0,1]} ≤ (φ.L/(k+3))²`. The
    uniform pointwise deviation `|durrOp φ ((k+3)²−2) x − φ(x)| ≤ φ.L/(k+3)` (`durrOp_converges`)
    transfers to the residual test through the `[0,1]`-agreement (`durrTest_eq_on_unit`,
    `Rabs_Rsub_symm`), and `innerI_self_le_of_bound` upgrades the sup bound to the energy bound. The exact
    analogue of `bernOp_L2_converges` for the moment-computed image. -/
theorem durrTest_L2_converges (φ : L2Test) (k : Nat) :
    Rle (innerI (L2Test.sub φ (durrTest φ ((k + 3) * (k + 3) - 2) (durrN_pos k)))
                (L2Test.sub φ (durrTest φ ((k + 3) * (k + 3) - 2) (durrN_pos k))))
        (ofQ (mul (mul φ.L (⟨1, k + 3⟩ : Q)) (mul φ.L (⟨1, k + 3⟩ : Q)))
          (Qmul_den_pos (Qmul_den_pos φ.hLd (Nat.succ_pos (k + 2)))
                        (Qmul_den_pos φ.hLd (Nat.succ_pos (k + 2))))) := by
  refine innerI_self_le_of_bound _ (B := mul φ.L (⟨1, k + 3⟩ : Q))
    (Qmul_den_pos φ.hLd (Nat.succ_pos (k + 2)))
    (Int.mul_nonneg φ.hLn (by show (0 : Int) ≤ 1; decide)) ?_
  intro x h0 h1
  refine Rle_trans (Rle_of_Req (Req_trans
    (Rabs_congr (Rsub_congr (Req_refl (φ.f x))
      (durrTest_eq_on_unit φ ((k + 3) * (k + 3) - 2) (durrN_pos k) h0 h1)))
    (Rabs_Rsub_symm (φ.f x) (durrOp φ ((k + 3) * (k + 3) - 2) x)))) ?_
  exact durrOp_converges φ x h0 h1 k

end Multiplicity.UOR.Bridge.F1Square.Square
