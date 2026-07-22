/-
F1 square — Track 1, item 3: the **theta modular relation as a labelled seam** — the single
Poisson-summation atom the completed-zeta functional equation rests on, now *expressible* in the
constructive language (it was not before: it needs the theta function below `t = 1`, `thetaFnPos`,
and the real-radicand square root `RsqrtReal`, both built in this layer).

For the half theta `ψ(t) = Σ_{n≥1} e^{−πn²t}` the Jacobi modular transformation is
`ψ(1/t) = (√t − 1)/2 + √t·ψ(t)` — equivalent to `ϑ(1/t) = √t·ϑ(t)` for the full theta
`ϑ = 1 + 2ψ`. We state it as a predicate `ThetaModular` (over `t ≥ 1`, its reciprocal `u = 1/t`,
and the real √), matching the program's labelled-seam style (`CompletedZetaFE`, the `HadamardXi`
seams): the genuine analytic content (Poisson summation / Gaussian self-duality) is carried as this
explicit, audit-visible hypothesis, never an axiom. The remaining bridge — the Mellin transform of
this relation yielding `CompletedZetaFE` — sits on the certified `halfLineIntegral` already built.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.ThetaFunctionPos
import Core.F1.Analysis.SqrtRealOf

namespace UOR.Bridge.F1Square.Analysis

/-- **The theta modular relation (labelled Poisson seam)** `ψ(1/t) = (√t − 1)/2 + √t·ψ(t)` for the
    half theta `ψ`, with `t ≥ 1`, `u = 1/t` (`t·u = 1`, `u ≥ 1/Dᵤ`), and `√t = RsqrtReal t`. This is
    the constructive face of Poisson summation — the one analytic atom item-3's `CompletedZetaFE`
    reduces to once the Mellin step (over `halfLineIntegral`) is carried out. -/
def ThetaModular (t u : Real) (htlo : Rle one t) (Du : Nat) (hDu : 0 < Du)
    (hu : Rle (ofQ (⟨1, Du⟩ : Q) hDu) u) (_hprod : Req (Rmul t u) one) : Prop :=
  Req (thetaFnPos u Du hDu hu)
    (Radd (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rsub (RsqrtReal t htlo) one))
          (Rmul (RsqrtReal t htlo) (thetaFn t htlo)))

end UOR.Bridge.F1Square.Analysis
