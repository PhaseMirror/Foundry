/-
F1 square — **the multiplied-form energy bound** (`BernsteinEnergyBound.lean`), the Bernstein arc,
sub-brick H₇. Integrating the pointwise deviation bound (H₅) against `φ`, weighted by `2δn`:

    `2δn · |⟨φ, φ − B_n(φ)⟩| ≤ M_φ·L·(δ² + n/4)`   (`bernOp_energy_bound`, any `δ ≥ 0`).

The residual pairing `⟨φ, φ − B_n(φ)⟩ = ∫₀¹ φ·(φ − B_nφ)` has integrand bounded pointwise on `[0,1]` by
`M_φ·(deviation)`, and `2δn·(deviation sum) ≤ δ² + n/4` (sub-brick H₆); so `2δn·|φ·(φ−B_nφ)| ≤
M_φ·L·(δ²+n/4)` there. The scalar `2δn` is pulled out at the **raw integral** level via the rational
`riemannIntegral_smul`/`riemannIntegral_Rsmul` (weakened to a common modulus), and the unit-local
absolute integral bound (`riemannIntegral_abs_le_unit`) lands the result — no `constTest`, so the
deeply-nested operator test is never `whnf`-forced. Kept in multiplied form so the reciprocal is only
formed at the concrete squeeze schedule.

WHY (the Sonine route, step 3, the Mellin FRONT). With `⟨φ,φ⟩ = ⟨φ, φ − B_nφ⟩` (H₅), this is a
`2δn`-weighted bound on the L² energy of a moment-null test; the schedule `δ = 2^m`, `n = 4^m` makes the
right side `→ 0` geometrically, forcing `⟨φ,φ⟩ ≈ 0` — the last input the determinacy squeeze consumes.

HONEST SCOPE. The multiplied-form energy bound and the unit-local absolute integral bound, over `Real`.
Infrastructure for determinacy; NOT yet `⟨φ,φ⟩ ≈ 0`, NOT determinacy, NOT inversion, NOT positivity.
Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.BernsteinDevBound
import Multiplicity.F1Square.Square.BernsteinDeviationTransfer
import Multiplicity.F1Square.Analysis.IntegralRsmul
import Multiplicity.F1Square.Analysis.IntegralLocal

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- Seal the operator test so unification never unfolds `(bernOpCTest …).f x` to the free-`n` `ratPt`;
-- it enters the proofs only opaquely, through `bernOpCTest_pointwise_dev`.
attribute [local irreducible] ratPt bernCoef bernTermCTest bernOpCTest

/-- **The unit-local absolute integral bound**: `|f| ≤ B` on `[0,1]` ⟹ `|∫₀¹ f| ≤ B`, comparison
    against the constants `±B` (unit-local monotonicity `riemannIntegral_le_unit`). -/
theorem riemannIntegral_abs_le_unit {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y))
    (B : Q) (hBd : 0 < B.den)
    (hbd : ∀ x, Rle zero x → Rle x one → Rle (Rabs (f x)) (ofQ B hBd)) :
    Rle (Rabs (riemannIntegral hLd hLn hlip hfc)) (ofQ B hBd) := by
  have hzeroL : Qle (⟨0, 1⟩ : Q) L := by
    show (0 : Int) * (L.den : Int) ≤ L.num * 1
    rw [Int.zero_mul, Int.mul_one]; exact hLn
  have hlipB : ∀ x y, Rle (Rabs (Rsub (ofQ B hBd) (ofQ B hBd)))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) :=
    lip_weaken (by decide) hLd hzeroL (const_lip0 (ofQ B hBd))
  have hlipnB : ∀ x y, Rle (Rabs (Rsub (Rneg (ofQ B hBd)) (Rneg (ofQ B hBd))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) :=
    lip_weaken (by decide) hLd hzeroL (const_lip0 (Rneg (ofQ B hBd)))
  have hcB := riemannIntegral_const_gen (ofQ B hBd) hLd hLn hlipB (fun _ _ _ => Req_refl _)
  have hcnB := riemannIntegral_const_gen (Rneg (ofQ B hBd)) hLd hLn hlipnB (fun _ _ _ => Req_refl _)
  refine Rabs_le_of_both ?_ ?_
  · exact Rle_trans (riemannIntegral_le_unit hLd hLn hlip hfc hlipB (fun _ _ _ => Req_refl _)
      (fun x h0 h1 => Rle_of_Rabs_le (hbd x h0 h1))) (Rle_of_Req hcB)
  · have hlo : Rle (Rneg (ofQ B hBd)) (riemannIntegral hLd hLn hlip hfc) :=
      Rle_trans (Rle_of_Req (Req_symm hcnB))
        (riemannIntegral_le_unit hLd hLn hlipnB (fun _ _ _ => Req_refl _) hlip hfc
          (fun x h0 h1 => Rneg_le_of_Rabs_le (hbd x h0 h1)))
    exact Rle_trans (Rle_Rneg hlo) (Rle_of_Req (Rneg_Rneg (ofQ B hBd)))

/-- `a·(b·c) ≈ b·(a·c)` (real, left-commute). -/
private theorem Rmul_left_comm (a b c : Real) : Req (Rmul a (Rmul b c)) (Rmul b (Rmul a c)) :=
  Req_trans (Req_symm (Rmul_assoc a b c))
    (Req_trans (Rmul_congr (Rmul_comm a b) (Req_refl c)) (Rmul_assoc b a c))

/-- **The scaled-pairing bound, abstractly**, via the RAW integral (no `constTest`): for a rational
    `c ≥ 0`, if `|c·(φ·ψ)| ≤ B` on `[0,1]` then `c·|⟨φ,ψ⟩| ≤ B`. The scalar is pulled out with
    `riemannIntegral_Rsmul` at the common weakened modulus `l2L + c·l2L`; certificate independence
    realigns the integral to `⟨φ,ψ⟩`, and `riemannIntegral_abs_le_unit` closes. `ψ` stays abstract,
    so no operator test is ever unfolded. General in both slots — reused by the two-function
    reconstruction energy bound (Mellin-inversion arc, I₃). -/
theorem energy_from_pointwise (φ ψ : L2Test) (c : Q) (hcd : 0 < c.den) (hcn : 0 ≤ c.num)
    (B : Q) (hBd : 0 < B.den)
    (hpt : ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (Rmul (ofQ c hcd) (Rmul (φ.f x) (ψ.f x)))) (ofQ B hBd)) :
    Rle (Rmul (ofQ c hcd) (Rabs (innerI φ ψ))) (ofQ B hBd) := by
  have hL'd : 0 < (add (l2L φ ψ) (mul c (l2L φ ψ))).den :=
    add_den_pos (l2L_den φ ψ) (Qmul_den_pos hcd (l2L_den φ ψ))
  have hL'n : 0 ≤ (add (l2L φ ψ) (mul c (l2L φ ψ))).num :=
    Qadd_num_nonneg_loc (l2L_num φ ψ) (Int.mul_nonneg hcn (l2L_num φ ψ))
  have hlipg := lip_weaken (l2L_den φ ψ) hL'd
    (Qle_self_add (Int.mul_nonneg hcn (l2L_num φ ψ))) (l2lip φ ψ)
  have hfcg := l2fc φ ψ
  -- `c·(φ·ψ)` Lipschitz at the common modulus
  have hlipcg : ∀ x y, Rle (Rabs (Rsub (Rmul (ofQ c hcd) (Rmul (φ.f x) (ψ.f x)))
        (Rmul (ofQ c hcd) (Rmul (φ.f y) (ψ.f y)))))
      (Rmul (ofQ (add (l2L φ ψ) (mul c (l2L φ ψ))) hL'd) (Rabs (Rsub x y))) := by
    intro x y
    refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Rmul_sub_distrib (ofQ c hcd)
      (Rmul (φ.f x) (ψ.f x)) (Rmul (φ.f y) (ψ.f y)))))) ?_
    refine Rle_trans (Rle_of_Req (Rabs_Rmul (ofQ c hcd)
      (Rsub (Rmul (φ.f x) (ψ.f x)) (Rmul (φ.f y) (ψ.f y))))) ?_
    refine Rle_trans (Rle_of_Req (Rmul_congr (Rabs_ofQ_nonneg hcd hcn) (Req_refl _))) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hcd hcn) (l2lip φ ψ x y)) ?_
    refine Rle_trans (Rle_of_Req (Req_symm (Rmul_assoc (ofQ c hcd)
      (ofQ (l2L φ ψ) (l2L_den φ ψ)) (Rabs (Rsub x y))))) ?_
    refine Rmul_le_Rmul_right (Rnonneg_Rabs _) ?_
    exact Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ hcd (l2L_den φ ψ)))
      (Rle_ofQ_ofQ (Qmul_den_pos hcd (l2L_den φ ψ)) hL'd (Qle_self_add_l (l2L_num φ ψ)))
  have hfccg : ∀ x y, Req x y →
      Req (Rmul (ofQ c hcd) (Rmul (φ.f x) (ψ.f x))) (Rmul (ofQ c hcd) (Rmul (φ.f y) (ψ.f y))) :=
    fun x y h => Rmul_congr (Req_refl _) (l2fc φ ψ x y h)
  -- `c·⟨φ,ψ⟩ = ∫(c·(φ·ψ))`
  have key : Req (Rmul (ofQ c hcd) (innerI φ ψ))
      (riemannIntegral hL'd hL'n hlipcg hfccg) :=
    Req_trans (Rmul_congr (Req_refl _)
      (riemannIntegral_certif_irrel (l2L_den φ ψ) (l2L_num φ ψ) (l2lip φ ψ) (l2fc φ ψ)
        hL'd hL'n hlipg hfcg))
      (Req_symm (riemannIntegral_Rsmul (ofQ c hcd) hL'd hL'n hlipg hfcg hlipcg hfccg))
  refine Rle_trans (Rle_of_Req (Req_trans
    (Req_symm (Req_trans (Rabs_Rmul _ _) (Rmul_congr (Rabs_ofQ_nonneg hcd hcn) (Req_refl _))))
    (Rabs_congr key))) ?_
  exact riemannIntegral_abs_le_unit hL'd hL'n hlipcg hfccg B hBd hpt

set_option maxHeartbeats 1600000 in
/-- The pointwise bound, **abstract in the residual `ψ`**: given the deviation bound on `|ψ(x)|`,
    `|2δn·(φ(x)·ψ(x))| ≤ M_φ·L·(δ²+n/4)` on `[0,1]`. Abstract `ψ` means `bernOpCTest` never appears;
    it enters only when the caller sets `ψ := φ − B_nφ` and supplies the deviation via
    `bernOpCTest_pointwise_dev`. -/
private theorem bernOp_energy_pt (φ ψ : L2Test) (n : Nat) (hn : 0 < n) (δ : Q) (hδd : 0 < δ.den)
    (htwoden : 0 < (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)).den)
    (htwonum : (0 : Int) ≤ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)).num)
    (hBden : 0 < (mul (mul φ.M φ.L) (add (mul δ δ) (⟨(n : Int), 4⟩ : Q))).den)
    (x : Real) (h0 : Rle zero x) (h1 : Rle x one)
    (hdev : Rle (Rabs (ψ.f x))
      (Rmul (ofQ φ.L φ.hLd)
        (RsumN (fun k => Rmul (Rabs (Rsub (ratPt k n hn) x)) (bernR x n k)) (n + 1)))) :
    Rle (Rabs (Rmul (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) htwoden)
        (Rmul (φ.f x) (ψ.f x))))
      (ofQ (mul (mul φ.M φ.L) (add (mul δ δ) (⟨(n : Int), 4⟩ : Q))) hBden) := by
  -- `|2δn·(φ·ψ)| = 2δn·(|φ|·|ψ|)`
  refine Rle_trans (Rle_of_Req (Req_trans (Rabs_Rmul _ _)
    (Rmul_congr (Rabs_ofQ_nonneg htwoden htwonum) (Rabs_Rmul _ _)))) ?_
  -- `≤ 2δn·(M_φ·dev)`
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ htwoden htwonum)
    (Rle_trans (Rmul_le_Rmul_left (Rnonneg_Rabs _) hdev)
      (Rmul_le_Rmul_right
        (Rnonneg_Rmul (Rnonneg_ofQ φ.hLd φ.hLn)
          (Rnonneg_RsumN (n + 1) (fun k _ => Rnonneg_Rmul (Rnonneg_Rabs _)
            (bernR_nonneg x (Rnonneg_of_Rle_zero h0) (Rnonneg_Rsub_of_Rle h1) n k))))
        (φ.hbd x)))) ?_
  -- reorder `2δn·(M·(L·devsum))` to `M·(L·(2δn·devsum))`, bound `2δn·devsum ≤ δ²+n/4`
  refine Rle_trans (Rle_of_Req (Req_trans
    (Rmul_left_comm (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) htwoden)
      (ofQ φ.M φ.hMd) (Rmul (ofQ φ.L φ.hLd) _))
    (Rmul_congr (Req_refl _)
      (Rmul_left_comm (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) htwoden)
        (ofQ φ.L φ.hLd) _)))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ φ.hMd φ.hMn)
    (Rmul_le_Rmul_left (Rnonneg_ofQ φ.hLd φ.hLn)
      (bernOp_devsum_bound n hn h0 h1 δ hδd))) ?_
  have hDd : 0 < (add (mul δ δ) (⟨(n : Int), 4⟩ : Q)).den :=
    add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide)
  refine Rle_of_Req (Req_trans (Rmul_congr (Req_refl _) (Rmul_ofQ_ofQ φ.hLd hDd))
    (Req_trans (Rmul_ofQ_ofQ φ.hMd (Qmul_den_pos φ.hLd hDd)) ?_))
  exact ofQ_congr (Qmul_den_pos φ.hMd (Qmul_den_pos φ.hLd hDd)) hBden
    (by show Qeq (mul φ.M (mul φ.L (add (mul δ δ) (⟨(n : Int), 4⟩ : Q))))
          (mul (mul φ.M φ.L) (add (mul δ δ) (⟨(n : Int), 4⟩ : Q)))
        simp only [Qeq, mul]; push_cast; ring_uor)

/-- **★ THE MULTIPLIED-FORM ENERGY BOUND**: `2δn·|⟨φ, φ − B_n(φ)⟩| ≤ M_φ·L·(δ² + n/4)`, any `δ ≥ 0`.
    The residual integrand is bounded pointwise by `M_φ·(deviation)` (H₅ + `φ.hbd`, `bernOp_energy_pt`),
    and `2δn·(deviation sum) ≤ δ² + n/4` (H₆); the abstract raw-integral `energy_from_pointwise` closes
    without unfolding the operator test's certificates. -/
theorem bernOp_energy_bound (φ : L2Test) (n : Nat) (hn : 0 < n) (δ : Q) (hδd : 0 < δ.den)
    (hδn : 0 ≤ δ.num) :
    Rle (Rmul (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q))
                (Qmul_den_pos (Qmul_den_pos (by decide) hδd) Nat.one_pos))
              (Rabs (innerI φ (L2Test.sub φ (bernOpCTest φ n hn)))))
        (ofQ (mul (mul φ.M φ.L) (add (mul δ δ) (⟨(n : Int), 4⟩ : Q)))
          (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hLd)
            (add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide)))) :=
  energy_from_pointwise φ (L2Test.sub φ (bernOpCTest φ n hn))
    (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q))
    (Qmul_den_pos (Qmul_den_pos (by decide) hδd) Nat.one_pos)
    (Int.mul_nonneg (Int.mul_nonneg (by decide) hδn) (Int.ofNat_nonneg n))
    (mul (mul φ.M φ.L) (add (mul δ δ) (⟨(n : Int), 4⟩ : Q)))
    (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hLd)
      (add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide)))
    (fun x h0 h1 => bernOp_energy_pt φ (L2Test.sub φ (bernOpCTest φ n hn)) n hn δ hδd
      (Qmul_den_pos (Qmul_den_pos (by decide) hδd) Nat.one_pos)
      (Int.mul_nonneg (Int.mul_nonneg (by decide) hδn) (Int.ofNat_nonneg n))
      (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hLd)
        (add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide)))
      x h0 h1 (bernOpCTest_pointwise_dev φ n hn h0 h1))

end Multiplicity.UOR.Bridge.F1Square.Square
