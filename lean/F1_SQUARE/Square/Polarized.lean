/-
F1 square — v0.17.0 stage C, brick 6: the POLARIZED canonical square — the ample class,
the Hodge index ON THE DERIVED LATTICE, and the precise reason this is NOT the crux.

Companion §1.4 / §1.5 / §2.3-control / T5. This brick lifts the three template fields to
canonical `𝕊` (the ROADMAP stage-C de-hedge): the `Crux.Polarized` instance is now `𝕊`'s
own derived lattice (`squarePolarized`), not the product-of-curves analogy —

  • AMPLE CLASS on `𝕊` (§1.4): `H = [V] + [H]` has `H² = 2 > 0` (`sq_ample_pos`) and meets
    the distinguished effective classes positively (`sq_ample_meets`, Nakai-style). Per the
    tropical literature's caution (§2.2: `H² > 0` is NOT automatic on a tropical surface),
    this is a genuine verification on the constructed object, not an assumption.

  • HODGE INDEX of the derived lattice: `H^⊥ = span{V−H, E₃}` carries `diag(−2,−2)` —
    negative-definite (`sq_hperp_neg_semidef`, `sq_hperp_definite`); with `sq_ample_pos`,
    signature `(1, 2)`: `square_hodgeIndex : Crux.HodgeIndex squarePolarized`.

  • ⚠ THE FAITHFULNESS BOUNDARY (read before citing `square_hodgeIndex`): this Hodge index
    is a theorem about the COARSE NUMERICAL LATTICE of `𝕊`, and that lattice is
    PENCIL-BLIND — `[Γ_n] = [Δ]` and `Δ·Γ_n = 0` for ALL `n`
    (`square_hodge_pencil_blind`). The function-field mechanism forces RH-for-curves
    through the trace data `Δ·Γ_q = q + 1 − a` (`Mechanism.hodgeType`); on `𝕊` that data
    is NOT in the integer lattice — it relocated to the real shift lengths `log n`
    (`Square/Pencil.lean`), i.e. to the spectral side (T4: the `H¹` on which scaling acts
    with spectrum = the zeta zeros). A positivity that holds with NO spectral input says
    nothing about the spectrum — the same §2.3 control that exposed the naive shift-length
    Gram as vacuous (`Bridge.control_psd`). THE CRUX (T5 = RH) is the Hodge
    index / Weil positivity of the `H¹`-bearing pairing, equivalently `λₙ ≥ 0 ∀n`
    (`Li.LiCrux`); it is OPEN, `hodgeIndexHolds = none` stays, and `square_hodgeIndex`
    must never be mistaken for it. The v0.18.0 bridge states the equivalence faithfully.

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Square.Lattice
import F1Square.Crux

namespace UOR.Bridge.F1Square.Square

/-- The ample class of `𝕊`: `[V] + [H]` (coordinates `(1,1,0)`). -/
def clsAmple : SqCls := (1, 1, 0)

/-- The ample class is the sum of the two ruling classes (its construction, not its
    coordinates, is the datum). -/
theorem clsAmple_eq : clsAmple = addC clsV clsH := by decide

/-- AMPLE on `𝕊` (§1.4): `H² = 2 > 0` — the projectivity/Kähler precondition, verified on
    the derived form (NOT automatic for a tropical surface, §2.2 caution). -/
theorem sq_ample_pos : 0 < sqPair clsAmple clsAmple := by decide

/-- The ample class meets the distinguished effective classes positively (Nakai-style):
    `H·V = H·H = 1`, `H·Δ = H·Γ_n = 2`. -/
theorem sq_ample_meets (n : Nat) :
    sqPair clsAmple clsV = 1 ∧ sqPair clsAmple clsH = 1
    ∧ sqPair clsAmple clsDiag = 2 ∧ sqPair clsAmple (clsGraph n) = 2 :=
  ⟨by decide, by decide, by decide, rfl⟩

/-- The primitive complement `H^⊥` of the derived lattice is spanned by
    `f₁ = V − H = (1,−1,0)` and `f₂ = E₃`: both are orthogonal to `H`. -/
theorem sq_hperp_span :
    sqPair clsAmple (1, -1, 0) = 0 ∧ sqPair clsAmple clsE3 = 0 :=
  ⟨by decide, by decide⟩

/-- The general `H^⊥` vector `x·f₁ + y·f₂ = (x, −x, y)` has self-intersection
    `−2x² − 2y²` on the derived form (derived, not assumed). -/
theorem sq_hperp_value (x y : Int) :
    sqPair (x, -x, y) (x, -x, y) = -2 * (x * x) - 2 * (y * y) :=
  Template.Hperp_value x y

/-- The derived form is negative-SEMIdefinite on `H^⊥`. -/
theorem sq_hperp_neg_semidef (x y : Int) : sqPair (x, -x, y) (x, -x, y) ≤ 0 :=
  Template.Hperp_neg_semidef x y

/-- Nondegeneracy on `H^⊥`: the only null vector is `0` — with `sq_hperp_neg_semidef`,
    NEGATIVE-DEFINITENESS on the primitive complement of `𝕊`'s derived lattice. -/
theorem sq_hperp_definite (x y : Int) :
    sqPair (x, -x, y) (x, -x, y) = 0 → x = 0 ∧ y = 0 :=
  Template.Hperp_definite x y

/-- CANONICAL `𝕊` AS A POLARIZED LATTICE — the `Crux.Polarized` instance is now the
    constructed square's own derived intersection lattice (the stage-C lift: the realization
    the crux is stated against is `𝕊`, no longer the product-of-curves template). -/
def squarePolarized : Crux.Polarized where
  C := SqCls
  p := sqPair
  H := clsAmple
  f := fun x y => (x, -x, y)

/-- **THE HODGE INDEX OF THE DERIVED LATTICE** (signature `(1,2)`): `H² > 0` and the form
    is negative-definite on `H^⊥`. Proven — and PENCIL-BLIND (see the module docstring and
    `square_hodge_pencil_blind`): this is the Hodge index of the coarse numerical lattice,
    NOT the crux. The crux (T5 = RH) is the same property for the `H¹`-bearing spectral
    pairing, which this lattice provably does not carry. -/
theorem square_hodgeIndex : Crux.HodgeIndex squarePolarized :=
  ⟨sq_ample_pos, sq_hperp_neg_semidef, sq_hperp_definite⟩

/-- **THE HONESTY PACKAGE** — the Hodge index of `𝕊`'s derived lattice holds AND the
    lattice is pencil-blind: `Δ·Γ_n = 0` and `[Γ_n] = [Δ]` for every `n`. The two facts
    together are the precise statement that `square_hodgeIndex` carries no spectral
    content (the trace `a` of `Mechanism.hodgeType` never enters), hence bears nothing on
    RH — the geometric counterpart of the §2.3 control `Bridge.control_psd`. The crux
    fields stay `none`. -/
theorem square_hodge_pencil_blind :
    Crux.HodgeIndex squarePolarized
    ∧ (∀ n : Nat, sqPair clsDiag (clsGraph n) = 0)
    ∧ (∀ n : Nat, clsGraph n = clsDiag) :=
  ⟨square_hodgeIndex, fun _ => rfl, fun _ => rfl⟩

end UOR.Bridge.F1Square.Square
