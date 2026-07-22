/-
F1 square — Track 1, item 3: **refining the `CompletedZetaFE` seam through Riemann's symmetric
formula.** `Cxi_functional_equation` (`ComplexXiFE.lean`) reduces `ξ(s)=ξ(1−s)` to the single seam
`CompletedZetaFE : Z(s)=Z(1−s)`, `Z(s)=π^{−s/2}Γ(s/2)ζ(s)`. The classical proof of that seam is
Riemann's symmetric formula

    Z(s) = −1/s − 1/(1−s) + ∫₁^∞ (t^{s/2−1} + t^{(1−s)/2−1}) ψ(t) dt,

whose right side is *manifestly* `s↔1−s`-symmetric: the boundary `−1/s−1/(1−s)` swaps its two terms,
and the symmetric Mellin integral is invariant under swapping the two exponents
(`thetaMellinPowSym_symm`, `ThetaMellinPow.lean`). This file discharges the **mechanical half** of that
argument and isolates the analytic atom:

  • `boundaryTerm_symm` — the boundary `−1/s−1/(1−s)` is `s↔1−s`-symmetric, *unconditionally*
    (`Cadd_comm` + `Cinv_congr` through the involution `oneSub_oneSub`).
  • `CompletedZetaFE_of_MellinRep` — `CompletedZetaFE` follows from the Mellin representation
    (`Z(s) = boundary(s) + Isym`, `Z(1−s) = boundary(1−s) + Isym'`) together with the integral swap
    symmetry `Isym ≈ Isym'`. Realization-independent in the factor values (like
    `Cxi_functional_equation`), so it composes with any discharge of the representation.

This refines the single `CompletedZetaFE` seam into **[Riemann's representation] + [integral swap
symmetry]**, with the boundary algebra fully proven and the swap symmetry already constructive
(`thetaMellinPowSym_symm`) for real exponents; what remains is the representation itself — the genuine
Mellin/Poisson atom (per-term Gamma integral + the `t↦1/t` modular split).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.ComplexXiFE
import Core.F1.Analysis.ComplexZetaConj

namespace UOR.Bridge.F1Square.Analysis

/-- **The boundary term** `−1/s − 1/(1−s)` of Riemann's symmetric formula, with the two `Cinv`
    positivity witnesses (`s ≠ 0` via `ks`, `1−s ≠ 0` via `k1`) explicit. -/
def boundaryTerm (s : Complex) (ks : Nat) (hks : Qlt (Qbound ks) ((CnormSq s).seq ks))
    (k1 : Nat) (hk1 : Qlt (Qbound k1) ((CnormSq (oneSub s)).seq k1)) : Complex :=
  Cadd (Cneg (Cinv s ks hks)) (Cneg (Cinv (oneSub s) k1 hk1))

/-- **The boundary term is `s↔1−s`-symmetric**, unconditionally: `−1/s−1/(1−s) ≈ −1/(1−s)−1/(1−(1−s))`.
    `Cadd_comm` swaps the two summands; the second pairs `−1/(1−(1−s))` with `−1/s` through the
    reflection involution `oneSub_oneSub` (`1−(1−s) ≈ s`) under `Cinv_congr`. The witnesses of the
    `(1−s)` form (`k1', hks'`) are taken as given; they exist because `|1−(1−s)|² ≈ |s|²`. -/
theorem boundaryTerm_symm (s : Complex)
    (ks : Nat) (hks : Qlt (Qbound ks) ((CnormSq s).seq ks))
    (k1 : Nat) (hk1 : Qlt (Qbound k1) ((CnormSq (oneSub s)).seq k1))
    (k1' : Nat) (hk1' : Qlt (Qbound k1') ((CnormSq (oneSub s)).seq k1'))
    (ks' : Nat) (hks' : Qlt (Qbound ks') ((CnormSq (oneSub (oneSub s))).seq ks')) :
    Ceq (boundaryTerm s ks hks k1 hk1) (boundaryTerm (oneSub s) k1' hk1' ks' hks') := by
  unfold boundaryTerm
  refine Ceq_trans (Cadd_comm (Cneg (Cinv s ks hks)) (Cneg (Cinv (oneSub s) k1 hk1))) ?_
  exact Cadd_congr
    (Cneg_congr (Cinv_congr k1 hk1 k1' hk1' (Ceq_refl (oneSub s))))
    (Cneg_congr (Cinv_congr ks hks ks' hks' (Ceq_symm (oneSub_oneSub s))))

/-- **`CompletedZetaFE` from Riemann's symmetric formula** — the mechanical bridge. Given the Mellin
    representation `Z(s) = boundary(s) + Isym` and `Z(1−s) = boundary(1−s) + Isym'`, together with the
    integral swap symmetry `Isym ≈ Isym'` (discharged constructively by `thetaMellinPowSym_symm` for the
    real Mellin exponents `e₁=s/2−1`, `e₂=(1−s)/2−1`), the functional equation `Z(s)=Z(1−s)` follows:
    both sides equal `boundary(s) + Isym` after the proven `boundaryTerm_symm`. Realization-independent
    in `gs,zs,g₁,z₁` (matching `Cxi_functional_equation`), so it composes with any discharge of the
    representation. This reduces the `CompletedZetaFE` seam to **the representation `hrep`/`hrep'`** (the
    Mellin/Poisson atom) — the boundary algebra and the swap symmetry are now off the seam. -/
theorem CompletedZetaFE_of_MellinRep (s gs zs g₁ z₁ : Complex)
    (ks : Nat) (hks : Qlt (Qbound ks) ((CnormSq s).seq ks))
    (k1 : Nat) (hk1 : Qlt (Qbound k1) ((CnormSq (oneSub s)).seq k1))
    (k1' : Nat) (hk1' : Qlt (Qbound k1') ((CnormSq (oneSub s)).seq k1'))
    (ks' : Nat) (hks' : Qlt (Qbound ks') ((CnormSq (oneSub (oneSub s))).seq ks'))
    (Isym Isym' : Complex)
    (hrep : Ceq (completedZeta s gs zs) (Cadd (boundaryTerm s ks hks k1 hk1) Isym))
    (hrep' : Ceq (completedZeta (oneSub s) g₁ z₁)
      (Cadd (boundaryTerm (oneSub s) k1' hk1' ks' hks') Isym'))
    (hIsym : Ceq Isym Isym') :
    CompletedZetaFE s gs zs g₁ z₁ :=
  Ceq_trans hrep
    (Ceq_trans
      (Cadd_congr (boundaryTerm_symm s ks hks k1 hk1 k1' hk1' ks' hks') hIsym)
      (Ceq_symm hrep'))

end UOR.Bridge.F1Square.Analysis
