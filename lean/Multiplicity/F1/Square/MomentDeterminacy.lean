/-
F1 square — **GENERAL MOMENT DETERMINACY** (`MomentDeterminacy.lean`), the Bernstein arc, sub-brick H₈
— the capstone. A bounded-Lipschitz test whose *every* integer moment vanishes is the zero function on
`[0,1]`:

    (∀ n, ⟨φ, xⁿ⟩ ≈ 0)  ⟹  ⟨φ,φ⟩ ≈ 0        (`moment_determinacy`)
                          ⟹  ∀ x ∈ [0,1], φ(x) ≈ 0   (`moment_determinacy_unit`).

This closes the general-determinacy question the polynomial-class result (brick 64) left open. The
energy `⟨φ,φ⟩` equals the pairing with the Bernstein residual (H₅), which the multiplied-form energy
bound (H₇) controls: `2δn·⟨φ,φ⟩ ≤ M_φ·L·(δ²+n/4)` for every `δ ≥ 0`. Under the schedule `δ = k+1`,
`n = (k+1)²`, dividing by `2δn = 2(k+1)³` gives `⟨φ,φ⟩ ≤ 5·M_φ·L / (8(k+1))`, i.e.
`≤ (5·M_φ.num·L.num)/(k+1)`; the real squeeze (`Req_of_Rle_ofQ_all`) forces `⟨φ,φ⟩ ≈ 0` (it is `≥ 0` by
`innerI_self_nonneg`), and brick 79 (`innerI_self_zero_imp_zero`) lifts that to the pointwise statement.

WHY (the Sonine route, step 3, the Mellin FRONT). This is the determinacy half of the transform pair on
the *general* bounded-Lipschitz class — the input the moment problem / Mellin inversion needs beyond the
polynomial class. A genuine constructive Weierstrass/Bernstein theorem: no `sqrt`, no case split,
choice-free.

HONEST SCOPE. General moment determinacy on `[0,1]`. NOT Mellin inversion, NOT the transform pair's
surjectivity, NOT positivity. Step 4 (the band-coupling positivity) is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.BernsteinEnergyBound

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `Req (Rsub a b) zero → Req a b` (local copy of `ZeroGeometry`'s additive helper). -/
private theorem Req_of_Rsub_zero {a b : Real} (h : Req (Rsub a b) zero) : Req a b := by
  have h1 : Req a (Radd (Rsub a b) b) := by
    show Req a (Radd (Radd a (Rneg b)) b)
    refine Req_trans (Req_symm (Radd_zero a)) ?_
    have hz : Req zero (Radd (Rneg b) b) :=
      Req_symm (Req_trans (Radd_comm (Rneg b) b) (Radd_neg b))
    exact Req_trans (Radd_congr (Req_refl a) hz) (Req_symm (Radd_assoc a (Rneg b) b))
  exact Req_trans h1 (Req_trans (Radd_congr h (Req_refl b)) (Req_trans (Radd_comm zero b) (Radd_zero b)))

/-- **Divide a weighted bound by the (positive) weight**: from `c·x ≤ B` with `c.num = R > 0`,
    `x ≤ (1/c)·B`. Multiply by the reciprocal `⟨c.den, R⟩`, whose product with `c` is `1`. General
    division lemma — reused by the reconstruction convergence of the Mellin-inversion arc (I₃b). -/
theorem Rle_of_Rmul_ofQ_le (R : Nat) (hR : 0 < R) {c : Q} (hcd : 0 < c.den)
    (hcnum : c.num = (R : Int)) {x : Real} {B : Q} (hBd : 0 < B.den)
    (h : Rle (Rmul (ofQ c hcd) x) (ofQ B hBd)) :
    Rle x (ofQ (mul (⟨(c.den : Int), R⟩ : Q) B) (Qmul_den_pos hR hBd)) := by
  have hone : Req x (Rmul (ofQ (⟨(c.den : Int), R⟩ : Q) hR) (Rmul (ofQ c hcd) x)) := by
    refine Req_trans (Req_symm (Rone_mul x)) (Req_trans (Rmul_congr ?_ (Req_refl x))
      (Rmul_assoc (ofQ (⟨(c.den : Int), R⟩ : Q) hR) (ofQ c hcd) x))
    refine Req_trans ?_ (Req_symm (Rmul_ofQ_ofQ hR hcd))
    refine Req_of_seq_Qeq (fun _ => ?_)
    show Qeq (⟨1, 1⟩ : Q) (mul (⟨(c.den : Int), R⟩ : Q) c)
    simp only [Qeq, mul]; rw [hcnum]; push_cast; ring_uor
  refine Rle_trans (Rle_of_Req hone)
    (Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hR (Int.ofNat_nonneg c.den)) h)
      (Rle_of_Req (Rmul_ofQ_ofQ hR hBd)))

/-- **★ GENERAL MOMENT DETERMINACY (energy form)**: if every moment of `φ` vanishes then `⟨φ,φ⟩ ≈ 0`.
    The Bernstein residual energy bound at the schedule `δ = k+1`, `n = (k+1)²` decays like `1/(k+1)`
    and the real squeeze closes. -/
theorem moment_determinacy (φ : L2Test) (hmom : ∀ i, Req (mellinMoment φ i) zero) :
    Req (innerI φ φ) zero := by
  have hself := innerI_self_nonneg φ
  have hMN : (0 : Int) ≤ φ.M.num * φ.L.num := Int.mul_nonneg φ.hMn φ.hLn
  refine Req_of_Rle_ofQ_all (C := (5 * (φ.M.num * φ.L.num)).toNat) (fun k => ?_) (fun k => ?_)
  · -- `⟨φ,φ⟩ − 0 ≤ (5·M.num·L.num)/(k+1)`
    refine Rle_trans (Rle_of_Req (Rsub_zero (innerI φ φ))) ?_
    have hn : 0 < (k + 1) * (k + 1) := Nat.mul_pos (Nat.succ_pos k) (Nat.succ_pos k)
    have hδd : 0 < (⟨((k + 1 : Nat) : Int), 1⟩ : Q).den := Nat.one_pos
    have hδn : 0 ≤ (⟨((k + 1 : Nat) : Int), 1⟩ : Q).num := Int.ofNat_nonneg _
    have hEB := bernOp_energy_bound φ ((k + 1) * (k + 1)) hn (⟨((k + 1 : Nat) : Int), 1⟩ : Q) hδd hδn
    have hRabs : Req (Rabs (innerI φ (L2Test.sub φ (bernOpCTest φ ((k + 1) * (k + 1)) hn))))
        (innerI φ φ) :=
      Req_trans (Rabs_congr (Req_symm (innerI_self_eq_sub φ hmom ((k + 1) * (k + 1)) hn)))
        (Rabs_of_nonneg hself)
    have hEB2 := Rle_trans (Rle_of_Req (Rmul_congr (Req_refl
      (ofQ (mul (mul (⟨2, 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
              (⟨(((k + 1) * (k + 1) : Nat) : Int), 1⟩ : Q))
            (Qmul_den_pos (Qmul_den_pos (by decide) hδd) Nat.one_pos))) (Req_symm hRabs))) hEB
    -- reciprocal weight `R = 2(k+1)³` as a `Nat`
    have hcnum : (mul (mul (⟨2, 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
        (⟨(((k + 1) * (k + 1) : Nat) : Int), 1⟩ : Q)).num
        = ((2 * (k + 1) * ((k + 1) * (k + 1)) : Nat) : Int) := by
      show (2 * ((k + 1 : Nat) : Int)) * (((k + 1) * (k + 1) : Nat) : Int)
          = ((2 * (k + 1) * ((k + 1) * (k + 1)) : Nat) : Int)
      push_cast; ring_uor
    have hR : 0 < 2 * (k + 1) * ((k + 1) * (k + 1)) :=
      Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos k)) hn
    refine Rle_trans (Rle_of_Rmul_ofQ_le (2 * (k + 1) * ((k + 1) * (k + 1))) hR _ hcnum _ hEB2) ?_
    refine Rle_ofQ_ofQ _ (Nat.succ_pos k) ?_
    have hC : ((5 * (φ.M.num * φ.L.num)).toNat : Int) = 5 * (φ.M.num * φ.L.num) :=
      Int.toNat_of_nonneg (by omega)
    have hMD : (1 : Int) ≤ (φ.M.den : Int) * (φ.L.den : Int) := by
      have : 1 ≤ φ.M.den * φ.L.den := Nat.mul_le_mul φ.hMd φ.hLd
      exact_mod_cast this
    have hK : (0 : Int) ≤ (k : Int) + 1 := by omega
    show Qle (mul (⟨(1 : Int), 2 * (k + 1) * ((k + 1) * (k + 1))⟩ : Q)
                (mul (mul φ.M φ.L) (add (mul (⟨((k + 1 : Nat) : Int), 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
                  (⟨(((k + 1) * (k + 1) : Nat) : Int), 4⟩ : Q))))
             (⟨((5 * (φ.M.num * φ.L.num)).toNat : Int), k + 1⟩ : Q)
    simp only [Qle, mul, add]
    rw [hC]; push_cast
    -- `i − h = 5·(M.num·L.num)·(k+1)³·(8·M.den·L.den − 1) ≥ 0`
    have hfac :
        5 * (φ.M.num * φ.L.num) * (2 * ((k : Int) + 1) * (((k : Int) + 1) * ((k : Int) + 1))
            * ((φ.M.den : Int) * (φ.L.den : Int) * 4))
          - 1 * (φ.M.num * φ.L.num * (((k : Int) + 1) * ((k : Int) + 1) * 4
              + ((k : Int) + 1) * ((k : Int) + 1) * 1)) * ((k : Int) + 1)
        = 5 * (φ.M.num * φ.L.num) * (((k : Int) + 1) * ((k : Int) + 1) * ((k : Int) + 1))
            * (8 * ((φ.M.den : Int) * (φ.L.den : Int)) - 1) := by ring_uor
    have hnn : (0 : Int) ≤ 5 * (φ.M.num * φ.L.num)
        * (((k : Int) + 1) * ((k : Int) + 1) * ((k : Int) + 1))
        * (8 * ((φ.M.den : Int) * (φ.L.den : Int)) - 1) :=
      Int.mul_nonneg (Int.mul_nonneg (by omega) (Int.mul_nonneg (Int.mul_nonneg hK hK) hK)) (by omega)
    omega
  · -- neg side: `0 − ⟨φ,φ⟩ ≤ (C)/(k+1)`, automatic since `⟨φ,φ⟩ ≥ 0`
    refine Rle_trans (Rle_of_Req (Req_trans (Radd_comm zero (Rneg (innerI φ φ)))
      (Radd_zero (Rneg (innerI φ φ))))) ?_
    exact Rle_trans (Rle_trans (Rle_Rneg (Rle_zero_of_Rnonneg hself)) (Rle_of_Req Rneg_zero))
      (Rle_zero_of_Rnonneg (Rnonneg_ofQ (Nat.succ_pos k) (Int.ofNat_nonneg _)))

/-- **★ GENERAL MOMENT DETERMINACY (function form)**: a bounded-Lipschitz test whose every moment
    vanishes is the zero function on `[0,1]` — brick 79 applied to `moment_determinacy`. -/
theorem moment_determinacy_unit (φ : L2Test) (hmom : ∀ i, Req (mellinMoment φ i) zero)
    (x : Real) (h0 : Rle zero x) (h1 : Rle x one) :
    Req (φ.f x) zero :=
  innerI_self_zero_imp_zero φ (moment_determinacy φ hmom) x h0 h1

/-- **★ THE MOMENT MAP IS INJECTIVE ON THE GENERAL CLASS**: two bounded-Lipschitz tests with the same
    integer moment sequence agree at every point of `[0,1]` — the transform pair's injectivity half on
    the *general* class, `moment_determinacy_unit` applied to `φ − ψ` (whose moments are the differences,
    all zero by `innerI_sub_left`). -/
theorem moment_injective_unit (φ ψ : L2Test)
    (hmom : ∀ n, Req (mellinMoment φ n) (mellinMoment ψ n))
    (x : Real) (h0 : Rle zero x) (h1 : Rle x one) :
    Req (φ.f x) (ψ.f x) :=
  Req_of_Rsub_zero (moment_determinacy_unit (L2Test.sub φ ψ)
    (fun n => Req_trans (innerI_sub_left φ ψ (powTest n))
      (Req_trans (Rsub_congr (hmom n) (Req_refl _)) (Radd_neg (mellinMoment ψ n)))) x h0 h1)

end Multiplicity.UOR.Bridge.F1Square.Square
