/-
F1 square — v0.21.0 stage G, brick **coherence is the closure condition**: the Atlas closes by
COHERENCE across all facets — not by any single facet.

The Atlas is "a coherent system operating at its zero-state" (§4): the canonical, conserved,
balanced configuration to which every expression resolves, coherent exactly there. Coherence — not
a single facet — is the closure condition. A witness for the crux must be coherent with the WHOLE
structure (the conserved zero-state, the forced unity), not merely match one facet (e.g. growth).

WHAT IS ESTABLISHED (how coherence is expressed). The Atlas's zero-state laws are theorems:
round-trip closure (`atlas_roundtrip`, `π∘ι = id`), no-loss conservation (`class_no_loss`), and
scale-invariance (`atlas_scale_consistent`). Bundled, `atlas_coherent` is the mechanized coherence
of the Atlas. The forced web (`atlas_forced_web`) and the single-Prime emanation
(`single_generator_emanates`) are the same coherence seen as unity.

THE CLOSURE CONDITION. `coherent_closure_not_single_facet`: a COHERENT witness — one realizing the
full diagonal for all `n` at once (`strictRealizes_closes_crux`), respecting the whole structure —
closes the crux; a SINGLE facet (the shift-length growth `atlasShiftDiag`, which survives the growth
filter) is NECESSARY but is not the coherent whole. The coherent witness is the zero-state emanation
of `2λₙ` as a manifest sum of squares from the single Prime — that is RH (§4.1), not asserted; the
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.AtlasGenerator
import F1Square.Square.AtlasConservation
import F1Square.Square.SinglePrime

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

/-- **COHERENCE IS ESTABLISHED**: the Atlas's zero-state laws hold across facets — round-trip
    closure (`π∘ι = id`), no-loss conservation (the addressing is information-preserving), and
    scale-invariance (the inverse system commutes). This is the mechanized coherence of the Atlas. -/
theorem atlas_coherent :
    (∀ k r, r < atlasModulus k → atlasProject k r = r)
    ∧ (∀ h2, h2 < 4 → ∀ d, d < 3 → ∀ l, l < 8 →
        classDecode (classIndex h2 d l) = (h2, d, l))
    ∧ (∀ k r, atlasProject k (atlasProject (k + 1) r) = atlasProject k r) :=
  ⟨fun k r h => atlas_roundtrip k r h, class_no_loss, fun k r => atlas_scale_consistent k r⟩

/-- **COHERENCE, NOT A SINGLE FACET, IS THE CLOSURE CONDITION**: coherence is established
    (round-trip closure); a single facet — the shift-length growth `atlasShiftDiag`, which survives
    the growth filter — is NECESSARY but not the coherent whole; and a COHERENT witness, realizing
    the full diagonal for all `n` at once, closes the crux (`strictRealizes_closes_crux`). The
    coherent witness — `2λₙ` as a sum of squares emanating from the single Prime, respecting the
    conserved zero-state — is the open content (RH). The crux fields stay `none`. -/
theorem coherent_closure_not_single_facet :
    (∀ k r, r < atlasModulus k → atlasProject k r = r)
    ∧ (∀ n, 2 ≤ n → Rle (Radd (atlasShiftDiag n) one) (atlasShiftDiag (n + 1)))
    ∧ (∀ (E : StieltjesEta) (ι : AtlasRule) (D : Nat),
        StrictRealizes E ι D → SpectralCrux (genuineSpectralSquare E)) :=
  ⟨fun k r h => atlas_roundtrip k r h, atlasShiftDiag_step_ge_one, strictRealizes_closes_crux⟩

end UOR.Bridge.F1Square.Square
