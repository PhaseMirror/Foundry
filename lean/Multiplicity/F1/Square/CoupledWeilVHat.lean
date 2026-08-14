/-
F1 square — **grounding the coupled kernel's `v` in the genuine Mellin TRANSFORM** (`CoupledWeilVHat.lean`):
the coupled Weil kernel's prime side `primeGram w v M` intends `v m i = ĝ_i(m)`, a Mellin-TRANSFORM value
(only for the transform does convolution factor as a product). The prior grounding `vFrom g m i =
placeVal(g_i, m)` fed POINT values, which are not the transform (`CoupledWeilPlaceValue.lean`'s open link).
This file feeds the genuine transform: `vHat g m i = mellinMoment (g_i) m = ĝ_i(m) = ∫₀¹ g_i·xᵐ` — a
constructed real, zero-free, so

    `weilPrimeGram (vHat g) M (i,j) = Σ_{m<M} Λ(m+1)·ĝ_i(m)·ĝ_j(m)`

is the coupled kernel's prime Gram at the transform data it was designed for.

WHY (grounding `v = ĝ`). Wall 3's factorization `convMellinHat = M[f]·M[g]` (`convMellinHat_eq_MfMoment`)
is what will identify this transform prime Gram with the autocorrelation prime side
`weilPrimePart(g_i ⋆ g_j^τ)` — because `M[g_i⋆g_j^τ] = M[g_i]·M[g_j^τ]` factors, while the point-value
`(g_i⋆g_j^τ)(m)` does not. This file supplies the transform-valued `v`; the full autocorrelation
identity (the diagonal-recovery law) is the next brick on top of it.

HONEST SCOPE. The transform-valued `v`-slot and its prime Gram (symmetric, unconditionally PSD on the von
Mangoldt weight). It does NOT yet prove `weilPrimeGram (vHat g) = weilPrimePart(g_i⋆g_j^τ)` (the
autocorrelation identification — needs Wall 3's factorization wired through), does NOT assemble the coupled
kernel's positivity, and applies NO step-4 dominance (`ArchDominatesPrime`), which is RH. The crux fields
stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.CoupledWeilKernel
import Multiplicity.F1Square.Square.TestAlgebra

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The coupled kernel's interface `v`, **fed the genuine Mellin transform** `ĝ_i(m) = mellinMoment (g_i) m`
    — the transform value at place `m`, a constructed real with no zeros (contrast `vFrom`, which feeds the
    point value `placeVal`). This is the `v = ĝ` the coupled kernel is designed for. -/
def vHat (g : Nat → L2Test) : Nat → Nat → Real :=
  fun m i => mellinMoment (g i) m

/-- **The transform prime Gram, explicitly**: `weilPrimeGram (vHat g) M (i,j) =
    Σ_{m<M} Λ(m+1)·ĝ_i(m)·ĝ_j(m)` — the coupled kernel's prime Gram at genuine Mellin-transform data. -/
theorem primeGram_vHat_apply (g : Nat → L2Test) (M i j : Nat) :
    primeGram (fun m => vonMangoldt (m + 1)) (vHat g) M i j
      = RsumN (fun m => Rmul (vonMangoldt (m + 1))
          (Rmul (mellinMoment (g i) m) (mellinMoment (g j) m))) M := rfl

/-- **The transform prime Gram is UNCONDITIONALLY PSD** — the von Mangoldt instance at genuine
    Mellin-transform data (`Λ ≥ 0`, each weighted square nonneg, no sqrt, no RH input). -/
theorem weilPrimeGram_vHat_psd (g : Nat → L2Test) (M : Nat) :
    WeilPSD (weilPrimeGram (vHat g) M) :=
  WeilPSD_weilPrimeGram (vHat g) M

/-- **Symmetry of the transform prime Gram**: `weilPrimeGram (vHat g) M (i,j) ≈
    weilPrimeGram (vHat g) M (j,i)` — symmetric in the two test indices. -/
theorem primeGram_vHat_sym (g : Nat → L2Test) (M i j : Nat) :
    Req (weilPrimeGram (vHat g) M i j) (weilPrimeGram (vHat g) M j i) :=
  primeGram_sym (fun m => vonMangoldt (m + 1)) (vHat g) M i j

/-- **The transform prime Gram's diagonal is the transform-domain prime ENERGY** of test `i`:
    `weilPrimeGram (vHat g) M (i,i) = Σ_{m<M} Λ(m+1)·ĝ_i(m)²` — a manifest weighted sum of squares over
    prime powers, `≥ 0`. This is the diagonal the autocorrelation-recovery law will tie to
    `weilPrimePart(g_i ⋆ g_i^τ)` via Wall 3's factorization. -/
theorem primeGram_vHat_diag (g : Nat → L2Test) (M i : Nat) :
    Req (weilPrimeGram (vHat g) M i i)
        (RsumN (fun m => Rmul (vonMangoldt (m + 1))
          (Rmul (mellinMoment (g i) m) (mellinMoment (g i) m))) M) :=
  Req_refl _

end Multiplicity.UOR.Bridge.F1Square.Square
