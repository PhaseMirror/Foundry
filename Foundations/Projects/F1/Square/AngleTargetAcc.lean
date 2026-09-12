/-
F1 square — **the ACCELERATED angle target: repairing the certificate route's closing mechanism**
(`AngleTargetAcc.lean`). `AngleTargetBound.lean` proved the raw target's satisfiability gap
(`angleDiagTarget_Rlim_le_two`: `reg` forces `Rlim ≤ 2`, incompatible with `hid : Rlim = 2λₙ ~ n log n`).
The fix: reindex the raw partial sums by a monotone schedule `sched`,

    `angleDiagTargetAcc θ n sched j := angleDiagTarget θ n (sched j)`.

For `sched 0 > 0` the accelerated sequence starts from a LARGE partial (`Y_0 = angleDiagTarget θ n
(sched 0) ≠ 0`), so `RReg` no longer caps the limit at `2` — `reg'` (regularity of the accelerated
target) and `hid` (`Rlim = 2λₙ`) become JOINTLY SATISFIABLE. The closing theorem's proof is
target-agnostic (it only consumes `hid`/`hpos`, never the target's shape), so it transfers verbatim to
the accelerated target — with hypotheses that can actually be met on the genuine, unbounded `2λₙ`.

This is the repair `AngleTargetBound.lean` named: it makes `atlasAngleFamily_closes_crux` INSTANTIABLE.
It still constructs no `θ`, no `sched`, and asserts nothing about the genuine `2λₙ` (that identity is
`hid`, which is RH). Discharging `reg'` for a sum-converging `θ` (choosing `sched` fast enough that the
accelerated partials are canonical-rate Cauchy) is separate convergence analysis; here `reg'` is an
explicit hypothesis, exactly as `reg` was — but now on a target where it does not contradict `hid`.

HONEST SCOPE. The accelerated closing reduction, with `reg'` compatible with an unbounded limit. It
repairs a formalization defect; it does NOT close the crux. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.AtlasAngleFamily

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The accelerated angle target**: the raw partial sums reindexed by a schedule `sched : Nat → Nat`,
    `angleDiagTargetAcc θ n sched j = angleDiagTarget θ n (sched j)`. With `sched 0 > 0` it starts from a
    large partial, so its `RReg` limit is not capped (contrast `angleDiagTarget_Rlim_le_two`). -/
def angleDiagTargetAcc (θ : Nat → Real) (n : Nat) (sched : Nat → Nat) : Nat → Real :=
  fun j => angleDiagTarget θ n (sched j)

/-- **Every accelerated partial is a nonneg SOS** — it is a raw partial `Σ_{k<sched j}(2−2cos(nθ_k)) ≥ 0`
    (`angleDiagTarget_nonneg`). The semidefinite face stays free after acceleration. -/
theorem angleDiagTargetAcc_nonneg (θ : Nat → Real) (n : Nat) (sched : Nat → Nat) :
    ∀ j, Rnonneg (angleDiagTargetAcc θ n sched j) :=
  fun j => angleDiagTarget_nonneg θ n (sched j)

/-- **The identity forces the semidefinite face** (accelerated): if the accelerated angle target
    converges to `2λₙ` for all `n > 0`, then `SpectralHodgeNeg`. Same as `atlasAngleFamily_hodgeNeg`,
    now with `reg` on the accelerated target — where it does not contradict the growth of `2λₙ`. -/
theorem atlasAngleFamily_hodgeNeg_acc (E : StieltjesEta) (θ : Nat → Real) (sched : Nat → Nat)
    (reg : ∀ n, RReg (angleDiagTargetAcc θ n sched))
    (hid : ∀ n, 0 < n → Req (Rlim (angleDiagTargetAcc θ n sched) (reg n))
        (Radd (genuineLamSeq E.eta n) (genuineLamSeq E.eta n))) :
    SpectralHodgeNeg (genuineSpectralSquare E) := by
  intro n hn
  refine Rnonneg_congr (Req_symm (genuine_vanCyc_normal E n)) ?_
  refine Rnonneg_congr (hid n hn) ?_
  exact Rnonneg_Rlim_seq (reg n) (angleDiagTargetAcc_nonneg θ n sched)

/-- **★ THE REPAIRED STEP-4 TARGET: an Atlas-intrinsic strict angle family, on the ACCELERATED target,
    closes the crux.** Identical reduction to `atlasAngleFamily_closes_crux` (the proof is
    target-agnostic — `Pos_congr` on `hid`/`hpos` through `genuine_vanCyc_normal`), but stated on
    `angleDiagTargetAcc`, whose `reg` does NOT cap the limit at `2` and so is jointly satisfiable with
    `hid : Rlim = 2λₙ` on the genuine, unbounded data. NOTHING here constructs `θ`/`sched` or asserts
    the identity/strictness for the genuine `2λₙ` — that is RH; the crux fields stay `none`. -/
theorem atlasAngleFamily_closes_crux_acc (E : StieltjesEta) (θ : Nat → Real) (sched : Nat → Nat)
    (reg : ∀ n, RReg (angleDiagTargetAcc θ n sched))
    (hpos : ∀ n, 0 < n → Pos (Rlim (angleDiagTargetAcc θ n sched) (reg n)))
    (hid : ∀ n, 0 < n → Req (Rlim (angleDiagTargetAcc θ n sched) (reg n))
        (Radd (genuineLamSeq E.eta n) (genuineLamSeq E.eta n))) :
    SpectralCrux (genuineSpectralSquare E) := by
  intro n hn
  exact Pos_congr (Req_symm (genuine_vanCyc_normal E n))
    (Pos_congr (hid n hn) (hpos n hn))

end Multiplicity.UOR.Bridge.F1Square.Square
