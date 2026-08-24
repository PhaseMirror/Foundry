/-
F1 square — **pointwise self-duality of the Mellin-even test class** (`SelfDualPointwise.lean`): the
value-level (in `t`) form of `selfDualTest`'s reflection symmetry, the version the convolution
consumes (`mulConv` integrates over `t` directly). The value-level involution
(`clampedInv_involutive`) lifts through `φ.hfc` to the pointwise involution of the reflection
operator, and then — exactly as at the `logPull` level — the symmetrization is self-dual pointwise.

    `(reflectTest a (selfDualTest a φ)).f t  ≈  (selfDualTest a φ).f t`     (`a ≤ t ≤ 1/a`, `t > 0`).

WHY (the self-dual arm). `mulConv_congr_right` needs the second-factor agreement AT THE INTEGRATION
POINTS `t` (not at `exp u`), so this pointwise form — not the `logPull` one — is what feeds it to give
`autocorr(selfDual) ≈ selfDual ⋆ selfDual`, the autocorrelation-is-self-convolution identity, WITHOUT
the nonlinear change-of-variables.

HONEST SCOPE. Pointwise reflection-involution and self-duality of `selfDualTest`, on the
reciprocal-symmetric window. NOT yet the autocorrelation identity (next brick, `mulConv_congr_right`
fed by this over the window points), NOT the Mellin-moment reconciliation, and NO step-4 positivity
(`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.ValueInvolution
import Multiplicity.F1.Square.SelfDualTest

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The reflection operator is a pointwise involution on the window**: `(reflectTest a
    (reflectTest a φ)).f t ≈ φ.f t` for `a ≤ t ≤ 1/a` — `φ.hfc` through the value-level clamped
    reciprocal involution `clampedInv²t ≈ t`. -/
theorem reflectTest_involutive_pointwise (a : Q) (han : 0 < a.num) (had : 0 < a.den) (φ : L2Test)
    {t : Real} {kt : Nat} (hkt : Qlt (Qbound kt) (t.seq kt)) (ht_lo : Rle (ofQ a had) t)
    (ht_hi : Rle t (ofQ (Qinv a) (Qinv_den_pos han))) :
    Req ((reflectTest a han had (reflectTest a han had φ)).f t) (φ.f t) :=
  φ.hfc _ _ (clampedInv_involutive a han had hkt ht_lo ht_hi)

/-- **The symmetrization is self-dual pointwise on the window**: `(reflectTest a (selfDualTest a φ)).f
    t ≈ (selfDualTest a φ).f t` for `a ≤ t ≤ 1/a`. Both `reflectTest` and `.f` distribute over the
    `L2Test.add`, so the reflected symmetrization is `(reflectTest a φ)(t) + (reflectTest²φ)(t)`; the
    pointwise involution collapses the second summand to `φ(t)` and `Radd_comm` reorders to
    `(selfDualTest a φ)(t)`. The value-level twin of `logPull_selfDualTest_self_dual`. -/
theorem selfDualTest_self_dual_pointwise (a : Q) (han : 0 < a.num) (had : 0 < a.den) (φ : L2Test)
    {t : Real} {kt : Nat} (hkt : Qlt (Qbound kt) (t.seq kt)) (ht_lo : Rle (ofQ a had) t)
    (ht_hi : Rle t (ofQ (Qinv a) (Qinv_den_pos han))) :
    Req ((reflectTest a han had (selfDualTest a han had φ)).f t)
        ((selfDualTest a han had φ).f t) := by
  show Req (Radd ((reflectTest a han had φ).f t)
             ((reflectTest a han had (reflectTest a han had φ)).f t))
           (Radd (φ.f t) ((reflectTest a han had φ).f t))
  exact Req_trans
    (Radd_congr (Req_refl _) (reflectTest_involutive_pointwise a han had φ hkt ht_lo ht_hi))
    (Radd_comm ((reflectTest a han had φ).f t) (φ.f t))

end Multiplicity.UOR.Bridge.F1Square.Square
