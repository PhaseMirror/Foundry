/-
F1 square — v0.21.0 stage G, brick **uniform closure**: closure is ONE structural fact, not
enumeration — the program's §2 thesis, formalized, re-orienting the discovery away from per-`n`.

Being stuck at enumeration (certifying `λ₁, λ₂, λ₃, …` one at a time, `CruxFrontierN3`) is the wrong
path: no finite head closes the crux, which is `∀ n`. The function-field template
`BridgeFF.ff_hodge_iff_hasse` shows the right shape — ONE positivity fact (`4q − a² ≥ 0`) gives
negative-definiteness in EVERY direction at once. The arithmetic crux must close the same way: a
single uniform structural fact yielding the sign for all `n` simultaneously.

This brick makes the dichotomy a theorem:
- **Enumeration does NOT close** (`enumeration_insufficient`): the two-slice square is certified at
  the head (`⟨C₁,C₁⟩ < 0`, `⟨C₂,C₂⟩ < 0`) yet is NOT the crux — head certification, to any finite
  depth, is not the all-`n` statement.
- **One uniform fact DOES close** (`uniform_fact_closes`): a single strict atlas embedding realizing
  the diagonal gives `SpectralCrux` for ALL `n` at once (`strictRealizes_closes_crux`), the
  `ff_hodge_iff_hasse` shape over ℤ.

So completing the discovery means finding the Atlas's NOVEL uniform feature that supplies that single
witness — a zero-free atlas formula exhibiting `2λₙ` as a manifest sum of squares for all `n`
simultaneously (§4.1). That object is not yet discovered; the forced web and the (indefinite)
spectral operator do not supply it, and producing it is RH. The crux fields stay `none` — the gate,
not enumeration and not ambition, decides.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.GateSanity

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

/-- **Enumeration does NOT close the crux**: the two-slice square has strictly negative
    self-intersection at the head (`n = 1, 2` certified) yet is provably NOT the crux. Certifying a
    finite head — to any depth — is not the all-`n` statement. -/
theorem enumeration_insufficient :
    ∃ S : SpectralSquare,
      (Pos (Rneg (S.cSq 1)) ∧ Pos (Rneg (S.cSq 2))) ∧ ¬ SpectralCrux S :=
  ⟨spectralTwoSlice, spectral_evidence_two, spectralTwoSlice_not_crux⟩

/-- **One uniform structural fact DOES close the crux for all `n` at once**: a single strict atlas
    embedding realizing the genuine diagonal yields `SpectralCrux (genuineSpectralSquare E)` — every
    `n` simultaneously, the `ff_hodge_iff_hasse` shape. This is the right target; the witness is the
    Atlas's (undiscovered) novel uniform feature, never asserted. -/
theorem uniform_fact_closes :
    ∀ (E : StieltjesEta) (ι : AtlasRule) (D : Nat),
      StrictRealizes E ι D → SpectralCrux (genuineSpectralSquare E) :=
  strictRealizes_closes_crux

/-- **CLOSURE IS UNIFORM, NOT ENUMERATION** (the §2 thesis, mechanized): no finite head suffices
    (`enumeration_insufficient`), while a single uniform fact closes all `n`
    (`uniform_fact_closes`). The discovery completes by exhibiting the Atlas's novel uniform feature
    that supplies the witness — not by enumerating coefficients. Crux fields stay `none`. -/
theorem closure_is_uniform_not_enumeration :
    (∃ S : SpectralSquare,
        (Pos (Rneg (S.cSq 1)) ∧ Pos (Rneg (S.cSq 2))) ∧ ¬ SpectralCrux S)
    ∧ (∀ (E : StieltjesEta) (ι : AtlasRule) (D : Nat),
        StrictRealizes E ι D → SpectralCrux (genuineSpectralSquare E)) :=
  ⟨enumeration_insufficient, uniform_fact_closes⟩

end UOR.Bridge.F1Square.Square
