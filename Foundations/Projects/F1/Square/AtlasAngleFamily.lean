/-
F1 square — **the Gate-A Atlas-intrinsic angle family: the step-4 implementation target, stated**
(`AtlasAngleFamily.lean`). The crux-closing plan reduces step 4 to ONE identity: supply an infinite
angle family `θ` and prove `Σ_k (2 − 2cos(nθ_k)) ≈ 2λₙ` for all `n > 0`. This file states that
hypothesis and proves it closes the crux — the family's *existence* (an Atlas-intrinsic infinite `θ`
with the identity and the strict positivity) is never asserted; that is RH. The crux fields stay `none`.

The certificate's shape is already built: `angleGram_diag θ n m : gramOf (angleEmb θ) (2m) n n =
angleDiagTarget θ n m`, the partial sum `Σ_{k<m} (2 − 2cos(nθ_k))`. This file adds:

- `angleDiagTarget_nonneg`: every partial is a nonneg SOS (`2 − 2cos φ = (1−cos)+(1−cos) ≥ 0`,
  `Rcos_le_one`). So the certificate's NON-strict face is FREE from the angle structure — no hypothesis
  beyond the identity.
- `atlasAngleFamily_hodgeNeg`: the identity `Rlim(angleDiagTarget θ n) = 2λₙ` alone forces
  `SpectralHodgeNeg` (`Rlim` of nonnegs is nonneg, transported across `genuine_vanCyc_normal`
  `−⟨Cₙ,Cₙ⟩ = 2λₙ`); it is `LiNonneg` through `genuine_hodgeNeg_iff`. This is the semidefinite face, not the crux.
- `atlasAngleFamily_closes_crux`: the STRICT form — the identity plus `∀ n>0, Pos(Rlim(angleDiagTarget θ n))`
  closes `SpectralCrux`. The strict positivity `hpos` is a property of the FREE angle family `θ` (the angles
  are nonzero, so the on-object gram diagonal is strictly positive), exactly mirroring the repo's accepted
  `StrictRealizes → crux` discipline (`strictRealizes_closes_crux`) — `Pos` of a free embedding's diagonal
  plus the realization identity — now at the INFINITE rank the fence forces (`realized_seq_uniformly_bounded`)
  and in the explicit angle-SOS shape.

HONEST SCOPE. The reduction "Atlas-intrinsic strict angle family ⟹ crux", and the free semidefinite face.
It does NOT construct any `θ`, does NOT assert the identity or the strict positivity for the genuine `2λₙ`
(that is RH), and does NOT flip the crux fields. It is the plan's step-4 implementation target, stated.
Crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.AngleGramDiagonal
import Foundations.F1.Square.Forced
import Foundations.F1.Analysis.DyadicIntegral

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- **Every partial of the angle sum is a nonneg SOS.** `angleDiagTarget θ n m = Σ_{k<m}(2 − 2cos(nθ_k)) ≥ 0`,
    each block `2 − 2cos φ = (1−cos φ)+(1−cos φ) ≥ 0` via `Rcos_le_one`. So the on-object certificate's
    semidefinite face is free from the angle structure. -/
theorem angleDiagTarget_nonneg (θ : Nat → Real) (n : Nat) :
    ∀ m, Rnonneg (angleDiagTarget θ n m)
  | 0 => Rnonneg_zero
  | (m + 1) =>
      Rnonneg_Radd (angleDiagTarget_nonneg θ n m)
        (Rnonneg_Rsub_of_Rle
          (Radd_le_add (Rcos_le_one (nsmulR n (θ m))) (Rcos_le_one (nsmulR n (θ m)))))

/-- **The identity forces the semidefinite (Hodge-nonneg) face.** If the angle sum converges to `2λₙ`
    for all `n > 0`, then `−⟨Cₙ,Cₙ⟩ ≥ 0` for all `n > 0` (`SpectralHodgeNeg`): `Rlim` of the nonneg SOS
    partials is nonneg, transported across `genuine_vanCyc_normal`. NO strict positivity here — this is the
    face, not the crux. -/
theorem atlasAngleFamily_hodgeNeg (E : StieltjesEta) (θ : Nat → Real)
    (reg : ∀ n, RReg (angleDiagTarget θ n))
    (hid : ∀ n, 0 < n → Req (Rlim (angleDiagTarget θ n) (reg n))
        (Radd (genuineLamSeq E.eta n) (genuineLamSeq E.eta n))) :
    SpectralHodgeNeg (genuineSpectralSquare E) := by
  intro n hn
  refine Rnonneg_congr (Req_symm (genuine_vanCyc_normal E n)) ?_
  refine Rnonneg_congr (hid n hn) ?_
  exact Rnonneg_Rlim_seq (reg n) (angleDiagTarget_nonneg θ n)

/-- **★ THE STEP-4 IMPLEMENTATION TARGET: an Atlas-intrinsic STRICT angle family closes the crux.**
    Given an angle family `θ` whose on-object gram diagonal `Rlim(angleDiagTarget θ n)` is strictly
    positive for every `n > 0` (`hpos` — a property of the free angles, they are nonzero) and equals
    `2λₙ` (`hid`, the realization identity), the crux `SpectralCrux (genuineSpectralSquare E)` holds:
    `Pos(Rlim) = Pos(2λₙ) = Pos(−⟨Cₙ,Cₙ⟩)`. This mirrors `strictRealizes_closes_crux` (strict `Pos` of a
    free embedding's diagonal + the realization identity) at the INFINITE rank the fence forces, in the
    explicit angle-SOS shape. NOTHING here constructs `θ` or asserts the identity/strictness for the
    genuine `2λₙ` — that is RH; the crux fields stay `none`. -/
theorem atlasAngleFamily_closes_crux (E : StieltjesEta) (θ : Nat → Real)
    (reg : ∀ n, RReg (angleDiagTarget θ n))
    (hpos : ∀ n, 0 < n → Pos (Rlim (angleDiagTarget θ n) (reg n)))
    (hid : ∀ n, 0 < n → Req (Rlim (angleDiagTarget θ n) (reg n))
        (Radd (genuineLamSeq E.eta n) (genuineLamSeq E.eta n))) :
    SpectralCrux (genuineSpectralSquare E) := by
  intro n hn
  exact Pos_congr (Req_symm (genuine_vanCyc_normal E n))
    (Pos_congr (hid n hn) (hpos n hn))

end Multiplicity.UOR.Bridge.F1Square.Square
