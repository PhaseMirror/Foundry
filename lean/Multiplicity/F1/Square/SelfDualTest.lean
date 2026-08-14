/-
F1 square — **the self-dual (Mellin-even) test class** (`SelfDualTest.lean`): the Connes–Consani test
class the Sonine/autocorrelation construction needs — tests invariant under the multiplicative
inversion `g^τ(x) = g(1/x)`, built by symmetrization and certified self-dual via the reflection
involution.

    `selfDualTest a φ := φ + reflectTest a φ`,   `logPull (reflectTest a (selfDualTest a φ)) u ≈
     logPull (selfDualTest a φ) u`   (on the reciprocal-symmetric window `a ≤ exp u ≤ 1/a`).

WHY (the self-dual arm). The autocorrelation `g ⋆ g^τ` and the reflection symmetry `M[g^τ](s) = M[g](−s)`
collapse to `M[g^τ] = M[g]` exactly on the SELF-DUAL tests (`g^τ ≈ g`), for which the moment identity
that matches `weilPrimeGram (vHat g)` to the genuine autocorrelation prime side becomes a CONGRUENCE
rather than a change of variables. This file builds that class and proves its defining symmetry — the
direct payoff of the reflection involution (`logPull_reflect_involutive`).

The construction is symmetrization: `reflectTest` and `logPull` both distribute over `L2Test.add`
DEFINITIONALLY (`.f` is the pointwise sum), so
`logPull (reflectTest a (φ + reflectTest a φ)) u = logPull (reflectTest a φ) u + logPull (reflectTest²φ) u`
and the involution `logPull (reflectTest²φ) u ≈ logPull φ u` plus `Radd_comm` returns
`logPull φ u + logPull (reflectTest a φ) u = logPull (selfDualTest a φ) u`. No change of variables.

HONEST SCOPE. The self-dual test class and its defining symmetry ON THE WINDOW (where the floor clamp
is inert both ways). It is NOT the reflected Mellin MOMENT identity `M[reflectTest g](m) = M[g](m)` —
that still needs the moment-congruence wired through `innerI`/`mellinMoment` and the boundary handling
outside the window (the `[0, a)` clamp region the `[0,1]` moment sees) — NOT the autocorrelation
identification, and applies NO step-4 positivity (`ArchDominatesPrime`), which is RH. The crux fields
stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.LogReflect
import Multiplicity.F1Square.Analysis.IntegralBilinear

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The self-dual (Mellin-even) test** `selfDualTest a φ := φ + reflectTest a φ` — the symmetrization
    of `φ` under the multiplicative inversion `g ↦ g^τ`. On the reciprocal-symmetric window it is
    invariant under `reflectTest` (`logPull_selfDualTest_self_dual`); the Connes–Consani test class the
    autocorrelation self-dual arm is built on. -/
def selfDualTest (a : Q) (han : 0 < a.num) (had : 0 < a.den) (φ : L2Test) : L2Test :=
  L2Test.add φ (reflectTest a han had φ)

/-- **The symmetrization is self-dual on the window**: `logPull (reflectTest a (selfDualTest a φ)) u ≈
    logPull (selfDualTest a φ) u` on `a ≤ exp u ≤ 1/a` (the involution's two window conditions). Both
    `reflectTest` and `logPull` distribute over `+` definitionally, so the left side is
    `logPull (reflectTest a φ) u + logPull (reflectTest²φ) u`; the involution collapses the second summand
    to `logPull φ u` and `Radd_comm` reorders to `logPull (selfDualTest a φ) u`. -/
theorem logPull_selfDualTest_self_dual (a : Q) (han : 0 < a.num) (had : 0 < a.den) (φ : L2Test)
    (u : Real) {kx : Nat} (hkx : Qlt (Qbound kx) ((RexpReal u).seq kx))
    (hx : Rle (ofQ a had) (RexpReal u))
    {kx2 : Nat} (hkx2 : Qlt (Qbound kx2) ((RexpReal (Rneg u)).seq kx2))
    (hx2 : Rle (ofQ a had) (RexpReal (Rneg u))) :
    Req (logPull (reflectTest a han had (selfDualTest a han had φ)) u)
        (logPull (selfDualTest a han had φ) u) := by
  show Req (Radd (logPull (reflectTest a han had φ) u)
             (logPull (reflectTest a han had (reflectTest a han had φ)) u))
           (Radd (logPull φ u) (logPull (reflectTest a han had φ) u))
  exact Req_trans
    (Radd_congr (Req_refl _) (logPull_reflect_involutive a han had φ u hkx hx hkx2 hx2))
    (Radd_comm (logPull (reflectTest a han had φ) u) (logPull φ u))

end Multiplicity.UOR.Bridge.F1Square.Square
