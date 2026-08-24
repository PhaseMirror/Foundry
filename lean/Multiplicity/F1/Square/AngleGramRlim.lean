/-
F1 square — **the angle certificate's infinite-rank gram diagonal is the angle sum** (`AngleGramRlim.lean`):
tying the Gate-A angle-family reduction to the built on-object embedding `angleEmb` at the infinite rank the
fence forces. `angleGram_diag` is the FINITE identity `gramOf (angleEmb θ) (2m) n n = angleDiagTarget θ n m`;
its `Rlim` over `m` is the infinite-rank on-object gram diagonal, and it equals the angle sum's limit:

    `Rlim_m gramOf (angleEmb θ) (2m) n n  ≈  Rlim_m (angleDiagTarget θ n)`   (`angleGram_Rlim`).

So the reduction `atlasAngleFamily_closes_crux` — stated on `Rlim(angleDiagTarget θ n)` — is exactly a
statement about the *actual* embedding `angleEmb`'s infinite-rank squared-norm diagonal, the `gramOf`
object `realizesDiag_genuine_iff` is about, taken past every fixed dimension `D` (the rank fence
`realized_seq_uniformly_bounded` kills finite `D`). Both regularity proofs are supplied as hypotheses, so no
`RReg`-transport is needed: `Rlim_congr` consumes the finite per-`m` identity directly.

HONEST SCOPE. A pure `Rlim_congr` bridge from the built embedding's gram diagonal to the angle sum. It
constructs no `θ`, asserts no identity for the genuine `2λₙ`, adds no positivity. Step 4 (band-coupling
positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.AtlasAngleFamily
import Multiplicity.F1.Analysis.RlimProps

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The infinite-rank on-object gram diagonal is the angle sum's limit.** `Rlim_m gramOf (angleEmb θ)
    (2m) n n = Rlim_m (angleDiagTarget θ n)` — `Rlim_congr` over the finite identity `angleGram_diag`. This
    is the `gramOf` object of `realizesDiag_genuine_iff`, taken past every fixed dimension. -/
theorem angleGram_Rlim (θ : Nat → Real) (n : Nat)
    (reg' : RReg (fun m => gramOf (angleEmb θ) (2 * m) n n))
    (reg : RReg (angleDiagTarget θ n)) :
    Req (Rlim (fun m => gramOf (angleEmb θ) (2 * m) n n) reg')
        (Rlim (angleDiagTarget θ n) reg) :=
  Rlim_congr (fun m => gramOf (angleEmb θ) (2 * m) n n) (angleDiagTarget θ n)
    reg' reg (fun m => angleGram_diag θ n m)

/-- **The step-4 target in the embedding's own terms.** If the infinite-rank on-object gram diagonal of
    `angleEmb θ` is strictly positive for every `n > 0` and equals `2λₙ`, the crux holds. The same
    reduction as `atlasAngleFamily_closes_crux`, now stated directly on `Rlim gramOf (angleEmb θ)` — the
    `gramOf` realization `realizesDiag_genuine_iff` asks for, at infinite rank. Constructs no `θ`; that is RH. -/
theorem angleEmb_Rlim_closes_crux (E : StieltjesEta) (θ : Nat → Real)
    (reg' : ∀ n, RReg (fun m => gramOf (angleEmb θ) (2 * m) n n))
    (reg : ∀ n, RReg (angleDiagTarget θ n))
    (hpos : ∀ n, 0 < n → Pos (Rlim (fun m => gramOf (angleEmb θ) (2 * m) n n) (reg' n)))
    (hid : ∀ n, 0 < n → Req (Rlim (fun m => gramOf (angleEmb θ) (2 * m) n n) (reg' n))
        (Radd (genuineLamSeq E.eta n) (genuineLamSeq E.eta n))) :
    SpectralCrux (genuineSpectralSquare E) :=
  atlasAngleFamily_closes_crux E θ reg
    (fun n hn => Pos_congr (angleGram_Rlim θ n (reg' n) (reg n)) (hpos n hn))
    (fun n hn => Req_trans (Req_symm (angleGram_Rlim θ n (reg' n) (reg n))) (hid n hn))

end Multiplicity.UOR.Bridge.F1Square.Square
