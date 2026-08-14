/-
F1 square — **the pre-Hilbert layer, brick 97** (`ContinuousMomentFloor.lean`): **the continuous
transform's integrand is floor-independent at every rational sample point** — `compactPow a s (q) ≈
(1/q)^{−s}` for every rational `q ≥ a` (`compactPow_ofQ`), independent of the floor `a`
(`compactPow_floor_indep`).

The compact power (brick 93) is totalized by a rational floor `a` that only matters BELOW `a`; at a
rational point `q ≥ a` the clamp is inert (`clampedInv a q = 1/q`, `ClampedInv.lean`), so
`compactPow a s q = gPowClamp(−s)(1/q) = max(1/q,1)^{−s}` — a value that does not mention `a`. Hence two
floors `a, a'` both `≤ q` give the *same* integrand value at `q` (`compactPow_floor_indep`).

This is the structural fact the `a → 0` limit rests on: the certified Riemann integral samples its
integrand only at the RATIONAL partition points `i/(N+1) ∈ [0,1)`, and above the floor those samples are
floor-free. So the only floor-dependence of `compactMoment φ a s` is through the sub-`a` partition points
— the `O(M·a^{s+1})` tail flagged in brick 93 — and shrinking `a` changes the transform only there.

HONEST SCOPE. The floor-independence of the integrand VALUES at rational points `≥ a`; the `a → 0` limit
of `compactMoment` itself (a Cauchy estimate on the sub-`a` tail) is NOT assembled here, and the value
`(1/q)^{−s}` is still the reciprocal power, not identified with `q^s` (which needs `log(1/q) = −log q`).
No transform pair, no inversion, no positivity. Step 4 is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.ContinuousMoment

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `−s ≤ 0` from `s ≥ 0` (local; the `ContinuousMoment` copy is private). -/
private theorem negs_nonpos {s : Real} (hs : Rnonneg s) : Rle (Rneg s) zero :=
  Rle_trans (Rle_Rneg (Rle_zero_of_Rnonneg hs)) (Rle_of_Req Rneg_zero)

/-- **The compact power at a rational point above the floor** `compactPow a s (q) ≈ (1/q)^{−s}` for
    `q ≥ a` — the clamp is inert at `q`, so `clampedInv a q = 1/q` and the value drops the floor `a`. -/
theorem compactPow_ofQ (a : Q) (han : 0 < a.num) (had : 0 < a.den) {s : Real} (hs : Rnonneg s)
    {q : Q} (hqd : 0 < q.den) (hqn : 0 < q.num) (haq : Qle a q) :
    Req (compactPow a han had s (ofQ q hqd))
        (gPowClamp (Rneg s) (ofQ (Qinv q) (Qinv_den_pos hqn))) := by
  unfold compactPow
  exact gPowClamp_congr (Rneg s) (negs_nonpos hs) (clampedInv_ofQ han had hqd hqn haq)

/-- **Floor-independence at rational points**: for two floors `a, a'` both `≤ q`, the compact power
    integrand takes the *same* value at `q` — both equal `(1/q)^{−s}`. The certified integral samples
    only rational points, so above the floor the transform is floor-free. -/
theorem compactPow_floor_indep (a a' : Q) (han : 0 < a.num) (had : 0 < a.den)
    (han' : 0 < a'.num) (had' : 0 < a'.den) {s : Real} (hs : Rnonneg s)
    {q : Q} (hqd : 0 < q.den) (hqn : 0 < q.num) (haq : Qle a q) (ha'q : Qle a' q) :
    Req (compactPow a han had s (ofQ q hqd)) (compactPow a' han' had' s (ofQ q hqd)) :=
  Req_trans (compactPow_ofQ a han had hs hqd hqn haq)
    (Req_symm (compactPow_ofQ a' han' had' hs hqd hqn ha'q))

end Multiplicity.UOR.Bridge.F1Square.Square
