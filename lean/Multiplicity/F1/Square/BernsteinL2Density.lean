/-
F1 square — **L² density of the Bernstein polynomials** (`BernsteinL2Density.lean`), the Bernstein arc,
sub-brick L₂. The uniform (sup-norm) convergence of the operator-as-test (L₁) upgrades to convergence in
the L² norm: the Bernstein residual of `φ` has vanishing energy at a rational rate,

  `⟨φ − bernOpCTest φ ((k+1)²) …, φ − …⟩ = ‖φ − B_n φ‖²_{L²[0,1]} ≤ (5·φ.L/(8(k+1)))²`   (`bernOp_L2_converges`),

so the polynomials `bernOpCTest φ n` are **dense in `L²[0,1]`** — the residual tends to `0` in energy.

Two ingredients:
- a reusable `innerI_self_le_of_bound`: a pointwise sup bound `|g(x)| ≤ B` on `[0,1]` forces
  `⟨g,g⟩ = ∫₀¹ g² ≤ B²` (unit-local monotonicity of the certified integral against the constant `B²`);
- the uniform bound `|φ(x) − (bernOpCTest φ ((k+1)²) …).f x| ≤ 5·φ.L/(8(k+1))` on `[0,1]` (L₁,
  `bernOp_uniform_converges`), applied to `g = φ − bernOpCTest φ ((k+1)²) …`.

WHY (the Sonine route, step 3, the completed L² space). Density of the polynomials in `L²[0,1]` is the
approximation half of the completed function space the Mellin front left open — complementary to
`L2Complete.lean` (which extends the pairing along L²-Cauchy sequences but constructs no approximating
family) and to moment determinacy (the injectivity half). Together: the moment map is injective, and its
image polynomials are L²-dense.

HONEST SCOPE. Convergence of one polynomial scheme to a bounded-Lipschitz test in the `L²[0,1]` norm, at
an explicit rational rate. NOT a completed L² space of *functions* (no limit member, no inversion of an
arbitrary L² element), NOT surjectivity onto function space, NOT positivity. Step 4 is RH; crux fields
stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.BernsteinUniform
import Multiplicity.F1.Square.MomentSummable
import Multiplicity.F1.Square.PairingLimitI
import Multiplicity.F1.Analysis.IntervalIntegral
import Multiplicity.F1.Analysis.IntegralLocal

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **A POINTWISE SUP BOUND CONTROLS THE L² ENERGY**: if `|g(x)| ≤ B` on `[0,1]` (with `B ≥ 0`), then
    `⟨g,g⟩ = ∫₀¹ g² ≤ B²`. The energy integrand `g²` is dominated pointwise by the constant `B²`
    (`Rsq_le_of_abs_le`), so unit-local monotonicity of the certified integral against that constant
    (`riemannIntegral_le_unit`, `riemannIntegral_const_gen`) gives the bound. Reusable. -/
theorem innerI_self_le_of_bound (g : L2Test) {B : Q} (hBd : 0 < B.den) (hBn : 0 ≤ B.num)
    (hbnd : ∀ x, Rle zero x → Rle x one → Rle (Rabs (g.f x)) (ofQ B hBd)) :
    Rle (innerI g g) (ofQ (mul B B) (Qmul_den_pos hBd hBd)) := by
  have hLd := l2L_den g g
  have hLn := l2L_num g g
  have hzeroL : Qle (⟨0, 1⟩ : Q) (l2L g g) := by
    show (0 : Int) * ((l2L g g).den : Int) ≤ (l2L g g).num * 1
    rw [Int.zero_mul, Int.mul_one]; exact hLn
  -- the constant `B²` is Lipschitz at the product modulus `l2L g g`
  have hlipC : ∀ x y, Rle (Rabs (Rsub (ofQ (mul B B) (Qmul_den_pos hBd hBd))
        (ofQ (mul B B) (Qmul_den_pos hBd hBd))))
      (Rmul (ofQ (l2L g g) hLd) (Rabs (Rsub x y))) :=
    lip_weaken (by decide) hLd hzeroL (const_lip0 (ofQ (mul B B) (Qmul_den_pos hBd hBd)))
  have hcC := riemannIntegral_const_gen (ofQ (mul B B) (Qmul_den_pos hBd hBd)) hLd hLn hlipC
    (fun _ _ _ => Req_refl _)
  -- `g(x)² ≤ B²` pointwise on `[0,1]`
  have hpt : ∀ x, Rle zero x → Rle x one →
      Rle (Rmul (g.f x) (g.f x)) (ofQ (mul B B) (Qmul_den_pos hBd hBd)) := by
    intro x h0 h1
    exact Rle_trans (Rsq_le_of_abs_le (Rnonneg_ofQ hBd hBn) (hbnd x h0 h1))
      (Rle_of_Req (Rmul_ofQ_ofQ hBd hBd))
  exact Rle_trans (riemannIntegral_le_unit hLd hLn (l2lip g g) (l2fc g g) hlipC
    (fun _ _ _ => Req_refl _) hpt) (Rle_of_Req hcC)

/-- **L² DENSITY OF THE BERNSTEIN POLYNOMIALS**: the energy of the Bernstein residual of `φ` vanishes at
    a rational rate, `‖φ − bernOpCTest φ ((k+1)²) …‖²_{L²[0,1]} ≤ (5·φ.L/(8(k+1)))²`. The uniform
    pointwise bound (L₁) feeds `innerI_self_le_of_bound` on the residual test. So the polynomials are dense
    in `L²[0,1]`: `⟨φ − B_n φ, φ − B_n φ⟩ → 0`. -/
theorem bernOp_L2_converges (φ : L2Test) (k : Nat) :
    Rle (innerI (L2Test.sub φ (bernOpCTest φ ((k + 1) * (k + 1))
              (Nat.mul_pos (Nat.succ_pos k) (Nat.succ_pos k))))
            (L2Test.sub φ (bernOpCTest φ ((k + 1) * (k + 1))
              (Nat.mul_pos (Nat.succ_pos k) (Nat.succ_pos k)))))
        (ofQ (mul (mul φ.L (⟨5, 8 * (k + 1)⟩ : Q)) (mul φ.L (⟨5, 8 * (k + 1)⟩ : Q)))
          (Qmul_den_pos (Qmul_den_pos φ.hLd (Nat.mul_pos (by decide) (Nat.succ_pos k)))
                        (Qmul_den_pos φ.hLd (Nat.mul_pos (by decide) (Nat.succ_pos k))))) := by
  have h8d : 0 < (⟨5, 8 * (k + 1)⟩ : Q).den := Nat.mul_pos (by decide) (Nat.succ_pos k)
  refine innerI_self_le_of_bound _ (B := mul φ.L (⟨5, 8 * (k + 1)⟩ : Q))
    (Qmul_den_pos φ.hLd h8d) (Int.mul_nonneg φ.hLn (by show (0 : Int) ≤ 5; decide)) ?_
  intro x h0 h1
  exact bernOp_uniform_converges φ h0 h1 k

end Multiplicity.UOR.Bridge.F1Square.Square
