/-
F1 square — **the constructive Bessel modulus: making the Riesz–Fischer input rational**
(`BesselCauchyModulus.lean`), the coda of the moment-realization sub-arc. `besselSeq_L2Elt_moment`
(brick `MomentRealize`) realizes a moment sequence `μ` *under* the hypothesis `L2CauchyU (besselSeq μ)`
— an opaque real-analytic condition. This brick discharges that hypothesis to a **checkable rational
condition** on the Riesz projections themselves: a modulus bounding their squared `ℚ`-distances by the
completion's rate.

  `besselDiffNorm μ j k`     :  `qHil (p_j − p_k) (p_j − p_k) (j+k+1)` — the *rational* squared distance
                                of the `j`-th and `k`-th Riesz projections (at the canonical dimension);
  `besselSeq_L2CauchyU`      :  a rational modulus `besselDiffNorm μ j k ≤ (1/(j+1)+1/(k+1))²` gives the
                                real `L2CauchyU (besselSeq μ)`;
  `besselSeq_realizes_of_modulus` :  the composed statement — a `μ` with such a rational modulus is
                                realized by a completed `L²` element, `⟨E, xⁿ⟩ = ofQ (μ n)` for all `n`.

The squared distance is a `ℚ`-value read off `besselSeq_dist2I`, so `Rle_ofQ_ofQ` turns the rational
bound directly into the real Cauchy bound. This is the honest constructive Riesz–Fischer input: not the
opaque `L2CauchyU`, but the statement that the Bessel/Gram data of the projections is `ℚ`-Cauchy at the
framework rate — a condition one can *exhibit* for a given `μ`.

HONEST SCOPE. **Conditional**, unchanged: the modulus is a supplied, audit-visible hypothesis (never an
axiom, never asserted for a particular `μ`); this brick only makes its shape rational and checkable. This
is the constructive Hausdorff sufficiency for sequences carrying the certificate — NOT surjectivity onto
arbitrary sequences, NOT positivity. Step 4 (band-coupling positivity) is RH; the crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1Square.Square.BesselSeqDist
import Multiplicity.F1Square.Square.MomentRealize

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The **rational squared `L²`-distance** of the `j`-th and `k`-th Riesz projections, read at the
    canonical common dimension `j+k+1` — the exact `ℚ`-value that `besselSeq_dist2I` embeds. -/
def besselDiffNorm (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den) (j k : Nat) : Q :=
  qHil (fun i => Qsub (pVec μ (j + k + 1) gsFam j i) (pVec μ (j + k + 1) gsFam k i))
       (fun i => Qsub (pVec μ (j + k + 1) gsFam j i) (pVec μ (j + k + 1) gsFam k i)) (j + k + 1)

theorem besselDiffNorm_den (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den) (j k : Nat) :
    0 < (besselDiffNorm μ hμ j k).den :=
  qHil_den_pos _ _
    (fun i => add_den_pos (pVec_den μ (j + k + 1) gsFam gsFam_den hμ j i)
      (neg_den_pos (pVec_den μ (j + k + 1) gsFam gsFam_den hμ k i)))
    (fun i => add_den_pos (pVec_den μ (j + k + 1) gsFam gsFam_den hμ j i)
      (neg_den_pos (pVec_den μ (j + k + 1) gsFam gsFam_den hμ k i))) (j + k + 1)

/-- **★ THE RATIONAL RIESZ–FISCHER INPUT**: a `ℚ`-modulus bounding the projections' squared distances by
    the completion's rate `(1/(j+1)+1/(k+1))²` produces the real Cauchy certificate `L2CauchyU`. -/
theorem besselSeq_L2CauchyU (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den)
    (hmod : ∀ j k, Qle (besselDiffNorm μ hμ j k)
      (mul (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)) (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)))) :
    L2CauchyU (besselSeq μ hμ) := by
  intro j k
  refine Rle_trans (Rle_of_Req
    (besselSeq_dist2I μ hμ j k (j + k + 1) (by omega) (by omega))) ?_
  exact Rle_ofQ_ofQ (besselDiffNorm_den μ hμ j k)
    (Qmul_den_pos (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
      (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))) (hmod j k)

/-- **★ REALIZATION FROM A RATIONAL MODULUS**: a moment sequence `μ` whose Riesz projections satisfy the
    rational Bessel modulus is realized by a completed `L²` element — `⟨E, xⁿ⟩ = ofQ (μ n)` for every
    `n`. The end-to-end constructive Hausdorff sufficiency with a checkable hypothesis. -/
theorem besselSeq_realizes_of_modulus (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den)
    (hmod : ∀ j k, Qle (besselDiffNorm μ hμ j k)
      (mul (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)) (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))))
    (n : Nat) :
    Req ((⟨besselSeq μ hμ, besselSeq_L2CauchyU μ hμ hmod⟩ : L2Elt).moment n) (ofQ (μ n) (hμ n)) :=
  besselSeq_L2Elt_moment μ hμ (besselSeq_L2CauchyU μ hμ hmod) n

end Multiplicity.UOR.Bridge.F1Square.Square
