/-
F1 square — **general-window integral additivity over `L2Test.add`** (`IntervalAddTest.lean`): the
reusable brick the `Σ_m`/`∫_t` interchange (the convolution factorization's tail assembly) is built
from —

    `∫_{lo}^{lo+w} (φ + ψ)  ≈  ∫_{lo}^{lo+w} φ  +  ∫_{lo}^{lo+w} ψ`,

the interval-integral analog of `innerI_add_left` (which is `[0,1]`-fixed). All three integrands are
certified at the common modulus `φ.L + ψ.L` (where `riemannIntegralI_add` applies), and
`riemannIntegralI_certif_irrel` moves each summand back to its own canonical modulus.

This is the two-term additivity from which the finite sum `∫ Σ_{m<N} (T m) = Σ_{m<N} ∫ (T m)` follows
by induction — the interchange that turns `Σ_m [∫_t coupOut_m]` into `∫_t [Σ_m coupOut_m]`, i.e. the
convolution's tail-term sum into a single `t`-integral of the summed dilated tail.

HONEST SCOPE. Two-term interval-integral additivity over `L2Test.add`. It builds NO `Σ_m`/`∫_t`
interchange (that is the induction on top of this), NO tail assembly, NO factorization
`M[f⋆g]=M[f]·M[g]`, NO positivity, NO crux. Step 4 (band-coupling positivity) is RH; the crux fields
stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.IntegralBilinear
import Multiplicity.F1.Square.MellinLinear

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The interval integral is additive over `L2Test.add`**: `∫_{lo}^{lo+w} (φ + ψ) = ∫ φ + ∫ ψ`. The
    three integrands are weakened to the common modulus `φ.L + ψ.L` (`lip_weaken`), where
    `riemannIntegralI_add` fires; `riemannIntegralI_certif_irrel` returns each summand to its own
    modulus. The general-window analog of `innerI_add_left`. -/
theorem riemannIntegralI_addTest (φ ψ : L2Test) (lo w : Q)
    (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Req (riemannIntegralI (L2Test.add φ ψ).hLd (L2Test.add φ ψ).hLn
          (L2Test.add φ ψ).hlip (L2Test.add φ ψ).hfc lo w hlo hw hwn)
        (Radd (riemannIntegralI φ.hLd φ.hLn φ.hlip φ.hfc lo w hlo hw hwn)
              (riemannIntegralI ψ.hLd ψ.hLn ψ.hlip ψ.hfc lo w hlo hw hwn)) := by
  have hLd : 0 < (add φ.L ψ.L).den := add_den_pos φ.hLd ψ.hLd
  have hLn : 0 ≤ (add φ.L ψ.L).num := Qadd_num_nonneg_loc φ.hLn ψ.hLn
  have hlipf := lip_weaken φ.hLd hLd (Qle_self_add ψ.hLn) φ.hlip
  have hlipg := lip_weaken ψ.hLd hLd (Qle_self_add_l φ.hLn) ψ.hlip
  refine Req_trans
    (riemannIntegralI_add hLd hLn hlipf φ.hfc hlipg ψ.hfc
      (L2Test.add φ ψ).hlip (L2Test.add φ ψ).hfc lo w hlo hw hwn) ?_
  exact Radd_congr
    (riemannIntegralI_certif_irrel hLd hLn hlipf φ.hfc φ.hLd φ.hLn φ.hlip φ.hfc lo w hlo hw hwn)
    (riemannIntegralI_certif_irrel hLd hLn hlipg ψ.hfc ψ.hLd ψ.hLn ψ.hlip ψ.hfc lo w hlo hw hwn)

/-- The zero test (`f ≡ 0`), the empty-sum base of `genSumTest`. Fields chosen to match
    `riemannIntegralI_const zero` exactly, so its integral is `zero` by definitional equality. -/
def sumZeroTest : L2Test where
  f := fun _ => zero
  L := (⟨0, 1⟩ : Q)
  M := (⟨0, 1⟩ : Q)
  hLd := by decide
  hLn := by decide
  hMd := by decide
  hMn := by decide
  hlip := const_lip0 zero
  hfc := fun _ _ _ => Req_refl zero
  hbd := fun _ => Rle_of_Req Rabs_zero

/-- **The finite `L2Test.add`-sum** `Σ_{m<N} (T m)` as a single test — `.f = Σ_{m<N} (T m).f`,
    `.L = Σ (T m).L`. The base of the `Σ_m`/`∫_t` interchange. -/
def genSumTest (T : Nat → L2Test) : Nat → L2Test
  | 0 => sumZeroTest
  | (N + 1) => L2Test.add (genSumTest T N) (T N)

/-- **The `Σ_m`/`∫_t` interchange (finite):** `Σ_{m<N} ∫_{lo}^{lo+w} (T m) = ∫_{lo}^{lo+w} Σ_{m<N} (T m)`.
    By induction on `N`: the base is `∫ 0 = 0` (`riemannIntegralI_const`), the step is
    `riemannIntegralI_addTest` on `genSumTest T (N+1) = (genSumTest T N) + (T N)`. This is the interchange
    that turns the convolution's per-window tail-term sum into a single `t`-integral of the summed
    dilated tail. -/
theorem riemannIntegralI_genSumTest (T : Nat → L2Test) (lo w : Q)
    (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    ∀ N, Req (genSum (fun m => riemannIntegralI (T m).hLd (T m).hLn (T m).hlip (T m).hfc
              lo w hlo hw hwn) N)
             (riemannIntegralI (genSumTest T N).hLd (genSumTest T N).hLn (genSumTest T N).hlip
              (genSumTest T N).hfc lo w hlo hw hwn)
  | 0 => Req_symm (Req_trans (riemannIntegralI_const zero lo w hlo hw hwn) (Rmul_zero (ofQ w hw)))
  | (N + 1) =>
      Req_trans
        (Radd_congr (riemannIntegralI_genSumTest T lo w hlo hw hwn N) (Req_refl _))
        (Req_symm (riemannIntegralI_addTest (genSumTest T N) (T N) lo w hlo hw hwn))

end Multiplicity.UOR.Bridge.F1Square.Square
