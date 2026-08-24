/-
F1 square — **the pre-Hilbert layer, brick 7** (`IntegralBilinear.lean`): **bilinearity of the L²
pairing** — the bounded-Lipschitz test class is closed under addition, and the pairing is additive
in each slot.

`L2Test.add` bundles the pointwise sum with the summed certificates (`L = L_φ + L_ψ`,
`M = M_φ + M_ψ`, via the existing `Radd_lipschitz_real` and the triangle). Then, with
`lip_weaken` (a Lipschitz certificate at `L` is one at any `L' ≥ L`), all three integrands of a
sum are certified at the COMMON modulus `l2L φ ψ + l2L φ' ψ`, where `riemannIntegral_add`
applies; certificate independence (brick 6) moves each end back to its canonical certificate:

    `⟨φ + φ', ψ⟩ ≈ ⟨φ,ψ⟩ + ⟨φ',ψ⟩`    (`innerI_add_left`; right slot by symmetry).

With brick 6's `innerI_symm`, the L² pairing is now a genuine symmetric additive pairing on the
test class — the function-space mirror of the discrete `innerN` laws of brick 1.

HONEST SCOPE. Additivity and symmetry of the pairing on the bounded-Lipschitz class; no scalar
action is packaged yet, no completion, no Cauchy–Schwarz for integrals (banked next: the
uniform-weight Riemann-sum route through brick 1's `cauchy_schwarz`). The crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.IntegralCertIrrel

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **Certificate weakening**: a Lipschitz certificate at modulus `L` is a certificate at any
    larger modulus `L'`. -/
theorem lip_weaken {f : Real → Real} {L L' : Q} (hLd : 0 < L.den) (hL'd : 0 < L'.den)
    (h : Qle L L')
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y)))) :
    ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L' hL'd) (Rabs (Rsub x y))) :=
  lip_q_of_lip_real hL'd (Rle_ofQ_ofQ hLd hL'd h) hlip

/-- `x ≤ p + x` for `p` with nonnegative numerator (the left-slot mirror of `Qle_self_add`). -/
theorem Qle_self_add_l {x p : Q} (hp : 0 ≤ p.num) : Qle x (add p x) := by
  show x.num * ((p.den * x.den : Nat) : Int) ≤ (p.num * x.den + x.num * p.den) * (x.den : Int)
  push_cast
  have e1 : x.num * ((p.den : Int) * (x.den : Int))
      = x.num * (p.den : Int) * (x.den : Int) := by ring_uor
  have e2 : (p.num * (x.den : Int) + x.num * (p.den : Int)) * (x.den : Int)
      = p.num * (x.den : Int) * (x.den : Int) + x.num * (p.den : Int) * (x.den : Int) := by
    ring_uor
  rw [e1, e2]
  refine Int.le_add_of_nonneg_left ?_
  exact Int.mul_nonneg (Int.mul_nonneg hp (Int.ofNat_nonneg _)) (Int.ofNat_nonneg _)

/-- **The test class is closed under addition**: the pointwise sum with the summed certificates
    (`L = L_φ + L_ψ`, `M = M_φ + M_ψ`). -/
def L2Test.add (φ ψ : L2Test) : L2Test where
  f := fun x => Radd (φ.f x) (ψ.f x)
  L := UOR.Bridge.F1Square.Analysis.add φ.L ψ.L
  M := UOR.Bridge.F1Square.Analysis.add φ.M ψ.M
  hLd := add_den_pos φ.hLd ψ.hLd
  hLn := Qadd_num_nonneg_loc φ.hLn ψ.hLn
  hMd := add_den_pos φ.hMd ψ.hMd
  hMn := Qadd_num_nonneg_loc φ.hMn ψ.hMn
  hlip := fun x y =>
    Rle_trans (Radd_lipschitz_real φ.hlip ψ.hlip x y)
      (Rmul_le_Rmul_right (Rnonneg_Rabs _) (Rle_of_Req (Radd_ofQ_ofQ φ.hLd ψ.hLd)))
  hfc := fun x y h => Radd_congr (φ.hfc x y h) (ψ.hfc x y h)
  hbd := fun x =>
    Rle_trans (Rabs_Radd _ _)
      (Rle_trans (Radd_le_add (φ.hbd x) (ψ.hbd x))
        (Rle_of_Req (Radd_ofQ_ofQ φ.hMd ψ.hMd)))

/-- **ADDITIVITY OF THE L² PAIRING IN THE FIRST SLOT**: `⟨φ + φ', ψ⟩ ≈ ⟨φ,ψ⟩ + ⟨φ',ψ⟩`. All
    three product integrands are certified at the common weakened modulus
    `l2L φ ψ + l2L φ' ψ`, where the integral is additive; certificate independence moves each
    end back to its canonical certificate. -/
theorem innerI_add_left (φ φ' ψ : L2Test) :
    Req (innerI (L2Test.add φ φ') ψ) (Radd (innerI φ ψ) (innerI φ' ψ)) := by
  -- the common modulus and the weakened certificates
  have hLcd : 0 < (add (l2L φ ψ) (l2L φ' ψ)).den :=
    add_den_pos (l2L_den φ ψ) (l2L_den φ' ψ)
  have hLcn : 0 ≤ (add (l2L φ ψ) (l2L φ' ψ)).num :=
    Qadd_num_nonneg_loc (l2L_num φ ψ) (l2L_num φ' ψ)
  have hlip1 := lip_weaken (l2L_den φ ψ) hLcd (Qle_self_add (l2L_num φ' ψ)) (l2lip φ ψ)
  have hlip2 := lip_weaken (l2L_den φ' ψ) hLcd (Qle_self_add_l (l2L_num φ ψ)) (l2lip φ' ψ)
  -- the summed integrand's certificate at the common modulus
  have hlipS : ∀ x y, Rle (Rabs (Rsub
        (Radd (Rmul (φ.f x) (ψ.f x)) (Rmul (φ'.f x) (ψ.f x)))
        (Radd (Rmul (φ.f y) (ψ.f y)) (Rmul (φ'.f y) (ψ.f y)))))
      (Rmul (ofQ (add (l2L φ ψ) (l2L φ' ψ)) hLcd) (Rabs (Rsub x y))) := fun x y =>
    Rle_trans (Radd_lipschitz_real (l2lip φ ψ) (l2lip φ' ψ) x y)
      (Rmul_le_Rmul_right (Rnonneg_Rabs _)
        (Rle_of_Req (Radd_ofQ_ofQ (l2L_den φ ψ) (l2L_den φ' ψ))))
  have hfcS : ∀ x y, Req x y → Req
      (Radd (Rmul (φ.f x) (ψ.f x)) (Rmul (φ'.f x) (ψ.f x)))
      (Radd (Rmul (φ.f y) (ψ.f y)) (Rmul (φ'.f y) (ψ.f y))) := fun x y h =>
    Radd_congr (l2fc φ ψ x y h) (l2fc φ' ψ x y h)
  -- the distributed integrand: ((φ+φ')·ψ) x ≈ (φψ + φ'ψ) x pointwise
  have hdist : ∀ x, Req (Rmul (Radd (φ.f x) (φ'.f x)) (ψ.f x))
      (Radd (Rmul (φ.f x) (ψ.f x)) (Rmul (φ'.f x) (ψ.f x))) :=
    fun x => Rmul_distrib_right (φ.f x) (φ'.f x) (ψ.f x)
  -- the product integrand of the sum test, certified at the common modulus (transported)
  have hlipP : ∀ x y, Rle (Rabs (Rsub
        (Rmul (Radd (φ.f x) (φ'.f x)) (ψ.f x)) (Rmul (Radd (φ.f y) (φ'.f y)) (ψ.f y))))
      (Rmul (ofQ (add (l2L φ ψ) (l2L φ' ψ)) hLcd) (Rabs (Rsub x y))) := fun x y =>
    Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (hdist x) (hdist y)))) (hlipS x y)
  have hfcP := l2fc (L2Test.add φ φ') ψ
  -- assemble
  refine Req_trans (riemannIntegral_certif_irrel (l2L_den (L2Test.add φ φ') ψ)
    (l2L_num (L2Test.add φ φ') ψ) (l2lip (L2Test.add φ φ') ψ) (l2fc (L2Test.add φ φ') ψ)
    hLcd hLcn hlipP hfcP) ?_
  refine Req_trans (riemannIntegral_congr hLcd hLcn hlipP hfcP hlipS hfcS hdist) ?_
  refine Req_trans (riemannIntegral_add hLcd hLcn hlip1 (l2fc φ ψ) hlip2 (l2fc φ' ψ)
    hlipS hfcS) ?_
  exact Radd_congr
    (riemannIntegral_certif_irrel hLcd hLcn hlip1 (l2fc φ ψ)
      (l2L_den φ ψ) (l2L_num φ ψ) (l2lip φ ψ) (l2fc φ ψ))
    (riemannIntegral_certif_irrel hLcd hLcn hlip2 (l2fc φ' ψ)
      (l2L_den φ' ψ) (l2L_num φ' ψ) (l2lip φ' ψ) (l2fc φ' ψ))

/-- **Additivity in the second slot**, by symmetry: `⟨φ, ψ + ψ'⟩ ≈ ⟨φ,ψ⟩ + ⟨φ,ψ'⟩`. -/
theorem innerI_add_right (φ ψ ψ' : L2Test) :
    Req (innerI φ (L2Test.add ψ ψ')) (Radd (innerI φ ψ) (innerI φ ψ')) :=
  Req_trans (innerI_symm φ (L2Test.add ψ ψ'))
    (Req_trans (innerI_add_left ψ ψ' φ)
      (Radd_congr (innerI_symm ψ φ) (innerI_symm ψ' φ)))

end Multiplicity.UOR.Bridge.F1Square.Analysis
