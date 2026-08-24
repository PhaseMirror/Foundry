/-
F1 square — **window-moment reflection symmetry of the self-dual class** (`WindowMomentReflect.lean`):
the moment-integral analog of Milestone A's autocorrelation congruence. For a self-dual test
`g = selfDualTest a φ` and a window `[lo,lo+w] ⊆ [a,1/a]`,

    `∫_{lo}^{lo+w} (reflectTest a g)·t^m dt  ≈  ∫_{lo}^{lo+w} g·t^m dt`.

`reflectTest a g ≈ g` pointwise on the window (`selfDualTest_self_dual_pointwise`), so
`riemannIntegralI_congr_unit_mod` (different Lipschitz moduli — `reflectTest` carries `(1/a)²`) swaps the
reflected weight for the plain one against `powTest m`. NO change of variables, NO case-split (every
sample point is `≥ a`).

HONEST SCOPE. The window-moment reflection symmetry only. Composed with the support collapse
`∫_{[a,1]} = mellinMoment` it will give the reflection MOMENT identity `M[reflectTest a g] = M[g]`
(Milestone B sub-goal 1). It is NOT the convolution factorization, and the SYMMETRIC transform Gram
identification `weilPrimeGram (vHat g) = Σ Λ·M[g_i⋆g_j^τ]` remains blocked by the f-side window wall
(`mellinHat(g_i) ≠ mellinMoment(g_i)` for straddling support). Applies NO step-4 positivity
(`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.SelfDualPointwise
import Multiplicity.F1.Square.TwTermPowBand
import Multiplicity.F1.Square.TestAlgebra

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Window-moment reflection symmetry of the self-dual class**: `∫_{[lo,lo+w]}(reflectTest a g)·t^m =
    ∫_{[lo,lo+w]} g·t^m` for `g = selfDualTest a φ` and `[lo,lo+w] ⊆ [a,1/a]`. One
    `riemannIntegralI_congr_unit_mod` fed by `selfDualTest_self_dual_pointwise`; the moment-integral
    twin of `autocorr_selfDual_eq_conv`. -/
theorem windowMoment_reflect_selfDual (a : Q) (han : 0 < a.num) (had : 0 < a.den) (φ : L2Test)
    (m : Nat) (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (halo : Qle a lo) (hhi : Qle (add lo w) (Qinv a)) :
    Req (riemannIntegralI
          (L2Test.mul (reflectTest a han had (selfDualTest a han had φ)) (powTest m)).hLd
          (L2Test.mul (reflectTest a han had (selfDualTest a han had φ)) (powTest m)).hLn
          (L2Test.mul (reflectTest a han had (selfDualTest a han had φ)) (powTest m)).hlip
          (L2Test.mul (reflectTest a han had (selfDualTest a han had φ)) (powTest m)).hfc
          lo w hlo hw hwn)
        (riemannIntegralI
          (L2Test.mul (selfDualTest a han had φ) (powTest m)).hLd
          (L2Test.mul (selfDualTest a han had φ) (powTest m)).hLn
          (L2Test.mul (selfDualTest a han had φ) (powTest m)).hlip
          (L2Test.mul (selfDualTest a han had φ) (powTest m)).hfc
          lo w hlo hw hwn) := by
  refine riemannIntegralI_congr_unit_mod
    (L2Test.mul (reflectTest a han had (selfDualTest a han had φ)) (powTest m)).hLd
    (L2Test.mul (reflectTest a han had (selfDualTest a han had φ)) (powTest m)).hLn
    (L2Test.mul (reflectTest a han had (selfDualTest a han had φ)) (powTest m)).hlip
    (L2Test.mul (reflectTest a han had (selfDualTest a han had φ)) (powTest m)).hfc
    (L2Test.mul (selfDualTest a han had φ) (powTest m)).hLd
    (L2Test.mul (selfDualTest a han had φ) (powTest m)).hLn
    (L2Test.mul (selfDualTest a han had φ) (powTest m)).hlip
    (L2Test.mul (selfDualTest a han had φ) (powTest m)).hfc
    lo w hlo hw hwn ?_
  intro y h0 h1
  have ht_lo : Rle (ofQ a had) (affineMap lo w hlo hw y) :=
    Rle_trans (Rle_ofQ_ofQ had hlo halo)
      (Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ hw hwn) (Rnonneg_of_Rle_zero h0)))
  have ht_hi : Rle (affineMap lo w hlo hw y) (ofQ (Qinv a) (Qinv_den_pos han)) := by
    have hwy : Rle (Rmul (ofQ w hw) y) (ofQ w hw) :=
      Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hw hwn) h1) (Rle_of_Req (Rmul_one (ofQ w hw)))
    exact Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _)) hwy)
      (Rle_trans (Rle_of_Req (Radd_ofQ_ofQ hlo hw))
        (Rle_ofQ_ofQ (add_den_pos hlo hw) (Qinv_den_pos han) hhi))
  obtain ⟨kt, hkt⟩ := Pos_of_Rle_ofQ han had ht_lo
  show Req (Rmul ((reflectTest a han had (selfDualTest a han had φ)).f (affineMap lo w hlo hw y))
             ((powTest m).f (affineMap lo w hlo hw y)))
           (Rmul ((selfDualTest a han had φ).f (affineMap lo w hlo hw y))
             ((powTest m).f (affineMap lo w hlo hw y)))
  exact Rmul_congr
    (selfDualTest_self_dual_pointwise a han had φ hkt ht_lo ht_hi)
    (Req_refl ((powTest m).f (affineMap lo w hlo hw y)))

end Multiplicity.UOR.Bridge.F1Square.Square
