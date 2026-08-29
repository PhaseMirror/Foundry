/-
F1 square — **the pre-Hilbert layer, brick 78** (`DyadicDense.lean`): **THE RATIONALS ARE
DYADICALLY APPROXIMABLE, AND SO THE `L²` PAIRING IS DEFINITE AT EVERY RATIONAL POINT** —

    `q` rational in `[0,1)`   ⟹   `DyadicApproximable (ofQ q)`   (`dyadicApproximable_ofQ`)
    `∫₀¹ φ² ≈ 0`              ⟹   `φ(q) ≈ 0` at every such `q`   (`innerI_self_zero_imp_rational_zero`)

and the polynomial-class capstone `polyPN_rational_zero`.

This discharges `DyadicApproximable` (brick 76) on the rationals, by pairing brick 75's floor with
brick 77's clamp and the fact that `2^m` outruns any rational (`exists_depth`). Every step is a
`ℚ` computation; no real is ever compared to anything.

The extension from rationals to **all** reals is the one remaining step, and it is now purely
mechanical in shape: `Rabs_sub_seq_le` (a real is within `1/(N+1)` of `x.seq N`) plus the triangle
inequality would carry the bound, provided the approximant is handled when it falls outside
`[0,1)`. That case analysis is decidable but is **not** performed here.

HONEST SCOPE. Definiteness at every **rational** point of `[0,1)` — a strict strengthening of
brick 74's dyadic points, and still not all points. It says nothing about the moment problem: a
nonzero test with all *moments* vanishing is a different question, still open, and still needs
Bernstein. Nothing here touches the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.DyadicClamp
import Foundations.F1.Square.PolyDeterminacy
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **THE RATIONALS OF `[0,1)` ARE DYADICALLY APPROXIMABLE.** -/
theorem dyadicApproximable_ofQ (q : Q) (hd : 0 < q.den) (hn : 0 ≤ q.num)
    (hq : q.num.toNat < q.den) :
    DyadicApproximable (ofQ q hd) := by
  intro k
  -- a depth with `1/2^m ≤ 1/(k+1)`: `2^m` outruns any rational
  obtain ⟨m, hm⟩ := exists_depth (⟨1, 1⟩ : Q) (⟨1, k + 1⟩ : Q) (by decide) (Nat.succ_pos k)
    (by show (0 : Int) < 1; decide)
  refine ⟨m, dyadJC q m, dyadJC_lt q m, ?_⟩
  -- the distance is a RATIONAL distance, transported through `ofQ`
  have hQ : Qle (Qabs (Qsub q (⟨((dyadJC q m : Nat) : Int), 2 ^ m⟩ : Q))) (⟨1, 2 ^ m⟩ : Q) :=
    dyadJC_approx q hd hn hq m
  have hstep : Qle (⟨1, 2 ^ m⟩ : Q) (⟨1, k + 1⟩ : Q) := by
    refine Qle_trans (Qmul_den_pos (by decide) (two_pow_pos m)) ?_ hm
    show (1 : Int) * ((1 * 2 ^ m : Nat) : Int) ≤ (1 * 1 : Int) * ((2 ^ m : Nat) : Int)
    push_cast
    omega
  refine Rle_trans (Rle_of_Req ?_) (Rle_ofQ_ofQ (Qabs_den_pos (add_den_pos hd (two_pow_pos m)))
    (Nat.succ_pos k) (Qle_trans (Nat.pos_pow_of_pos m (by decide)) hQ hstep))
  -- `|ofQ q − ofQ p| ≈ ofQ |q − p|`
  refine Req_trans (Rabs_congr (Rsub_ofQ_ofQ hd (two_pow_pos m))) ?_
  exact Rabs_ofQ (add_den_pos hd (two_pow_pos m))

/-- **DEFINITENESS AT EVERY RATIONAL POINT of `[0,1)`.** -/
theorem innerI_self_zero_imp_rational_zero (φ : L2Test) (h : Req (innerI φ φ) zero)
    (q : Q) (hd : 0 < q.den) (hn : 0 ≤ q.num) (hq : q.num.toNat < q.den) :
    Req (φ.f (ofQ q hd)) zero :=
  zero_of_dyadic_approximable φ h (ofQ q hd) (dyadicApproximable_ofQ q hd hn hq)

/-- **THE POLYNOMIAL CLASS, AT EVERY RATIONAL POINT**: a `d`-coefficient polynomial test whose
    first `d` moments vanish is zero at every rational of `[0,1)`. Brick 64's determinacy,
    upgraded from the moments to the function on a dense set of points. -/
theorem polyPN_rational_zero (a b : Nat → Nat) (d : Nat)
    (hmom : ∀ i : Nat, i < d → Req (mellinMoment (polyPN a b d) i) zero)
    (q : Q) (hd : 0 < q.den) (hn : 0 ≤ q.num) (hq : q.num.toNat < q.den) :
    Req ((polyPN a b d).f (ofQ q hd)) zero :=
  innerI_self_zero_imp_rational_zero (polyPN a b d)
    (innerI_polyPN_self_zero a b d hmom) q hd hn hq

end Multiplicity.UOR.Bridge.F1Square.Square
