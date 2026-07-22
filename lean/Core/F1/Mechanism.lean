/-
F1 square — the genuine-proof layer.

This module is the REAL Lean proof layer for the program (companion docs
`f1_square_intersection_theory.md`, `missing_object_over_Q.md`,
`characteristic_1_constructions.md`). Unlike `F1Square.lean` — which records the
construction's *epistemic status* as UOR ontology data (`universallyValid : Option Bool`) —
this module states load-bearing claims as honest Lean `theorem`s with real proofs.

Discipline (matching the UOR Lean corpus, verified zero-`sorry`):
  * NO `sorry`, NO `axiom`, NO `native_decide`, NO `partial def`.
  * For now, only [VERIFIED] / [CLASSICAL] boundary/shadow facts are proved here.
  * NO ARBITRARY CEILING on the crux. The Hodge index theorem for `Spec ℤ ×_𝔽₁ Spec ℤ`
    IS the Riemann Hypothesis. We do NOT forbid proving it: if a genuine, axiom-clean proof of
    a FAITHFUL statement ever lands and survives the audit, that is a result, and the manifest
    status flips `none → some true` because that is then the truth. What is forbidden is
    *fooling ourselves* — hidden `sorry`/`axiom`/`native_decide`, circular or vacuous positivity
    (the §2.3 control discipline), and mislabeling a finite SHADOW as the crux. In this pure
    (no-Mathlib) setting we cannot yet even *state* RH faithfully (no ℂ, no ζ), so every theorem
    here is a boundary/shadow fact, labeled as such — not the summit mistaken for the climb.
-/

namespace UOR.Bridge.F1Square.Mechanism

/-! ## 1. The Hodge-index signature governor — the function-field mechanism, integer core

On the Néron–Severi lattice `{F_h, F_v, Δ, Γ_q}` of `C × C` with `Δ·Γ_q = q + 1 − a`
(companion §0.3 / §9.1), the intersection form is of Hodge type `(1, ρ−1)` exactly when the
arithmetic 2-plane's Gram determinant is sign-correct, which reduces to the sign of `4q − a²`.
The analytic-looking Hasse bound `|a| ≤ 2√q` is, over `ℤ`, the square-root-free integer
condition `a² ≤ 4q`. This is the *verified boundary mechanism* — it forces RH-for-curves on a
genuine surface — and is emphatically NOT the crux (which is the same positivity on the
*unbuilt* `𝔽₁` square). -/

/-- The signature governor `4q − a²`. Its sign decides the Hodge type. -/
def governor (q a : Int) : Int := 4 * q - a * a

/-- Hodge-type signature `(1, ρ−1)` holds iff the governor is non-negative. -/
def hodgeType (q a : Int) : Prop := 0 ≤ governor q a

instance instDecidableHodgeType (q a : Int) : Decidable (hodgeType q a) := by
  unfold hodgeType; infer_instance

/-- The signature flips *exactly* at the Hasse bound: Hodge type `⟺ a² ≤ 4q` — the
    square-root-free form of `|a| ≤ 2√q`, with no real square root needed. -/
theorem hodgeType_iff (q a : Int) : hodgeType q a ↔ a * a ≤ 4 * q :=
  Iff.intro (fun h => by unfold hodgeType governor at h; omega)
    (fun h => by unfold hodgeType governor; omega)

/-- Verified case (companion §9.1), `q = 25`, `a = 10 = 2√25`: Hodge type HOLDS. -/
theorem hasse_q25_a10 : hodgeType 25 10 := by decide

/-- Verified case, `q = 25`, `a = 12 > 2√25`: Hodge type VIOLATED — the flip is exact. -/
theorem hasse_q25_a12 : ¬ hodgeType 25 12 := by decide

/-- Verified case (companion §9.1), `q = 4`, `a = 4 = 2√4`: Hodge type HOLDS. -/
theorem hasse_q4_a4 : hodgeType 4 4 := by decide

/-- Verified case, `q = 4`, `a = 5 > 2√4`: Hodge type VIOLATED. -/
theorem hasse_q4_a5 : ¬ hodgeType 4 5 := by decide

/-- Verified case (companion §9.1), `q = 9`, `a = 6 = 2√9`: Hodge type HOLDS. -/
theorem hasse_q9_a6 : hodgeType 9 6 := by decide

/-- Verified case, `q = 9`, `a = 7 > 2√9`: Hodge type VIOLATED. -/
theorem hasse_q9_a7 : ¬ hodgeType 9 7 := by decide

/-! ## 2. Tropical intersection-positivity — companion R13 / §8.4

The stable-intersection multiplicity of two tropical curve-edges with primitive directions
`u, v` and lattice weights `mu, mv` is `mu · mv · |det(u, v)|` — a non-negative integer by
construction. This positivity is *free* in characteristic 1; its `ℤ`-analogue on the square is
exactly the open crux. Proving the shadow is honest precisely because it is only the shadow. -/

/-- Tropical stable-intersection multiplicity `mu · mv · |det(u, v)|`. -/
def tropMult (mu mv : Nat) (u v : Int × Int) : Nat :=
  mu * mv * (u.1 * v.2 - u.2 * v.1).natAbs

/-- Tropical intersection-positivity is automatic — the characteristic-1 shadow of the
    open surface-positivity that is RH. -/
theorem tropMult_nonneg (mu mv : Nat) (u v : Int × Int) : 0 ≤ tropMult mu mv u v :=
  Nat.zero_le _

/-- Tropical Bézout: line ∩ line `= 1`. -/
theorem bezout_line_line : tropMult 1 1 (1, 0) (0, 1) = 1 := by decide

/-- Tropical Bézout: line ∩ conic `= 2` (a weight-2 edge). -/
theorem bezout_line_conic : tropMult 1 2 (1, 0) (0, 1) = 2 := by decide

end UOR.Bridge.F1Square.Mechanism
