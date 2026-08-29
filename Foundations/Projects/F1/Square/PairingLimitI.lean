/-
F1 square — **the pre-Hilbert layer, brick 14** (`PairingLimitI.lean`): **THE L² MIRROR of the
completion axis** — negation and subtraction on the test class, the L² squared distance, and
the extension of the L² pairing to squared-Cauchy sequences of tests.

- `L2Test.neg` / `L2Test.sub` — the test class is closed under negation (SAME modulus and bound,
  definitionally) and subtraction; with `add` (brick 7) and `mul` (brick 10) the class is a
  genuine commutative algebra with subtraction.
- `innerI_neg_left` / `innerI_sub_left` — the pairing is linear over them: `⟨−φ, ψ⟩ ≈ −⟨φ,ψ⟩`
  (pointwise sign flip through the SAME certificate, then `riemannIntegral_neg`), hence
  `⟨φ−φ', ψ⟩ ≈ ⟨φ,ψ⟩ − ⟨φ',ψ⟩`.
- `dist2I φ ψ = ⟨φ−ψ, φ−ψ⟩` — the L² squared distance on the test class.
- `innerI_sub_sq_le` — the L² Cauchy–Schwarz continuity: `(⟨φ,ψ⟩−⟨φ',ψ⟩)² ≤ d²(φ,φ')·⟨ψ,ψ⟩`
  (brick 9's integral Cauchy–Schwarz at the difference test).
- **`pairingILim`** — for a sequence of tests squared-Cauchy against `ψ`, the L² pairings
  `⟨Φⱼ, ψ⟩` are `RReg` and their Bishop limit exists, with the effective rate
  `pairingILim_dist` (`≤ 2/(j+1)`) — the completion axis opened on the FUNCTION-SPACE side.

HONEST SCOPE. Extended L² pairing values along squared-Cauchy sequences of tests; no completed
L² space, no limit member, no strong convergence, no claim toward the `f, f̂` coupling. The
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.TestAlgebra
import Foundations.F1.Square.PairingLimit
import Foundations.F1.Analysis.T4PoleAPieces

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Negation and subtraction on the test class.
-- ===========================================================================

/-- **Closure under negation**: same modulus, same bound — definitionally. -/
def L2Test.neg (φ : L2Test) : L2Test where
  f := fun x => Rneg (φ.f x)
  L := φ.L
  M := φ.M
  hLd := φ.hLd
  hLn := φ.hLn
  hMd := φ.hMd
  hMn := φ.hMn
  hlip := lip_neg φ.hlip
  hfc := congr_neg φ.hfc
  hbd := fun x => Rle_trans (Rle_of_Req (Rabs_Rneg (φ.f x))) (φ.hbd x)

/-- **Closure under subtraction**. -/
def L2Test.sub (φ ψ : L2Test) : L2Test := L2Test.add φ (L2Test.neg ψ)

/-- **The pairing flips sign with the first slot**: `⟨−φ, ψ⟩ ≈ −⟨φ,ψ⟩` — the negated test has
    the SAME product modulus definitionally, so the pointwise sign flip passes through one
    congruence and `riemannIntegral_neg`. -/
theorem innerI_neg_left (φ ψ : L2Test) :
    Req (innerI (L2Test.neg φ) ψ) (Rneg (innerI φ ψ)) := by
  have hlipn : ∀ x y, Rle (Rabs (Rsub (Rneg (Rmul (φ.f x) (ψ.f x)))
      (Rneg (Rmul (φ.f y) (ψ.f y)))))
      (Rmul (ofQ (l2L φ ψ) (l2L_den φ ψ)) (Rabs (Rsub x y))) :=
    lip_neg (l2lip φ ψ)
  have hfcn : ∀ x y, Req x y → Req (Rneg (Rmul (φ.f x) (ψ.f x)))
      (Rneg (Rmul (φ.f y) (ψ.f y))) :=
    congr_neg (l2fc φ ψ)
  refine Req_trans (riemannIntegral_congr (l2L_den φ ψ) (l2L_num φ ψ)
    (l2lip (L2Test.neg φ) ψ) (l2fc (L2Test.neg φ) ψ) hlipn hfcn
    (fun x => Rmul_neg_left (φ.f x) (ψ.f x))) ?_
  exact riemannIntegral_neg (l2L_den φ ψ) (l2L_num φ ψ) (l2lip φ ψ) (l2fc φ ψ) hlipn hfcn

/-- **Subtraction in the first slot**: `⟨φ − φ', ψ⟩ ≈ ⟨φ,ψ⟩ − ⟨φ',ψ⟩`. -/
theorem innerI_sub_left (φ φ' ψ : L2Test) :
    Req (innerI (L2Test.sub φ φ') ψ) (Rsub (innerI φ ψ) (innerI φ' ψ)) :=
  Req_trans (innerI_add_left φ (L2Test.neg φ') ψ)
    (Radd_congr (Req_refl _) (innerI_neg_left φ' ψ))

-- ===========================================================================
-- The L² squared distance and the Cauchy–Schwarz continuity.
-- ===========================================================================

/-- The **L² squared distance** on the test class: `d²(φ,ψ) = ⟨φ−ψ, φ−ψ⟩`. -/
def dist2I (φ ψ : L2Test) : Real := innerI (L2Test.sub φ ψ) (L2Test.sub φ ψ)

/-- `d²(φ,ψ) ≥ 0`. -/
theorem dist2I_nonneg (φ ψ : L2Test) : Rnonneg (dist2I φ ψ) :=
  innerI_self_nonneg (L2Test.sub φ ψ)

/-- **L² Cauchy–Schwarz continuity of the pairing**:
    `(⟨φ,ψ⟩ − ⟨φ',ψ⟩)² ≤ d²(φ,φ')·⟨ψ,ψ⟩`. -/
theorem innerI_sub_sq_le (φ φ' ψ : L2Test) :
    Rle (Rmul (Rsub (innerI φ ψ) (innerI φ' ψ)) (Rsub (innerI φ ψ) (innerI φ' ψ)))
        (Rmul (dist2I φ φ') (innerI ψ ψ)) := by
  have hz : Req (Rsub (innerI φ ψ) (innerI φ' ψ)) (innerI (L2Test.sub φ φ') ψ) :=
    Req_symm (innerI_sub_left φ φ' ψ)
  refine Rle_trans (Rle_of_Req (Rmul_congr hz hz)) ?_
  exact innerI_cauchy_schwarz (L2Test.sub φ φ') ψ

-- ===========================================================================
-- The L² pairing extends to squared-Cauchy sequences of tests.
-- ===========================================================================

/-- `|z|² ≈ z²` (local copy). -/
private theorem abs_sq' (z : Real) : Req (Rmul (Rabs z) (Rabs z)) (Rmul z z) :=
  Req_trans (Req_symm (Rabs_Rmul z z)) (Rabs_of_nonneg (Rnonneg_Rmul_self z))

/-- **The L² pairings along a squared-Cauchy sequence of tests are regular**: with
    `d²(Φⱼ,Φₖ)·⟨ψ,ψ⟩ ≤ (1/(j+1) + 1/(k+1))²`, the reals `⟨Φⱼ,ψ⟩` satisfy `RReg`. -/
theorem pairingI_RReg {Φ : Nat → L2Test} {ψ : L2Test}
    (hΦψ : ∀ j k, Rle (Rmul (dist2I (Φ j) (Φ k)) (innerI ψ ψ))
      (ofQ (mul (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
                (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)))
        (Qmul_den_pos (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
                      (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))))) :
    RReg (fun j => innerI (Φ j) ψ) := by
  refine RReg_of_real_bound _
    (fun j k => add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
    (fun j k => add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
    (fun j k => Qle_refl _) (fun j k => ?_)
  have hεn : 0 ≤ (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)).num :=
    Qadd_num_nonneg_loc (by show (0 : Int) ≤ 1; decide) (by show (0 : Int) ≤ 1; decide)
  refine Rle_trans (Rle_Rabs_self _) ?_
  refine Rle_of_Rsq_le (Rnonneg_Rabs _)
    (Rnonneg_ofQ (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k)) hεn) ?_
  refine Rle_trans (Rle_of_Req (abs_sq' _)) ?_
  refine Rle_trans (innerI_sub_sq_le (Φ j) (Φ k) ψ) ?_
  refine Rle_trans (hΦψ j k) ?_
  exact Rle_of_Req (Req_symm (Rmul_ofQ_ofQ
    (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
    (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))))

/-- **THE EXTENDED L² PAIRING**: `lim_j ⟨Φⱼ, ψ⟩` exists as a constructed real for every
    squared-Cauchy sequence of tests — the completion axis opened on the function-space side. -/
def pairingILim (Φ : Nat → L2Test) (ψ : L2Test)
    (hΦψ : ∀ j k, Rle (Rmul (dist2I (Φ j) (Φ k)) (innerI ψ ψ))
      (ofQ (mul (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
                (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)))
        (Qmul_den_pos (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
                      (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))))) : Real :=
  Rlim (fun j => innerI (Φ j) ψ) (pairingI_RReg hΦψ)

/-- The effective rate: `|⟨Φⱼ,ψ⟩ − pairingILim| ≤ 2/(j+1)`. -/
theorem pairingILim_dist {Φ : Nat → L2Test} {ψ : L2Test}
    (hΦψ : ∀ j k, Rle (Rmul (dist2I (Φ j) (Φ k)) (innerI ψ ψ))
      (ofQ (mul (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
                (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)))
        (Qmul_den_pos (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
                      (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))))) (j : Nat) :
    Rle (Rabs (Rsub (innerI (Φ j) ψ) (pairingILim Φ ψ hΦψ)))
        (ofQ (⟨2, j + 1⟩ : Q) (Nat.succ_pos j)) :=
  Rabs_dist_Rlim (pairingI_RReg hΦψ) j

end Multiplicity.UOR.Bridge.F1Square.Square
