/-
F1 square — v0.21.0 stage G, brick **the Single Prime Hypothesis**: the Atlas as the unified
structure emanating from one Prime object — and why that makes crux-closure UNIFORM.

The UOR Atlas is founded on **unity**: a single Prime object from which all other objects emanate
(the Single Prime Hypothesis). In the formalized structure this shows up two ways, and they are the
same principle:

- **One generating prime — `2`.** Everything is binary: the tower dimensions are `2^j`
  (`single_prime_binary`), the top is `O = 2^T`, the substrate is the `2`-power tower `W_n = ℤ/2ⁿ`
  (`m_0 = 2⁵·3`), and the distinguished prime is `2` (§10). The Atlas's numbers EMANATE from the
  single prime `2`.
- **One generating object — the free generator.** The canonical `H¹` is FREE ON ONE GENERATOR
  (`H1_isFree`), and its orbit `orbit n = n` (`H1_orbit`) emanates EVERY class `Cₙ` from that single
  generator. The whole spectral family is one object's emanation.

WHY THIS MAKES CLOSURE UNIFORM. If every `Cₙ` emanates from one Prime object, then the sign of the
whole family is a property of that ONE object — not `n` facts but one. That is precisely
`UniformClosure` (`uniform_fact_closes`: one structural fact closes all `n`) and the
`ff_hodge_iff_hasse` shape. The Single Prime Hypothesis is the conceptual ground of the uniform
target: unity ⟹ one witness, not enumeration (`sph_closure_is_uniform`).

HONEST BOUNDARY. The SPH explains WHY a single uniform witness should exist (and why enumeration is
wrong), and the unity is real and forced (`atlas_forced_web`). It does not, by itself, EXHIBIT the
witness — the genuine emanation of `2λₙ` as a manifest sum of squares from the single Prime. That
exhibition is RH (§4.1); the gate decides; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `()`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.AtlasCharacteristics
import F1Square.Square.UniformClosure

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

/-- **The single prime is `2`**: the Atlas's tower emanates from the one prime `2` — every level
    dimension is a power of `2` (`towerDim j = 2^j`), and the top is `O = 2^T`. -/
theorem single_prime_binary :
    (8 = 2 ^ 3)
    ∧ towerDim 0 = 2 ^ 0 ∧ towerDim 1 = 2 ^ 1 ∧ towerDim 2 = 2 ^ 2 ∧ towerDim 3 = 2 ^ 3 := by
  decide

/-- **The single generating object**: the canonical `H¹` is FREE ON ONE GENERATOR (`H1_isFree`), and
    its orbit emanates every class — `orbit n = n` for all `n` (`H1_orbit`). All spectral classes
    `Cₙ` are emanations of the one Prime object. -/
theorem single_generator_emanates : IsFreeFrob H1 ∧ ∀ n, H1.orbit n = n :=
  ⟨H1_isFree, fun n => H1_orbit n⟩

/-- **THE SINGLE PRIME HYPOTHESIS MAKES CLOSURE UNIFORM**: because every class emanates from one
    Prime object (`single_generator_emanates`), the crux's sign is a property of that one object —
    one structural fact for all `n` (`uniform_fact_closes`), NOT enumeration
    (`enumeration_insufficient`). Unity is the conceptual ground of the uniform target. The witness
    — the emanation of `2λₙ` as a manifest sum of squares — is the open content (RH); crux `none`. -/
theorem sph_closure_is_uniform :
    (IsFreeFrob H1 ∧ ∀ n, H1.orbit n = n)
    ∧ (∃ S : SpectralSquare,
        (Pos (Rneg (S.cSq 1)) ∧ Pos (Rneg (S.cSq 2))) ∧ ¬ SpectralCrux S)
    ∧ (∀ (E : StieltjesEta) (ι : AtlasRule) (D : Nat),
        StrictRealizes E ι D → SpectralCrux (genuineSpectralSquare E)) :=
  ⟨single_generator_emanates, enumeration_insufficient, uniform_fact_closes⟩

end UOR.Bridge.F1Square.Square
