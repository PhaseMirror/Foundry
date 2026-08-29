/-
F1 square — **the pre-Hilbert layer, brick 77** (`DyadicClamp.lean`): **THE CLAMPED DYADIC INDEX**
— the second piece brick 76 named as missing.

Brick 75's floor `⌊q·2^m⌋` lands in `[0, 2^m)` only when the rational `q` is already in `[0,1)`.
The rationals that arise in the density argument are the approximants `x.seq N` of a real
`x ∈ [0,1]`, and those need **not** be in range: they can dip below `0` or reach `1` by up to the
approximation error. So the index has to be clamped, and the clamp has to cost something bounded:

    `dyadJC q m := min (⌊q·2^m⌋) (2^m − 1)`,      `dyadJC q m < 2^m`   (`dyadJC_lt`).

The clamp is a `ℕ` `min` — decidable, no real compared to anything.

HONEST SCOPE. This brick supplies the clamped index and its range bound only. It does **not**
prove the approximation quality of the clamped point for an out-of-range `q` — that needs the
case analysis on `q` (below `0`, in range, at-or-above `1`), which is decidable but is arithmetic
this brick does not carry out. So `DyadicApproximable` is still **not discharged**, and brick 74's
definiteness remains stated at dyadic points. Nothing here touches the Weil form. The crux fields
stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.L2DefiniteDensity
import Foundations.F1.Analysis.RSeqApprox

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The clamped dyadic index**: the floor, capped at the last index of `[0,1)`. -/
def dyadJC (q : Q) (m : Nat) : Nat := Nat.min (dyadJ q m) (2 ^ m - 1)

/-- **The clamped index is always in range** — unconditionally, for every rational. -/
theorem dyadJC_lt (q : Q) (m : Nat) : dyadJC q m < 2 ^ m := by
  have hpow : 0 < 2 ^ m := two_pow_pos m
  have hle : dyadJC q m ≤ 2 ^ m - 1 := Nat.min_le_right _ _
  omega

/-- When the floor is already in range the clamp is inert, so brick 75's bound survives. -/
theorem dyadJC_eq_of_lt (q : Q) (m : Nat) (h : dyadJ q m < 2 ^ m) :
    dyadJC q m = dyadJ q m :=
  Nat.min_eq_left (by omega)

/-- **The clamp is inert on in-range rationals**, so `|q − dyadJC/2^m| ≤ 1/2^m` there — brick 75
    restated on the clamped index, which is the form the density argument consumes. -/
theorem dyadJC_approx (q : Q) (hd : 0 < q.den) (hn : 0 ≤ q.num)
    (hq : q.num.toNat < q.den) (m : Nat) :
    Qle (Qabs (Qsub q (⟨((dyadJC q m : Nat) : Int), 2 ^ m⟩ : Q))) (⟨1, 2 ^ m⟩ : Q) := by
  rw [dyadJC_eq_of_lt q m (dyadJ_lt q hd hq m)]
  exact dyadApprox_spec q hd hn m

end Multiplicity.UOR.Bridge.F1Square.Square
