/-
F1 square — v0.21.0 stage G, brick **gate sanity**: the crux gate is a genuine *discriminating*
verifier, not a vacuous "always-fail".

A faithfulness gate is only honest if it WORKS in both directions: it must accept a genuine positive
instance and reject a genuine negative one. A gate hardwired to reject everything would fail a true
proof too — it would not be a verifier at all. This brick certifies, from already-proven theorems,
that both gates of the v0.21.0 construction discriminate, and that the crux is REACHABLE (closes on a
genuine witness). So the genuine crux fields stay `none` because their specific witness is unmet —
NOT because the gate arbitrarily fails.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.StageG
import F1Square.Square.AtlasSpectrum

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

/-- **THE CRUX GATE IS A GENUINE DISCRIMINATING VERIFIER** (it does not arbitrarily fail
    everything). Five facts, all already proven:

    1. **Gate B accepts a positive instance** — the E₈ seed Gram is `WeilPSD`;
    2. **Gate B rejects a negative instance** — the indefinite atlas spectral operator is NOT
       `WeilPSD`. So `WeilPSD` is a real predicate that separates definite from indefinite, not a
       constant `False`.
    3. **The crux accepts a positive instance** — the template spectral square satisfies
       `SpectralCrux`;
    4. **The crux rejects a negative instance** — the two-slice square does NOT (its `n = 3` slice
       vanishes). So `SpectralCrux` separates, not a constant `False`.
    5. **The crux CLOSES on a genuine witness** — a strict atlas embedding realizing the genuine
       diagonal flips `SpectralCrux (genuineSpectralSquare E)` to true.

    Hence the gate is passable: were the genuine witness (the definite infinite limit, §4/§G2b.1)
    supplied, the crux fields WOULD flip. They stay `none` because that specific witness is unmet
    (the atlas spectral signature is indefinite, `atlasM_indefinite`), not because the gate rejects
    all input. The gate works as intended. -/
theorem crux_gate_faithful :
    WeilPSD e8Gram
    ∧ ¬ WeilPSD atlasM
    ∧ (∃ S : SpectralSquare, SpectralCrux S)
    ∧ (∃ S : SpectralSquare, ¬ SpectralCrux S)
    ∧ (∀ (E : StieltjesEta) (ι : AtlasRule) (D : Nat),
        StrictRealizes E ι D → SpectralCrux (genuineSpectralSquare E)) :=
  ⟨e8_weilPSD, atlasM_indefinite,
   ⟨spectralTemplate, spectral_template_crux⟩,
   ⟨spectralTwoSlice, spectralTwoSlice_not_crux⟩,
   strictRealizes_closes_crux⟩

end UOR.Bridge.F1Square.Square
