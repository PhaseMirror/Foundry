/-
F1 square — **the moment realization: the L²-limit of the Riesz projections** (`MomentRealize.lean`),
the final brick of the moment-realization sub-arc (the Hausdorff *sufficiency* front). Given a moment
sequence `μ` whose Riesz projections are `L²`-Cauchy (the constructive Riesz–Fischer / Bessel condition),
the completed `L²` element they define realizes `μ`:

  `besselSeq_moment`        :  `n ≤ m  ⟹  ⟨besselSeq μ m, xⁿ⟩ = ofQ (μ n)`   (moments are eventually exact);
  `besselSeq_L2Elt_moment`  :  `L2CauchyU (besselSeq μ)  ⟹  ⟨E, xⁿ⟩ = ofQ (μ n)` for `E = ⟨besselSeq μ, ·⟩`.

The finite realization `realize_moment` makes the degree-`m` projection reproduce `μ` up to degree `m`
exactly (read through `mellinMoment_qPolyTest` and `qHil_eVec_right`); so along the completion the reads
`⟨besselSeq μ (…j…), xⁿ⟩` are *eventually equal* to `ofQ (μ n)`, and the completion's own convergence rate
(`L2Elt_converges`, `2/(j+1)`) pins the limit member's `n`-th moment to `ofQ (μ n)` (`Req_of_Rle_ofQ_all`,
reindexing `j = k+n`).

HONEST SCOPE. **Conditional.** The realization is proved *under the hypothesis* `L2CauchyU (besselSeq μ)`
— the constructive Riesz–Fischer input that the Bessel partial-norm sequence `‖p_N‖²` is Cauchy at the
completion's rate (an explicit, audit-visible hypothesis, never an axiom, and never asserted for a
particular `μ`). The necessary-side analysis (`MomentRangeNecessary`) already shows the transform's range
is confined; this is the matching sufficient direction *for sequences carrying the convergence
certificate*. This is the constructive Hausdorff sufficiency, NOT surjectivity onto arbitrary sequences,
and NOT positivity. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1Square.Square.BesselSeqDist
import Multiplicity.F1Square.Square.RieszMoment
import Multiplicity.F1Square.Square.QHilEVec
import Multiplicity.F1Square.Square.L2ElementSpace
import Multiplicity.F1Square.Analysis.ComplexZeta

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The projection's moments are eventually exact.
-- ===========================================================================

/-- **★ THE PROJECTION REALIZES `μ` UP TO ITS DEGREE**: `⟨besselSeq μ m, xⁿ⟩ = ofQ (μ n)` for `n ≤ m`.
    The finite realization identity `realize_moment` read through the moment bridge. -/
theorem besselSeq_moment (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den) (m n : Nat) (hnm : n ≤ m) :
    Req (mellinMoment (besselSeq μ hμ m) n) (ofQ (μ n) (hμ n)) := by
  have hnd : n < m + 1 := by omega
  have hqorth : ∀ a b, a < m + 1 → b < m + 1 → a ≠ b →
      Qeq (qHil (gsFam a) (gsFam b) (m + 1)) (⟨0, 1⟩ : Q) :=
    fun a b ha hb hab => gsFam_ortho a b hab (m + 1) ha hb
  have hval : Qeq (qsumL (fun i => mul (pVec μ (m + 1) gsFam m i) (⟨1, i + n + 1⟩ : Q))
      (List.range (m + 1))) (μ n) :=
    Qeq_trans
      (qHil_den_pos (pVec μ (m + 1) gsFam m) (eVec n)
        (pVec_den μ (m + 1) gsFam gsFam_den hμ m) (eVec_den n) (m + 1))
      (Qeq_symm (qHil_eVec_right (pVec μ (m + 1) gsFam m)
        (pVec_den μ (m + 1) gsFam gsFam_den hμ m) (m + 1) n hnd))
      (realize_moment μ (m + 1) gsFam gsFam_den hμ hqorth (fun k _ => gsFam_monic k)
        (fun k _ idx hkidx => gsFam_support k idx hkidx) m (Nat.lt_succ_self m) n hnm)
  refine Req_trans (mellinMoment_qPolyTest (pVec μ (m + 1) gsFam m)
    (pVec_den μ (m + 1) gsFam gsFam_den hμ m) (m + 1) n) ?_
  exact Req_of_seq_Qeq (fun _ => hval)

-- ===========================================================================
-- ★ The completed element realizes the moment sequence.
-- ===========================================================================

set_option maxHeartbeats 1000000 in
/-- **★ THE MOMENT REALIZATION**: if the Riesz projections of `μ` are `L²`-Cauchy, the completed element
    `E = ⟨besselSeq μ, ·⟩` realizes `μ` on the moment map — `⟨E, xⁿ⟩ = ofQ (μ n)` for every `n`. The
    completion's reads are eventually exactly `ofQ (μ n)` (`besselSeq_moment`), and its `2/(j+1)` rate
    (`L2Elt_converges`) pins the limit. **Conditional** on the supplied Bessel-Cauchy certificate. -/
theorem besselSeq_L2Elt_moment (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den)
    (hcauchy : L2CauchyU (besselSeq μ hμ)) (n : Nat) :
    Req ((⟨besselSeq μ hμ, hcauchy⟩ : L2Elt).moment n) (ofQ (μ n) (hμ n)) := by
  -- `|ofQ(μ n) − ⟨E, xⁿ⟩| ≤ 2/(k+1)` for every `k`, by reading the completion at `j = k+n`.
  have key : ∀ k, Rle (Rabs (Rsub (ofQ (μ n) (hμ n))
      ((⟨besselSeq μ hμ, hcauchy⟩ : L2Elt).moment n))) (ofQ (⟨2, k + 1⟩ : Q) (Nat.succ_pos k)) := by
    intro k
    have h1 : 1 ≤ selfBnd (powTest n) := selfBnd_pos (powTest n)
    have hnM : n ≤ selfBnd (powTest n) * ((k + n) + 1) :=
      Nat.le_trans (by omega) (Nat.le_mul_of_pos_left ((k + n) + 1) h1)
    have hrd : Req (mellinMoment (besselSeq μ hμ (selfBnd (powTest n) * ((k + n) + 1))) n)
        (ofQ (μ n) (hμ n)) :=
      besselSeq_moment μ hμ (selfBnd (powTest n) * ((k + n) + 1)) n hnM
    have hconv := L2Elt_converges (⟨besselSeq μ hμ, hcauchy⟩ : L2Elt) (powTest n) (k + n)
    have hstep : Rle (Rabs (Rsub (ofQ (μ n) (hμ n))
        ((⟨besselSeq μ hμ, hcauchy⟩ : L2Elt).moment n)))
        (ofQ (⟨2, (k + n) + 1⟩ : Q) (Nat.succ_pos (k + n))) :=
      Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_symm hrd) (Req_refl _)))) hconv
    exact Rle_trans hstep (Rle_ofQ_ofQ (Nat.succ_pos (k + n)) (Nat.succ_pos k)
      (by show (2 : Int) * ((k + 1 : Nat) : Int) ≤ (2 : Int) * (((k + n) + 1 : Nat) : Int)
          push_cast; omega))
  refine Req_of_Rle_ofQ_all (C := 2) (fun k => ?_) (fun k => ?_)
  · -- `⟨E, xⁿ⟩ − ofQ(μ n) ≤ 2/(k+1)`
    refine Rle_trans (Rle_of_Req (Req_symm (Rneg_Rsub (ofQ (μ n) (hμ n))
      ((⟨besselSeq μ hμ, hcauchy⟩ : L2Elt).moment n)))) ?_
    exact Rle_trans (Rle_trans (Rle_Rabs_self (Rneg (Rsub (ofQ (μ n) (hμ n))
        ((⟨besselSeq μ hμ, hcauchy⟩ : L2Elt).moment n))))
      (Rle_of_Req (Rabs_Rneg _))) (key k)
  · -- `ofQ(μ n) − ⟨E, xⁿ⟩ ≤ 2/(k+1)`
    exact Rle_trans (Rle_Rabs_self (Rsub (ofQ (μ n) (hμ n))
      ((⟨besselSeq μ hμ, hcauchy⟩ : L2Elt).moment n))) (key k)

end Multiplicity.UOR.Bridge.F1Square.Square
