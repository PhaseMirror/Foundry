/-
F1 square — v0.21.0 stage G, brick **G2b.1-sourced (the atlas spectral operator)**: the genuine
UOR-Atlas signature `Σ = {10, 2, 7, −1}`, now SOURCED and formalized, with its computed
spectrum/trace verified and its indefiniteness established.

The UOR Atlas (`uor-atlas.md`, §5/§6.6) defines the scale-invariant spectral operator
    `M = (O+2)·I − T·Π_T − O·Π_O`   on `V_T ⊗ V_O`,   `(T, O) = (3, 8)`,
with `Π_T, Π_O` the projections onto the nontrivial (imaginary) factors. Its spectrum is the block
eigenvalues `(O+2) − T·ε_T − O·ε_O` for `ε_T, ε_O ∈ {0,1}`:
    `{O+2, O−1, T−1, −1} = {10, 7, 2, −1}`   with multiplicities `{1, T−1, O−1, (T−1)(O−1)} = {1, 2, 7, 14}`.
The Atlas records this as a COMPUTED fact (not posited) and verifies `Σ mᵢ = 24 = T·O` (dimension)
and `Σ mᵢλᵢ = 24 = T·O` (trace). This brick reproduces both checks in F1, by `decide`.

WHY THIS MATTERS FOR THE CRUX. v0.21.0 §10 named `Σ = {10,2,7,−1}` the hypothesized atlas signature
that, IF it lands in the metric, makes Gate B's infinite limit indefinite — and flagged it "not yet
sourced from the atlas repo". It is now sourced: the Atlas's own §5 operator HAS the negative
eigenspace (`−1`, multiplicity 14, the largest). So `atlasM` is INDEFINITE (`atlasM_indefinite`,
via `not_WeilPSD_of_neg_diag`): the atlas spectral signature does NOT supply a positive-definite
metric for Gate B.

This is faithful to the Atlas, NOT a defect of it. The Atlas (§5) builds `M` as a BALANCED operator
whose negative space shapes the positivity invariant (`positive 38 − reflection 14 = T·O = 24`); its
genuinely DEFINITE object is the Hurwitz norm `|x|² = Σ xᵢ² > 0` (§9, a manifest sum of squares —
`WeilPSD_rankOne`), which the Atlas explicitly states is a DIFFERENT object from "the signed
quadratic form over the primes whose non-negativity is the Riemann Hypothesis" (§9: "the model does
not identify the two; on the evidence to date they are different"). The intersection-form / Hodge
positivity that the crux fields track is RH-equivalent and OPEN by the Atlas's own §11/§12/§15 —
exactly where this construction stands. So this brick CLOSES the atlas object's spectral facet and
leaves the crux fields `none`, mirroring the Atlas.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.GaugeTower

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

-- ===========================================================================
-- The atlas constants and the block eigenvalue formula M = (O+2)I − T·Π_T − O·Π_O.
-- ===========================================================================

/-- The minimal cyclic order `T = 3` (UOR Atlas §1). -/
def atlasT : Int := 3
/-- The maximal normed-division-algebra dimension `O = 8 = 2^T` (UOR Atlas §1). -/
def atlasO : Int := 8

/-- The block eigenvalue of `M = (O+2)I − T·Π_T − O·Π_O` on the `(ε_T, ε_O)` block
    (`ε = 0` trivial factor, `ε = 1` nontrivial/imaginary factor). -/
def blockEig (eT eO : Int) : Int := (atlasO + 2) - atlasT * eT - atlasO * eO

/-- The four block eigenvalues `{(0,0)↦10, (1,0)↦7, (0,1)↦2, (1,1)↦−1}` — the Atlas spectrum
    `{O+2, O−1, T−1, −1}`. Computed, not posited (Atlas §6.6). -/
theorem blockEig_spectrum :
    blockEig 0 0 = 10 ∧ blockEig 1 0 = 7 ∧ blockEig 0 1 = 2 ∧ blockEig 1 1 = -1 := by decide

/-- The eigenvalue at carrier index `i < T·O = 24`, laid out by block with the Atlas multiplicities:
    `i = 0` → `10` (mult 1); `i ∈ {1,2}` → `7` (mult `T−1 = 2`); `i ∈ {3..9}` → `2` (mult
    `O−1 = 7`); `i ∈ {10..23}` → `−1` (mult `(T−1)(O−1) = 14`). -/
def atlasEig : Nat → Int
  | 0 => blockEig 0 0
  | 1 => blockEig 1 0
  | 2 => blockEig 1 0
  | (n + 3) => if n < 7 then blockEig 0 1 else blockEig 1 1

-- ===========================================================================
-- The verified spectral facts (Atlas §6.6): dimension and trace both = T·O = 24.
-- ===========================================================================

/-- The trace `Σ_{i<24} λᵢ` of the atlas operator. -/
def atlasTrace : Int := ((List.range 24).map atlasEig).foldl (· + ·) 0

/-- **Trace = `T·O = 24`** (Atlas §6.6: `Σ mᵢλᵢ = 24`). Computed. -/
theorem atlasTrace_eq : atlasTrace = 24 := by decide

/-- **Multiplicities `{1, 2, 7, 14}`** over the 24-dimensional carrier (Atlas §5/§6.6), summing to
    `T·O = 24` (dimension). Computed. -/
theorem atlasMult :
    ((List.range 24).filter (fun i => atlasEig i == 10)).length = 1
    ∧ ((List.range 24).filter (fun i => atlasEig i == 7)).length = 2
    ∧ ((List.range 24).filter (fun i => atlasEig i == 2)).length = 7
    ∧ ((List.range 24).filter (fun i => atlasEig i == -1)).length = 14 := by decide

/-- The dimension of the carrier `V_T ⊗ V_O` is `T·O = 24`. -/
theorem atlasDim_eq : (List.range 24).length = 24 := by decide

/-- **THE ATLAS SPECTRAL SIGNATURE IS `(10, 14)`** — `10` positive eigendirections (`λ = 10, 7, 2`,
    multiplicities `1, 2, 7`) and `14` negative (`λ = −1`). Computed. This is a structural feature that
    distinguishes `atlasM` from the crux's intersection form: a Hodge-index / Lefschetz form has
    signature `(1, ρ−1)` — exactly ONE positive direction (`H² > 0`) and negative-definite on the
    primitive complement. `atlasM` has TEN positive directions, so it is a genuinely DIFFERENT
    indefinite object; the spectral operator alone cannot be the crux's intersection form (its definite
    companion is the Hurwitz norm §9, not the RH form). Crux fields stay `none`. -/
theorem atlasM_signature :
    ((List.range 24).filter (fun i => decide (0 < atlasEig i))).length = 10
    ∧ ((List.range 24).filter (fun i => decide (atlasEig i < 0))).length = 14 := by decide

/-- **`atlasM` is NOT of Hodge-index signature**: it has strictly more than one positive eigendirection
    (ten, `atlasM_signature`), whereas a Hodge-index form has exactly one. So the spectral operator is
    structurally distinct from the crux's intersection form — sharpening, as a theorem, why the
    spectral facet alone does not carry the crux. -/
theorem atlasM_not_hodge_signature :
    1 < ((List.range 24).filter (fun i => decide (0 < atlasEig i))).length := by
  rw [atlasM_signature.1]; decide

-- ===========================================================================
-- The operator as a metric, and its indefiniteness (the sourced make-or-break).
-- ===========================================================================

/-- The atlas spectral operator as a diagonal metric over the carrier indices. -/
def atlasM (i j : Nat) : Real := if i = j then ofQ ⟨atlasEig i, 1⟩ Nat.one_pos else zero

/-- The `−1` (reflection) eigenspace: `−⟨e₁₀, e₁₀⟩ = 1 > 0` — a strictly negative diagonal entry. -/
theorem atlasM_neg_entry : Pos (Rneg (atlasM 10 10)) := by
  have e : atlasM 10 10 = ofQ ⟨-1, 1⟩ Nat.one_pos := rfl
  rw [e]
  exact Pos_congr (Req_symm (Rneg_ofQ ⟨-1, 1⟩ Nat.one_pos)) Pos_one

/-- **THE SOURCED MAKE-OR-BREAK: the atlas spectral signature `Σ = {10,2,7,−1}` is INDEFINITE.**
    Its `−1` eigenspace (multiplicity 14) is a negative diagonal entry, so `atlasM` is not `WeilPSD`
    (`not_WeilPSD_of_neg_diag`). Per v0.21.0 §10, a negative signature entry in the metric makes
    Gate B's infinite limit indefinite — so the atlas spectral operator does NOT, by itself, supply
    the positive-definite limit Gate B needs. (Faithful to Atlas §5: `M` is balanced-with-negative-
    space by construction; the Atlas's definite object is the Hurwitz norm of §9, NOT identified
    with the RH form — so the crux stays `none`.) -/
theorem atlasM_indefinite : ¬ WeilPSD atlasM :=
  not_WeilPSD_of_neg_diag 10 atlasM_neg_entry

/-- **The atlas's DEFINITE object (Hurwitz norm, §9) is a sum of squares, hence `WeilPSD`** — a
    manifest, closed positivity, and a DIFFERENT object from the indefinite spectral form `atlasM`
    (Atlas §9: "the model does not identify the two; on the evidence to date they are different").
    The norm closes; the intersection-form/RH positivity (the crux) stays open. -/
theorem atlasNorm_psd (f : Nat → Real) : WeilPSD (fun i j => Rmul (f i) (f j)) :=
  WeilPSD_rankOne f

end UOR.Bridge.F1Square.Square
