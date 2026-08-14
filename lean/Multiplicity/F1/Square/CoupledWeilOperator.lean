/-
F1 square — **the coupled Weil kernel as a self-adjoint operator** (`CoupledWeilOperator.lean`):
placing the off-diagonal `coupledWeil arch w v M` into the step-3 operator/Hilbert layer
(`SelfAdjoint.lean`). The multiplier form `multForm α` was the layer's DIAGONAL self-adjoint instance
(`multForm_self_adjoint`); this file adds the genuinely off-diagonal coupled kernel as the next
self-adjoint operator — the language the doc states "the band-coupling positivity (step 4) has to be
phrased in."

THE LAWS (all genuine, kernel-checked):
  • `coupledWeil_sym` — the coupled kernel is a symmetric kernel (`SymKernel`): `multForm arch`
    (`multForm_sym`) minus the symmetric prime Gram (`primeGram_sym`).
  • `coupledWeil_self_adjoint` — hence a self-adjoint operator on the pre-Hilbert space,
    `⟨(coupledWeil …)·c, d⟩_N ≈ ⟨c, (coupledWeil …)·d⟩_N` (`applyN_self_adjoint`).
  • `coupledWeil_quad_eq_inner` — its Weil quadratic form IS the inner product against its operator
    action, `weilQuad (coupledWeil …) c N ≈ ⟨c, (coupledWeil …)·c⟩_N` (`weilQuad_eq_inner`), so the
    `WeilPSD` form-language and the operator language coincide on the coupled kernel.

HONEST SCOPE. Pure operator algebra on the assembled object; abstract over interface data
`arch, w, v` (no `λ`, no zeros). Self-adjointness is a STRUCTURAL property (it holds for every
symmetric kernel, definite or not) — it does NOT bear on positivity; the coupled kernel's `WeilPSD`
(= dominance = RH) stays exactly as open as before. This makes the coupled kernel a first-class
self-adjoint operator in the Hilbert layer, the setting a spectral/positivity argument for step 4 runs
in. Crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1Square.Square.CoupledWeilKernel
import Multiplicity.F1Square.Square.SelfAdjoint

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The coupled kernel is symmetric** (`SymKernel`): `multForm arch` (`multForm_sym`) minus the
    symmetric prime Gram (`primeGram_sym`). -/
theorem coupledWeil_sym (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat) :
    SymKernel (coupledWeil arch w v M) :=
  fun i j => Rsub_congr (multForm_sym arch i j) (primeGram_sym w v M i j)

/-- **The coupled kernel is a self-adjoint operator**: `⟨(coupledWeil …)·c, d⟩_N ≈
    ⟨c, (coupledWeil …)·d⟩_N` — the off-diagonal step-4 companion of `multForm_self_adjoint`. -/
theorem coupledWeil_self_adjoint (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (c d : Nat → Real) (N : Nat) :
    Req (innerN (applyN (coupledWeil arch w v M) c N) d N)
        (innerN c (applyN (coupledWeil arch w v M) d N) N) :=
  applyN_self_adjoint (coupledWeil_sym arch w v M) c d N

/-- **The coupled Weil quadratic form is the inner product against the coupled operator action**:
    `weilQuad (coupledWeil …) c N ≈ ⟨c, (coupledWeil …)·c⟩_N`. The `WeilPSD` form-language and the
    operator language of the Hilbert layer coincide on the coupled kernel. -/
theorem coupledWeil_quad_eq_inner (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (c : Nat → Real) (N : Nat) :
    Req (weilQuad (coupledWeil arch w v M) c N)
        (innerN c (applyN (coupledWeil arch w v M) c N) N) :=
  weilQuad_eq_inner (coupledWeil arch w v M) c N

end Multiplicity.UOR.Bridge.F1Square.Square
