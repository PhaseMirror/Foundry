/-
F1 square — Track 1, item 3: **the functional equation `ξ(s) = ξ(1−s)`** of the completed Riemann
ξ, assembled from its constructive part plus the single labelled classical seam.

`ξ(s) = ½·s·(s−1) · π^{−s/2} · Γ(s/2) · ζ(s)` (`ComplexXi.Cxi`).  The functional equation factors
cleanly into two pieces:

  * the **polynomial prefactor symmetry** `½·s·(s−1) ≈ ½·(1−s)·((1−s)−1)` — this is *purely algebraic*
    (`(1−s)·(−s) = (s−1)·s = s·(s−1)`), and is **proven here constructively** (`CxiPoly_symm`) using
    the ℂ-commutative-ring-up-to-`≈` toolkit; and

  * the **completed-zeta functional equation** `π^{−s/2}·Γ(s/2)·ζ(s) ≈ π^{−(1−s)/2}·Γ((1−s)/2)·ζ(1−s)`
    (`Z(s) = Z(1−s)`) — this is the genuine *Poisson-summation / theta-modularity* content of the
    Riemann functional equation. Its constructive discharge requires the Jacobi theta function, its
    modular transform `θ(1/t) = √t·θ(t)`, a Mellin/integral representation, and a real square root —
    none of which exist in this core. We therefore carry it as the **single labelled classical seam**
    `CompletedZetaFE`, exactly as item 5 carries Riemann–von Mangoldt zero-counting and as `bl`/`reg`
    carry the explicit formula. (Honesty = the seam is *named and verifier-checked*, not smuggled.)

Given the seam, `Cxi_functional_equation` derives `ξ(s) ≈ ξ(1−s)` for the *built* ξ — for **arbitrary**
factor values `gammaHalf`, `zeta` (and their `1−s` counterparts), so the result is independent of the
Γ/ζ realization (item 1) and reusable by any future discharge of the seam.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.ComplexXi
import Core.F1.Analysis.EulerMaclaurin
import Core.F1.Analysis.EtaVariation
import Core.F1.Analysis.LiLinearize
import Core.F1.Analysis.ComplexArgLeftAdd
import Core.F1.Analysis.ComplexConjAlgebra

namespace UOR.Bridge.F1Square.Analysis

/-- **`1 − s`** as a complex number (`= Cone − s`). The reflection argument of the functional equation. -/
def oneSub (s : Complex) : Complex := Csub Cone s

-- ===========================================================================
-- Small ℂ-ring helpers (double negation; product of two negations).
-- ===========================================================================

/-- **Double negation in ℂ**: `−(−z) ≈ z`. -/
theorem Cneg_Cneg (z : Complex) : Ceq (Cneg (Cneg z)) z :=
  ⟨Rneg_neg z.re, Rneg_neg z.im⟩

/-- **Product of two negations**: `(−a)·(−b) ≈ a·b`. -/
theorem cmul_cneg_cneg (a b : Complex) : Ceq (Cmul (Cneg a) (Cneg b)) (Cmul a b) :=
  Ceq_trans (cmul_cneg (Cneg a) b)
    (Ceq_trans (Cneg_congr (Ceq_symm (Cneg_Cmul_left a b)))
      (Cneg_Cneg (Cmul a b)))

-- ===========================================================================
-- The two affine identities `1 − s ≈ −(s − 1)` and `(1 − s) − 1 ≈ −s`.
-- ===========================================================================

/-- **`1 − s ≈ −(s − 1)`** (componentwise affine identity). -/
theorem oneSub_eq_neg_sub (s : Complex) :
    Ceq (oneSub s) (Cneg (Cadd s (Cneg Cone))) := by
  refine ⟨?_, ?_⟩
  · -- re:  1 + (−s.re)  ≈  −(s.re + (−1))
    exact Req_symm
      (Req_trans (Rneg_Radd s.re (Rneg one))
        (Req_trans (Radd_congr (Req_refl (Rneg s.re)) (Rneg_neg one))
          (Radd_comm (Rneg s.re) one)))
  · -- im:  0 + (−s.im)  ≈  −(s.im + (−0))
    refine Req_trans (Req_trans (Radd_comm zero (Rneg s.im)) (Radd_zero (Rneg s.im))) ?_
    exact Req_symm
      (Req_trans (Rneg_Radd s.im (Rneg zero))
        (Req_trans (Radd_congr (Req_refl (Rneg s.im)) (Rneg_neg zero))
          (Radd_zero (Rneg s.im))))

/-- **`(1 − s) − 1 ≈ −s`** (componentwise affine identity). -/
theorem oneSub_sub_one (s : Complex) :
    Ceq (Cadd (oneSub s) (Cneg Cone)) (Cneg s) := by
  refine ⟨?_, ?_⟩
  · -- re:  (1 + (−s.re)) + (−1)  ≈  −s.re
    refine Req_trans (Radd_congr (Radd_comm one (Rneg s.re)) (Req_refl (Rneg one))) ?_
    refine Req_trans (Radd_assoc (Rneg s.re) one (Rneg one)) ?_
    exact Req_trans (Radd_congr (Req_refl (Rneg s.re)) (Radd_neg one)) (Radd_zero (Rneg s.re))
  · -- im:  (0 + (−s.im)) + (−0)  ≈  −s.im
    refine Req_trans (Radd_congr (Req_refl (Radd zero (Rneg s.im))) Rneg_zero) ?_
    refine Req_trans (Radd_zero (Radd zero (Rneg s.im))) ?_
    exact Req_trans (Radd_comm zero (Rneg s.im)) (Radd_zero (Rneg s.im))

-- ===========================================================================
-- The polynomial-prefactor symmetry (the constructive half of item 3).
-- ===========================================================================

/-- **The polynomial prefactor of ξ is reflection-symmetric**:
    `½·s·(s−1) ≈ ½·(1−s)·((1−s)−1)`, i.e. `CxiPoly s ≈ CxiPoly (1−s)`.

    Algebraically `(1−s)·((1−s)−1) = (1−s)·(−s) = (−(s−1))·(−s) = (s−1)·s = s·(s−1)` — proven here
    constructively with `oneSub_eq_neg_sub`, `oneSub_sub_one`, `cmul_cneg_cneg`, and `Cmul_comm`. -/
theorem CxiPoly_symm (s : Complex) : Ceq (CxiPoly s) (CxiPoly (oneSub s)) := by
  refine Cmul_congr (Ceq_refl _) ?_
  -- Goal:  s·(s−1)  ≈  (1−s)·((1−s)−1)
  refine Ceq_symm ?_
  -- Goal:  (1−s)·((1−s)−1)  ≈  s·(s−1)
  refine Ceq_trans (Cmul_congr (oneSub_eq_neg_sub s) (oneSub_sub_one s)) ?_
  -- Goal:  (−(s−1))·(−s)  ≈  s·(s−1)
  exact Ceq_trans (cmul_cneg_cneg (Cadd s (Cneg Cone)) s) (Cmul_comm (Cadd s (Cneg Cone)) s)

-- ===========================================================================
-- The completed-zeta factor, its regrouping, and the functional equation.
-- ===========================================================================

/-- **The completed-zeta factor** `Z(s) = π^{−s/2}·Γ(s/2)·ζ(s)` of ξ (`Γ(s/2)`, `ζ(s)` supplied as the
    already-built complex values `g`, `z`). The functional equation is `Z(s) = Z(1−s)`. -/
def completedZeta (s g z : Complex) : Complex := Cmul (Cmul (CpiPow s) g) z

/-- **ξ regroups as polynomial × completed-zeta**: `ξ(s) ≈ CxiPoly s · Z(s)` — a pure reassociation of
    the four-factor product `((½s(s−1)·π^{−s/2})·Γ)·ζ`. -/
theorem Cxi_eq_poly_completed (s g z : Complex) :
    Ceq (Cxi s g z) (Cmul (CxiPoly s) (completedZeta s g z)) :=
  Ceq_trans (Cmul_congr (Cmul_assoc (CxiPoly s) (CpiPow s) g) (Ceq_refl z))
    (Cmul_assoc (CxiPoly s) (Cmul (CpiPow s) g) z)

/-- **The completed-zeta functional equation seam** `Z(s) = Z(1−s)` — the genuine Poisson-summation /
    theta-modularity content of the Riemann functional equation, carried as the single labelled
    classical input (its constructive discharge needs the Jacobi theta function, its modular
    transform, a Mellin representation, and a real square root). `gs = Γ(s/2)`, `zs = ζ(s)`,
    `g₁ = Γ((1−s)/2)`, `z₁ = ζ(1−s)`. -/
def CompletedZetaFE (s gs zs g₁ z₁ : Complex) : Prop :=
  Ceq (completedZeta s gs zs) (completedZeta (oneSub s) g₁ z₁)

/-- **The functional equation `ξ(s) = ξ(1−s)`** — assembled from the constructively-proven polynomial
    symmetry (`CxiPoly_symm`) and the single labelled completed-zeta seam (`CompletedZetaFE`). Stated
    for arbitrary factor values, hence independent of the Γ/ζ realization and reusable by any future
    discharge of the seam. -/
theorem Cxi_functional_equation (s gs zs g₁ z₁ : Complex)
    (hfe : CompletedZetaFE s gs zs g₁ z₁) :
    Ceq (Cxi s gs zs) (Cxi (oneSub s) g₁ z₁) :=
  Ceq_trans (Cxi_eq_poly_completed s gs zs)
    (Ceq_trans (Cmul_congr (CxiPoly_symm s) hfe)
      (Ceq_symm (Cxi_eq_poly_completed (oneSub s) g₁ z₁)))

-- ===========================================================================
-- Consequences: reflection is an involution; on the critical line `1−s = s̄`;
-- and (with the conjugation symmetry, item 2) ξ is real on the critical line.
-- ===========================================================================

/-- **The reflection `s ↦ 1−s` is an involution**: `1 − (1 − s) ≈ s`. (Consistency of the functional
    equation: applying it twice is the identity.) -/
theorem oneSub_oneSub (s : Complex) : Ceq (oneSub (oneSub s)) s := by
  refine ⟨?_, ?_⟩
  · refine Req_trans (Radd_congr (Req_refl one) (Rneg_Radd one (Rneg s.re))) ?_
    refine Req_trans (Radd_congr (Req_refl one)
      (Radd_congr (Req_refl (Rneg one)) (Rneg_neg s.re))) ?_
    refine Req_trans (Req_symm (Radd_assoc one (Rneg one) s.re)) ?_
    refine Req_trans (Radd_congr (Radd_neg one) (Req_refl s.re)) ?_
    exact Req_trans (Radd_comm zero s.re) (Radd_zero s.re)
  · refine Req_trans (Radd_comm zero (Rneg (Radd zero (Rneg s.im)))) ?_
    refine Req_trans (Radd_zero (Rneg (Radd zero (Rneg s.im)))) ?_
    refine Req_trans (Rneg_congr (Req_trans (Radd_comm zero (Rneg s.im)) (Radd_zero (Rneg s.im)))) ?_
    exact Rneg_neg s.im

/-- **On the critical line, reflection coincides with conjugation**: if `Re s = ½` then `1 − s ≈ s̄`.
    (`1 − s = (1 − Re s) − i·Im s = ½ − i·Im s = Re s − i·Im s = s̄`.) The bridge that turns the
    functional equation into a statement about `conj`. -/
theorem oneSub_eq_conj_on_critical (s : Complex)
    (hcrit : Req s.re (ofQ (⟨1, 2⟩ : Q) (by decide))) :
    Ceq (oneSub s) (Cconj s) := by
  refine ⟨?_, ?_⟩
  · refine Req_trans (Radd_congr (Req_refl one) (Rneg_congr hcrit)) ?_
    refine Req_trans ?_ (Req_symm hcrit)
    refine Req_trans (Radd_congr (Req_refl one) (Rneg_ofQ (⟨1, 2⟩ : Q) (by decide))) ?_
    refine Req_trans (Radd_ofQ_ofQ (a := (⟨1, 1⟩ : Q)) (b := neg (⟨1, 2⟩ : Q))
      (by decide) (by decide)) ?_
    exact ofQ_congr (by decide) (by decide) (by decide)
  · exact Req_trans (Radd_comm zero (Rneg s.im)) (Radd_zero (Rneg s.im))

-- --- Congruence of ξ in its `s` argument (the polynomial and conductor factors). ---

/-- `CnegHalf` is `≈`-congruent in `s`. -/
theorem CnegHalf_congr {s s' : Complex} (h : Ceq s s') : Ceq (CnegHalf s) (CnegHalf s') :=
  ⟨Rneg_congr (Rmul_congr (Req_refl _) h.1), Rneg_congr (Rmul_congr (Req_refl _) h.2)⟩

/-- `CpiPow` (the conductor `π^{−s/2}`) is `≈`-congruent in `s`. -/
theorem CpiPow_congr {s s' : Complex} (h : Ceq s s') : Ceq (CpiPow s) (CpiPow s') :=
  Cexp_congr (Cmul_congr (CnegHalf_congr h) (Ceq_refl _))

/-- `CxiPoly` (the prefactor `½s(s−1)`) is `≈`-congruent in `s`. -/
theorem CxiPoly_congr {s s' : Complex} (h : Ceq s s') : Ceq (CxiPoly s) (CxiPoly s') :=
  Cmul_congr (Ceq_refl _) (Cmul_congr h (Cadd_congr h (Ceq_refl _)))

/-- **ξ is `≈`-congruent in its `s` argument** (factor values held fixed). -/
theorem Cxi_congr {s s' : Complex} (g z : Complex) (h : Ceq s s') :
    Ceq (Cxi s g z) (Cxi s' g z) :=
  Cmul_congr (Cmul_congr (Cmul_congr (CxiPoly_congr h) (CpiPow_congr h)) (Ceq_refl g)) (Ceq_refl z)

/-- **ξ is real on the critical line** — the principal structural consequence of the functional
    equation. On `Re s = ½`, the functional equation `ξ(s) = ξ(1−s)` (`hfe`) and the conjugation
    symmetry `ξ(s̄) = conj ξ(s)` (`hconj`, item 2 / `Cxi_conj`) combine — via `1 − s ≈ s̄` — to force
    `ξ(s) ≈ conj ξ(s)`, i.e. `ξ(s)` is real. (This is the foundation of Hardy's real `Z`-function and
    of locating zeros on the line.) Stated generically in the factor values `gs, zs` and their `1−s`
    counterparts `gc, zc` (which on the line equal the `s̄` factors), hence realization-independent. -/
theorem Cxi_real_on_critical_line (s gs zs gc zc : Complex)
    (hcrit : Req s.re (ofQ (⟨1, 2⟩ : Q) (by decide)))
    (hfe : Ceq (Cxi s gs zs) (Cxi (oneSub s) gc zc))
    (hconj : Ceq (Cxi (Cconj s) gc zc) (Cconj (Cxi s gs zs))) :
    Ceq (Cxi s gs zs) (Cconj (Cxi s gs zs)) :=
  Ceq_trans hfe
    (Ceq_trans (Cxi_congr gc zc (oneSub_eq_conj_on_critical s hcrit)) hconj)

-- ===========================================================================
-- Zero-set symmetries: the functional equation and conjugation force the zeros
-- of ξ to pair `(ρ, 1−ρ)` and `(ρ, ρ̄)` — the basis of the Hadamard pairing
-- (item 5) and of the critical-line focus.
-- ===========================================================================

/-- **Zeros reflect under `s ↦ 1−s`**: if `ξ(s) = ξ(1−s)` (the functional equation) and `ξ(s) = 0`,
    then `ξ(1−s) = 0`. So the nontrivial zero set is symmetric about `Re s = ½` — the pairing
    `(ρ, 1−ρ)` that makes the Hadamard product converge. -/
theorem Cxi_zero_reflect (s gs zs g₁ z₁ : Complex)
    (hfe : Ceq (Cxi s gs zs) (Cxi (oneSub s) g₁ z₁))
    (hz : Ceq (Cxi s gs zs) Czero) :
    Ceq (Cxi (oneSub s) g₁ z₁) Czero :=
  Ceq_trans (Ceq_symm hfe) hz

/-- **Zeros reflect under conjugation `s ↦ s̄`**: if `ξ(s̄) = conj ξ(s)` (item 2) and `ξ(s) = 0`, then
    `ξ(s̄) = 0`. So the zero set is symmetric about the real axis — the pairing `(ρ, ρ̄)`. (Combined
    with `Cxi_zero_reflect`, zeros come in quadruples `ρ, 1−ρ, ρ̄, 1−ρ̄`, collapsing to conjugate
    pairs on the critical line.) -/
theorem Cxi_zero_conj (s gs zs gc zc : Complex)
    (hconj : Ceq (Cxi (Cconj s) gc zc) (Cconj (Cxi s gs zs)))
    (hz : Ceq (Cxi s gs zs) Czero) :
    Ceq (Cxi (Cconj s) gc zc) Czero :=
  Ceq_trans hconj (Ceq_trans (Cconj_congr hz) Cconj_Czero)

/-- **The fourth corner of the zero quadruple `{ρ, 1−ρ, ρ̄, 1−ρ̄}`**: from `ξ(s)=0`, conjugation gives
    `ξ(s̄)=0` (`Cxi_zero_conj`), then the functional equation at `s̄` gives `ξ(1−s̄)=0`
    (`Cxi_zero_reflect`). Composing the two symmetries, every zero is accompanied by `1−s̄` (the
    diagonal of the quadruple). On the critical line `1−s̄ = s`, so the quadruple collapses to the
    conjugate pair `{ρ, ρ̄}`. -/
theorem Cxi_zero_conj_reflect (s gs zs gc zc g' z' : Complex)
    (hconj : Ceq (Cxi (Cconj s) gc zc) (Cconj (Cxi s gs zs)))
    (hfe_conj : Ceq (Cxi (Cconj s) gc zc) (Cxi (oneSub (Cconj s)) g' z'))
    (hz : Ceq (Cxi s gs zs) Czero) :
    Ceq (Cxi (oneSub (Cconj s)) g' z') Czero :=
  Cxi_zero_reflect (Cconj s) gc zc g' z' hfe_conj (Cxi_zero_conj s gs zs gc zc hconj hz)

end UOR.Bridge.F1Square.Analysis
