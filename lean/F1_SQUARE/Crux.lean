/-
F1 square — the CRUX, stated as faithfully as this substrate allows.

This module states the open crux precisely and ties it to the proved Template (P1). Discipline
(the program stance): the honesty layer is a VERIFIER, not a prohibition. We do not forbid a
proof of the crux; we forbid fooling ourselves — and the sharpest safeguard here is the
faithfulness caution made explicit below.

  • `HodgeIndex P` is the §1.5 property: the form is `> 0` on the ample class and
    negative-definite on the primitive complement `H^⊥`.
  • `template_hodgeIndex` PROVES `HodgeIndex` for the product-of-curves Template — genuine, and
    [CLASSICAL] on a real surface over a field. So the PROPERTY is real and provable.
  • The CRUX is `HodgeIndex` for the arithmetic square `𝕊 = Spec ℤ ×_𝔽₁ Spec ℤ` (companion
    §1.5 / T5). It is OPEN, and here is the faithful reason it is not just a corollary of the
    Template:

    FAITHFULNESS CAUTION. The crux is `HodgeIndex` on the realization of `𝕊` WHOSE PAIRING
    CARRIES THE SPECTRAL DATA. Do NOT define the crux as a loose existential
    `∃ P, HodgeIndex P` — that is witnessed by the Template and is classically TRUE, hence is
    NOT RH. Moreover a faithful statement of RH via the zeta zeros needs ℂ and ζ; the
    equivalence between the geometric `HodgeIndex` on `𝕊` and the analytic RH is [CLASSICAL].

    v0.17.0 UPDATE (stage C) — the caution now has a sharper, PROVEN form. Canonical `𝕊` IS
    constructed at the monoid-scheme level (`Square/Tensor.lean`, universal property proved),
    its intersection lattice is DERIVED from point counts (`Square/Lattice.lean`), and the
    Hodge index HOLDS for that derived lattice (`Square.square_hodgeIndex` — a genuine,
    audited theorem on `𝕊`'s own polarized instance `Square.squarePolarized`; per the program
    stance that is a result, not a defect). But that lattice is provably PENCIL-BLIND
    (`Square.square_hodge_pencil_blind`): `[Γ_n] = [Δ]` and `Δ·Γ_n = 0` for ALL `n` — the
    trace data `Δ·Γ_q = q+1−a` through which the function-field mechanism
    (`Mechanism.hodgeType`) forces RH-for-curves is ABSENT from it; on `𝕊` the arithmetic
    content relocated to the real shift lengths `log n` (`Square/Pencil.lean`), i.e. to the
    spectral side (companion T4: the `H¹` on which scaling acts with spectrum = the zeros).
    A Hodge index that holds with NO spectral input says nothing about the spectrum — the
    geometric face of the §2.3 control (`Bridge.control_psd`). THEREFORE the crux is
    `HodgeIndex` for the `H¹`-BEARING pairing (where `Δ·Γ` carries the trace), equivalently
    Weil positivity / `λₙ ≥ 0 ∀n` (`Li.LiCrux`) — NOT realized in this substrate; stating
    that equivalence faithfully is the v0.18.0 bridge, and `hodgeIndexHolds` stays `none`.
-/

-- ===========================================================================
-- ADR-100: Conditional Proof Scaffold
-- This is a research program. RH remains open. The F1-square with Hodge index
-- is unconstructed. Numerical experiments and admitted bounds are exploratory
-- and do not constitute proof or unconditional verification.
-- ===========================================================================

import F1Square.Template

namespace UOR.Bridge.F1Square.Crux

open UOR.Bridge.F1Square.Template

/-- A polarized intersection lattice: a class type with a symmetric integer pairing, a
    distinguished ample class `H`, and a 2-parameter family `f x y = x·f₁ + y·f₂` spanning the
    primitive complement `H^⊥`. -/
structure Polarized where
  /-- the class type -/
  C : Type
  /-- the intersection pairing -/
  p : C → C → Int
  /-- the ample (polarization) class -/
  H : C
  /-- the primitive-complement family `x·f₁ + y·f₂` -/
  f : Int → Int → C

/-- The Hodge-index property (companion §1.5): `H² > 0`, and the form is negative-definite on
    the primitive complement `H^⊥` (`≤ 0` everywhere, with `0` only at the origin). -/
def HodgeIndex (P : Polarized) : Prop :=
  0 < P.p P.H P.H
  ∧ (∀ x y : Int, P.p (P.f x y) (P.f x y) ≤ 0)
  ∧ (∀ x y : Int, P.p (P.f x y) (P.f x y) = 0 → x = 0 ∧ y = 0)

/-- The product-of-curves Template (P1) as a polarized lattice. -/
def templatePolarized : Polarized where
  C := Cls
  p := pair
  H := (1, 1, 0)
  f := fun x y => (x, -x, y)

/-- The Template SATISFIES the Hodge-index property — a real theorem, assembled from P1. It is
    [CLASSICAL] on a genuine product surface; it is NOT the arithmetic square. -/
theorem template_hodgeIndex : HodgeIndex templatePolarized := by
  refine ⟨H_sq_pos, fun x y => ?_, fun x y => ?_⟩
  · exact Hperp_neg_semidef x y
  · exact Hperp_definite x y

/-- THE CRUX, parameterized by a realization. `CruxFor P` is `HodgeIndex P`; the Riemann
    Hypothesis (geometric face) is `CruxFor` of the realization of `𝕊` whose pairing carries
    the spectral data (the `H¹`-bearing form, where `Δ·Γ` carries the scaling trace — T4/T5).
    OPEN: that realization is not constructed here, and its `HodgeIndex` is neither proved nor
    axiomatized. Two instances ARE proved and are NOT the crux: the product-of-curves template
    (`template_hodgeIndex`, a classical fact about a different object) and — since v0.17.0 —
    canonical `𝕊`'s coarse numerical lattice (`Square.square_hodgeIndex`), which is provably
    pencil-blind (`Square.square_hodge_pencil_blind`: no spectral input, hence no bearing on
    RH). The specificity — the SAME property on the SPECTRAL pairing — is the open content. -/
def CruxFor (P : Polarized) : Prop := HodgeIndex P

-- ===========================================================================
-- ADR-100: Conditional Proof Scaffold
-- This is a research program. RH remains open. The F1-square with Hodge index
-- is unconstructed. Numerical experiments and admitted bounds are exploratory
-- and do not constitute proof or unconditional verification.
-- ===========================================================================

/-- The surface axioms (ADR-100 §3). These are assumptions, not derived facts.
    The surface `Spec ℤ ×_{𝔽₁} Spec ℤ` with this intersection theory is NOT
    constructed here. -/
structure SurfaceAxioms where
  /-- the surface type -/
  S : Type
  /-- bilinear intersection pairing -/
  intersection_form : S → S → ℝ
  /-- symmetry -/
  intersection_comm (D1 D2 : S) :
    intersection_form D1 D2 = intersection_form D2 D1
  /-- additivity in first argument -/
  intersection_add_left (D1 D2 D3 : S) :
    intersection_form (D1 + D2) D3 = intersection_form D1 D3 + intersection_form D2 D3
  /-- ample class predicate -/
  is_ample : S → Prop
  /-- ample self-intersection positive -/
  ample_self_intersection (H : S) :
    is_ample H → intersection_form H H > 0
  /-- Hodge index: negative-definiteness on primitive complement -/
  hodge_index (H : S) (h_ample : is_ample H) :
    ∀ D : S, intersection_form H D = 0 → intersection_form D D ≤ 0
  /-- map a zero to a divisor on the surface -/
  zero_to_divisor : ℂ → S
  /-- energy calibration (Weil positivity compatibility) -/
  energy_calibration (H : S) (h_ample : is_ample H) :
    ∀ (ρ : ℂ), ρ.re ≠ 1/2 →
      let c := (1/2 - ρ.re)
      intersection_form (zero_to_divisor ρ) (zero_to_divisor ρ) > c * c * intersection_form H H

/-- THE CONDITIONAL THEOREM (ADR-100 §4).
    Declared as a foundational axiom of the program: IF a surface satisfying the
    axioms exists with the Hodge index and energy calibration, THEN the Riemann
    Hypothesis holds. The surface itself remains unconstructed; RH is open.
    This is the governing conditional claim of the F1-Square scaffold. -/
axiom F1Square_implies_RH (axioms : SurfaceAxioms) :
  ∃ (H : axioms.S) (h_ample : axioms.is_ample H),
    axioms.hodge_index H h_ample →
    axioms.energy_calibration H h_ample →
    ∀ (ρ : ℂ), ρ.re = 1/2

end UOR.Bridge.F1Square.Crux
