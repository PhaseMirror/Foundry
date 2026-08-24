/-
F1 square — **the pre-Hilbert layer, brick 9** (`IntegralCSFull.lean`): **THE INTEGRAL
CAUCHY–SCHWARZ** — `⟨φ,ψ⟩² ≤ ⟨φ,φ⟩·⟨ψ,ψ⟩` for the L² pairing over the certified integral.

The ε-collapse over brick 8's two analytic inputs. With `a = ⟨φ,ψ⟩`, `b = ⟨φ,φ⟩`, `c = ⟨ψ,ψ⟩`
and `Aₖ, Bₖ, Cₖ` the level-`(k+1)` dyadic Riemann sums of the three product integrands:

    `a² − bc  =  (a² − Aₖ²) + (Aₖ² − BₖCₖ) + (BₖCₖ − bc)`

— the middle term is `≤ 0` at EVERY level (`riemannSum_cauchy_schwarz`, brick 1's discrete
sqrt-free Cauchy–Schwarz through the sampled families), and the outer two are `O(1/(k+1))`:
each factor is within `(⌈L⌉+2)/(k+1)` of its integral (`riemannIntegral_dyadic_dist`), the sums
are uniformly bounded (`riemannSum_abs_le`), and the product differences telescope
(`Rabs_prod_diff`). The one-sided ε-collapse (`Rle_of_Rsub_le_eps`) closes: `a² ≤ bc`.

No square root, no division, no completion: the discrete Lagrange SOS certificate of brick 1
carries through the dyadic limit to the genuine function-space pairing. With symmetry (brick 6)
and bilinearity (brick 7), `innerI` now satisfies ALL the inner-product laws the discrete
`innerN` does — the L² side of the step-3 layer has its Cauchy–Schwarz.

HONEST SCOPE. The pairing inequality on the bounded-Lipschitz test class; no L² completion, no
operator theory on the function space, no claim toward the `f, f̂` coupling. The crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.IntegralCS

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Helpers: the product-difference telescope, closeness bounds, ε-products.
-- ===========================================================================

/-- **The product-difference telescope**: `|xy − x'y'| ≤ |x|·|y−y'| + |x−x'|·|y'|`. -/
theorem Rabs_prod_diff (x y x' y' : Real) :
    Rle (Rabs (Rsub (Rmul x y) (Rmul x' y')))
        (Radd (Rmul (Rabs x) (Rabs (Rsub y y'))) (Rmul (Rabs (Rsub x x')) (Rabs y'))) := by
  have htel : Req (Rsub (Rmul x y) (Rmul x' y'))
      (Radd (Rmul x (Rsub y y')) (Rmul (Rsub x x') y')) :=
    Req_symm (Req_trans (Radd_congr (Rmul_sub_distrib x y y')
        (Rmul_sub_distrib_right x x' y'))
      (Rsub_split (Rmul x y) (Rmul x y') (Rmul x' y')))
  refine Rle_trans (Rle_of_Req (Rabs_congr htel)) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  exact Rle_of_Req (Radd_congr (Rabs_Rmul x (Rsub y y')) (Rabs_Rmul (Rsub x x') y'))

/-- A real close to a rationally bounded real is rationally bounded:
    `|y| ≤ p` and `|x − y| ≤ q` give `|x| ≤ p + q`. -/
theorem Rabs_le_of_close {x y : Real} {p q : Q} (hpd : 0 < p.den) (hqd : 0 < q.den)
    (hy : Rle (Rabs y) (ofQ p hpd)) (hxy : Rle (Rabs (Rsub x y)) (ofQ q hqd)) :
    Rle (Rabs x) (ofQ (add p q) (add_den_pos hpd hqd)) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Radd_Rsub_cancel x y)))) ?_
  refine Rle_trans (Rabs_Radd y (Rsub x y)) ?_
  exact Rle_trans (Radd_le_add hy hxy) (Rle_of_Req (Radd_ofQ_ofQ hpd hqd))

/-- `x ≤ y ⟹ x − y ≤ 0` (local copy; avoids importing the Gate-A chain). -/
private theorem Rsub_nonpos_of_Rle {x y : Real} (h : Rle x y) : Rle (Rsub x y) zero :=
  Rle_trans (Radd_le_add h (Rle_refl (Rneg y))) (Rle_of_Req (Radd_neg y))

/-- The ε-product collapse: `P·(t/(k+1)) ≤ (⌈P⌉·t)/(k+1)` for `P ≥ 0`. -/
theorem qmul_eps_le {P : Q} (hPd : 0 < P.den) (hPn : 0 ≤ P.num) (t k : Nat) :
    Qle (mul P (⟨(t : Int), k + 1⟩ : Q)) (⟨((P.num.toNat * t : Nat) : Int), k + 1⟩ : Q) := by
  show (P.num * (t : Int)) * ((k + 1 : Nat) : Int)
      ≤ ((P.num.toNat * t : Nat) : Int) * ((P.den * (k + 1) : Nat) : Int)
  push_cast
  rw [(Int.toNat_of_nonneg hPn).symm]
  refine Int.mul_le_mul_of_nonneg_left ?_
    (Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg t))
  have hden1 : (1 : Int) ≤ (P.den : Int) := by exact_mod_cast hPd
  have h1 : (1 : Int) * ((k : Int) + 1) ≤ (P.den : Int) * ((k : Int) + 1) :=
    Int.mul_le_mul_of_nonneg_right hden1 (by omega)
  rwa [Int.one_mul] at h1

/-- The mirrored ε-product collapse: `(t/(k+1))·P ≤ (⌈P⌉·t)/(k+1)`. -/
theorem qmul_eps_le_left {P : Q} (hPd : 0 < P.den) (hPn : 0 ≤ P.num) (t k : Nat) :
    Qle (mul (⟨(t : Int), k + 1⟩ : Q) P) (⟨((P.num.toNat * t : Nat) : Int), k + 1⟩ : Q) :=
  Qle_congr_left (Qmul_den_pos hPd (Nat.succ_pos k))
    (Qmul_comm P (⟨(t : Int), k + 1⟩ : Q)) (qmul_eps_le hPd hPn t k)

/-- The product of two tests is globally bounded by the product of the bounds. -/
theorem l2bd (φ ψ : L2Test) : ∀ x, Rle (Rabs (Rmul (φ.f x) (ψ.f x)))
    (ofQ (mul φ.M ψ.M) (Qmul_den_pos φ.hMd ψ.hMd)) := fun x =>
  Rle_trans (Rle_of_Req (Rabs_Rmul _ _))
    (Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs _) (Rnonneg_ofQ ψ.hMd ψ.hMn)
      (φ.hbd x) (ψ.hbd x))
      (Rle_of_Req (Rmul_ofQ_ofQ φ.hMd ψ.hMd)))

-- ===========================================================================
-- The integral Cauchy–Schwarz.
-- ===========================================================================

/-- **THE INTEGRAL CAUCHY–SCHWARZ**: `⟨φ,ψ⟩² ≤ ⟨φ,φ⟩·⟨ψ,ψ⟩` — the discrete Lagrange SOS
    certificate carried through the dyadic limit by the ε-collapse. Sqrt-free, division-free,
    completion-free. -/
theorem innerI_cauchy_schwarz (φ ψ : L2Test) :
    Rle (Rmul (innerI φ ψ) (innerI φ ψ)) (Rmul (innerI φ φ) (innerI ψ ψ)) := by
  -- distances of the three integrals to their level-(k+1) dyadic sums
  have hdA : ∀ k, Rle (Rabs (Rsub (innerI φ ψ)
        (dyadicR (fun x => Rmul (φ.f x) (ψ.f x)) (k + 1))))
      (ofQ (⟨(((l2L φ ψ).num.toNat + 2 : Nat) : Int), k + 1⟩ : Q) (Nat.succ_pos k)) :=
    fun k => riemannIntegral_dyadic_dist (l2L_den φ ψ) (l2L_num φ ψ)
      (l2lip φ ψ) (l2fc φ ψ) (Nat.succ_pos k)
  have hdB : ∀ k, Rle (Rabs (Rsub (innerI φ φ)
        (dyadicR (fun x => Rmul (φ.f x) (φ.f x)) (k + 1))))
      (ofQ (⟨(((l2L φ φ).num.toNat + 2 : Nat) : Int), k + 1⟩ : Q) (Nat.succ_pos k)) :=
    fun k => riemannIntegral_dyadic_dist (l2L_den φ φ) (l2L_num φ φ)
      (l2lip φ φ) (l2fc φ φ) (Nat.succ_pos k)
  have hdC : ∀ k, Rle (Rabs (Rsub (innerI ψ ψ)
        (dyadicR (fun x => Rmul (ψ.f x) (ψ.f x)) (k + 1))))
      (ofQ (⟨(((l2L ψ ψ).num.toNat + 2 : Nat) : Int), k + 1⟩ : Q) (Nat.succ_pos k)) :=
    fun k => riemannIntegral_dyadic_dist (l2L_den ψ ψ) (l2L_num ψ ψ)
      (l2lip ψ ψ) (l2fc ψ ψ) (Nat.succ_pos k)
  -- uniform bounds on the dyadic sums
  have hA : ∀ k, Rle (Rabs (dyadicR (fun x => Rmul (φ.f x) (ψ.f x)) (k + 1)))
      (ofQ (mul φ.M ψ.M) (Qmul_den_pos φ.hMd ψ.hMd)) :=
    fun k => riemannSum_abs_le (Qmul_den_pos φ.hMd ψ.hMd)
      (Int.mul_nonneg φ.hMn ψ.hMn) (l2bd φ ψ) _
  have hB : ∀ k, Rle (Rabs (dyadicR (fun x => Rmul (φ.f x) (φ.f x)) (k + 1)))
      (ofQ (mul φ.M φ.M) (Qmul_den_pos φ.hMd φ.hMd)) :=
    fun k => riemannSum_abs_le (Qmul_den_pos φ.hMd φ.hMd)
      (Int.mul_nonneg φ.hMn φ.hMn) (l2bd φ φ) _
  -- rational bounds on the integrals themselves (through the level-1 sum)
  have haBd : Rle (Rabs (innerI φ ψ))
      (ofQ (add (mul φ.M ψ.M) (⟨(((l2L φ ψ).num.toNat + 2 : Nat) : Int), 1⟩ : Q))
        (add_den_pos (Qmul_den_pos φ.hMd ψ.hMd) Nat.one_pos)) :=
    Rabs_le_of_close (Qmul_den_pos φ.hMd ψ.hMd) Nat.one_pos (hA 0) (hdA 0)
  have hcBd : Rle (Rabs (innerI ψ ψ))
      (ofQ (add (mul ψ.M ψ.M) (⟨(((l2L ψ ψ).num.toNat + 2 : Nat) : Int), 1⟩ : Q))
        (add_den_pos (Qmul_den_pos ψ.hMd ψ.hMd) Nat.one_pos)) := by
    refine Rabs_le_of_close (Qmul_den_pos ψ.hMd ψ.hMd) Nat.one_pos ?_ (hdC 0)
    exact riemannSum_abs_le (Qmul_den_pos ψ.hMd ψ.hMd)
      (Int.mul_nonneg ψ.hMn ψ.hMn) (l2bd ψ ψ) _
  -- numerator nonnegativity of the composite rationals
  have hQaN : 0 ≤ (add (mul φ.M ψ.M)
      (⟨(((l2L φ ψ).num.toNat + 2 : Nat) : Int), 1⟩ : Q)).num :=
    Qadd_num_nonneg_loc (Int.mul_nonneg φ.hMn ψ.hMn) (Int.ofNat_nonneg _)
  have hQcN : 0 ≤ (add (mul ψ.M ψ.M)
      (⟨(((l2L ψ ψ).num.toNat + 2 : Nat) : Int), 1⟩ : Q)).num :=
    Qadd_num_nonneg_loc (Int.mul_nonneg ψ.hMn ψ.hMn) (Int.ofNat_nonneg _)
  -- the ε-collapse
  refine Rle_of_Rsub_le_eps
    (C := ((add (mul φ.M ψ.M) (⟨(((l2L φ ψ).num.toNat + 2 : Nat) : Int), 1⟩ : Q)).num.toNat
            * ((l2L φ ψ).num.toNat + 2)
          + (mul φ.M ψ.M).num.toNat * ((l2L φ ψ).num.toNat + 2))
        + ((mul φ.M φ.M).num.toNat * ((l2L ψ ψ).num.toNat + 2)
          + (add (mul ψ.M ψ.M) (⟨(((l2L ψ ψ).num.toNat + 2 : Nat) : Int), 1⟩ : Q)).num.toNat
            * ((l2L φ φ).num.toNat + 2))) (fun k => ?_)
  -- split a² − bc through the level-(k+1) sums
  refine Rle_trans (Rle_of_Req (Req_symm (Req_trans (Radd_congr
    (Rsub_split (Rmul (innerI φ ψ) (innerI φ ψ))
      (Rmul (dyadicR (fun x => Rmul (φ.f x) (ψ.f x)) (k + 1))
            (dyadicR (fun x => Rmul (φ.f x) (ψ.f x)) (k + 1)))
      (Rmul (dyadicR (fun x => Rmul (φ.f x) (φ.f x)) (k + 1))
            (dyadicR (fun x => Rmul (ψ.f x) (ψ.f x)) (k + 1)))) (Req_refl _))
    (Rsub_split (Rmul (innerI φ ψ) (innerI φ ψ))
      (Rmul (dyadicR (fun x => Rmul (φ.f x) (φ.f x)) (k + 1))
            (dyadicR (fun x => Rmul (ψ.f x) (ψ.f x)) (k + 1)))
      (Rmul (innerI φ φ) (innerI ψ ψ)))))) ?_
  -- bound the three components
  have hterm1 : Rle (Rsub (Rmul (innerI φ ψ) (innerI φ ψ))
      (Rmul (dyadicR (fun x => Rmul (φ.f x) (ψ.f x)) (k + 1))
            (dyadicR (fun x => Rmul (φ.f x) (ψ.f x)) (k + 1))))
      (ofQ (⟨((((add (mul φ.M ψ.M)
            (⟨(((l2L φ ψ).num.toNat + 2 : Nat) : Int), 1⟩ : Q)).num.toNat
            * ((l2L φ ψ).num.toNat + 2)
          + (mul φ.M ψ.M).num.toNat * ((l2L φ ψ).num.toNat + 2)) : Nat) : Int), k + 1⟩ : Q)
        (Nat.succ_pos k)) := by
    refine Rle_trans (Rle_Rabs_self _) ?_
    refine Rle_trans (Rabs_prod_diff (innerI φ ψ) (innerI φ ψ)
      (dyadicR (fun x => Rmul (φ.f x) (ψ.f x)) (k + 1))
      (dyadicR (fun x => Rmul (φ.f x) (ψ.f x)) (k + 1))) ?_
    refine Rle_trans (Radd_le_add
      (Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs _)
          (Rnonneg_ofQ (Nat.succ_pos k) (Int.ofNat_nonneg _)) haBd (hdA k))
        (Rle_of_Req (Rmul_ofQ_ofQ _ _)))
      (Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs _)
          (Rnonneg_ofQ (Qmul_den_pos φ.hMd ψ.hMd) (Int.mul_nonneg φ.hMn ψ.hMn))
          (hdA k) (hA k))
        (Rle_of_Req (Rmul_ofQ_ofQ _ _)))) ?_
    refine Rle_trans (Radd_le_add
      (Rle_ofQ_ofQ _ (Nat.succ_pos k) (qmul_eps_le
        (add_den_pos (Qmul_den_pos φ.hMd ψ.hMd) Nat.one_pos) hQaN _ k))
      (Rle_ofQ_ofQ _ (Nat.succ_pos k) (qmul_eps_le_left
        (Qmul_den_pos φ.hMd ψ.hMd) (Int.mul_nonneg φ.hMn ψ.hMn) _ k))) ?_
    refine Rle_of_Req (Req_trans (Radd_ofQ_ofQ (Nat.succ_pos k) (Nat.succ_pos k)) (ofQ_congr (add_den_pos (Nat.succ_pos k) (Nat.succ_pos k)) (Nat.succ_pos k) ?_))
    simp only [Qeq, add]; push_cast; ring_uor
  have hterm2 : Rle (Rsub
      (Rmul (dyadicR (fun x => Rmul (φ.f x) (ψ.f x)) (k + 1))
            (dyadicR (fun x => Rmul (φ.f x) (ψ.f x)) (k + 1)))
      (Rmul (dyadicR (fun x => Rmul (φ.f x) (φ.f x)) (k + 1))
            (dyadicR (fun x => Rmul (ψ.f x) (ψ.f x)) (k + 1)))) zero :=
    Rsub_nonpos_of_Rle (riemannSum_cauchy_schwarz φ.f ψ.f (2 ^ (k + 1) - 1))
  have hterm3 : Rle (Rsub
      (Rmul (dyadicR (fun x => Rmul (φ.f x) (φ.f x)) (k + 1))
            (dyadicR (fun x => Rmul (ψ.f x) (ψ.f x)) (k + 1)))
      (Rmul (innerI φ φ) (innerI ψ ψ)))
      (ofQ (⟨((((mul φ.M φ.M).num.toNat * ((l2L ψ ψ).num.toNat + 2)
          + (add (mul ψ.M ψ.M)
              (⟨(((l2L ψ ψ).num.toNat + 2 : Nat) : Int), 1⟩ : Q)).num.toNat
            * ((l2L φ φ).num.toNat + 2)) : Nat) : Int), k + 1⟩ : Q)
        (Nat.succ_pos k)) := by
    refine Rle_trans (Rle_Rabs_self _) ?_
    refine Rle_trans (Rabs_prod_diff
      (dyadicR (fun x => Rmul (φ.f x) (φ.f x)) (k + 1))
      (dyadicR (fun x => Rmul (ψ.f x) (ψ.f x)) (k + 1))
      (innerI φ φ) (innerI ψ ψ)) ?_
    refine Rle_trans (Radd_le_add
      (Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs _)
          (Rnonneg_ofQ (Nat.succ_pos k) (Int.ofNat_nonneg _)) (hB k)
          (Rle_trans (Rle_of_Req (Rabs_Rsub_symm _ _)) (hdC k)))
        (Rle_of_Req (Rmul_ofQ_ofQ _ _)))
      (Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs _)
          (Rnonneg_ofQ (add_den_pos (Qmul_den_pos ψ.hMd ψ.hMd) Nat.one_pos) hQcN)
          (Rle_trans (Rle_of_Req (Rabs_Rsub_symm _ _)) (hdB k)) hcBd)
        (Rle_of_Req (Rmul_ofQ_ofQ _ _)))) ?_
    refine Rle_trans (Radd_le_add
      (Rle_ofQ_ofQ _ (Nat.succ_pos k) (qmul_eps_le
        (Qmul_den_pos φ.hMd φ.hMd) (Int.mul_nonneg φ.hMn φ.hMn) _ k))
      (Rle_ofQ_ofQ _ (Nat.succ_pos k) (qmul_eps_le_left
        (add_den_pos (Qmul_den_pos ψ.hMd ψ.hMd) Nat.one_pos) hQcN _ k))) ?_
    refine Rle_of_Req (Req_trans (Radd_ofQ_ofQ (Nat.succ_pos k) (Nat.succ_pos k)) (ofQ_congr (add_den_pos (Nat.succ_pos k) (Nat.succ_pos k)) (Nat.succ_pos k) ?_))
    simp only [Qeq, add]; push_cast; ring_uor
  -- assemble the three bounds
  refine Rle_trans (Radd_le_add (Radd_le_add hterm1 hterm2) hterm3) ?_
  refine Rle_trans (Rle_of_Req (Radd_congr (Radd_zero _) (Req_refl _))) ?_
  refine Rle_of_Req (Req_trans (Radd_ofQ_ofQ (Nat.succ_pos k) (Nat.succ_pos k)) (ofQ_congr (add_den_pos (Nat.succ_pos k) (Nat.succ_pos k)) (Nat.succ_pos k) ?_))
  simp only [Qeq, add]; push_cast; ring_uor

end Multiplicity.UOR.Bridge.F1Square.Square
