/-
F1 square — v0.22.0 Track 1, item 2 (the completed ξ): the archimedean **conductor factor**
`π^{−s/2}` of `ξ(s) = ½ s(s−1) π^{−s/2} Γ(s/2) ζ(s)`, as a constructive complex object.

For a *real positive base* `π` the complex power is simply `π^w = exp(w · log π)`, where `log π = Rlog_pi`
(`Pi.lean`) is already a real. So `π^{−s/2} = Cexp((−s/2) · ⟨log π, 0⟩)` — this avoids the complex
`Clog`/`Carg`/`cnormSq` of `π` entirely (no genuine `arctan`, and crucially no `Rpi²`, whose `whnf` is
infeasible — `Rpi.seq` is a deep nested-arctan computation). The factor is therefore both barrier-free
and computation-cheap (`Rlog_pi` stays an opaque atom).

With `CSpougeGammaW` (the strip-applicable `Γ(w)`, `ComplexDigamma.lean`) and `CzetaStrip`
(`CriticalZeta.lean`) in hand, this completes the factor inventory for ξ; the remaining work is the
(mechanical) product assembly and then the genuine analytic content (functional equation, order-1
bound, Hadamard) of items 3–5.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import F1Square.Analysis.ComplexExp
import F1Square.Analysis.Pi

namespace UOR.Bridge.F1Square.Analysis

/-- **`−s/2` as a complex number** `⟨−½·Re s, −½·Im s⟩`, the exponent of the conductor power. -/
def CnegHalf (s : Complex) : Complex :=
  ⟨Rneg (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) s.re),
   Rneg (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) s.im)⟩

/-- **The conductor factor `π^{−s/2}`** of ξ, a constructive complex object built as
    `exp((−s/2)·log π)` with the *real* `log π = Rlog_pi` (embedded `⟨log π, 0⟩`). No complex
    `Clog`/`Carg`/`cnormSq` of `π` — hence no `1/16` value-identity barrier and no infeasible `Rpi²`
    `whnf`; `Rlog_pi` enters as an opaque real atom. -/
def CpiPow (s : Complex) : Complex :=
  Cexp (Cmul (CnegHalf s) (ofReal Rlog_pi))

/-- `CpiPow` is non-vacuous (it is a total function — instantiated here at `s = 1`). -/
noncomputable def cpiPowWitness : Complex := CpiPow Cone

/-- **The polynomial prefactor `½·s·(s−1)`** of `ξ` (entire, cancels the pole of `ζ` at `s = 1` and the
    trivial structure at `s = 0`), a constructive complex object. -/
def CxiPoly (s : Complex) : Complex :=
  Cmul (ofReal (ofQ (⟨1, 2⟩ : Q) (by decide))) (Cmul s (Cadd s (Cneg Cone)))

/-- **The completed Riemann ξ as a product of its factors**:
    `ξ(s) = ½·s·(s−1) · π^{−s/2} · Γ(s/2) · ζ(s)`. To keep the interface clean, the two factors that
    carry heavy construction data — `Γ(s/2)` (via `CSpougeGammaW` at `s/2`, `Re(s/2) ∈ (0,½)`) and
    `ζ(s)` (via `CzetaStrip`) — are passed as already-built complex values `gammaHalf`, `zeta`; the
    polynomial `½s(s−1)` (`CxiPoly`) and the barrier-free conductor `π^{−s/2}` (`CpiPow`) are computed
    here. This is the constructive **assembly** of ξ from item-1/Track-1 pieces; the genuine analytic
    *properties* (functional equation, order-1 bound, Hadamard product — items 3–5) are separate and
    not asserted here. -/
def Cxi (s : Complex) (gammaHalf zeta : Complex) : Complex :=
  Cmul (Cmul (Cmul (CxiPoly s) (CpiPow s)) gammaHalf) zeta

/-- `Cxi` is non-vacuous (total in its factor inputs — at `s = 1` with placeholder unit factors it is
    `½·1·0·π^{−1/2}·1·1`, exhibiting the `s−1` zero that tames `ζ`'s pole). -/
noncomputable def cxiWitness : Complex := Cxi Cone Cone Cone

end UOR.Bridge.F1Square.Analysis
