/-
F1 square — **the moment problem is well-posed** (`MomentProblemWellPosed.lean`), the capstone of the
moment-realization sub-arc. It packages the two halves the sub-arc built — conditional *existence* and
completion-level *uniqueness* — into the single statement they were aiming at: a rational sequence
carrying a Bessel modulus is the moment sequence of a **unique** completed `L²` element.

  `besselSeq_realizes_unique`   :  any `L²` element with the same moments as the realized one equals it;
  `moment_problem_wellposed`    :  existence ∧ uniqueness — `μ` (with a rational Bessel modulus) is
                                   realized by the completed element `E`, and every completed element
                                   with those moments is `E`.

Existence is `besselSeq_realizes_of_modulus` (the coda's conditional realization); uniqueness is
`L2Elt_moment_eq_imp_eq` (the completion-level injectivity of the moment map, already proved via the
completed Bernstein arc). The composition is a two-line splice — no new analysis — but it is the honest
headline: the moment map is a *bijection* between valid rational sequences (those carrying the modulus)
and completed `L²` elements, the constructive Hausdorff moment theorem for this class.

HONEST SCOPE. **Conditional**, unchanged: existence rests on the supplied rational Bessel modulus (an
audit-visible hypothesis, never an axiom, never asserted for a particular `μ`); uniqueness is
unconditional. This well-posedness is classical measure-theoretic content about the *moment map*, NOT
surjectivity onto arbitrary sequences, and NOT positivity of any crux form. Step 4 (band-coupling
positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1Square.Square.BesselCauchyModulus
import Multiplicity.F1Square.Square.PairingMomentInjective

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The completed `L²` element the modulus realizes `μ` on (abbreviation for readability). -/
private def realizedElt (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den)
    (hmod : ∀ j k, Qle (besselDiffNorm μ hμ j k)
      (mul (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)) (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)))) :
    L2Elt :=
  ⟨besselSeq μ hμ, besselSeq_L2CauchyU μ hμ hmod⟩

/-- **★ UNIQUENESS**: any completed `L²` element whose moments are `ofQ (μ n)` equals the realized one —
    the realized element is the *unique* solution of the moment problem for `μ`. -/
theorem besselSeq_realizes_unique (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den)
    (hmod : ∀ j k, Qle (besselDiffNorm μ hμ j k)
      (mul (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)) (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))))
    (F : L2Elt) (hF : ∀ n, Req (F.moment n) (ofQ (μ n) (hμ n))) :
    F.eq (realizedElt μ hμ hmod) :=
  L2Elt_moment_eq_imp_eq F (realizedElt μ hμ hmod)
    (fun i => Req_trans (hF i) (Req_symm (besselSeq_realizes_of_modulus μ hμ hmod i)))

/-- **★ THE MOMENT PROBLEM IS WELL-POSED**: for a rational sequence `μ` carrying a Bessel modulus there is
    a completed `L²` element `E` realizing it (`⟨E, xⁿ⟩ = ofQ (μ n)` for all `n`), and every completed
    element with those moments is `E`. Existence (conditional) ∧ uniqueness — the moment map is a
    bijection on this class. -/
theorem moment_problem_wellposed (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den)
    (hmod : ∀ j k, Qle (besselDiffNorm μ hμ j k)
      (mul (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)) (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)))) :
    (∀ n, Req ((realizedElt μ hμ hmod).moment n) (ofQ (μ n) (hμ n))) ∧
    (∀ F : L2Elt, (∀ n, Req (F.moment n) (ofQ (μ n) (hμ n))) → F.eq (realizedElt μ hμ hmod)) :=
  ⟨fun n => besselSeq_realizes_of_modulus μ hμ hmod n,
   fun F hF => besselSeq_realizes_unique μ hμ hmod F hF⟩

end Multiplicity.UOR.Bridge.F1Square.Square
