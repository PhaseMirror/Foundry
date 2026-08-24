/-
F1 square — **the two-function reconstruction energy bound** (`MomentReconEnergy.lean`), the
Mellin-inversion arc, sub-brick I₃a. The quantitative core of the weak (pairing) inversion: the error
between the pairing `⟨φ,ψ⟩` and the reconstruction sum `bernReconSum φ ψ n` (= `⟨φ, B_n(ψ)⟩`, computed
from `φ`'s moments, I₂) is bounded, in multiplied form,

    `2δn · |⟨φ,ψ⟩ − bernReconSum φ ψ n| ≤ M_φ · L_ψ · (δ² + n/4)`   (`bernOp_recon_energy_bound`, δ ≥ 0).

Since `⟨φ,ψ⟩ − bernReconSum φ ψ n = ⟨φ, ψ − B_n(ψ)⟩` (`innerI_resid_eq`, via `innerI_sub_right` and I₂),
the residual integrand `φ·(ψ − B_nψ)` is bounded pointwise on `[0,1]` by `M_φ·L_ψ·(deviation)`
(`bernOpCTest_pointwise_dev` for `ψ`, with `ψ`'s own Lipschitz constant, times `φ.hbd`), and
`2δn·(deviation sum) ≤ δ²+n/4` (H₆, `bernOp_devsum_bound`, φ-independent). The scalar is pulled out at the
raw-integral level via the exposed general `energy_from_pointwise` (H₇), with `ψ − B_nψ` staying abstract
so the operator test is never `whnf`-forced. This is the two-function generalization of the determinacy
energy bound (`bernOp_energy_bound`), which is the `φ = ψ`, moment-null case.

WHY (the Sonine route, step 3, the Mellin FRONT). Determinacy squeezes a fixed real `⟨φ,φ⟩` to zero with
`n → ∞`; inversion instead squeezes the *reconstruction error* `⟨φ,ψ⟩ − bernReconSum φ ψ n`, an
`n`-indexed sequence, to zero. This bound is that squeeze in multiplied form; a schedule `δ, n` making the
right side `o(2δn)` yields `bernReconSum φ ψ n → ⟨φ,ψ⟩` — the pairing functional recovered from the moment
data. Forming the limit is the next step (I₃b).

HONEST SCOPE. The multiplied-form reconstruction-error bound and the residual identity, over `Real`.
Infrastructure for inversion; NOT yet the limit `bernReconSum φ ψ n → ⟨φ,ψ⟩`, NOT inversion, NOT the
transform pair's surjectivity, NOT positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.BernsteinEnergyBound
import Multiplicity.F1.Square.MomentReconSum

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- Seal the operator test so unification never unfolds `(bernOpCTest …).f x` to the free-`n` `ratPt`;
-- it enters the proofs only opaquely, through `bernOpCTest_pointwise_dev` and the pairing lemmas.
attribute [local irreducible] ratPt bernCoef bernTermCTest bernOpCTest

/-- `a·(b·c) ≈ b·(a·c)` (real, left-commute) — local copy for the general pointwise bound. -/
private theorem Rmul_left_comm' (a b c : Real) : Req (Rmul a (Rmul b c)) (Rmul b (Rmul a c)) :=
  Req_trans (Req_symm (Rmul_assoc a b c))
    (Req_trans (Rmul_congr (Rmul_comm a b) (Req_refl c)) (Rmul_assoc b a c))

/-- **The pointwise energy bound with a general Lipschitz constant**, abstract in the residual `ψ`:
    given `|ψ(x)| ≤ L·(deviation sum)` on `[0,1]`, `|2δn·(φ(x)·ψ(x))| ≤ M_φ·L·(δ²+n/4)`. The `φ = ψ`,
    `L = φ.L` case is H₇'s `bernOp_energy_pt`; here `L` is a parameter so the caller can use `ψ`'s own
    Lipschitz constant for the residual `ψ − B_n(ψ)`. Abstract `ψ` means `bernOpCTest` never appears. -/
private theorem energy_pt_gen (φ ψ : L2Test) (L : Q) (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (n : Nat) (hn : 0 < n) (δ : Q) (hδd : 0 < δ.den)
    (htwoden : 0 < (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)).den)
    (htwonum : (0 : Int) ≤ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)).num)
    (hBden : 0 < (mul (mul φ.M L) (add (mul δ δ) (⟨(n : Int), 4⟩ : Q))).den)
    (x : Real) (h0 : Rle zero x) (h1 : Rle x one)
    (hdev : Rle (Rabs (ψ.f x))
      (Rmul (ofQ L hLd)
        (RsumN (fun k => Rmul (Rabs (Rsub (ratPt k n hn) x)) (bernR x n k)) (n + 1)))) :
    Rle (Rabs (Rmul (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) htwoden)
        (Rmul (φ.f x) (ψ.f x))))
      (ofQ (mul (mul φ.M L) (add (mul δ δ) (⟨(n : Int), 4⟩ : Q))) hBden) := by
  -- `|2δn·(φ·ψ)| = 2δn·(|φ|·|ψ|)`
  refine Rle_trans (Rle_of_Req (Req_trans (Rabs_Rmul _ _)
    (Rmul_congr (Rabs_ofQ_nonneg htwoden htwonum) (Rabs_Rmul _ _)))) ?_
  -- `≤ 2δn·(M_φ·(L·devsum))`
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ htwoden htwonum)
    (Rle_trans (Rmul_le_Rmul_left (Rnonneg_Rabs _) hdev)
      (Rmul_le_Rmul_right
        (Rnonneg_Rmul (Rnonneg_ofQ hLd hLn)
          (Rnonneg_RsumN (n + 1) (fun k _ => Rnonneg_Rmul (Rnonneg_Rabs _)
            (bernR_nonneg x (Rnonneg_of_Rle_zero h0) (Rnonneg_Rsub_of_Rle h1) n k))))
        (φ.hbd x)))) ?_
  -- reorder `2δn·(M·(L·devsum))` to `M·(L·(2δn·devsum))`, bound `2δn·devsum ≤ δ²+n/4`
  refine Rle_trans (Rle_of_Req (Req_trans
    (Rmul_left_comm' (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) htwoden)
      (ofQ φ.M φ.hMd) (Rmul (ofQ L hLd) _))
    (Rmul_congr (Req_refl _)
      (Rmul_left_comm' (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) htwoden)
        (ofQ L hLd) _)))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ φ.hMd φ.hMn)
    (Rmul_le_Rmul_left (Rnonneg_ofQ hLd hLn)
      (bernOp_devsum_bound n hn h0 h1 δ hδd))) ?_
  have hDd : 0 < (add (mul δ δ) (⟨(n : Int), 4⟩ : Q)).den :=
    add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide)
  refine Rle_of_Req (Req_trans (Rmul_congr (Req_refl _) (Rmul_ofQ_ofQ hLd hDd))
    (Req_trans (Rmul_ofQ_ofQ φ.hMd (Qmul_den_pos hLd hDd)) ?_))
  exact ofQ_congr (Qmul_den_pos φ.hMd (Qmul_den_pos hLd hDd)) hBden
    (by show Qeq (mul φ.M (mul L (add (mul δ δ) (⟨(n : Int), 4⟩ : Q))))
          (mul (mul φ.M L) (add (mul δ δ) (⟨(n : Int), 4⟩ : Q)))
        simp only [Qeq, mul]; push_cast; ring_uor)

/-- **THE RESIDUAL IDENTITY**: `⟨φ, ψ − B_n(ψ)⟩ ≈ ⟨φ,ψ⟩ − bernReconSum φ ψ n` — the pairing of `φ`
    with `ψ`'s Bernstein residual is the reconstruction error, since `⟨φ, B_n(ψ)⟩ = bernReconSum`
    (`innerI_bernOpCTest_eq_reconSum`, I₂). -/
theorem innerI_resid_eq (φ ψ : L2Test) (n : Nat) (hn : 0 < n) :
    Req (innerI φ (L2Test.sub ψ (bernOpCTest ψ n hn)))
        (Rsub (innerI φ ψ) (bernReconSum φ ψ n hn)) :=
  Req_trans (innerI_sub_right φ ψ (bernOpCTest ψ n hn))
    (Rsub_congr (Req_refl _) (innerI_bernOpCTest_eq_reconSum φ ψ n hn))

/-- **★ THE MULTIPLIED-FORM RECONSTRUCTION-ERROR BOUND**:
    `2δn · |⟨φ,ψ⟩ − bernReconSum φ ψ n| ≤ M_φ·L_ψ·(δ²+n/4)`, any `δ ≥ 0`. The reconstruction error is the
    residual pairing `⟨φ, ψ − B_nψ⟩` (`innerI_resid_eq`); its integrand is bounded pointwise by
    `M_φ·L_ψ·(deviation)` (`energy_pt_gen` with `L = ψ.L`, deviation via `bernOpCTest_pointwise_dev` for
    `ψ`), and `2δn·(deviation sum) ≤ δ²+n/4` (H₆); the exposed general `energy_from_pointwise` (H₇) pulls
    the scalar `2δn` out at the raw-integral level, never unfolding the operator test. The two-function
    generalization of `bernOp_energy_bound` (the `φ = ψ`, moment-null determinacy case). -/
theorem bernOp_recon_energy_bound (φ ψ : L2Test) (n : Nat) (hn : 0 < n) (δ : Q) (hδd : 0 < δ.den)
    (hδn : 0 ≤ δ.num) :
    Rle (Rmul (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q))
                (Qmul_den_pos (Qmul_den_pos (by decide) hδd) Nat.one_pos))
              (Rabs (Rsub (innerI φ ψ) (bernReconSum φ ψ n hn))))
        (ofQ (mul (mul φ.M ψ.L) (add (mul δ δ) (⟨(n : Int), 4⟩ : Q)))
          (Qmul_den_pos (Qmul_den_pos φ.hMd ψ.hLd)
            (add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide)))) := by
  have hres := energy_from_pointwise φ (L2Test.sub ψ (bernOpCTest ψ n hn))
    (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q))
    (Qmul_den_pos (Qmul_den_pos (by decide) hδd) Nat.one_pos)
    (Int.mul_nonneg (Int.mul_nonneg (by decide) hδn) (Int.ofNat_nonneg n))
    (mul (mul φ.M ψ.L) (add (mul δ δ) (⟨(n : Int), 4⟩ : Q)))
    (Qmul_den_pos (Qmul_den_pos φ.hMd ψ.hLd)
      (add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide)))
    (fun x h0 h1 => energy_pt_gen φ (L2Test.sub ψ (bernOpCTest ψ n hn)) ψ.L ψ.hLd ψ.hLn n hn δ hδd
      (Qmul_den_pos (Qmul_den_pos (by decide) hδd) Nat.one_pos)
      (Int.mul_nonneg (Int.mul_nonneg (by decide) hδn) (Int.ofNat_nonneg n))
      (Qmul_den_pos (Qmul_den_pos φ.hMd ψ.hLd)
        (add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide)))
      x h0 h1 (bernOpCTest_pointwise_dev ψ n hn h0 h1))
  exact Rle_trans (Rle_of_Req (Rmul_congr (Req_refl _)
    (Rabs_congr (Req_symm (innerI_resid_eq φ ψ n hn))))) hres

end Multiplicity.UOR.Bridge.F1Square.Square
