/-
F1 square — **the coupled kernel welded to the genuine crux** (`CoupledWeilGenuine.lean`): connecting
the off-diagonal coupled Weil kernel to the program's central localization `atlas_crux_localization`,
so its strict diagonal dominance is tied to the GENUINE prime–archimedean coupling positivity, not a
generic induced square.

The coupled kernel's diagonal is `coupledWeil arch w v M (n,n) = arch n − primeGram(n,n)` — the Weil
value at index `n`. The explicit-formula identity is that this Weil value equals `2λₙ = −⟨Cₙ,Cₙ⟩ =
Rneg (genuineSpectralSquare E).cSq n` (the pairing dictionary, `genuineSpectralSquare_dict`). Supplying
that identity as an EXPLICIT hypothesis `hmatch` (exactly the `realizesDiag_genuine_iff` discipline —
the diagonal match is the interface, never proven; proving it is the explicit formula), the coupled
kernel's strict diagonal dominance becomes the genuine crux:

  • `coupledWeil_diag_pos_iff_genuine_crux` — under `hmatch`, `(∀n>0, Pos (coupledWeil arch w v M n n))
    ⟺ SpectralCrux (genuineSpectralSquare E)` (a `Pos_congr` on the diagonal match; `SpectralCrux` is
    `Pos (−cSq)`).
  • `coupledWeil_diag_pos_iff_genuine_coupling` — chaining through `atlas_crux_localization`, under
    `hmatch` the strict diagonal dominance is EQUIVALENT to the genuine coupling positivity
    `∀n>0, Pos (genuineArithSeq E.eta n + genuineArchSeq n)` — THE crux.

HONEST SCOPE. `hmatch` (the coupled Weil diagonal equals `2λₙ`, the explicit-formula identity) is an
EXPLICIT hypothesis, never discharged — there is no instantiation of `arch, w, v` at the genuine `ζ`
data that proves it, and even with it the strict dominance is `SpectralCrux` = RH, never asserted. This
weld only routes the coupled kernel's face into the program's central crux equivalence; it discharges
nothing. Crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.CoupledWeilKernel
import Foundations.F1.Square.AtlasCruxSynthesis

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 1000000 in
/-- **The coupled kernel's strict diagonal dominance ⟺ the genuine `SpectralCrux`**, under the
    explicit-formula diagonal match `hmatch : coupledWeil arch w v M (n,n) ≈ −⟨Cₙ,Cₙ⟩ = 2λₙ`. A
    `Pos_congr` on the match (`SpectralCrux` unfolds to `∀n>0, Pos (Rneg (·.cSq n))`). The match is
    never proven; it is the interface. -/
theorem coupledWeil_diag_pos_iff_genuine_crux (E : StieltjesEta)
    (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (hmatch : ∀ n, 0 < n →
      Req (coupledWeil arch w v M n n) (Rneg ((genuineSpectralSquare E).cSq n))) :
    (∀ n, 0 < n → Pos (coupledWeil arch w v M n n)) ↔ SpectralCrux (genuineSpectralSquare E) := by
  constructor
  · intro h n hn; exact Pos_congr (hmatch n hn) (h n hn)
  · intro h n hn; exact Pos_congr (Req_symm (hmatch n hn)) (h n hn)

set_option maxHeartbeats 1000000 in
/-- **★ THE GENUINE WELD**: under the explicit-formula diagonal match, the coupled kernel's strict
    diagonal dominance is EQUIVALENT to the genuine prime–archimedean coupling positivity
    `∀n>0, Pos (genuineArithSeq E.eta n + genuineArchSeq n)` — THE crux (`atlas_crux_localization`).
    Nothing here asserts either side. -/
theorem coupledWeil_diag_pos_iff_genuine_coupling (E : StieltjesEta)
    (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (hmatch : ∀ n, 0 < n →
      Req (coupledWeil arch w v M n n) (Rneg ((genuineSpectralSquare E).cSq n))) :
    (∀ n, 0 < n → Pos (coupledWeil arch w v M n n))
      ↔ (∀ n, 0 < n → Pos (Radd (genuineArithSeq E.eta n) (genuineArchSeq n))) :=
  Iff.trans (coupledWeil_diag_pos_iff_genuine_crux E arch w v M hmatch)
    (atlas_crux_localization E).2.1

set_option maxHeartbeats 1000000 in
/-- **★ THE EXPLICIT-FORMULA DECOMPOSITION, kernel-explicit**: under the diagonal match `hmatch`, the
    Li coefficient is exactly the archimedean multiplier MINUS the prime Gram diagonal —
    `2λₙ = arch n − primeGram(n,n)` for all `n > 0`. This is why `2λₙ` is not manifestly a sum of
    squares: its intrinsic expression is a DIFFERENCE of the two PSD-form diagonals (arch spectral,
    prime Gram), so a `RealizesDiag` Euclidean embedding (`gramOf ι D n n = 2λₙ`, a pure SOS) exists
    only when the arch diagonal dominates the prime — which is RH. Ties the coupled kernel (step 4) to
    the discharge form. `hmatch` is never discharged; the crux stays `none`. -/
theorem genuineLam_eq_arch_sub_prime (E : StieltjesEta)
    (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (hmatch : ∀ n, 0 < n →
      Req (coupledWeil arch w v M n n) (Rneg ((genuineSpectralSquare E).cSq n))) :
    ∀ n, 0 < n → Req (Radd (genuineLamSeq E.eta n) (genuineLamSeq E.eta n))
                     (Rsub (arch n) (primeGram w v M n n)) := by
  intro n hn
  -- 2λ ≈ −cSq  (dict: cSq = −2λ)
  have h2lam : Req (Radd (genuineLamSeq E.eta n) (genuineLamSeq E.eta n))
      (Rneg ((genuineSpectralSquare E).cSq n)) :=
    Req_symm (Req_trans (Rneg_congr (genuineSpectralSquare_dict E n)) (Rneg_Rneg _))
  -- −cSq ≈ coupledWeil n n  (hmatch)
  have hc : Req (Rneg ((genuineSpectralSquare E).cSq n)) (coupledWeil arch w v M n n) :=
    Req_symm (hmatch n hn)
  -- coupledWeil n n ≈ arch n − primeGram(n,n)  (multForm diagonal)
  have hd : Req (coupledWeil arch w v M n n) (Rsub (arch n) (primeGram w v M n n)) := by
    show Req (Rsub (multForm arch n n) (primeGram w v M n n))
             (Rsub (arch n) (primeGram w v M n n))
    rw [multForm_diag]
    exact Req_refl _
  exact Req_trans h2lam (Req_trans hc hd)

end Multiplicity.UOR.Bridge.F1Square.Square
