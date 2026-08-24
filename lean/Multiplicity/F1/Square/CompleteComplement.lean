/-
F1 square — **the pre-Hilbert layer, brick 16** (`CompleteComplement.lean`): **THE SONINE
COMPLEMENT IS CLOSED UNDER COMPLETION** — band-vanishing Cauchy sequences have band-vanishing
limits, and the skeleton's unconditional positivity survives the passage to limit members.

- `limMember_band_zero` — if every `F j` vanishes on the negative-band index (`F j 1 ≈ 0`),
  then so does the constructed limit member: the band coordinate of the limit is the Bishop
  limit of the band coordinates (`fourierC_indic` + `Rlim_zero`).
- **`sonine_complement_complete`** — the payoff, unconditional: for every band-vanishing
  `dist2`-Cauchy sequence, the Weil multiplier pairing of the LIMIT member is `≥ 0` at every
  truncation — `burnol_pairing_psd_on_sonine` applied to the constructed limit. The Sonine
  complement (the skeleton subspace where positivity is a theorem) is a COMPLETE subspace:
  positivity is not lost in the limit.

WHY (the Sonine route, steps 3–4). This closes the loop between the completion arc (bricks
13–15) and the skeleton dichotomy (`SonineProjection`): the projection subspace is complete
and positivity passes to its limits — so what step 4 must supply is EXACTLY the coupling
beyond this closed subspace, not any limit bookkeeping inside it. The localization sharpens:
the band-coupling content is not hiding in the completion.

HONEST SCOPE. Closure and positivity for the SKELETON's band condition under fixed-truncation
completion; nothing about the genuine `f, f̂` co-support coupling, whose positivity beyond the
complement is step 4 and is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.Completion
import Multiplicity.F1.Square.SonineProjection

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Band vanishing passes to the limit member**: if every `F j` vanishes at the
    negative-band index, so does the constructed limit — the band coordinate of the limit is
    the limit of the band coordinates. -/
theorem limMember_band_zero {F : Nat → Nat → Real} {N : Nat} (hF : SqCauchy F N)
    (h1 : 1 < N) (hband : ∀ j, Req (F j 1) zero) :
    Req (limMember F N hF 1) zero := by
  refine Rlim_zero _ (pairing_RReg (sqCauchy_pairing hF 1)) (fun j => ?_)
  exact Req_trans (fourierC_indic (F j) h1) (hband j)

/-- **THE SONINE COMPLEMENT IS COMPLETE, WITH POSITIVITY** (unconditional): for every
    band-vanishing `dist2`-Cauchy sequence of test families, the Weil multiplier pairing of
    the constructed limit member is `≥ 0` at every truncation. The skeleton's
    complement-positivity survives the passage to limits — what step 4 must supply is exactly
    the coupling beyond this closed subspace. Crux `none`. -/
theorem sonine_complement_complete {F : Nat → Nat → Real} {N : Nat} (hF : SqCauchy F N)
    (h1 : 1 < N) (hband : ∀ j, Req (F j 1) zero) (N' : Nat) :
    Rnonneg (weilQuad (multForm burnolMult) (limMember F N hF) N') :=
  burnol_pairing_psd_on_sonine (limMember F N hF) N' (limMember_band_zero hF h1 hband)

end Multiplicity.UOR.Bridge.F1Square.Square
