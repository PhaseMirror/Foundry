/-
F1 square — **complex convergence**: `CReg`, `Clim`, `CTendsTo`, completeness, uniqueness, and the
limit congruence, lifted coordinatewise from the constructive-real completeness (`Complete.lean`,
`RlimProps.lean`).

Track 1 needs the completed `ξ` and its analytic properties (the Hadamard product, the
`CSpougeGamma → Γ` convergence as a `Ceq`, the log-derivative series). All of those are limits over
ℂ, and `ℂ = ℝ × ℝ` with componentwise Bishop equality (`Complex.lean`), so a sequence of complex
numbers converges iff both real-component sequences converge — a clean coordinatewise lift of the
v0.7.0 real completeness brick.  This file is that lift: it provides the substrate (`Clim`,
`CTendsTo`, completeness `Clim_tendsTo`, uniqueness `CTendsTo_unique`, congruence `Clim_congr`) on
which the complex series and infinite products of the remaining Track-1 stack are built.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.Complex
import Core.F1.Analysis.RlimProps

namespace UOR.Bridge.F1Square.Analysis

/-- A sequence of complex numbers is **regular** iff both its real-part and imaginary-part sequences
    are regular (the coordinatewise Cauchy condition). -/
def CReg (X : Nat → Complex) : Prop :=
  RReg (fun n => (X n).re) ∧ RReg (fun n => (X n).im)

/-- **The limit of a regular sequence of complex numbers** — the coordinatewise Bishop diagonal limit
    `Clim X := (Rlim (re ∘ X)) + i·(Rlim (im ∘ X))`. -/
def Clim (X : Nat → Complex) (h : CReg X) : Complex :=
  ⟨Rlim (fun n => (X n).re) h.1, Rlim (fun n => (X n).im) h.2⟩

/-- The limit's real part is the real limit of the real parts (definitional). -/
theorem Clim_re (X : Nat → Complex) (h : CReg X) :
    (Clim X h).re = Rlim (fun n => (X n).re) h.1 := rfl

/-- The limit's imaginary part is the real limit of the imaginary parts (definitional). -/
theorem Clim_im (X : Nat → Complex) (h : CReg X) :
    (Clim X h).im = Rlim (fun n => (X n).im) h.2 := rfl

/-- **Convergence with a rate** over ℂ: `X k → L` iff both component sequences converge (with the same
    canonical `2/(k+1) + 2/(n+1)` modulus inherited from `RTendsTo`). -/
def CTendsTo (X : Nat → Complex) (L : Complex) : Prop :=
  RTendsTo (fun n => (X n).re) L.re ∧ RTendsTo (fun n => (X n).im) L.im

/-- **Completeness of ℂ**: every regular sequence of complex numbers converges to its coordinatewise
    diagonal limit — both `Rlim_tendsTo` halves. -/
theorem Clim_tendsTo (X : Nat → Complex) (h : CReg X) : CTendsTo X (Clim X h) :=
  ⟨Rlim_tendsTo (fun n => (X n).re) h.1, Rlim_tendsTo (fun n => (X n).im) h.2⟩

/-- **Limits are unique up to `≈`** over ℂ: if `X → L` and `X → L'` then `L ≈ L'` (both `RTendsTo`
    uniqueness halves). -/
theorem CTendsTo_unique {X : Nat → Complex} {L L' : Complex}
    (hL : CTendsTo X L) (hL' : CTendsTo X L') : Ceq L L' :=
  ⟨RTendsTo_unique hL.1 hL'.1, RTendsTo_unique hL.2 hL'.2⟩

/-- A convergent sequence's limit is `≈` its diagonal limit: if `X → L` then `L ≈ Clim X`. -/
theorem CTendsTo_Clim {X : Nat → Complex} {L : Complex} (h : CReg X) (hL : CTendsTo X L) :
    Ceq L (Clim X h) :=
  CTendsTo_unique hL (Clim_tendsTo X h)

/-- **Limit congruence**: pointwise-`≈` regular complex sequences have `≈` limits (both `Rlim_congr`
    halves). The workhorse for transporting a convergence result across an `≈`-equal reindexing. -/
theorem Clim_congr (X Y : Nat → Complex) (hX : CReg X) (hY : CReg Y)
    (h : ∀ j, Ceq (X j) (Y j)) : Ceq (Clim X hX) (Clim Y hY) :=
  ⟨Rlim_congr (fun n => (X n).re) (fun n => (Y n).re) hX.1 hY.1 (fun j => (h j).1),
   Rlim_congr (fun n => (X n).im) (fun n => (Y n).im) hX.2 hY.2 (fun j => (h j).2)⟩

/-- **Zero limit**: a regular complex sequence that is pointwise `≈ 0` has limit `≈ 0` (both
    `Rlim_zero` halves). The complex lift of the real `Rlim_zero` (`RlimProps.lean`), the convergence
    side of a telescoped complex series of differences vanishing — the companion of `Clim_congr`. -/
theorem Clim_zero (X : Nat → Complex) (h : CReg X) (hz : ∀ j, Ceq (X j) Czero) :
    Ceq (Clim X h) Czero :=
  ⟨Rlim_zero (fun n => (X n).re) h.1 (fun j => (hz j).1),
   Rlim_zero (fun n => (X n).im) h.2 (fun j => (hz j).2)⟩

/-- **Limit additivity** `lim (X + Y) ≈ lim X + lim Y` over ℂ — linearity of the complex Bishop limit.
    Componentwise from the real `Rlim_add` (`RlimProps.lean`): `Cadd`'s real/imaginary parts are the
    `Radd`s of the parts, so each half is one `Rlim_add`. The forced gateway to `Cseries` linearity
    (splitting a complex series into its two component series, toward the Hadamard `bl` expansion). -/
theorem Clim_add (X Y : Nat → Complex) (hX : CReg X) (hY : CReg Y)
    (hXY : CReg (fun n => Cadd (X n) (Y n))) :
    Ceq (Clim (fun n => Cadd (X n) (Y n)) hXY) (Cadd (Clim X hX) (Clim Y hY)) :=
  ⟨Rlim_add (fun j => (X j).re) (fun j => (Y j).re) hX.1 hY.1 hXY.1,
   Rlim_add (fun j => (X j).im) (fun j => (Y j).im) hX.2 hY.2 hXY.2⟩

/-- **Limit additivity, up to an approximation** `lim W ≈ lim X + lim Y` when `W ≈ X + Y` pointwise,
    over ℂ — componentwise from the real `Rlim_add_of_approx`. The generalization of `Clim_add` that
    sidesteps the fixed-modulus wall: `W`'s regularity `hW` is GIVEN (not derived from `X + Y`), so this
    applies whenever a regular sequence `W` is pointwise `≈` a sum of two convergent sequences — e.g.
    `W = CsumN (F+G)` against `CsumN F`, `CsumN G` (`Cseries_add`). -/
theorem Clim_add_of_approx (W X Y : Nat → Complex) (hX : CReg X) (hY : CReg Y) (hW : CReg W)
    (happ : ∀ j, Ceq (W j) (Cadd (X j) (Y j))) :
    Ceq (Clim W hW) (Cadd (Clim X hX) (Clim Y hY)) :=
  ⟨Rlim_add_of_approx (fun j => (W j).re) (fun j => (X j).re) (fun j => (Y j).re)
     hX.1 hY.1 hW.1 (fun j => (happ j).1),
   Rlim_add_of_approx (fun j => (W j).im) (fun j => (X j).im) (fun j => (Y j).im)
     hX.2 hY.2 hW.2 (fun j => (happ j).2)⟩

/-- **Limit negation** `lim (−X) ≈ −lim X` over ℂ — componentwise from the real `Rlim_neg`
    (`RlimProps.lean`). Unlike `Clim_add`, negation is modulus-SAFE (`Rneg` does not inflate the
    sequence index, so `RReg` is preserved exactly), but the codebase idiom still threads the
    transformed regularity `hNX` as a hypothesis (cf. `Clim_Cconj`). With `Clim_add` this gives the
    full additive-group linearity of the complex Bishop limit (subtraction in `1 − Re(·)` / `−ζ′/ζ`). -/
theorem Clim_neg (X : Nat → Complex) (hX : CReg X) (hNX : CReg (fun j => Cneg (X j))) :
    Ceq (Clim (fun j => Cneg (X j)) hNX) (Cneg (Clim X hX)) :=
  ⟨Rlim_neg (fun j => (X j).re) hX.1 hNX.1, Rlim_neg (fun j => (X j).im) hX.2 hNX.2⟩

end UOR.Bridge.F1Square.Analysis
