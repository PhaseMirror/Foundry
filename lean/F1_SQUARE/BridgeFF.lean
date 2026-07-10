/- ===========================================================================
   ADR-100: Conditional Proof Scaffold
   This is a research program. RH remains open. The F1-square with Hodge index
   is unconstructed. Numerical experiments and admitted bounds are exploratory
   and do not constitute proof or unconditional verification.
   ===========================================================================
   F1 square — v0.18.0 stage D, brick 1: the CASTELNUOVO–SEVERI BRIDGE at the lattice level —
the function-field model of "Hodge index ⟹ RH" as a genuine derivation, not governor
arithmetic.

Companion §0.3 / §9.1 / ROADMAP stage D. Weil's proof of RH-for-curves runs the Hodge index
property on the Néron–Severi lattice of `C × C` against the graph of Frobenius. This module
mechanizes that run COMPLETELY for the template case (`E × E`, genus 1 — the §2.2 sourced
lattice extended by the Frobenius graph):

  • The lattice: classes `h·F_h + v·F_v + d·Δ + g·Γ` with the standard sourced/derived
    intersection numbers over `𝔽_q` — `F_h² = F_v² = 0`, `F_h·F_v = 1`, `Δ·F = Γ·F_h = 1`,
    `Γ·F_v = q` (Frobenius has bidegree `(1, q)`), `Δ² = Γ² = 0` (genus 1, adjunction), and
    the TRACE DATUM `Δ·Γ = q + 1 − a` (the Lefschetz fixed-point count `#E(𝔽_q)`).
  • The primitive projection: for `D = x·Δ + y·Γ`, the class
    `D° = D − (D·F_v)·F_h − (D·F_h)·F_v` is orthogonal to both rulings
    (`primDG_perp_h/v`) — the projection to the primitive complement of the ample cone.
  • THE COMPUTATION (`primDG_sq`): `D°² = −2·(x² + a·xy + q·y²)` — the Hodge-index
    quadratic form IS the binary quadratic form `x² + axy + qy²` of discriminant `a² − 4q`.
  • THE BRIDGE (`ff_hodge_iff_hasse`): negativity of `D°²` for ALL `x, y`
    ⟺ `a² ≤ 4q` — Hodge-index negativity on the primitive `{Δ, Γ}`-span is EXACTLY the
    Hasse bound (`4(x² + axy + qy²) = (2x + ay)² + (4q − a²)y²`), i.e. RH for the curve.
    Tied to the v0.1.0 governor (`ff_hodge_iff_hodgeType`): `Mechanism.hodgeType` is now a
    DERIVED consequence of lattice positivity, closing the §0.3 statement "the mechanism is
    not the gap" as a theorem.

WHY THIS IS STAGE-D SUBSTRATE: the v0.18.0 bridge states `HodgeIndex(spectral 𝕊) ⟺ Li
positivity`. Its classical anchor is precisely this function-field model — where the trace
datum `Δ·Γ = q+1−a` sits INSIDE the lattice and positivity forces the spectral bound. On
canonical `𝕊` the coarse lattice is pencil-blind (`Square.square_hodge_pencil_blind`,
`Δ·Γ_n = 0`): the trace datum is what the spectral (`H¹`-bearing) enrichment must carry, and
THIS module is the exact shape of what carrying it buys. RH itself stays OPEN.

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Mechanism
import F1Square.Template
import F1Square.Analysis.RingTac

namespace UOR.Bridge.F1Square.BridgeFF

/-- A divisor class on the function-field square `E × E` in the basis
    `{F_h, F_v, Δ, Γ}` (horizontal/vertical rulings, diagonal, Frobenius graph). -/
abbrev FFCls : Type := Int × Int × Int × Int

/-- The intersection pairing of `E × E` over `𝔽_q` with Frobenius trace `a`, by bilinear
    expansion of the standard Gram matrix
    `[[0,1,1,1],[1,0,1,q],[1,1,0,q+1−a],[1,q,q+1−a,0]]`
    on `{F_h, F_v, Δ, Γ}` (sourced/derived: rulings as in §2.2; `Γ·F_v = deg Fr = q`;
    `Δ² = Γ² = 0` by genus-1 adjunction; `Δ·Γ = #Fix(Fr) = q+1−a` by Lefschetz). -/
def ffPair (q a : Int) (u v : FFCls) : Int :=
  u.1 * (v.2.1 + v.2.2.1 + v.2.2.2)
    + u.2.1 * (v.1 + v.2.2.1 + q * v.2.2.2)
    + u.2.2.1 * (v.1 + v.2.1 + (q + 1 - a) * v.2.2.2)
    + u.2.2.2 * (v.1 + q * v.2.1 + (q + 1 - a) * v.2.2.1)

/-- The pairing is symmetric (the Gram matrix is). -/
theorem ffPair_symm (q a : Int) (u v : FFCls) : ffPair q a u v = ffPair q a v u := by
  obtain ⟨u1, u2, u3, u4⟩ := u
  obtain ⟨v1, v2, v3, v4⟩ := v
  simp only [ffPair]
  push_cast
  ring_uor

/-- The Frobenius bidegree, read off the pairing: `Γ·F_h = 1` and `Γ·F_v = q`
    (the graph covers the first factor once and the second `q = deg Fr` times). -/
theorem ff_gamma_bidegree (q a : Int) :
    ffPair q a (0, 0, 0, 1) (1, 0, 0, 0) = 1
    ∧ ffPair q a (0, 0, 0, 1) (0, 1, 0, 0) = q := by
  constructor <;> (simp only [ffPair]; push_cast; ring_uor)

/-- The trace datum sits inside the lattice: `Δ·Γ = q + 1 − a` — the Lefschetz fixed-point
    count of Frobenius, the input the Hasse mechanism runs on. (Contrast canonical `𝕊`,
    whose coarse lattice has `Δ·Γ_n = 0` — `Square.square_hodge_pencil_blind`.) -/
theorem ff_trace_datum (q a : Int) :
    ffPair q a (0, 0, 1, 0) (0, 0, 0, 1) = q + 1 - a := by
  simp only [ffPair]
  push_cast
  ring_uor

/-- The PRIMITIVE PROJECTION of `D = x·Δ + y·Γ`:
    `D° = D − (D·F_v)·F_h − (D·F_h)·F_v` with `D·F_h = x + y`, `D·F_v = x + q·y` —
    coordinates `(−(x + q·y), −(x + y), x, y)`. -/
def primDG (q x y : Int) : FFCls := (-(x + q * y), -(x + y), x, y)

/-- `D°` is orthogonal to the horizontal ruling. -/
theorem primDG_perp_h (q a x y : Int) :
    ffPair q a (primDG q x y) (1, 0, 0, 0) = 0 := by
  simp only [ffPair, primDG]
  push_cast
  ring_uor

/-- `D°` is orthogonal to the vertical ruling — with `primDG_perp_h`, `D°` lies in the
    primitive complement of the ample cone (the span of the rulings). -/
theorem primDG_perp_v (q a x y : Int) :
    ffPair q a (primDG q x y) (0, 1, 0, 0) = 0 := by
  simp only [ffPair, primDG]
  push_cast
  ring_uor

private theorem primDG_sq_int (q a x y : Int) :
    (-(x + q * y)) * (-(x + y) + x + y)
        + (-(x + y)) * (-(x + q * y) + x + q * y)
        + x * (-(x + q * y) + -(x + y) + (q + 1 - a) * y)
        + y * (-(x + q * y) + q * (-(x + y)) + (q + 1 - a) * x)
      = -2 * (x * x + a * (x * y) + q * (y * y)) := by
  ring_uor

/-- **THE HODGE-INDEX FORM IS THE HASSE FORM**: the primitive part of `x·Δ + y·Γ` has
    self-intersection `D°² = −2·(x² + a·xy + q·y²)` — the binary quadratic form of
    discriminant `a² − 4q`, derived from the lattice (not assumed). -/
theorem primDG_sq (q a x y : Int) :
    ffPair q a (primDG q x y) (primDG q x y)
      = -2 * (x * x + a * (x * y) + q * (y * y)) := by
  simp only [ffPair, primDG]
  exact primDG_sq_int q a x y

private theorem hasse_form_identity (a q x y : Int) :
    4 * (x * x + a * (x * y) + q * (y * y))
      = (2 * x + a * y) * (2 * x + a * y) + (4 * q - a * a) * (y * y) := by
  ring_uor

/-- **THE CASTELNUOVO–SEVERI BRIDGE** (the function-field model of stage D, complete):
    Hodge-index negativity on the primitive `{Δ, Γ}`-span — `D°² ≤ 0` for ALL integer
    combinations — holds **iff** `a² ≤ 4q`, the Hasse/Weil bound (= RH for the curve).
    Forward: instantiate at `(x, y) = (a, −2)`, where `x² + axy + qy² = 4q − a²`.
    Backward: `4(x² + axy + qy²) = (2x + ay)² + (4q − a²)·y² ≥ 0`. This derives the
    spectral bound FROM lattice positivity — the actual mechanism of Weil's proof, no
    governor shortcut. -/
theorem ff_hodge_iff_hasse (q a : Int) :
    (∀ x y : Int, ffPair q a (primDG q x y) (primDG q x y) ≤ 0) ↔ a * a ≤ 4 * q := by
  constructor
  · intro h
    have h2 := h a (-2)
    rw [primDG_sq] at h2
    have hsq : a * a + a * (a * (-2)) + q * ((-2) * (-2)) = 4 * q - a * a := by ring_uor
    rw [hsq] at h2
    omega
  · intro h x y
    rw [primDG_sq]
    have hid := hasse_form_identity a q x y
    have h1 : 0 ≤ (2 * x + a * y) * (2 * x + a * y) := Template.sq_nonneg (2 * x + a * y)
    have h2 : 0 ≤ y * y := Template.sq_nonneg y
    have h3 : 0 ≤ (4 * q - a * a) * (y * y) :=
      Int.mul_nonneg (by omega) h2
    omega

/-- The bridge, tied to the v0.1.0 governor: lattice Hodge-index negativity on the
    primitive `{Δ, Γ}`-span ⟺ `Mechanism.hodgeType q a`. The governor criterion is now a
    DERIVED consequence of intersection positivity — "the mechanism is not the gap" (§0.3)
    is a theorem. -/
theorem ff_hodge_iff_hodgeType (q a : Int) :
    (∀ x y : Int, ffPair q a (primDG q x y) (primDG q x y) ≤ 0)
      ↔ Mechanism.hodgeType q a := by
  rw [ff_hodge_iff_hasse, Mechanism.hodgeType_iff]

/-- Boundary instance `q = 25`, `a = 10 = 2√q`: the full lattice negativity HOLDS
    (via the bridge — an `∀ x y : Int` statement no `decide` could reach directly). -/
theorem ff_hasse_q25_a10 :
    ∀ x y : Int, ffPair 25 10 (primDG 25 x y) (primDG 25 x y) ≤ 0 :=
  (ff_hodge_iff_hasse 25 10).mpr (by decide)

/-- Violation instance `q = 25`, `a = 12 > 2√q`: the lattice negativity FAILS — the flip
    is exactly at the Hasse bound. -/
theorem ff_hasse_q25_a12_fails :
    ¬ ∀ x y : Int, ffPair 25 12 (primDG 25 x y) (primDG 25 x y) ≤ 0 := by
  intro h
  have := (ff_hodge_iff_hasse 25 12).mp h
  omega

end UOR.Bridge.F1Square.BridgeFF
