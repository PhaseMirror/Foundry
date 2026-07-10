/-
F1 square — v0.22.0 Track 1, utility: **closed forms for the `tmap` Cayley parameter at a rational
argument** — `tmap q = (q−1)/(q+1) = ((q.num−q.den)·q.den) / (q.den·(q.num+q.den))`.

`tmap` (`Log.lean`) is the artanh argument of the constructive log: `Rlog x = 2·artanh(tmap x)`. The
nat closed forms (`tmap_nat_num`/`tmap_nat_den`, `ExpLog.lean`) cover `q = ⟨n,1⟩`; these lift them to
an arbitrary rational `q` (`Qinv (q+1) = ⟨q.den, (q.num+q.den).toNat⟩` is unconditional). Reusable for
any rational-argument log/artanh work.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.ExpLog

namespace UOR.Bridge.F1Square.Analysis

/-- `tmap q` numerator: `(q.num − q.den)·q.den` (from `Qinv (q+1) = ⟨q.den, (q.num+q.den).toNat⟩`). -/
theorem tmap_rat_num (q : Q) : (tmap q).num = (q.num - (q.den : Int)) * (q.den : Int) := by
  unfold tmap mul Qsub add neg Qinv; push_cast; ring_uor

/-- `tmap q` denominator: `q.den·(q.num+q.den).toNat`. -/
theorem tmap_rat_den (q : Q) : (tmap q).den = q.den * (q.num + (q.den : Int)).toNat := by
  show q.den * 1 * (q.num * 1 + 1 * (q.den : Int)).toNat = q.den * (q.num + (q.den : Int)).toNat
  rw [Nat.mul_one]; congr 1; omega

end UOR.Bridge.F1Square.Analysis
