/-
F1 square — v0.21.0 stage G, brick **G0b (the full primitive form)**: the symmetric bilinear
form `⟨Cₙ,Cₘ⟩` on the Frobenius carrier, extending `SpectralSquare`'s diagonal-only data with
the off-diagonal.

ROADMAP §7 (the second prerequisite) and §8 (Stage G0b). The crux is a fact about the WHOLE
primitive form, not its diagonal (§4, "the form is not its diagonal"): negative-semidefiniteness
— the property that forces every diagonal `⟨Cₙ,Cₙ⟩ ≤ 0` — is a property of the full Gram. The
rank-4 lattice (`WeilLattice.lean`) cannot carry the off-diagonal: it is **pencil-blind**
(`square_hodge_pencil_blind`: `[Γₙ] = [Δ]`, `Δ·Γₙ = 0` for all `n`), so `⟨Cₙ,Cₘ⟩` for `n ≠ m`
has no home there. The free Frobenius system `H1 = (ℕ, succ, 0)` (`Cohomology.lean`) does carry
it: its orbit classes `orbit n = n` are **distinct** (`orbit_distinct`), and `orbit_shiftLength`
gives the separation `k·log p`.

WHAT IS BUILT.
- `FullForm S`: a symmetric kernel `B : ℕ → ℕ → Real` on the orbit indices whose DIAGONAL is the
  genuine spectral diagonal `S.cSq`. On the genuine square `FullForm.diag_genuine` forces
  `B n n ≈ −2λₙ` (reusing the derived dictionary `genuine_vanCyc_normal` / `vanCyc_selfpair`).
- The off-diagonal HAS A HOME on the carrier (`orbit_distinct`), refuting the falsifier "the
  carrier cannot hold the off-diagonal": the structure is inhabited by `diagOnlyForm` (trivial
  off-diagonal) and by `shiftFullForm` (a NON-trivial symmetric off-diagonal `shiftLen n +
  shiftLen m` built from the explicit-formula log weight `logN` — atlas-intrinsic, zero-free, no
  reference to `λ`, the §6 no-smuggling rule). The GENUINE off-diagonal is the analytic Weil
  cross-pairing `W(gₙ ⋆ ǧₘ)` (`Pairing.lean`), interface-level.
- **The bridge to Stage S** (`negPSD_to_hodgeNeg`): if the NEGATIVE of the full form `−B` is
  `WeilPSD` (the genuine, full-Gram condition — §4's embedding into the negative of a
  positive-definite space), then every `−⟨Cₙ,Cₙ⟩ ≥ 0`, i.e. `SpectralHodgeNeg S`. The hypothesis
  is RH-equivalent on the genuine square (it is exactly Weil positivity); it is NOT asserted.

HONEST SCOPE. Nothing here asserts the genuine full form is negative-semidefinite (that is RH).
This brick supplies the OBJECT — the full primitive form on a carrier that can hold it — and the
exact bridge that a definiteness proof would travel. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.WeilPSD
import F1Square.Square.Cohomology

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

-- ===========================================================================
-- The off-diagonal has a home: distinct orbit classes on the Frobenius carrier.
-- ===========================================================================

/-- **The off-diagonal has a home on the carrier**: distinct orbit indices give DISTINCT
    Frobenius classes (`H1.orbit n = n` is injective) — unlike the rank-4 lattice, which is
    pencil-blind (`square_hodge_pencil_blind`: `[Γₙ] = [Δ]` for all `n`). So `⟨Cₙ,Cₘ⟩`, `n ≠ m`,
    lives on `H1`. -/
theorem orbit_distinct {n m : Nat} (h : n ≠ m) : H1.orbit n ≠ H1.orbit m := by
  rw [H1_orbit, H1_orbit]; exact h

-- ===========================================================================
-- The full primitive form.
-- ===========================================================================

/-- **THE FULL PRIMITIVE FORM** on the Frobenius carrier `H1` (= ℕ, orbit `n ↔ Cₙ`): a symmetric
    bilinear kernel `B` on the orbit indices whose DIAGONAL is the genuine spectral diagonal
    `S.cSq`. It extends `SpectralSquare` (diagonal only) with the off-diagonal `⟨Cₙ,Cₘ⟩`. -/
structure FullForm (S : SpectralSquare) where
  /-- the Gram kernel `⟨Cₙ,Cₘ⟩` on the orbit indices -/
  B : Nat → Nat → Real
  /-- the form is symmetric -/
  symm : ∀ n m, Req (B n m) (B m n)
  /-- its diagonal is the spectral square's diagonal `⟨Cₙ,Cₙ⟩` -/
  diag : ∀ n, 0 < n → Req (B n n) (S.cSq n)

namespace FullForm

variable {S : SpectralSquare}

/-- On the GENUINE square the diagonal is FORCED to `−2λₙ` (the `vanCyc_selfpair` lineage,
    through `genuine_vanCyc_normal`). -/
theorem diag_genuine (E : StieltjesEta) (F : FullForm (genuineSpectralSquare E))
    (n : Nat) (hn : 0 < n) :
    Req (F.B n n) (Rneg (Radd (genuineLamSeq E.eta n) (genuineLamSeq E.eta n))) := by
  refine Req_trans (F.diag n hn) ?_
  exact Req_trans (Req_symm (Rneg_neg ((genuineSpectralSquare E).cSq n)))
    (Rneg_congr (genuine_vanCyc_normal E n))

/-- The NEGATIVE of the full form — the PSD target (§4: the embedding lands in the *negative* of
    a positive-definite space). -/
def neg (F : FullForm S) : Nat → Nat → Real := fun n m => Rneg (F.B n m)

/-- **THE BRIDGE TO STAGE S** (§4, the full-Gram `⟹`): if the negative `−B` of the full primitive
    form is `WeilPSD` (negative-semidefiniteness of the WHOLE form — not just its diagonal), then
    every `−⟨Cₙ,Cₙ⟩ ≥ 0`, i.e. `SpectralHodgeNeg S`. On the genuine square the hypothesis is
    exactly Weil positivity = RH; it is NOT asserted here. -/
theorem negPSD_to_hodgeNeg (F : FullForm S) (h : WeilPSD F.neg) : SpectralHodgeNeg S := by
  intro n hn
  exact Rnonneg_congr (Rneg_congr (F.diag n hn)) (WeilPSD_diag h n)

end FullForm

-- ===========================================================================
-- Inhabitants: the carrier holds a full form (falsifier refuted).
-- ===========================================================================

/-- The **diagonal-only** full form (off-diagonal zero): the carrier holds A full form, refuting
    "the carrier cannot hold the off-diagonal". The off-diagonal is trivial here. -/
def diagOnlyForm (S : SpectralSquare) : FullForm S where
  B := fun n m => if n = m then S.cSq n else zero
  symm := by
    intro n m
    show Req (if n = m then S.cSq n else zero) (if m = n then S.cSq m else zero)
    by_cases h : n = m
    · subst h; exact Req_refl _
    · rw [if_neg h, if_neg (fun he => h he.symm)]; exact Req_refl _
  diag := by
    intro n _
    show Req (if n = n then S.cSq n else zero) (S.cSq n)
    rw [if_pos rfl]
    exact Req_refl _

/-- Per-orbit-index shift length `logN(k+2)` — the explicit-formula weight at the orbit position
    (the pencil shift length, `Cohomology.orbitShift`). Atlas-intrinsic, zero-free. -/
def shiftLen (k : Nat) : Real := logN (k + 2) (by omega)

/-- A **non-trivial symmetric shift-length off-diagonal** `shiftLen n + shiftLen m`: built from
    the explicit-formula log weights only (no zeros, no `λ` — the §6 no-smuggling rule),
    manifestly symmetric. -/
def shiftOffDiag (n m : Nat) : Real := Radd (shiftLen n) (shiftLen m)

theorem shiftOffDiag_symm (n m : Nat) : Req (shiftOffDiag n m) (shiftOffDiag m n) :=
  Radd_comm (shiftLen n) (shiftLen m)

/-- A full form with a **non-trivial** symmetric atlas-intrinsic off-diagonal: the carrier holds
    a genuine off-diagonal (not merely zero). Its diagonal is still the spectral `S.cSq`; nothing
    is claimed about its definiteness. -/
def shiftFullForm (S : SpectralSquare) : FullForm S where
  B := fun n m => if n = m then S.cSq n else shiftOffDiag n m
  symm := by
    intro n m
    show Req (if n = m then S.cSq n else shiftOffDiag n m)
      (if m = n then S.cSq m else shiftOffDiag m n)
    by_cases h : n = m
    · subst h; exact Req_refl _
    · rw [if_neg h, if_neg (fun he => h he.symm)]; exact shiftOffDiag_symm n m
  diag := by
    intro n _
    show Req (if n = n then S.cSq n else shiftOffDiag n n) (S.cSq n)
    rw [if_pos rfl]
    exact Req_refl _

end UOR.Bridge.F1Square.Square
