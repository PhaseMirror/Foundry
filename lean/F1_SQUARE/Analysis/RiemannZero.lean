/-
F1 square — **the genuine Riemann Hypothesis, stated about the CONSTRUCTED ζ**: grounding the crux's
open input in the critical-strip ζ this development actually builds (`CzetaStrip`), rather than an
abstract zero predicate.

`CzetaStrip` (`CriticalZeta.lean`) is `ζ(s) = η(s)/(1 − 2^{1−s})` on `0 < Re s < 1`, but its value
carries per-point convergence data (the strip/imaginary bounds, the geometric block-decay witness
`hblk`, the denominator non-vanishing witness `k`/`hk`). That data is what blocks a one-line
`Complex → Prop` zero set. THIS FILE removes the blocker the honest way — by BUNDLING the convergence
certificate into the zero object itself: a `NontrivialZero` is a strip point together with its
convergence data and a proof that the constructed `ζ` vanishes there. The zero set is then clean, and

    `RiemannHypothesisStrip := ∀ Z : NontrivialZero, Re Z.s = ½`

is the genuine RH for the ζ this repository builds — a named, typed object, formalized as the open
statement it is (NOT proved; nothing here exhibits a zero or locates one — that is RH). It ties the
abstract `AllZerosOnLine` of the witness pipeline to the actual constructed ζ.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`. Defines the open statement; proves nothing about where the zeros are.
-/

import F1Square.Analysis.CriticalZeta
import F1Square.Analysis.ZeroGeometry

namespace UOR.Bridge.F1Square.Analysis

/-- **A nontrivial zero of the constructed critical-strip ζ**: a strip point `s`, its convergence
    certificate (the `CzetaStrip` preconditions — strip bound `sb`, imaginary cutoff `T`, the
    geometric block-decay `hblk`, the denominator non-vanishing `k`/`hk`), and a proof that the
    constructed `ζ` vanishes at `s`. Bundling the per-point data makes the zero set a clean object. -/
structure NontrivialZero where
  s : Complex
  sb : Q
  T : Q
  hsbd : 0 < sb.den
  hsb0 : 0 ≤ sb.num
  hTd : 0 < T.den
  hT0 : 0 ≤ T.num
  hσ : Rnonneg s.re
  hsb : Rle s.re (ofQ sb hsbd)
  hT1 : Rle (Rneg (ofQ T hTd)) s.im
  hT2 : Rle s.im (ofQ T hTd)
  τ : Q
  hτn : 0 < τ.num
  hτd : 0 < τ.den
  hblk : ∀ k, 1 ≤ k → Rle (Rsub (EtaVSum s T hTd (2 ^ (k + 1))) (EtaVSum s T hTd (2 ^ k)))
      (ofQ (mul (Vconst sb T) (qpow (Qinv (add ⟨1, 1⟩ τ)) k))
        (Qmul_den_pos (Vconst_den_pos hsbd hTd)
          (qpow_den_pos (Qinv_den_pos (by simp only [add]; push_cast; omega)) k)))
  k : Nat
  hk : Qlt (Qbound k) ((CnormSq (etaDenom s)).seq k)
  vanishes : Ceq (CzetaStrip s hsbd hsb0 hTd hT0 hσ hsb hT1 hT2 hτn hτd hblk k hk) Czero

/-- The complex point of a nontrivial zero. -/
def NontrivialZero.point (Z : NontrivialZero) : Complex := Z.s

/-- The zero set of the constructed ζ, as a clean predicate on `Complex`. -/
def isZeroOfZeta (z : Complex) : Prop := ∃ Z : NontrivialZero, Ceq Z.s z

/-- **THE GENUINE RIEMANN HYPOTHESIS for the constructed ζ**: every nontrivial zero of `CzetaStrip`
    lies on the critical line `Re s = ½`. The open statement, named and typed — formalized AS the
    unproven object it is; nothing here proves it, exhibits a zero, or locates one. -/
def RiemannHypothesisStrip : Prop := ∀ Z : NontrivialZero, OnCriticalLine Z.s

/-- **RH-strip is exactly `AllZerosOnLine` of the constructed zero set** — the bridge tying the
    abstract `AllZerosOnLine` hypothesis of the witness/BL pipeline to the genuine zeros of the ζ this
    repository constructs. (`OnCriticalLine` is `Re = ½`, congruent along `Ceq`.) -/
theorem riemannHypothesisStrip_iff :
    RiemannHypothesisStrip ↔ AllZerosOnLine isZeroOfZeta := by
  constructor
  · intro h z hz
    obtain ⟨Z, hZ⟩ := hz
    exact Req_trans (Req_symm hZ.1) (h Z)
  · intro h Z
    exact h Z.s ⟨Z, Ceq_refl Z.s⟩

end UOR.Bridge.F1Square.Analysis
