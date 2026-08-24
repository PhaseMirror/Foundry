/-
F1 square — **the raw angle target's limit is bounded by 1** (`AngleTargetBound.lean`): a
frontier-discovery finding that the certificate route's closing mechanism, as formalized, cannot be
instantiated on the genuine crux.

The closing reductions (`angleGram_Rlim`, `angleEmb_Rlim_closes_crux`, `atlasAngleFamily_closes_crux`)
all take `reg : RReg (angleDiagTarget θ n)` on the RAW partial-sum target — and `angleDiagTarget θ n 0 =
0` with nonneg terms `2 − 2cos ≥ 0`. `RReg` carries the CANONICAL Cauchy modulus, and completeness (`Rlim_tendsTo`) at `k = 0` gives
`|angleDiagTarget θ n 0 − Rlim| ≤ 2/(0+1) = 2`, i.e.

    `Rlim(angleDiagTarget θ n) ≤ 2` for EVERY `θ` satisfying `reg` (`angleDiagTarget_Rlim_le_two`)

— a fixed bound independent of `θ` (the sharper `RReg`-at-`j=0` argument gives `≤ 1`; `≤ 2` already
exhibits the gap).

But the identity `hid` demands `Rlim = 2λₙ`, and `2λₙ ~ n log n → ∞` (`2λ₇ ≈ 2.2 > 2`). So `reg` and
`hid` are JOINTLY UNSATISFIABLE for the genuine data at every `n` with `2λₙ > 2`: the raw-target closing
mechanism is valid as a theorem but cannot be instantiated to close the crux. The fix is an ACCELERATED
angle target (reindexed by a convergence-rate schedule so `RReg` holds while the limit is unbounded,
`digammaMidx`/`improper_schedule_eq` style) — pure convergence analysis, the next brick.

HONEST SCOPE. A bound on the raw angle target's limit, locating a satisfiability gap in the certificate
route's formalization. It is NOT a closure and NOT an obstruction to RH — it is a defect in one
mechanism's statement, to be repaired. It asserts no positivity of `2λₙ`. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.AngleGramDiagonal
import Multiplicity.F1.Analysis.Complete
import Multiplicity.F1.Analysis.ROrder

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The raw angle target's limit is `≤ 2`** for every `θ` making it regular. Since
    `angleDiagTarget θ n 0 = 0`, completeness (`Rlim_tendsTo`) at `k = 0` gives
    `|0 − Rlim| ≤ 2/(0+1) = 2`, so `Rlim ≤ 2` — a fixed bound, independent of `θ`. (The sharper `RReg`
    modulus at `j = 0` gives `≤ 1`; `≤ 2` already exhibits the gap.) This is why `reg` is incompatible
    with `hid : Rlim = 2λₙ` once `2λₙ > 2` — the certificate route's raw target cannot realize the
    genuine, unbounded `2λₙ ~ n log n`. -/
theorem angleDiagTarget_Rlim_le_two (θ : Nat → Real) (n : Nat)
    (reg : RReg (angleDiagTarget θ n)) :
    Rle (Rlim (angleDiagTarget θ n) reg) (ofQ ⟨2, 1⟩ (by decide)) := by
  intro N
  show Qle ((Rlim (angleDiagTarget θ n) reg).seq N) (add (⟨2, 1⟩ : Q) ⟨2, N + 1⟩)
  have htend := Rlim_tendsTo (angleDiagTarget θ n) reg 0 N
  rw [Qabs_Qsub_comm] at htend
  have hle := Qle_add_of_Qabs_sub
    ((Rlim (angleDiagTarget θ n) reg).den_pos N)
    ((angleDiagTarget θ n 0).den_pos N)
    (add_den_pos (by decide) (Nat.succ_pos N))
    htend
  rw [show (angleDiagTarget θ n 0).seq N = (⟨0, 1⟩ : Q) from rfl] at hle
  refine Qle_congr_right ?_ ?_ hle
  · exact add_den_pos (by decide) (add_den_pos (by decide) (Nat.succ_pos N))
  · -- `add ⟨0,1⟩ (2/1 + 2/(N+1)) = 2/1 + 2/(N+1)` (add-zero-left)
    simp only [Qeq, add]; push_cast; ring_uor

end Multiplicity.UOR.Bridge.F1Square.Square
